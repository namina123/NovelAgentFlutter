import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';
import '../runtime/draft_file_path_service.dart';

class SaveDraftUseCase {
  SaveDraftUseCase({
    required ProjectWorkspacePort projectWorkspacePort,
    DraftFilePathService? draftFilePathService,
  }) : _projectWorkspacePort = projectWorkspacePort,
       _draftFilePathService = draftFilePathService ?? DraftFilePathService();

  final ProjectWorkspacePort _projectWorkspacePort;
  final DraftFilePathService _draftFilePathService;

  Future<String> execute({
    required ProjectDescriptor project,
    required String content,
    String title = '',
    String relativePath = '',
  }) async {
    // 中文注释: 自动内容保存规则统一在这个用例里，避免宿主层各自决定正文落盘路径命名。
    final resolvedPath = relativePath.trim().isEmpty
        ? _draftFilePathService.buildPath(title: title)
        : relativePath.trim();
    await _projectWorkspacePort.writeTextFile(
      project.rootPath,
      resolvedPath,
      content,
    );
    return resolvedPath;
  }
}
