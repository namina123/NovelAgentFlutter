abstract class ProjectOpenActionHandler {
  void onProjectOpenRefreshRequested();

  void onProjectOpenCreateRequested();

  void onProjectOpenImportRequested();

  void onProjectOpenEntrySelected(String entryId);

  void onProjectOpenOpenRequested(String projectPath);

  /// 删除作品目录。实现侧必须做二次确认与路径安全校验。
  void onProjectOpenDeleteRequested(String projectPath);
}
