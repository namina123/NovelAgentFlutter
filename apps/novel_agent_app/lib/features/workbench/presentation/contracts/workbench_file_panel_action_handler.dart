import '../models/project_create_request_view_data.dart';
import '../models/workspace_command_request_view_data.dart';

abstract class WorkbenchFilePanelActionHandler {
  void onModelSettingsRequested();

  void onCreateProjectRequested();

  void onOpenProjectRequested();

  void onProjectLauncherDismissed();

  void onProjectLauncherRefreshRequested();

  void onProjectEntryOpened(String projectPath);

  void onProjectCreationBackRequested();

  void onProjectCreationSubmitted(ProjectCreateRequestViewData request);

  void onRefreshFilesRequested();

  void onCreateFileRequested();

  void onCreateFolderRequested();

  void onImportRequested();

  void onCreateChapterRequested();

  void onSaveCurrentRequested();

  void onResourceEntrySelected(String entryId);

  /// 中文注释: 资源条目删除（文件或整目录）。entryId 即资源相对路径。
  /// 二次确认弹窗在界面层处理；本方法只负责落盘与刷新资源树/已打开标签。
  void onDeleteResourceEntryRequested(String entryId);

  /// 中文注释: 资源条目重命名（文件或整目录）。nextName 为新的文件/目录名（不含目录前缀，
  /// 由控制器重新拼回原所在目录）。确认与输入在界面层完成。
  void onRenameResourceEntryRequested(String entryId, String nextName);

  void onWorkspaceCommandDismissed();

  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  );

  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  );

  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request);
}
