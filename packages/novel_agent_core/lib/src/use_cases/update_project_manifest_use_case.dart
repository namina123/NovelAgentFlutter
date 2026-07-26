import '../project/project_descriptor.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_manifest_commit_service.dart';
import 'read_project_file_use_case.dart';
import 'write_project_text_file_use_case.dart';

class UpdateProjectManifestUseCase {
  UpdateProjectManifestUseCase({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ProjectManifestCodecService? projectManifestCodecService,
    ReadProjectFileUseCase? readProjectFileUseCase,
  }) : _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _readProjectFileUseCase = readProjectFileUseCase,
       _projectManifestCommitService = ProjectManifestCommitService(
         writeProjectTextFileUseCase: writeProjectTextFileUseCase,
         projectManifestCodecService: projectManifestCodecService,
         readProjectFileUseCase: readProjectFileUseCase,
       );

  final ProjectManifestCodecService _projectManifestCodecService;
  final ReadProjectFileUseCase? _readProjectFileUseCase;
  final ProjectManifestCommitService _projectManifestCommitService;

  Future<void> execute({
    required ProjectDescriptor project,
    required String title,
    String genre = '',
    String premise = '',
    String notes = '',
  }) async {
    // 中文注释: 通用更新仅能改变展示元数据。类型、存储、知识库分支、运行基准和 trait
    // 都是项目合同，分别由转换或运行基准专用流程负责，不能用普通编辑入口传入。
    final currentTraitIds = _mergeTraitIds(
      project.additionalTraitIds,
      (await _readExistingAdditionalTraitIds(project)) ?? const <String>[],
    );
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: project.projectType,
      storageStrategy: project.storageStrategy,
      projectBranchId: project.projectBranchId,
      runtimeBaselineId: project.runtimeBaselineId,
      additionalTraitIds: currentTraitIds,
    );
    await _projectManifestCommitService.commit(
      project: project,
      manifest: manifest,
      genre: genre,
      premise: premise,
      notes: notes,
    );
  }

  Future<List<String>?> _readExistingAdditionalTraitIds(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 没有 readProjectFileUseCase（如纯单元测试夹具）时返回 null，回退到空列表。
    final reader = _readProjectFileUseCase;
    if (reader == null) {
      return null;
    }
    final source = await reader.execute(
      project,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (source == null || source.trim().isEmpty) {
      return null;
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

  List<String> _mergeTraitIds(
    List<String> descriptorTraitIds,
    List<String> manifestTraitIds,
  ) {
    final traitIds = <String>[];
    for (final traitId in <String>[
      ...descriptorTraitIds,
      ...manifestTraitIds,
    ]) {
      final cleanTraitId = traitId.trim();
      if (cleanTraitId.isNotEmpty && !traitIds.contains(cleanTraitId)) {
        traitIds.add(cleanTraitId);
      }
    }
    return traitIds;
  }
}
