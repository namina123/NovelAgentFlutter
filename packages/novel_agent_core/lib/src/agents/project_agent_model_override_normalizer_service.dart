import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../llm/profile/provider_custom_parameter_service.dart';
import 'project_agent_model_override.dart';

class ProjectAgentModelOverrideNormalizerService {
  ProjectAgentModelOverrideNormalizerService({
    ProviderCustomParameterService? customParameterService,
  }) : _customParameterService =
           customParameterService ?? ProviderCustomParameterService();

  final ProviderCustomParameterService _customParameterService;

  ProjectAgentModelOverride normalize(JsonMap raw) {
    // 中文注释: 项目级模型覆写只表达“这个项目里这个智能体怎么跑”，不混进智能体身份定义本体。
    final agentId = ValueReaders.stringValue(raw['agent_id']).trim();
    return ProjectAgentModelOverride(
      agentId: agentId,
      providerProfile: ValueReaders.stringValue(raw['provider_profile']).trim(),
      modelId: ValueReaders.stringValue(raw['model_id']).trim(),
      thinkingEnabled: raw.containsKey('thinking_enabled')
          ? ValueReaders.boolValue(raw['thinking_enabled'])
          : null,
      thinkingEffort: ValueReaders.stringValue(raw['thinking_effort']).trim(),
      temperature: raw['temperature'] == null
          ? null
          : ValueReaders.doubleValue(raw['temperature']),
      topP: raw['top_p'] == null
          ? null
          : ValueReaders.doubleValue(raw['top_p']),
      topK: raw['top_k'] == null ? null : ValueReaders.intValue(raw['top_k']),
      advancedModelOverrides: _customParameterService.normalizeCustomParameters(
        raw['advanced_model_overrides'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectAgentModelOverride override) {
    return <String, Object?>{
      'agent_id': override.agentId,
      'provider_profile': override.providerProfile,
      'model_id': override.modelId,
      if (override.thinkingEnabled != null)
        'thinking_enabled': override.thinkingEnabled,
      if (override.thinkingEffort.trim().isNotEmpty)
        'thinking_effort': override.thinkingEffort,
      if (override.temperature != null) 'temperature': override.temperature,
      if (override.topP != null) 'top_p': override.topP,
      if (override.topK != null) 'top_k': override.topK,
      'advanced_model_overrides': ValueReaders.deepCopyList(
        override.advancedModelOverrides,
      ),
      'metadata': ValueReaders.deepCopyMap(override.metadata),
    };
  }

  bool hasAnyValue(ProjectAgentModelOverride override) {
    return override.providerProfile.trim().isNotEmpty ||
        override.modelId.trim().isNotEmpty ||
        override.thinkingEnabled != null ||
        override.thinkingEffort.trim().isNotEmpty ||
        override.temperature != null ||
        override.topP != null ||
        override.topK != null ||
        override.advancedModelOverrides.isNotEmpty ||
        override.metadata.isNotEmpty;
  }
}
