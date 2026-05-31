class ProjectAgentSkillLoadoutHistoryPathService {
  const ProjectAgentSkillLoadoutHistoryPathService();

  static const String directoryPath =
      '.novel_agent/history/agent_skill_loadouts';
  static const String indexPath = '$directoryPath/index.json';

  String filePath(String entryId) {
    return '$directoryPath/$entryId.json';
  }
}
