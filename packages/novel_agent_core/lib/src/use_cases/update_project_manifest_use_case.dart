import '../project/project_descriptor.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_workspace_catalog.dart';
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
    String genre = '',
    String premise = '',
    String notes = '',
  }) async {
    // 中文注释: 项目信息更新统一同时刷新 manifest 与项目简介文档，保持工作区入口信息一致。
    final manifest = _projectManifestCodecService.create(
      title: title,
      projectType: projectType,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: ProjectManifestCodecService.manifestRelativePath,
      content: _projectManifestCodecService.encode(manifest),
    );
    final typeLabel = _projectTypeLabel(manifest.projectType);
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: 'specs/project_brief.md',
      content:
          '# ${manifest.title}\n\n- 项目类型：$typeLabel\n- 题材：${genre.trim()}\n- 核心设定：${premise.trim()}\n- 备注：${notes.trim()}\n',
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: 'README.md',
      content:
          '# ${manifest.title}\n\nNovelAgent Flutter 项目工作区。\n\n- 项目类型：$typeLabel\n',
    );
  }

  String _projectTypeLabel(String projectType) {
    // 中文注释: 项目类型标签只在简介文档中使用，因此直接从目录目录表外部轻量映射即可。
    for (final descriptor in ProjectWorkspaceCatalog.userWorkspaceDirs) {
      if (descriptor.path == 'outline/') {
        break;
      }
    }
    switch (projectType.trim()) {
      case 'long_task':
        return '长任务';
      case 'novel':
      default:
        return '小说';
    }
  }
}
