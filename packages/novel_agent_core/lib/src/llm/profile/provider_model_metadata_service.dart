import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_profile_constants.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderModelMetadataService {
  ProviderModelMetadataService({
    ProviderThinkingParameterService? thinkingService,
    ProviderCustomParameterService? customParameterService,
  }) : _thinkingService = thinkingService ?? ProviderThinkingParameterService(),
       _customParameterService =
           customParameterService ?? ProviderCustomParameterService();

  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;

  JsonMap buildEditorMetadata(JsonMap runtimeProfile) {
    // 中文注释: 这个服务只负责把运行态配置投影成前端更容易消费的“模型元能力摘要”。
    final capability = ValueReaders.mapValue(
      runtimeProfile['provider_model_capability'],
    );
    final supported = ValueReaders.stringList(
      capability['supported_parameters'],
    );
    final unsupported = ValueReaders.stringList(
      capability['unsupported_parameters'],
    );
    final thinkingFormat = ValueReaders.stringValue(
      runtimeProfile['thinking_parameter_format'],
      ProviderProfileConstants.thinkingFormatNone,
    );
    final thinkingMetadata = _thinkingService.thinkingMetadata(thinkingFormat);
    final supportsTemperature = _supportsStandardParameter(
      'temperature',
      supported,
      unsupported,
    );
    final supportsTopP = _supportsStandardParameter(
      'top_p',
      supported,
      unsupported,
    );
    final supportsTopK = _supportsStandardParameter(
      'top_k',
      supported,
      unsupported,
    );
    final supportsReasoning =
        ValueReaders.boolValue(thinkingMetadata['thinking_supported']) ||
        supported.contains('thinking') ||
        supported.contains('enable_thinking') ||
        supported.contains('reasoning_effort');
    final parameterDefinitions = ValueReaders.mapList(
      capability['parameter_definitions'],
    );
    return <String, Object?>{
      'provider_id': ValueReaders.stringValue(runtimeProfile['provider_id']),
      'provider_label': ValueReaders.stringValue(
        runtimeProfile['provider_label'],
      ),
      'protocol_mode': ValueReaders.stringValue(
        runtimeProfile['kind'],
        ProviderProfileConstants.kindOpenAiCompatible,
      ),
      'base_url': ValueReaders.stringValue(runtimeProfile['base_url']).trim(),
      'model_id': ValueReaders.stringValue(runtimeProfile['model']).trim(),
      'model_name': ValueReaders.stringValue(runtimeProfile['name']).trim(),
      'context_length': ValueReaders.intValue(runtimeProfile['context_length']),
      'max_output_tokens': ValueReaders.intValue(
        runtimeProfile['max_output_tokens'],
      ),
      'supports_reasoning': supportsReasoning,
      'thinking_parameter_format':
          thinkingMetadata['thinking_parameter_format'],
      'thinking_parameter_label': thinkingMetadata['thinking_parameter_label'],
      'thinking_enable_parameter_keys':
          thinkingMetadata['thinking_enable_parameter_keys'],
      'thinking_effort_supported':
          thinkingMetadata['thinking_effort_supported'],
      'thinking_effort_options': thinkingMetadata['thinking_effort_options'],
      'supports_temperature': supportsTemperature,
      'supports_top_p': supportsTopP,
      'supports_top_k': supportsTopK,
      'supports_streaming': ValueReaders.boolValue(
        runtimeProfile['supports_streaming'],
        true,
      ),
      'supports_tools': ValueReaders.boolValue(
        runtimeProfile['supports_tools'],
        true,
      ),
      'supports_tool_choice': ValueReaders.boolValue(
        runtimeProfile['supports_tool_choice'],
        false,
      ),
      'parameter_definitions': ValueReaders.deepCopyList(
        parameterDefinitions.cast<Object?>(),
      ),
      'custom_parameter_types': ProviderProfileConstants.customParameterTypes,
      'supported_parameters': supported,
      'unsupported_parameters': unsupported,
      'model_default_parameters': _modelDefaultParameters(
        runtimeProfile,
        supportsTemperature: supportsTemperature,
        supportsTopP: supportsTopP,
        supportsTopK: supportsTopK,
        supportsReasoning: supportsReasoning,
      ),
    };
  }

  List<Object?> _modelDefaultParameters(
    JsonMap runtimeProfile, {
    required bool supportsTemperature,
    required bool supportsTopP,
    required bool supportsTopK,
    required bool supportsReasoning,
  }) {
    // 中文注释: 这里把模型层默认参数整理成统一列表，方便前端直接画可编辑条目。
    final result = <Object?>[];
    if (supportsReasoning) {
      result.add(<String, Object?>{
        'key': 'thinking_enabled',
        'type': 'boolean',
        'value': ValueReaders.boolValue(runtimeProfile['thinking_enabled']),
      });
      result.add(<String, Object?>{
        'key': 'thinking_effort',
        'type': 'string',
        'value': _thinkingService.normalizeThinkingEffort(
          ValueReaders.stringValue(runtimeProfile['thinking_effort'], 'high'),
        ),
      });
    }
    if (supportsTemperature) {
      result.add(<String, Object?>{
        'key': 'temperature',
        'type': 'number',
        'value': ValueReaders.doubleValue(
          runtimeProfile['temperature'],
          ProviderProfileConstants.defaultTemperature,
        ),
      });
    }
    if (supportsTopP) {
      result.add(<String, Object?>{
        'key': 'top_p',
        'type': 'number',
        'value': ValueReaders.doubleValue(
          runtimeProfile['top_p'],
          ProviderProfileConstants.defaultTopP,
        ),
      });
    }
    if (supportsTopK) {
      result.add(<String, Object?>{
        'key': 'top_k',
        'type': 'integer',
        'value': ValueReaders.intValue(
          runtimeProfile['top_k'],
          ProviderProfileConstants.defaultTopK,
        ),
      });
    }
    result.addAll(
      _customParameterService.normalizeCustomParameters(
        runtimeProfile['custom_parameters'],
      ),
    );
    return result;
  }

  bool _supportsStandardParameter(
    String key,
    List<String> supported,
    List<String> unsupported,
  ) {
    // 中文注释: 标准参数支持性优先尊重显式黑名单，其次看白名单，最后回退到保守默认值。
    if (unsupported.contains(key)) {
      return false;
    }
    if (supported.isNotEmpty) {
      return supported.contains(key);
    }
    return true;
  }
}
