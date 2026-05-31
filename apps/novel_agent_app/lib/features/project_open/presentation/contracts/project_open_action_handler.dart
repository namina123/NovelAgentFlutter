abstract class ProjectOpenActionHandler {
  void onProjectOpenRefreshRequested();

  void onProjectOpenCreateRequested();

  void onProjectOpenImportRequested();

  void onProjectOpenEntrySelected(String entryId);

  void onProjectOpenOpenRequested(String projectPath);
}
