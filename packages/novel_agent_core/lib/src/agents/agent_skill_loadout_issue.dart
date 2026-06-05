import 'agent_skill_loadout_issue_code.dart';

class AgentSkillLoadoutIssue {
  const AgentSkillLoadoutIssue({
    required this.code,
    required this.subjectId,
    this.detailIds = const <String>[],
    this.message = '',
    this.metadata = const <String, Object?>{},
  });

  final AgentSkillLoadoutIssueCode code;
  final String subjectId;
  final List<String> detailIds;
  final String message;
  final Map<String, Object?> metadata;
}
