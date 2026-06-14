import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectSessionWorkspaceSnapshot {
  const ProjectSessionWorkspaceSnapshot({
    required this.sessionRecords,
    required this.activeSessionId,
  });

  final List<JsonMap> sessionRecords;
  final String activeSessionId;
}
