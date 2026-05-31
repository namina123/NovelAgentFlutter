import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectAgentSkillLoadoutDocumentCodecService {
  ProjectAgentSkillLoadoutDocumentCodecService({
    AgentSkillLoadoutNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ?? AgentSkillLoadoutNormalizerService();

  final AgentSkillLoadoutNormalizerService _normalizerService;

  List<AgentSkillLoadout> parseDocument(JsonMap document) {
    // 中文注释: 当前项目 loadout 文档只恢复项目内的实际装载，不负责历史和 preset。
    return ValueReaders.objectList(document['loadouts'])
        .map((item) => _normalizerService.normalize(ValueReaders.mapValue(item)))
        .where((item) => item.agentId.trim().isNotEmpty)
        .toList(growable: false);
  }

  JsonMap toDocument(List<AgentSkillLoadout> loadouts) {
    return <String, Object?>{
      'schema_version': 1,
      'loadouts': loadouts
          .map(_normalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
    };
  }
}
