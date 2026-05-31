import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_applicability_scope.dart';

class AgentApplicabilityScopeNormalizerService {
  const AgentApplicabilityScopeNormalizerService();

  AgentApplicabilityScope normalize(JsonMap raw) {
    // 中文注释: 这里统一把文档层的适用范围字段收束成强类型 scope，避免 adapter 和 app 各自维护别名解析。
    return AgentApplicabilityScope(
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

  JsonMap toDocument(AgentApplicabilityScope scope) {
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
