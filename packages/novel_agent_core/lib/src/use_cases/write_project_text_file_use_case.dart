import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';

class WriteProjectTextFileUseCase {
  WriteProjectTextFileUseCase({
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectWorkspacePort = projectWorkspacePort;

  final ProjectWorkspacePort _projectWorkspacePort;

  Future<void> execute({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
  }) {
    // 中文注释: 通用文本写入用例只承接项目内相对路径写入，不混入草稿专属命名或目录策略。
    return _projectWorkspacePort.writeTextFile(
      project.rootPath,
      relativePath,
      content,
    );
  }
}
