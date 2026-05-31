import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_applicability_scope.dart';

class AgentGroupApplicabilityScopeNormalizerService {
  const AgentGroupApplicabilityScopeNormalizerService();

  AgentGroupApplicabilityScope normalize(JsonMap raw) {
    // 中文注释: 智能体组和单智能体作用域在文档层保持同一别名兼容规则，避免后续 UI 读写再分叉。
    return AgentGroupApplicabilityScope(
      allowedProjectTypeIds: _stringList(
        raw['allowed_project_type_ids'] ??
            raw['project_type_ids'] ??
            raw['project_types'],
      ),
      requiredTraitIds: _stringList(
        raw['required_trait_ids'] ?? raw['required_traits'],
      ),
      excludedTraitIds: _stringList(
        raw['excluded_trait_ids'] ?? raw['excluded_traits'],
      ),
      allowedModeIds: _stringList(
        raw['allowed_mode_ids'] ?? raw['mode_ids'] ?? raw['modes'],
      ),
      allowedStageIds: _stringList(
        raw['allowed_stage_ids'] ?? raw['stage_ids'] ?? raw['stages'],
      ),
    );
  }

  JsonMap toDocument(AgentGroupApplicabilityScope scope) {
    return <String, Object?>{
      'allowed_project_type_ids': ValueReaders.deepCopyList(
        scope.allowedProjectTypeIds.cast<Object?>(),
      ),
      'required_trait_ids': ValueReaders.deepCopyList(
        scope.requiredTraitIds.cast<Object?>(),
      ),
      'excluded_trait_ids': ValueReaders.deepCopyList(
        scope.excludedTraitIds.cast<Object?>(),
      ),
      'allowed_mode_ids': ValueReaders.deepCopyList(
        scope.allowedModeIds.cast<Object?>(),
      ),
      'allowed_stage_ids': ValueReaders.deepCopyList(
        scope.allowedStageIds.cast<Object?>(),
      ),
    };
  }

  List<String> _stringList(Object? value) {
    return ValueReaders.stringList(value);
  }
}
