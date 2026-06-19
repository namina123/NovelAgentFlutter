abstract class WorkbenchProjectPanelActionHandler {
  void onCreateProjectRequested();

  void onOpenProjectRequested();

  void onEditProjectInfoRequested();

  void onProjectTypeTransitionRequested() {}

  void onRefreshFilesRequested();

  void onProjectAgentGroupRequested();

  void onAgentEcosystemRequested();

  void onCurrentAgentSkillLoadoutRequested();

  void onTemplatesRequested();

  void onProjectAssetsRequested();

  void onProjectRagRequested() => onProjectAssetsRequested();

  void onCurrentAgentExpressionConstraintsRequested();
}
