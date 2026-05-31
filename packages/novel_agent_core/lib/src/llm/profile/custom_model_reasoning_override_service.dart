import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';
import 'provider_thinking_parameter_service.dart';

class CustomModelReasoningOverrideService {
  CustomModelReasoningOverrideService({
    ProviderThinkingParameterService? thinkingParameterService,
  }) : _thinkingParameterService =
           thinkingParameterService ?? ProviderThinkingParameterService();

  final ProviderThinkingParameterService _thinkingParameterService;

  JsonMap normalize(Object? rawValue) {
    // 中文注释: 自定义 reasoning override 统一在这里收敛，避免设置页、运行态和请求构造各猜一套结构。
    final raw = ValueReaders.mapValue(rawValue);
    if (raw.isEmpty) {
      return <String, Object?>{};
    }
    final supportsReasoning = ValueReaders.boolValue(raw['supports_reasoning']);
    if (!supportsReasoning) {
      return <String, Object?>{
        'supports_reasoning': false,
        'reasoning_mode_behavior': 'unsupported',
      };
    }
    final reasoningCanToggle = ValueReaders.boolValue(
      raw['reasoning_can_toggle'],
      true,
    );
    final reasoningDefaultEnabled = reasoningCanToggle
        ? ValueReaders.boolValue(raw['reasoning_default_enabled'])
        : true;
    final reasoningSupportsEffort = ValueReaders.boolValue(
      raw['reasoning_supports_effort'],
    );
    final toggleStrategy = _normalizeToggleStrategy(
      ValueReaders.mapValue(raw['reasoning_toggle_parameter_strategy']),
    );
    final effortStrategy = _normalizeEffortStrategy(
      ValueReaders.mapValue(raw['reasoning_effort_parameter_strategy']),
      supportsEffort: reasoningSupportsEffort,
    );
    return <String, Object?>{
      'supports_reasoning': true,
      'reasoning_mode_behavior': reasoningCanToggle
          ? (reasoningDefaultEnabled ? 'hybrid_default_on' : 'hybrid_optional')
          : 'thinking_only',
      'reasoning_can_toggle': reasoningCanToggle,
      'reasoning_default_enabled': reasoningDefaultEnabled,
      'reasoning_supports_effort': reasoningSupportsEffort,
      'reasoning_effort_options': _reasoningEffortOptions(
        reasoningSupportsEffort: reasoningSupportsEffort,
        effortStrategy: effortStrategy,
      ),
      'reasoning_toggle_parameter_strategy': toggleStrategy,
      'reasoning_effort_parameter_strategy': effortStrategy,
    };
  }

  JsonMap buildRequestParameters(
    JsonMap normalizedOverride, {
    required bool enabled,
    required String effort,
  }) {
    // 中文注释: 自定义 reasoning 参数在这里直接翻译成请求字段，不依赖内置 provider 的旧 thinking format。
    if (!ValueReaders.boolValue(normalizedOverride['supports_reasoning'])) {
      return <String, Object?>{};
    }
    final canToggle = ValueReaders.boolValue(
      normalizedOverride['reasoning_can_toggle'],
      true,
    );
    final effectiveEnabled = canToggle
        ? enabled
        : ValueReaders.boolValue(
            normalizedOverride['reasoning_default_enabled'],
            true,
          );
    final result = <String, Object?>{};
    final toggleStrategy = ValueReaders.mapValue(
      normalizedOverride['reasoning_toggle_parameter_strategy'],
    );
    final toggleKind = ValueReaders.stringValue(toggleStrategy['kind']).trim();
    if (canToggle) {
      switch (toggleKind) {
        case 'boolean':
        case 'custom_text':
        case 'thinking_object':
          final key = ValueReaders.stringValue(toggleStrategy['key']).trim();
          if (key.isNotEmpty) {
            result[key] = effectiveEnabled
                ? toggleStrategy['enabled_value']
                : toggleStrategy['disabled_value'];
          }
          break;
        default:
          break;
      }
    }
    if (ValueReaders.boolValue(
          normalizedOverride['reasoning_supports_effort'],
        ) &&
        effectiveEnabled) {
      final normalizedEffort = _thinkingParameterService
          .normalizeThinkingEffort(effort);
      final effortStrategy = ValueReaders.mapValue(
        normalizedOverride['reasoning_effort_parameter_strategy'],
      );
      final key = ValueReaders.stringValue(effortStrategy['key']).trim();
      final values = ValueReaders.mapValue(effortStrategy['values']);
      final rawValue = values.containsKey(normalizedEffort)
          ? values[normalizedEffort]
          : normalizedEffort;
      if (key.isNotEmpty && !_shouldSkipValue(rawValue)) {
        result[key] = rawValue;
      }
    }
    return result;
  }

