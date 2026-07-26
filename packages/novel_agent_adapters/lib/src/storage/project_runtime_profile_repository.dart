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
    final profile = _documentService.parse(
      content ?? '',
      fallbackProjectType: project.projectType,
      fallbackRuntimeBaselineId: project.runtimeBaselineId,
    );
    // 中文注释: manifest descriptor 是项目类型和运行基准的事实源；profile 是该事实的运行配置。
    // 半写入、旧文件或外部编辑不能让 profile 反向改写当前项目的类型能力。
    if (profile.projectType.trim() != project.projectType.trim() ||
        profile.runtimeBaselineId.trim() != project.runtimeBaselineId.trim()) {
      return _documentService.buildProfile(
        projectType: project.projectType,
        runtimeBaselineId: project.runtimeBaselineId,
      );
    }
    return profile;
  }
}
