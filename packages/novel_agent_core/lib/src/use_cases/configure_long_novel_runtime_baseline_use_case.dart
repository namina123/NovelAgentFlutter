import '../project/project_descriptor.dart';
import '../project/project_manifest.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_runtime_baseline_catalog_service.dart';
import '../project/project_runtime_profile_document_service.dart';
import '../project/project_type_catalog_service.dart';
import 'read_project_file_use_case.dart';
import 'write_project_text_file_use_case.dart';

/// Repairs or changes the runtime baseline of an existing long-novel project.
///
/// The manifest is the project contract and the runtime profile is its derived
/// execution configuration. They are written as a compensating transaction:
/// if either write fails, both documents are restored to their source state.
class ConfigureLongNovelRuntimeBaselineUseCase {
  ConfigureLongNovelRuntimeBaselineUseCase({
    required ReadProjectFileUseCase readProjectFileUseCase,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required Future<bool> Function(ProjectDescriptor project)
    readHasActiveLongTaskRun,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectRuntimeBaselineCatalogService? projectRuntimeBaselineCatalogService,
    ProjectRuntimeProfileDocumentService? projectRuntimeProfileDocumentService,
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _readProjectFileUseCase = readProjectFileUseCase,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _readHasActiveLongTaskRun = readHasActiveLongTaskRun,
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectRuntimeBaselineCatalogService =
           projectRuntimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService(),
       _projectRuntimeProfileDocumentService =
           projectRuntimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService(),
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final ReadProjectFileUseCase _readProjectFileUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final Future<bool> Function(ProjectDescriptor project)
  _readHasActiveLongTaskRun;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectRuntimeBaselineCatalogService
  _projectRuntimeBaselineCatalogService;
  final ProjectRuntimeProfileDocumentService
  _projectRuntimeProfileDocumentService;
  final ProjectTypeCatalogService _projectTypeCatalogService;

  Future<ProjectDescriptor> execute({
    required ProjectDescriptor project,
    required String runtimeBaselineId,
  }) async {
    // Runtime baselines are a long-novel-only contract. This repair path must
    // never become a back door for changing the project type.
    final descriptorType = _projectTypeCatalogService.normalize(
      project.projectType,
    );
    if (descriptorType != 'long_novel') {
      throw StateError('只有长篇长任务项目可以配置运行基准。');
    }
    if (await _readHasActiveLongTaskRun(project)) {
      throw StateError('存在活跃长任务时，必须先归档后才能修改运行基准。');
    }

    final normalizedRuntimeBaselineId = _projectRuntimeBaselineCatalogService
        .normalizeForProjectType('long_novel', runtimeBaselineId);
    if (normalizedRuntimeBaselineId.isEmpty) {
      throw StateError('请选择一个可用于长篇长任务的运行基准。');
    }

    final previousManifestContent = await _readProjectFileUseCase.execute(
      project,
      ProjectManifestCodecService.manifestRelativePath,
    );
    final sourceManifest = _projectManifestCodecService.parse(
      previousManifestContent ?? '',
      fallbackTitle: project.name,
      fallbackProjectType: project.projectType,
      fallbackStorageStrategy: project.storageStrategy,
      fallbackProjectBranchId: project.projectBranchId,
      fallbackRuntimeBaselineId: project.runtimeBaselineId,
      fallbackAdditionalTraitIds: project.additionalTraitIds,
    );
    if (sourceManifest.projectType != 'long_novel') {
      throw StateError('项目清单不是长篇长任务项目，不能配置运行基准。');
    }

    final updatedManifest = _projectManifestCodecService.create(
      title: sourceManifest.title,
      projectType: sourceManifest.projectType,
      // The descriptor comes from the opened workspace and therefore reflects
      // the actual storage backend, including repaired legacy projects.
      storageStrategy: project.storageStrategy,
      projectBranchId: sourceManifest.projectBranchId,
      runtimeBaselineId: normalizedRuntimeBaselineId,
      additionalTraitIds: _mergeTraitIds(
        sourceManifest.additionalTraitIds,
        project.additionalTraitIds,
      ),
    );
    final previousRuntimeProfile = await _readProjectFileUseCase.execute(
      project,
      ProjectRuntimeProfileDocumentService.profileRelativePath,
    );
    final updatedRuntimeProfile = _projectRuntimeProfileDocumentService
        .buildProfile(
          projectType: updatedManifest.projectType,
          runtimeBaselineId: updatedManifest.runtimeBaselineId,
        );

    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectRuntimeProfileDocumentService.profileRelativePath,
        content: _projectRuntimeProfileDocumentService.encode(
          updatedRuntimeProfile,
        ),
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectManifestCodecService.manifestRelativePath,
        content: _projectManifestCodecService.encode(updatedManifest),
      );
    } catch (_) {
      await _restoreSourceDocuments(
        project: project,
        sourceManifest: sourceManifest,
        previousManifestContent: previousManifestContent,
        previousRuntimeProfile: previousRuntimeProfile,
      );
      rethrow;
    }

    return ProjectDescriptor(
      id: project.id,
      name: updatedManifest.title,
      rootPath: project.rootPath,
      projectType: updatedManifest.projectType,
      storageStrategy: updatedManifest.storageStrategy,
      projectBranchId: updatedManifest.projectBranchId,
      runtimeBaselineId: updatedManifest.runtimeBaselineId,
      additionalTraitIds: updatedManifest.additionalTraitIds,
    );
  }

  Future<void> _restoreSourceDocuments({
    required ProjectDescriptor project,
    required ProjectManifest sourceManifest,
    required String? previousManifestContent,
    required String? previousRuntimeProfile,
  }) async {
    // A filesystem write has no portable transaction. Restore the manifest and
    // profile independently; the manifest remains authoritative if recovery is
    // interrupted a second time.
    final manifestContent =
        previousManifestContent ??
        _projectManifestCodecService.encode(sourceManifest);
    final profileContent =
        previousRuntimeProfile ??
        _projectRuntimeProfileDocumentService.encode(
          _projectRuntimeProfileDocumentService.buildProfile(
            projectType: sourceManifest.projectType,
            runtimeBaselineId: sourceManifest.runtimeBaselineId,
          ),
        );
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectManifestCodecService.manifestRelativePath,
        content: manifestContent,
      );
    } catch (_) {
      // Preserve the original write error. ProjectRuntimeProfileRepository
      // rejects a profile that disagrees with the manifest on reopening.
    }
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectRuntimeProfileDocumentService.profileRelativePath,
        content: profileContent,
      );
    } catch (_) {
      // Preserve the original write error for the caller; a later retry can
      // safely reconstruct the profile from the manifest descriptor.
    }
  }

  List<String> _mergeTraitIds(
    List<String> manifestTraitIds,
    List<String> descriptorTraitIds,
  ) {
    final traitIds = <String>[];
    for (final traitId in <String>[
      ...manifestTraitIds,
      ...descriptorTraitIds,
    ]) {
      final cleanTraitId = traitId.trim();
      if (cleanTraitId.isNotEmpty && !traitIds.contains(cleanTraitId)) {
        traitIds.add(cleanTraitId);
      }
    }
    return traitIds;
  }
}
