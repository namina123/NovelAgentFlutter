import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_skill_loadout_history_entry.dart';
import 'agent_skill_loadout_normalizer_service.dart';

class AgentSkillLoadoutHistoryEntryNormalizerService {
  AgentSkillLoadoutHistoryEntryNormalizerService({
    AgentSkillLoadoutNormalizerService? loadoutNormalizerService,
  }) : _loadoutNormalizerService =
           loadoutNormalizerService ?? AgentSkillLoadoutNormalizerService();

  final AgentSkillLoadoutNormalizerService _loadoutNormalizerService;

  AgentSkillLoadoutHistoryEntry normalize(JsonMap raw) {
    // 中文注释: 历史记录只保存一次明确快照，不自动沉淀为技能组，也不夹带项目外的生态状态。
    final loadout = _loadoutNormalizerService.normalize(
      ValueReaders.mapValue(raw['loadout']),
    );
    final agentId = ValueReaders.stringValue(
      raw['agent_id'],
      loadout.agentId,
    ).trim();
    return AgentSkillLoadoutHistoryEntry(
      id: ValueReaders.stringValue(raw['id']).trim(),
      agentId: agentId,
      loadout: loadout,
      title: ValueReaders.stringValue(raw['title'] ?? raw['display_name']).trim(),
      createdAt: ValueReaders.stringValue(
        raw['created_at'] ?? raw['timestamp'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(raw['metadata'])),
    );
  }

  JsonMap toDocument(AgentSkillLoadoutHistoryEntry entry) {
    return <String, Object?>{
      'id': entry.id,
      'agent_id': entry.agentId,
      'title': entry.title,
      'created_at': entry.createdAt,
      'loadout': _loadoutNormalizerService.toDocument(entry.loadout),
      'metadata': ValueReaders.deepCopyMap(entry.metadata),
    };
  }
}
