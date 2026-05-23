abstract class AgentEcosystemActionHandler {
  void onAgentEcosystemBackRequested();

  void onEcosystemRefreshRequested();

  void onImportEcosystemPackageRequested();

  void onGenerateIndexRequested();

  void onEcosystemTabSelected(String tabId);

  void onEcosystemEntrySelected(String entryId);

  void onCreateAgentRequested();

  void onCreateSkillRequested();

  void onCreateSkillGroupRequested();

  void onCreateAgentGroupRequested();
}
