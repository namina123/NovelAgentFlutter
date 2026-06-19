import '../project/project_descriptor.dart';
import '../project/knowledge_base_branch_catalog_service.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_storage_strategy.dart';
import '../project/project_support_document_catalog.dart';
import 'write_project_text_file_use_case.dart';

class UpdateProjectManifestUseCase {
  UpdateProjectManifestUseCase({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ProjectManifestCodecService? projectManifestCodecService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final ProjectManifestCodecService _projectManifestCodecService;

  Future<void> execute({
    required ProjectDescriptor project,
    required String title,
    required String projectType,
    ProjectStorageStrategy? storageStrategy,
    String? projectBranchId,
    String? runtimeBaselineId,
    String genre = '',
    String premise = '',
    String notes = '',
  }) async {
    // 中文注释: 项目信息更新统一同时刷新 manifest 与项目简介文档，保持工作区入口信息一致。
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: projectType,
      storageStrategy: storageStrategy ?? project.storageStrategy,
      projectBranchId: projectBranchId ?? project.projectBranchId,
      runtimeBaselineId: runtimeBaselineId ?? project.runtimeBaselineId,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: ProjectManifestCodecService.manifestRelativePath,
      content: _projectManifestCodecService.encode(manifest),
    );
    final typeLabel = _projectTypeLabel(
      manifest.projectType,
      projectBranchId: manifest.projectBranchId,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      content:
          '# 项目概览\n\n'
          '> 这是系统维护的快速概览，不是正式故事前提或长期创作宪章。\n'
          '> 题材、正式前提、风格边界和世界规则应继续沉淀到 premise/、outlines/、assets/ 下的正式文档中。\n\n'
          '- 项目标题：${manifest.title}\n'
          '- 项目类型：$typeLabel\n'
          '- 题材：${genre.trim()}\n'
          '- 当前已知核心设定：${premise.trim()}\n'
          '- 备注：${notes.trim()}\n',
    );
  }

  String _projectTypeLabel(String projectType, {String projectBranchId = ''}) {
    // 中文注释: 项目类型标签只在简介文档中使用，因此保留轻量级本地映射即可。
    switch (projectType.trim()) {
      case 'long_novel':
        return '长任务长篇';
      case 'knowledge_base':
        return const KnowledgeBaseBranchCatalogService().isRagBranch(
              projectBranchId,
            )
            ? '语料库'
            : '结构化资料知识库';
      case 'short_collection':
        return '短文集';
      case 'book_deconstruction':
        return '拆书项目';
      case 'novel':
      default:
        return '小说';
    }
  }
}
