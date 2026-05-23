import '../models/project_create_request_view_data.dart';

abstract class ResourceManagerActionHandler {
  void onModelSettingsRequested();

  void onCreateProjectRequested();

  void onOpenProjectRequested();

  void onProjectLauncherDismissed();

  void onProjectLauncherRefreshRequested();

  void onProjectEntryOpened(String projectPath);

  void onProjectCreationSubmitted(ProjectCreateRequestViewData request);

  void onEditProjectInfoRequested();

  void onRefreshFilesRequested();

  void onCreateFileRequested();

  void onCreateFolderRequested();

  void onImportRequested();

  void onCreateChapterRequested();

  void onSaveCurrentRequested();

  void onAgentEcosystemRequested();

  void onTasksRequested();

  void onReviewsRequested();

  void onTemplatesRequested();

  void onResourceEntrySelected(String entryId);
}
