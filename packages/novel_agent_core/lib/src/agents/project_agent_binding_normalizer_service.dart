import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_agent_binding.dart';
import 'project_agent_model_override.dart';
import 'project_agent_model_override_normalizer_service.dart';

class ProjectAgentBindingNormalizerService {
  ProjectAgentBindingNormalizerService({
    ProjectAgentModelOverrideNormalizerService? modelOverrideNormalizerService,
  }) : _modelOverrideNormalizerService =
           modelOverrideNormalizerService ??
           ProjectAgentModelOverrideNormalizerService();

  final ProjectAgentModelOverrideNormalizerService
  _modelOverrideNormalizerService;

  ProjectAgentBinding normalize(JsonMap raw) {
    // 中文注释: 项目级绑定只负责“这个项目启用了哪些智能体以及它们的项目内约束”，不回写智能体定义本体。
    final agentId = ValueReaders.stringValue(
      raw['agent_id'] ?? raw['id'],
    ).trim();
    final modelOverride = _normalizeModelOverride(raw, agentId);
    return ProjectAgentBinding(
      agentId: agentId,
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      enabled: ValueReaders.boolValue(raw['enabled'], true),
      selectedByDefault: ValueReaders.boolValue(
        raw['selected_by_default'] ?? raw['default'],
      ),
      stageIds: ValueReaders.stringList(raw['stage_ids'] ?? raw['stages']),
      modeIds: ValueReaders.stringList(raw['mode_ids'] ?? raw['modes']),
      styleBindingIds: ValueReaders.stringList(
        raw['style_binding_ids'] ?? raw['styles'],
      ),
      modelOverride: modelOverride,
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ProjectAgentBinding binding) {
    return <String, Object?>{
      'agent_id': binding.agentId,
      'display_name': binding.displayName,
      'enabled': binding.enabled,
      'selected_by_default': binding.selectedByDefault,
      'stage_ids': ValueReaders.deepCopyList(binding.stageIds.cast<Object?>()),
      'mode_ids': ValueReaders.deepCopyList(binding.modeIds.cast<Object?>()),
      'style_binding_ids': ValueReaders.deepCopyList(
        binding.styleBindingIds.cast<Object?>(),
      ),
      if (binding.modelOverride != null)
        'model_override': _modelOverrideNormalizerService.toDocument(
          binding.modelOverride!,
        ),
      'metadata': ValueReaders.deepCopyMap(binding.metadata),
    };
  }

  ProjectAgentModelOverride? _normalizeModelOverride(
    JsonMap raw,
    String agentId,
  ) {
    final nested = ValueReaders.mapValue(raw['model_override']);
    if (nested.isNotEmpty) {
      return _modelOverrideNormalizerService.normalize(<String, Object?>{
        ...nested,
        'agent_id': agentId,
      });
    }
    final legacy = <String, Object?>{
      'agent_id': agentId,
      'provider_profile': raw['provider_profile'],
      'model_id': raw['model_id'],
      'thinking_enabled': raw['thinking_enabled'],
      'thinking_effort': raw['thinking_effort'],
      'temperature': raw['temperature'],
      'top_p': raw['top_p'],
      'top_k': raw['top_k'],
      'advanced_model_overrides': raw['advanced_model_overrides'],
    };
    final normalized = _modelOverrideNormalizerService.normalize(legacy);
    return _modelOverrideNormalizerService.hasAnyValue(normalized)
        ? normalized
        : null;
  }
}
