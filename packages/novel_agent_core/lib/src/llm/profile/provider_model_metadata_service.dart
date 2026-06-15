import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../catalog/writing_model_reasoning_profile_service.dart';
import 'custom_model_reasoning_override_service.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_profile_constants.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderModelMetadataService {
  ProviderModelMetadataService({
    ProviderThinkingParameterService? thinkingService,
    ProviderCustomParameterService? customParameterService,
    WritingModelReasoningProfileService? writingReasoningProfileService,
    CustomModelReasoningOverrideService? customReasoningOverrideService,
  }) : _thinkingService = thinkingService ?? ProviderThinkingParameterService(),
       _customParameterService =
           customParameterService ?? ProviderCustomParameterService(),
       _writingReasoningProfileService =
           writingReasoningProfileService ??
           WritingModelReasoningProfileService(),
       _customReasoningOverrideService =
           customReasoningOverrideService ??
           CustomModelReasoningOverrideService();

  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;
  final WritingModelReasoningProfileService _writingReasoningProfileService;
  final CustomModelReasoningOverrideService _customReasoningOverrideService;

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
    final writingReasoning = _writingReasoningProfileService.resolve(
      providerId: ValueReaders.stringValue(runtimeProfile['provider_id']),
      modelId: ValueReaders.stringValue(runtimeProfile['model']),
      baseUrl: ValueReaders.stringValue(runtimeProfile['base_url']),
    );
    final customReasoning = _customReasoningOverrideService.normalize(
      runtimeProfile['custom_reasoning_override'],
    );
    final effectiveReasoning = customReasoning.isNotEmpty
        ? customReasoning
        : writingReasoning;
    final matchedCanonicalModelId = customReasoning.isNotEmpty
        ? ''
        : ValueReaders.stringValue(
            writingReasoning['matched_canonical_model_id'],
          );
    final thinkingMetadata = customReasoning.isNotEmpty
        ? <String, Object?>{
            'thinking_supported': ValueReaders.boolValue(
              effectiveReasoning['supports_reasoning'],
            ),
            'thinking_parameter_format': _customReasoningOverrideService
                .compatibilityThinkingFormat(customReasoning),
            'thinking_parameter_label': _customReasoningOverrideService
                .parameterLabel(customReasoning),
            'thinking_enable_parameter_keys': _customReasoningOverrideService
                .toggleParameterKeys(customReasoning),
            'thinking_effort_supported': ValueReaders.boolValue(
              effectiveReasoning['reasoning_supports_effort'],
            ),
            'thinking_effort_options': ValueReaders.stringList(
              effectiveReasoning['reasoning_effort_options'],
            ),
            'thinking_effort_parameter_key': ValueReaders.stringValue(
              ValueReaders.mapValue(
                effectiveReasoning['reasoning_effort_parameter_strategy'],
              )['key'],
            ),
            'thinking_effort_parameter_label': _customReasoningOverrideService
                .effortParameterLabel(customReasoning),
          }
        : _thinkingService.thinkingMetadata(thinkingFormat);
    final reasoningModeBehavior = ValueReaders.stringValue(
      effectiveReasoning['reasoning_mode_behavior'],
      ValueReaders.boolValue(thinkingMetadata['thinking_supported'])
          ? 'hybrid_optional'
          : 'unsupported',
    );
    final reasoningCanToggle = ValueReaders.boolValue(
      effectiveReasoning['reasoning_can_toggle'],
      ValueReaders.boolValue(thinkingMetadata['thinking_supported']),
    );
    final reasoningSupportsEffort = ValueReaders.boolValue(
      effectiveReasoning['reasoning_supports_effort'],
      ValueReaders.boolValue(thinkingMetadata['thinking_effort_supported']),
    );
    final reasoningEffortOptions = ValueReaders.stringList(
      effectiveReasoning['reasoning_effort_options'],
    );
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
        ValueReaders.boolValue(effectiveReasoning['supports_reasoning']) ||
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
      'matched_writing_model_canonical_id': matchedCanonicalModelId,
      'reasoning_profile_source': customReasoning.isNotEmpty
          ? 'custom_override'
          : (matchedCanonicalModelId.isNotEmpty ? 'builtin_catalog' : 'legacy'),
      'reasoning_mode_behavior': reasoningModeBehavior,
      'reasoning_can_toggle': reasoningCanToggle,
      'reasoning_default_enabled': ValueReaders.boolValue(
        effectiveReasoning['reasoning_default_enabled'],
      ),
      'thinking_parameter_format':
          thinkingMetadata['thinking_parameter_format'],
      'thinking_parameter_label': thinkingMetadata['thinking_parameter_label'],
      'thinking_enable_parameter_keys':
          thinkingMetadata['thinking_enable_parameter_keys'],
      'thinking_effort_supported': reasoningSupportsEffort,
      'thinking_effort_parameter_key': ValueReaders.stringValue(
        ValueReaders.mapValue(
          effectiveReasoning['reasoning_effort_parameter_strategy'],
        )['key'],
      ),
      'thinking_effort_parameter_label': _effortParameterLabel(
        ValueReaders.mapValue(
          effectiveReasoning['reasoning_effort_parameter_strategy'],
        ),
      ),
      'thinking_effort_options': reasoningEffortOptions.isNotEmpty
          ? reasoningEffortOptions
          : thinkingMetadata['thinking_effort_options'],
      'reasoning_toggle_parameter_strategy': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(
          effectiveReasoning['reasoning_toggle_parameter_strategy'],
        ),
      ),
      'reasoning_effort_parameter_strategy': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(
          effectiveReasoning['reasoning_effort_parameter_strategy'],
        ),
      ),
      'has_custom_reasoning_override': customReasoning.isNotEmpty,
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
      'supports_file_attachments': ValueReaders.boolValue(
        runtimeProfile['supports_file_attachments'],
      ),
      'supports_image_attachments': ValueReaders.boolValue(
        runtimeProfile['supports_image_attachments'],
      ),
      'supports_attachment_urls_only': ValueReaders.boolValue(
        runtimeProfile['supports_attachment_urls_only'],
      ),
      'supports_multi_attachments': ValueReaders.boolValue(
        runtimeProfile['supports_multi_attachments'],
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
        reasoningCanToggle: reasoningCanToggle,
        reasoningSupportsEffort: reasoningSupportsEffort,
      ),
    };
  }

  List<Object?> _modelDefaultParameters(
    JsonMap runtimeProfile, {
    required bool supportsTemperature,
    required bool supportsTopP,
    required bool supportsTopK,
    required bool supportsReasoning,
    required bool reasoningCanToggle,
    required bool reasoningSupportsEffort,
  }) {
    // 中文注释: 这里把模型层默认参数整理成统一列表，方便前端直接画可编辑条目。
    final result = <Object?>[];
    if (supportsReasoning && reasoningCanToggle) {
      result.add(<String, Object?>{
        'key': 'thinking_enabled',
        'type': 'boolean',
        'value': ValueReaders.boolValue(runtimeProfile['thinking_enabled']),
      });
    }
    if (supportsReasoning && reasoningSupportsEffort) {
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

  String _effortParameterLabel(JsonMap strategy) {
    final kind = ValueReaders.stringValue(strategy['kind']).trim();
    switch (kind) {
      case 'boolean':
        return '深度思考布尔值';
      case 'thinking_object':
        return '深度思考对象';
      case 'custom_text':
        return '深度思考文本';
      case 'level_enum':
        return '深度思考等级';
      case 'budget_tokens':
        return '深度思考预算';
      default:
        return '深度思考强度协议';
    }
  }
}
