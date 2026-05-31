import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectAgentSkillLoadoutHistoryDocumentCodecService {
  ProjectAgentSkillLoadoutHistoryDocumentCodecService({
    AgentSkillLoadoutHistoryEntryNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ??
           AgentSkillLoadoutHistoryEntryNormalizerService();

  final AgentSkillLoadoutHistoryEntryNormalizerService _normalizerService;

  AgentSkillLoadoutHistoryEntry parseDocument(JsonMap document) {
    return _normalizerService.normalize(document);
  }

  JsonMap toDocument(AgentSkillLoadoutHistoryEntry entry) {
    return _normalizerService.toDocument(entry);
  }
}
