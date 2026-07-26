import '../project/project_descriptor.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_manifest_commit_service.dart';
import '../project/project_runtime_profile_document_service.dart';
import '../project/project_type_transition_blocker.dart';
import '../project/project_type_transition_preparation_service.dart';
import '../project/project_trait.dart';
import 'read_project_file_use_case.dart';
import 'write_project_text_file_use_case.dart';

class ExecuteProjectTypeTransitionUseCase {
  ExecuteProjectTypeTransitionUseCase({
    required ProjectTypeTransitionPreparationService
    projectTypeTransitionPreparationService,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required Future<bool> Function(ProjectDescriptor project)
    readHasActiveLongTaskRun,
    ReadProjectFileUseCase? readProjectFileUseCase,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectRuntimeProfileDocumentService? projectRuntimeProfileDocumentService,
  }) : _projectTypeTransitionPreparationService =
           projectTypeTransitionPreparationService,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _readHasActiveLongTaskRun = readHasActiveLongTaskRun,
       _readProjectFileUseCase = readProjectFileUseCase,
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectManifestCommitService = ProjectManifestCommitService(
         writeProjectTextFileUseCase: writeProjectTextFileUseCase,
         projectManifestCodecService: projectManifestCodecService,
         readProjectFileUseCase: readProjectFileUseCase,
       ),
       _projectRuntimeProfileDocumentService =
           projectRuntimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService();

  final ProjectTypeTransitionPreparationService
  _projectTypeTransitionPreparationService;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final Future<bool> Function(ProjectDescriptor project)
  _readHasActiveLongTaskRun;
  final ReadProjectFileUseCase? _readProjectFileUseCase;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectManifestCommitService _projectManifestCommitService;
  final ProjectRuntimeProfileDocumentService
  _projectRuntimeProfileDocumentService;

  /// Reads the same authoritative task state used by [execute].
  ///
  /// Composite workflows can use this before creating other durable artifacts,
  /// while execute still reads it again immediately before committing the
  /// transition to cover a task that starts concurrently.
  Future<bool> readHasActiveLongTaskRun(ProjectDescriptor project) {
    return _readHasActiveLongTaskRun(project);
  }

  Future<ProjectDescriptor> execute({
    required ProjectDescriptor project,
    required String targetProjectTypeId,
    String runtimeBaselineId = '',
    List<String>? preserveAdditionalTraitIds,
  }) async {
    // 中文注释: 执行阶段重新读取权威运行状态，不能信任 UI 缓存或调用方传入的布尔值。
    final hasActiveLongTaskRun = await readHasActiveLongTaskRun(project);
    final plan = _projectTypeTransitionPreparationService.prepare(
      project: project,
      targetProjectTypeId: targetProjectTypeId,
      runtimeBaselineId: runtimeBaselineId,
      hasActiveLongTaskRun: hasActiveLongTaskRun,
    );
    if (!plan.canTransition) {
      throw StateError(_buildBlockedMessage(plan.blockers));
    }
    final targetDefinition = plan.targetProjectTypeDefinition;
    if (targetDefinition == null) {
      throw StateError('项目类型转换计划缺少目标类型定义。');
    }
    final persistedTraitIds = await _readPersistedAdditionalTraitIds(project);
    final additionalTraitIds = _mergeTraitIds(
      _mergeTraitIds(project.additionalTraitIds, persistedTraitIds),
      <String>[
        if (project.projectType.trim() == 'book_deconstruction')
          ProjectTrait.bookDeconstruction.id,
        ...?preserveAdditionalTraitIds,
      ],
    );
    final targetManifest = _projectManifestCodecService.create(
      title: project.name,
      projectType: targetDefinition.id,
      storageStrategy: plan.targetStorageStrategy,
      projectBranchId: project.projectBranchId,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
      additionalTraitIds: additionalTraitIds,
    );
    // Keep the manifest as the transition commit marker. If generating the
    // runtime profile fails, reopening the workspace must still describe the
    // old project type so a retry executes the transition again.
    final runtimeProfile = _projectRuntimeProfileDocumentService.buildProfile(
      projectType: targetDefinition.id,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
    );
    final previousRuntimeProfile = await _readProjectFileUseCase?.execute(
      project,
      ProjectRuntimeProfileDocumentService.profileRelativePath,
    );
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectRuntimeProfileDocumentService.profileRelativePath,
        content: _projectRuntimeProfileDocumentService.encode(runtimeProfile),
      );
      await _projectManifestCommitService.commit(
        project: project,
        manifest: targetManifest,
      );
    } catch (_) {
      await _restoreSourceRuntimeProfile(
        project: project,
        previousRuntimeProfile: previousRuntimeProfile,
      );
      rethrow;
    }
    return ProjectDescriptor(
      id: project.id,
      name: project.name,
      rootPath: project.rootPath,
      projectType: targetDefinition.id,
      storageStrategy: plan.targetStorageStrategy,
      projectBranchId: targetManifest.projectBranchId,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
      additionalTraitIds: additionalTraitIds,
    );
  }

  String _buildBlockedMessage(List<ProjectTypeTransitionBlocker> blockers) {
    // 中文注释: 执行失败时只把核心阻断原因串起来，方便上层直接展示或记录。
    return blockers.map((item) => item.message).join('；');
  }

  List<String> _mergeTraitIds(
    List<String> existingTraitIds,
    List<String> preservedTraitIds,
  ) {
    final traitIds = <String>[];
    for (final traitId in <String>[...existingTraitIds, ...preservedTraitIds]) {
      final cleanTraitId = traitId.trim();
      if (cleanTraitId.isNotEmpty && !traitIds.contains(cleanTraitId)) {
        traitIds.add(cleanTraitId);
      }
    }
    return traitIds;
  }

  Future<List<String>> _readPersistedAdditionalTraitIds(
    ProjectDescriptor project,
  ) async {
    final reader = _readProjectFileUseCase;
    if (reader == null) {
      return const <String>[];
    }
    final source = await reader.execute(
      project,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (source == null || source.trim().isEmpty) {
      return const <String>[];
    }
    return _projectManifestCodecService
        .parse(
          source,
          fallbackTitle: project.name,
          fallbackProjectType: project.projectType,
          fallbackStorageStrategy: project.storageStrategy,
          fallbackProjectBranchId: project.projectBranchId,
          fallbackRuntimeBaselineId: project.runtimeBaselineId,
          fallbackAdditionalTraitIds: project.additionalTraitIds,
        )
        .additionalTraitIds;
  }

  Future<void> _restoreSourceRuntimeProfile({
    required ProjectDescriptor project,
    required String? previousRuntimeProfile,
  }) async {
    // 中文注释: runtime profile 先于 manifest 写入，因此后续提交失败时必须恢复源项目画像；
    // 否则重开会得到 source manifest + target baseline 的漂移状态。
    final sourceContent =
        previousRuntimeProfile ??
        _projectRuntimeProfileDocumentService.encode(
          _projectRuntimeProfileDocumentService.buildProfile(
            projectType: project.projectType,
            runtimeBaselineId: project.runtimeBaselineId,
          ),
        );
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectRuntimeProfileDocumentService.profileRelativePath,
        content: sourceContent,
      );
    } catch (_) {
      // 中文注释: 主错误仍应返回给调用方；重开时 repository 还会以 manifest descriptor 兜底过滤残留 profile。
    }
  }
}
