import '../use_cases/read_project_file_use_case.dart';
import '../use_cases/write_project_text_file_use_case.dart';
import 'knowledge_base_branch_catalog_service.dart';
import 'project_descriptor.dart';
import 'project_manifest.dart';
import 'project_manifest_codec_service.dart';
import 'project_support_document_catalog.dart';

/// Internal persistence primitive for a manifest that has already been
/// validated by its owning workflow.
///
/// Metadata updates and project-type transitions share the same commit order:
/// write the derived overview first, then use the manifest as the reopen-time
/// commit marker, and restore the overview if that commit fails.
class ProjectManifestCommitService {
  ProjectManifestCommitService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ProjectManifestCodecService? projectManifestCodecService,
    ReadProjectFileUseCase? readProjectFileUseCase,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _readProjectFileUseCase = readProjectFileUseCase;

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ReadProjectFileUseCase? _readProjectFileUseCase;

  Future<void> commit({
    required ProjectDescriptor project,
    required ProjectManifest manifest,
    String genre = '',
    String premise = '',
    String notes = '',
  }) async {
    final previousOverviewContent = await _readExistingOverviewContent(project);
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      content: _buildOverviewContent(
        title: manifest.title,
        typeLabel: _projectTypeLabel(
          manifest.projectType,
          projectBranchId: manifest.projectBranchId,
        ),
        genre: genre,
        premise: premise,
        notes: notes,
      ),
    );
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectManifestCodecService.manifestRelativePath,
        content: _projectManifestCodecService.encode(manifest),
      );
    } catch (error, stackTrace) {
      await _restoreSourceOverview(
        project: project,
        previousOverviewContent: previousOverviewContent,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String?> _readExistingOverviewContent(ProjectDescriptor project) {
    final reader = _readProjectFileUseCase;
    if (reader == null) {
      return Future<String?>.value();
    }
    return reader.execute(
      project,
      ProjectSupportDocumentCatalog.projectOverviewRelativePath,
    );
  }

  Future<void> _restoreSourceOverview({
    required ProjectDescriptor project,
    required String? previousOverviewContent,
  }) async {
    final sourceContent =
        previousOverviewContent ??
        _buildOverviewContent(
          title: project.name,
          typeLabel: _projectTypeLabel(
            project.projectType,
            projectBranchId: project.projectBranchId,
          ),
          genre: '',
          premise: '',
          notes: '',
        );
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: ProjectSupportDocumentCatalog.projectOverviewRelativePath,
        content: sourceContent,
      );
    } catch (_) {
      // Preserve the original manifest write failure.
    }
  }

  String _buildOverviewContent({
    required String title,
    required String typeLabel,
    required String genre,
    required String premise,
    required String notes,
  }) {
    return '# 项目概览\n\n'
        '> 这是系统维护的快速概览，不是正式故事前提或长期创作宪章。\n'
        '> 题材、正式前提、风格边界和世界规则应继续沉淀到 premise/、outlines/、assets/ 下的正式文档中。\n\n'
        '- 项目标题：${title.trim()}\n'
        '- 项目类型：$typeLabel\n'
        '- 题材：${genre.trim()}\n'
        '- 当前已知核心设定：${premise.trim()}\n'
        '- 备注：${notes.trim()}\n';
  }

  String _projectTypeLabel(String projectType, {String projectBranchId = ''}) {
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
