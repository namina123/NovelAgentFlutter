import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';

class ReadProjectFileUseCase {
  const ReadProjectFileUseCase(this._projectWorkspacePort);

  final ProjectWorkspacePort _projectWorkspacePort;

  Future<String?> execute(ProjectDescriptor project, String relativePath) {
    // 中文注释: 项目文件读取收口在用例层，避免 GUI 和 CLI 直接散落文件访问细节。
    return _projectWorkspacePort.readTextFile(project.rootPath, relativePath);
  }
}
