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

  void onWorkspaceCommandDismissed();

  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  );

  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request);
}
