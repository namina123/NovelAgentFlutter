import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../llm/profile/provider_custom_parameter_service.dart';
import '../llm/profile/provider_model_metadata_service.dart';
import '../llm/profile/provider_thinking_parameter_service.dart';

class AgentModelOverrideService {
  AgentModelOverrideService({
    ProviderCustomParameterService? customParameterService,
    ProviderThinkingParameterService? thinkingParameterService,
    ProviderModelMetadataService? metadataService,
  }) : _customParameterService =
           customParameterService ?? ProviderCustomParameterService(),
       _thinkingParameterService =
           thinkingParameterService ?? ProviderThinkingParameterService(),
       _metadataService = metadataService ?? ProviderModelMetadataService();

  final ProviderCustomParameterService _customParameterService;
  final ProviderThinkingParameterService _thinkingParameterService;
  final ProviderModelMetadataService _metadataService;

  List<Object?> normalizeAdvancedOverrides(Object? value) {
    // 中文注释: 智能体高级模型覆盖项使用和模型层同一套参数归一化，避免类型分叉。
    return _customParameterService.normalizeCustomParameters(value);
  }

  JsonMap applyOverrides(JsonMap runtimeProfile, JsonMap agentProfile) {
    // 中文注释: 智能体层的职责是“重写模型默认值”，这里不改动模型原始记录，只生成生效视图。
    final result = ValueReaders.deepCopyMap(runtimeProfile);
    final metadata = _metadataService.buildEditorMetadata(result);
    final supportsReasoning = ValueReaders.boolValue(
      metadata['supports_reasoning'],
    );
    final supportsTemperature = ValueReaders.boolValue(
      metadata['supports_temperature'],
      true,
    );
    final supportsTopP = ValueReaders.boolValue(
      metadata['supports_top_p'],
      true,
    );

    if (supportsReasoning) {
      result['thinking_enabled'] = ValueReaders.boolValue(
        agentProfile['thinking_enabled'],
      );
      result['thinking_effort'] = _thinkingParameterService
          .normalizeThinkingEffort(
            ValueReaders.stringValue(agentProfile['thinking_effort'], 'high'),
          );
    }
    if (supportsTemperature) {
      result['temperature'] = ValueReaders.doubleValue(
        agentProfile['temperature'],
        ValueReaders.doubleValue(result['temperature']),
      );
    }
    if (supportsTopP) {
      result['top_p'] = ValueReaders.doubleValue(
        agentProfile['top_p'],
        ValueReaders.doubleValue(result['top_p']),
      );
    }

    final mergedParameters = <Object?>[];
    mergedParameters.addAll(
      ValueReaders.objectList(result['custom_parameters']),
    );
    mergedParameters.addAll(
      normalizeAdvancedOverrides(agentProfile['advanced_model_overrides']),
    );
    result['custom_parameters'] = _customParameterService
        .resolveCustomParameters(
          mergedParameters,
          excludedKeys: ValueReaders.stringList(
            ValueReaders.mapValue(
              result['provider_model_capability'],
            )['excluded_parameters'],
          ),
        );
    result['agent_model_override_summary'] = <String, Object?>{
      'supports_reasoning': supportsReasoning,
      'supports_temperature': supportsTemperature,
      'supports_top_p': supportsTopP,
      'advanced_model_overrides': ValueReaders.deepCopyList(
        ValueReaders.objectList(result['custom_parameters']),
      ),
    };
    return result;
  }
}
