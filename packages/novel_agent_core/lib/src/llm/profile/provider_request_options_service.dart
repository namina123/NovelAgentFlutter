import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'custom_model_reasoning_override_service.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_model_metadata_service.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderRequestOptionsService {
  ProviderRequestOptionsService({
    ProviderModelMetadataService? metadataService,
    ProviderThinkingParameterService? thinkingService,
    ProviderCustomParameterService? customParameterService,
    CustomModelReasoningOverrideService? customReasoningOverrideService,
  }) : _metadataService = metadataService ?? ProviderModelMetadataService(),
       _thinkingService = thinkingService ?? ProviderThinkingParameterService(),
       _customParameterService =
           customParameterService ?? ProviderCustomParameterService(),
       _customReasoningOverrideService =
           customReasoningOverrideService ??
           CustomModelReasoningOverrideService();

  final ProviderModelMetadataService _metadataService;
  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;
  final CustomModelReasoningOverrideService _customReasoningOverrideService;

  JsonMap buildRequestOptions(
    JsonMap runtimeProfile, {
    String apiMode = 'chat',
    JsonMap baseOptions = const <String, Object?>{},
  }) {
    // 中文注释: 这个服务只负责把运行态模型配置翻译成网关请求参数，不处理设置来源。
    final metadata = _metadataService.buildEditorMetadata(runtimeProfile);
    final result = ValueReaders.deepCopyMap(baseOptions);
    result['api_mode'] = apiMode.trim().isEmpty ? 'chat' : apiMode.trim();
    result['stream'] = ValueReaders.boolValue(
      runtimeProfile['streaming_enabled'],
      true,
    );
    if (ValueReaders.boolValue(metadata['supports_temperature'], true)) {
      result['temperature'] = ValueReaders.doubleValue(
        runtimeProfile['temperature'],
      );
    }
    if (ValueReaders.boolValue(metadata['supports_top_p'], true)) {
      result['top_p'] = ValueReaders.doubleValue(runtimeProfile['top_p']);
    }
    if (ValueReaders.boolValue(metadata['supports_top_k'])) {
      result['top_k'] = ValueReaders.intValue(runtimeProfile['top_k']);
    }
    final customReasoning = _customReasoningOverrideService.normalize(
      runtimeProfile['custom_reasoning_override'],
    );
    final effectiveReasoningProfile = customReasoning.isNotEmpty
        ? customReasoning
        : _runtimeReasoningProfile(runtimeProfile);
    if (effectiveReasoningProfile.isNotEmpty) {
      result.addAll(
        _customReasoningOverrideService.buildRequestParameters(
          effectiveReasoningProfile,
          enabled: ValueReaders.boolValue(runtimeProfile['thinking_enabled']),
          effort: ValueReaders.stringValue(
            runtimeProfile['thinking_effort'],
            'high',
          ),
        ),
      );
    } else {
      result.addAll(
        _thinkingService.thinkingRequestParameters(
          ValueReaders.boolValue(runtimeProfile['thinking_enabled']),
          ValueReaders.stringValue(runtimeProfile['thinking_effort'], 'high'),
          ValueReaders.stringValue(runtimeProfile['thinking_parameter_format']),
        ),
      );
    }
    for (final rawEntry in _customParameterService.normalizeCustomParameters(
      runtimeProfile['custom_parameters'],
    )) {
      final entry = ValueReaders.mapValue(rawEntry);
      final key = ValueReaders.stringValue(entry['key']).trim();
      if (key.isEmpty) {
        continue;
      }
      final value = entry['value'];
      if (_shouldSkipValue(value)) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  JsonMap _runtimeReasoningProfile(JsonMap runtimeProfile) {
    if (!ValueReaders.boolValue(runtimeProfile['supports_reasoning'])) {
      return <String, Object?>{};
    }
    final toggleStrategy = ValueReaders.mapValue(
      runtimeProfile['reasoning_toggle_parameter_strategy'],
    );
    final effortStrategy = ValueReaders.mapValue(
      runtimeProfile['reasoning_effort_parameter_strategy'],
    );
    if (toggleStrategy.isEmpty && effortStrategy.isEmpty) {
      return <String, Object?>{};
    }
    return <String, Object?>{
      'supports_reasoning': true,
      'reasoning_can_toggle': ValueReaders.boolValue(
        runtimeProfile['reasoning_can_toggle'],
        true,
      ),
      'reasoning_default_enabled': ValueReaders.boolValue(
        runtimeProfile['reasoning_default_enabled'],
      ),
      'reasoning_supports_effort': ValueReaders.boolValue(
        runtimeProfile['reasoning_supports_effort'],
      ),
      'reasoning_toggle_parameter_strategy': toggleStrategy,
      'reasoning_effort_parameter_strategy': effortStrategy,
    };
  }

  bool _shouldSkipValue(Object? value) {
    // 中文注释: 空字符串参数不应被透传，避免“未填写”被误判为显式覆盖。
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    return false;
  }
}
