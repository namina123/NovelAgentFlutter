abstract class ProjectCollectionActionHandler {
  void onProjectCollectionBackRequested();

  void onProjectCollectionRefreshRequested();

  void onProjectCollectionEntrySelected(String entryId);

  void onProjectCollectionOpenRequested(String entryId);

  void onProjectCollectionCreateRequested();
}
