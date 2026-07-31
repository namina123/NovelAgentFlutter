abstract class WorkbenchProjectPanelActionHandler {
  void onCreateProjectRequested();

  void onOpenProjectRequested();

  void onEditProjectInfoRequested();

  void onProjectTypeTransitionRequested() {}

  void onRuntimeBaselineConfigurationRequested() {}

  void onRefreshFilesRequested();

  void onProjectAgentGroupRequested();

  void onAgentEcosystemRequested();

  void onCurrentAgentSkillLoadoutRequested();

  void onTemplatesRequested();

  void onProjectAssetsRequested();

  void onProjectRagRequested() => onProjectAssetsRequested();

  void onCurrentAgentExpressionConstraintsRequested();

  // 中文注释: 工作台项目面板内联恢复长任务 run——复用总站/任务中心同源的 resume 路径（真重入队列）。
  // 默认空实现，避免波及所有 implementer；真正接入由 app_shell 的 ResourceManagerActionHandler implementer 覆写。
  void onLongTaskRunResumeRequested(String runId) {}
}
