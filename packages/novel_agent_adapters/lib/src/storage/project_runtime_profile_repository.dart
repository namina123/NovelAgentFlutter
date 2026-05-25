import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectRuntimeProfileRepository {
  ProjectRuntimeProfileRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectRuntimeProfileDocumentService? documentService,
  }) : _workspacePort = workspacePort,
       _documentService =
           documentService ?? ProjectRuntimeProfileDocumentService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectRuntimeProfileDocumentService _documentService;

  Future<ProjectRuntimeProfile> load(ProjectDescriptor project) async {
    // 中文注释: 项目级运行画像统一从项目隐藏目录读取，缺失时按项目描述兜底生成默认基线。
    final content = await _workspacePort.readTextFile(
      project.rootPath,
      ProjectRuntimeProfileDocumentService.profileRelativePath,
    );
    return _documentService.parse(
      content ?? '',
      fallbackProjectType: project.projectType,
      fallbackRuntimeBaselineId: project.runtimeBaselineId,
    );
  }
}
