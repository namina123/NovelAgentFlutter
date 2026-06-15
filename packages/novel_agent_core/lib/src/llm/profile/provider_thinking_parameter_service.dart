import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';

class ProviderThinkingParameterService {
  List<JsonMap> thinkingParameterFormatOptions() {
    // 中文注释: 思考参数格式本质是请求协议映射规则，应该和 UI 展示层解耦。
    return const <JsonMap>[
      <String, Object?>{
        'id': ProviderProfileConstants.thinkingFormatNone,
        'label': '不发送深度思考字段',
      },
      <String, Object?>{
        'id': ProviderProfileConstants.thinkingFormatDeepseekObject,
        'label': 'DeepSeek：thinking 对象 + reasoning_effort',
      },
      <String, Object?>{
        'id': ProviderProfileConstants.thinkingFormatEnableBoolean,
        'label': 'enable_thinking 布尔值',
      },
      <String, Object?>{
        'id': ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort,
        'label': 'enable_thinking + reasoning_effort',
      },
      <String, Object?>{
        'id': ProviderProfileConstants.thinkingFormatReasoningEffortOnly,
        'label': '仅 reasoning_effort',
      },
    ];
  }

  String normalizeThinkingParameterFormat(String value) {
    // 中文注释: 这里统一兜底旧配置与手工修改值，避免请求构造阶段再处理脏输入。
    final clean = value.trim();
    for (final option in thinkingParameterFormatOptions()) {
      if (ValueReaders.stringValue(option['id']) == clean) {
        return clean;
      }
    }
    return ProviderProfileConstants.thinkingFormatNone;
  }

  String thinkingFormatLabel(String value) {
    // 中文注释: 格式标签由这一层提供，方便表单与摘要共享同一套显示文案。
    final normalized = normalizeThinkingParameterFormat(value);
    for (final option in thinkingParameterFormatOptions()) {
      if (ValueReaders.stringValue(option['id']) == normalized) {
        return ValueReaders.stringValue(option['label'], normalized);
      }
    }
    return '不发送深度思考字段';
  }

  List<JsonMap> thinkingEffortOptions() {
    // 中文注释: 思考强度属于稳定的领域枚举，不应散落在页面层重复声明。
    return const <JsonMap>[
      <String, Object?>{'id': 'auto', 'label': '自动'},
      <String, Object?>{'id': 'low', 'label': '低'},
      <String, Object?>{'id': 'medium', 'label': '中'},
      <String, Object?>{'id': 'high', 'label': '高'},
      <String, Object?>{'id': 'max', 'label': '极高'},
    ];
  }

  String normalizeThinkingEffort(String value) {
    // 中文注释: 思考强度不能被压成固定小词表；这里仅做去空与空值兜底，具体取值应保留模型自己的语义。
    final clean = value.trim();
    if (clean.isEmpty) {
      return 'high';
    }
    return clean;
  }

  bool supportsThinking(String format) {
    // 中文注释: 深度思考支持性由参数格式决定，这里集中提供给设置页和运行时共用。
    return normalizeThinkingParameterFormat(format) !=
        ProviderProfileConstants.thinkingFormatNone;
  }

  bool supportsThinkingEffort(String format) {
    // 中文注释: 并不是所有思考格式都允许强度调节，因此这里单独暴露强度支持判断。
    switch (normalizeThinkingParameterFormat(format)) {
      case ProviderProfileConstants.thinkingFormatDeepseekObject:
      case ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort:
      case ProviderProfileConstants.thinkingFormatReasoningEffortOnly:
        return true;
      default:
        return false;
    }
  }