  String compatibilityThinkingFormat(JsonMap normalizedOverride) {
    // 中文注释: 这里只做旧字段兼容映射，复杂自定义协议仍以 override 自身为准。
    final canToggle = ValueReaders.boolValue(
      normalizedOverride['reasoning_can_toggle'],
      true,
    );
    final supportsEffort = ValueReaders.boolValue(
      normalizedOverride['reasoning_supports_effort'],
    );
    if (!canToggle) {
      return supportsEffort
          ? ProviderProfileConstants.thinkingFormatReasoningEffortOnly
          : ProviderProfileConstants.thinkingFormatNone;
    }
    final toggleStrategy = ValueReaders.mapValue(
      normalizedOverride['reasoning_toggle_parameter_strategy'],
    );
    final toggleKind = ValueReaders.stringValue(toggleStrategy['kind']).trim();
    switch (toggleKind) {
      case 'boolean':
        return supportsEffort
            ? ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort
            : ProviderProfileConstants.thinkingFormatEnableBoolean;
      case 'thinking_object':
        return ProviderProfileConstants.thinkingFormatDeepseekObject;
      default:
        return ProviderProfileConstants.thinkingFormatNone;
    }
  }

  String parameterLabel(JsonMap normalizedOverride) {
    final toggleStrategy = ValueReaders.mapValue(
      normalizedOverride['reasoning_toggle_parameter_strategy'],
    );
    final kind = ValueReaders.stringValue(toggleStrategy['kind']).trim();
    switch (kind) {
      case 'boolean':
        return '自定义深度思考开关';
      case 'thinking_object':
        return '自定义深度思考对象';
      case 'custom_text':
        return '自定义深度思考参数';
      default:
        return '自定义深度思考协议';
    }
  }

  List<String> toggleParameterKeys(JsonMap normalizedOverride) {
    if (!ValueReaders.boolValue(normalizedOverride['reasoning_can_toggle'], true)) {
      return const <String>[];
    }
    final toggleStrategy = ValueReaders.mapValue(
      normalizedOverride['reasoning_toggle_parameter_strategy'],
    );
    final key = ValueReaders.stringValue(toggleStrategy['key']).trim();
    return key.isEmpty ? const <String>[] : <String>[key];
  }

  JsonMap _normalizeToggleStrategy(JsonMap raw) {
    final kind = ValueReaders.stringValue(raw['kind']).trim();
    switch (kind) {
      case 'boolean':
        return <String, Object?>{
          'kind': 'boolean',
          'key': ValueReaders.stringValue(raw['key'], 'enable_thinking').trim(),
          'enabled_value': true,
          'disabled_value': false,
        };
      case 'custom_text':
        return <String, Object?>{
          'kind': 'custom_text',
          'key': ValueReaders.stringValue(raw['key'], 'thinking_mode').trim(),
          'enabled_value': ValueReaders.stringValue(
            raw['enabled_value'],
            'enabled',
          ),
          'disabled_value': ValueReaders.stringValue(
            raw['disabled_value'],
            'disabled',
          ),
        };
      case 'thinking_object':
        return <String, Object?>{
          'kind': 'thinking_object',
          'key': ValueReaders.stringValue(raw['key'], 'thinking').trim(),
          'enabled_value': ValueReaders.deepCopyMap(
            ValueReaders.mapValue(raw['enabled_value']).isEmpty
                ? <String, Object?>{'type': 'enabled'}
                : ValueReaders.mapValue(raw['enabled_value']),
          ),
          'disabled_value': ValueReaders.deepCopyMap(
            ValueReaders.mapValue(raw['disabled_value']).isEmpty
                ? <String, Object?>{'type': 'disabled'}
                : ValueReaders.mapValue(raw['disabled_value']),
          ),
        };
      default:
        return <String, Object?>{'kind': 'none', 'key': ''};
    }
  }

  JsonMap _normalizeEffortStrategy(
    JsonMap raw, {
    required bool supportsEffort,
  }) {
    if (!supportsEffort) {
      return <String, Object?>{};
    }
    final values = <String, Object?>{};
    final rawValues = ValueReaders.mapValue(raw['values']);
    for (final option in ProviderProfileConstants.thinkingEfforts) {
      if (rawValues.containsKey(option) &&
          !_shouldSkipValue(rawValues[option])) {
        values[option] = rawValues[option];
      } else {
        values[option] = option;
      }
    }
    return <String, Object?>{
      'kind': 'custom_text',
      'key': ValueReaders.stringValue(raw['key'], 'reasoning_effort').trim(),
      'values': values,
    };
  }

  List<String> _reasoningEffortOptions({
    required bool reasoningSupportsEffort,
    required JsonMap effortStrategy,
  }) {
    if (!reasoningSupportsEffort) {
      return const <String>[];
    }
    final values = ValueReaders.mapValue(effortStrategy['values']);
    final result = <String>[];
    for (final option in ProviderProfileConstants.thinkingEfforts) {
      if (values.containsKey(option) && !_shouldSkipValue(values[option])) {
        result.add(option);
      }
    }
    return result.isEmpty
        ? const <String>['auto', 'low', 'medium', 'high', 'max']
        : result;
  }

  bool _shouldSkipValue(Object? value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    if (value is Map) {
      return value.isEmpty;
    }
    return false;
  }
}
