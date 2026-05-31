import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_skill_loadout.dart';
import 'agent_skill_loadout_scope.dart';
import 'agent_skill_loadout_source.dart';
import 'agent_string_list_service.dart';

class AgentSkillLoadoutNormalizerService {
  AgentSkillLoadoutNormalizerService({
    AgentStringListService? stringListService,
  }) : _stringListService = stringListService ?? AgentStringListService();

  final AgentStringListService _stringListService;

  AgentSkillLoadout normalize(JsonMap raw) {
    // 中文注释: loadout 文档只表达“当前项目如何装载技能”，不回写 agent 静态定义，也不承担展开逻辑。
    return AgentSkillLoadout(
      agentId: ValueReaders.stringValue(raw['agent_id'] ?? raw['id']).trim(),
      source: _sourceFromValue(raw['source']),
      scope: _normalizeScope(ValueReaders.mapValue(raw['scope'])),
      skillGroupIds: _stringListService.normalize(
        raw['skill_group_ids'] ?? raw['skill_groups'],
      ),
      extraSkillIds: _stringListService.normalize(
        raw['extra_skill_ids'] ?? raw['extra_skills'] ?? raw['skills'],
      ),
      disabledSkillIds: _stringListService.normalize(
        raw['disabled_skill_ids'] ?? raw['disabled_skills'],
      ),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(raw['metadata'])),
    );
  }

  JsonMap toDocument(AgentSkillLoadout loadout) {
    return <String, Object?>{
      'agent_id': loadout.agentId,
      'source': loadout.source.id,
      'scope': _scopeToDocument(loadout.scope),
      'skill_group_ids': ValueReaders.deepCopyList(
        loadout.skillGroupIds.cast<Object?>(),
      ),
      'extra_skill_ids': ValueReaders.deepCopyList(
        loadout.extraSkillIds.cast<Object?>(),
      ),
      'disabled_skill_ids': ValueReaders.deepCopyList(
        loadout.disabledSkillIds.cast<Object?>(),
      ),
      'metadata': ValueReaders.deepCopyMap(loadout.metadata),
    };
  }

  AgentSkillLoadoutScope _normalizeScope(JsonMap raw) {
    return AgentSkillLoadoutScope(
      projectTypeIds: _stringListService.normalize(
        raw['project_type_ids'] ?? raw['project_types'],
      ),
      agentGroupIds: _stringListService.normalize(
        raw['agent_group_ids'] ?? raw['groups'],
      ),
      modeIds: _stringListService.normalize(raw['mode_ids'] ?? raw['modes']),
      stageIds: _stringListService.normalize(raw['stage_ids'] ?? raw['stages']),
    );
  }

  JsonMap _scopeToDocument(AgentSkillLoadoutScope scope) {
    return <String, Object?>{
      'project_type_ids': ValueReaders.deepCopyList(
        scope.projectTypeIds.cast<Object?>(),
      ),
      'agent_group_ids': ValueReaders.deepCopyList(
        scope.agentGroupIds.cast<Object?>(),
      ),
      'mode_ids': ValueReaders.deepCopyList(scope.modeIds.cast<Object?>()),
      'stage_ids': ValueReaders.deepCopyList(scope.stageIds.cast<Object?>()),
    };
  }

  AgentSkillLoadoutSource _sourceFromValue(Object? rawSource) {
    switch (ValueReaders.stringValue(rawSource).trim()) {
      case 'agent_default':
        return AgentSkillLoadoutSource.agentDefault;
      case 'history_restore':
        return AgentSkillLoadoutSource.historyRestore;
      case 'saved_preset':
        return AgentSkillLoadoutSource.savedPreset;
      case 'ad_hoc':
        return AgentSkillLoadoutSource.adHoc;
      case 'project_selection':
      default:
        return AgentSkillLoadoutSource.projectSelection;
    }
  }
}