  List<String> thinkingToggleParameterKeys(String format) {
    // 中文注释: 前端需要知道“开启深度思考”会落到哪些字段，这里统一给出稳定键名。
    switch (normalizeThinkingParameterFormat(format)) {
      case ProviderProfileConstants.thinkingFormatDeepseekObject:
        return const <String>['thinking'];
      case ProviderProfileConstants.thinkingFormatEnableBoolean:
      case ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort:
        return const <String>['enable_thinking'];
      case ProviderProfileConstants.thinkingFormatReasoningEffortOnly:
        return const <String>['reasoning_effort'];
      default:
        return const <String>[];
    }
  }

  JsonMap thinkingMetadata(String format) {
    // 中文注释: 思考元信息供前端表单和智能体覆盖逻辑共享，避免每层自己猜字段语义。
    final normalizedFormat = normalizeThinkingParameterFormat(format);
    return <String, Object?>{
      'thinking_supported': supportsThinking(normalizedFormat),
      'thinking_parameter_format': normalizedFormat,
      'thinking_parameter_label': thinkingFormatLabel(normalizedFormat),
      'thinking_enable_parameter_keys': thinkingToggleParameterKeys(
        normalizedFormat,
      ),
      'thinking_effort_supported': supportsThinkingEffort(normalizedFormat),
      'thinking_effort_parameter_key': _effortParameterKey(normalizedFormat),
      'thinking_effort_parameter_label': _effortParameterLabel(
        normalizedFormat,
      ),
      'thinking_effort_options': supportsThinkingEffort(normalizedFormat)
          ? thinkingEffortOptions()
          : const <Object?>[],
    };
  }

  JsonMap thinkingRequestParameters(
    bool enabled,
    String effort,
    String format,
  ) {
    // 中文注释: 这里是思考能力到请求字段的纯映射，不应该混入目录匹配或模型默认值逻辑。
    final normalizedFormat = normalizeThinkingParameterFormat(format);
    if (normalizedFormat == ProviderProfileConstants.thinkingFormatNone) {
      return <String, Object?>{};
    }
    final normalizedEffort = normalizeThinkingEffort(effort);
    final includeEffort =
        enabled &&
        normalizedEffort != ProviderProfileConstants.thinkingEffortAuto;
    switch (normalizedFormat) {
      case ProviderProfileConstants.thinkingFormatDeepseekObject:
        final payload = <String, Object?>{
          'thinking': <String, Object?>{
            'type': enabled ? 'enabled' : 'disabled',
          },
        };
        if (includeEffort) {
          payload['reasoning_effort'] = normalizedEffort;
        }
        return payload;
      case ProviderProfileConstants.thinkingFormatEnableBoolean:
        return <String, Object?>{'enable_thinking': enabled};
      case ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort:
        final payload = <String, Object?>{'enable_thinking': enabled};
        if (includeEffort) {
          payload['reasoning_effort'] = normalizedEffort;
        }
        return payload;
      case ProviderProfileConstants.thinkingFormatReasoningEffortOnly:
        if (includeEffort) {
          return <String, Object?>{'reasoning_effort': normalizedEffort};
        }
        return <String, Object?>{};
      default:
        return <String, Object?>{};
    }
  }

  String _effortParameterKey(String format) {
    switch (normalizeThinkingParameterFormat(format)) {
      case ProviderProfileConstants.thinkingFormatDeepseekObject:
      case ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort:
        return 'reasoning_effort';
      case ProviderProfileConstants.thinkingFormatReasoningEffortOnly:
        return 'reasoning_effort';
      default:
        return 'reasoning_effort';
    }
  }

  String _effortParameterLabel(String format) {
    switch (normalizeThinkingParameterFormat(format)) {
      case ProviderProfileConstants.thinkingFormatDeepseekObject:
        return '深度思考对象附带的强度';
      case ProviderProfileConstants.thinkingFormatEnableBoolean:
      case ProviderProfileConstants.thinkingFormatEnableBooleanWithEffort:
        return '深度思考强度';
      case ProviderProfileConstants.thinkingFormatReasoningEffortOnly:
        return '思考强度';
      default:
        return '深度思考强度';
    }
  }
}
