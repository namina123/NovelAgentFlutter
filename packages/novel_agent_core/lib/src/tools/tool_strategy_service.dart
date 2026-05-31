import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'builtin_tool_catalog.dart';
import 'tool_strategy_mode.dart';

class ToolStrategyService {
  JsonMap defaultSettings() {
    // 中文注释: 默认策略保持“可用但克制”，避免一上来就让模型把片段内容乱写进错误目录。
    return <String, Object?>{
      'enabled': true,
      'mode': ToolStrategyMode.balanced,
      'allow_inline_fallback': true,
      'auto_present_options': true,
      'auto_task_plan': true,
      'auto_write_artifacts': true,
      'force_tool_choice': false,
      'require_list_before_read': true,
      'require_read_before_edit': true,
      'tool_enabled': _defaultToolEnabled(),
    };
  }

  JsonMap normalize(JsonMap settings) {
    // 中文注释: 工具策略归一化只处理纯配置结构，不关心具体工具如何实现。
    final normalized = defaultSettings()
      ..addAll(ValueReaders.deepCopyMap(settings));
    var mode = ValueReaders.stringValue(
      normalized['mode'],
      ToolStrategyMode.balanced,
    );
    if (!<String>[
      ToolStrategyMode.conservative,
      ToolStrategyMode.balanced,
      ToolStrategyMode.proactive,
    ].contains(mode)) {
      mode = ToolStrategyMode.balanced;
    }
    normalized['mode'] = mode;
    for (final key in <String>[
      'enabled',
      'allow_inline_fallback',
      'auto_present_options',
      'auto_task_plan',
      'auto_write_artifacts',
      'force_tool_choice',
      'require_list_before_read',
      'require_read_before_edit',
    ]) {
      normalized[key] = ValueReaders.boolValue(
        normalized[key],
        ValueReaders.boolValue(defaultSettings()[key]),
      );
    }
    final defaultTools = _defaultToolEnabled();
    final incomingTools = ValueReaders.mapValue(normalized['tool_enabled']);
    final toolEnabled = <String, Object?>{};
    for (final toolId in _catalogToolIds()) {
      toolEnabled[toolId] = ValueReaders.boolValue(
        incomingTools[toolId],
        ValueReaders.boolValue(defaultTools[toolId]),
      );
    }
    normalized['tool_enabled'] = toolEnabled;
    return normalized;
  }

  List<JsonMap> modeOptions() {
    // 中文注释: 模式说明集中在策略层维护，避免 UI 与 prompt 文案逐渐分叉。
    return const <JsonMap>[
      <String, Object?>{
        'id': ToolStrategyMode.conservative,
        'label': '保守',
        'description': '更少自动写入，倾向先给用户选择或说明。',
      },
      <String, Object?>{
        'id': ToolStrategyMode.balanced,
        'label': '平衡',
        'description': '默认策略：需要正式产物才写入，选项请求会调用选项工具。',
      },
      <String, Object?>{
        'id': ToolStrategyMode.proactive,
        'label': '主动',
        'description': '更积极读取目录、规划任务和保存明确产物。',
      },
    ];
  }

  List<JsonMap> flagDefinitions() {
    // 中文注释: 全局开关定义属于策略规则本身，不应该下沉到任何具体页面组件。
    return const <JsonMap>[
      <String, Object?>{
        'id': 'enabled',
        'name': '启用工具调用',
        'description': '关闭后不会向模型暴露工具 schema，也不会执行 fallback 工具调用。',
      },
      <String, Object?>{
        'id': 'allow_inline_fallback',
        'name': '允许 fallback 工具 JSON',
        'description': '当模型或中转不支持原生 tool calling 时，允许解析回复中的机器可读工具调用。',
      },
      <String, Object?>{
        'id': 'auto_present_options',
        'name': '选项请求优先用选项工具',
        'description': '用户要求几个方案/开局/方向时，优先展示可点击选项，而不是普通正文列表。',
      },
      <String, Object?>{
        'id': 'auto_task_plan',
        'name': '复杂任务允许任务计划',
        'description': '长篇、续写、修订等多步骤任务可先展示智能体自己的任务清单。',
      },
      <String, Object?>{
        'id': 'auto_write_artifacts',
        'name': '允许自动写入正式产物',
        'description': '只有明确产出大纲、正文、设定、风格等正式文档时才写入项目文件。',
      },
      <String, Object?>{
        'id': 'force_tool_choice',
        'name': '高级：请求级强制工具选择',
        'description': '默认关闭。开启后只在极确定的内置流程里发送 tool_choice 指定具体工具。',
      },
      <String, Object?>{
        'id': 'require_list_before_read',
        'name': '读取前鼓励先看目录',
        'description': '让 AI 先了解项目结构，再选择本轮需要读取的文件。',
      },
      <String, Object?>{
        'id': 'require_read_before_edit',
        'name': '修改前要求先读取',
        'description': '编辑已有文件前先读取原文，减少误改和覆盖。',
      },
    ];
  }

  List<JsonMap> toolToggleDefinitions() {
    // 中文注释: 工具开关清单只依赖内建工具目录，后续换成可下载目录时也能独立替换。
    return BuiltinToolCatalog.definitions
        .map(
          (tool) => <String, Object?>{
            'id': tool.id,
            'name': tool.name,
            'description': tool.description,
            'platform_policy': tool.platformPolicy,
          },
        )
        .toList(growable: false);
  }

  List<String> enabledToolIds(JsonMap settings) {
    // 中文注释: 这里给模型暴露的工具集合是硬开关结果，不能留给宿主自行猜测。
    final normalized = normalize(settings);
    if (!ValueReaders.boolValue(normalized['enabled'], true)) {
      return <String>[];
    }
    final toolEnabled = ValueReaders.mapValue(normalized['tool_enabled']);
    final result = <String>[];
    for (final toolId in _catalogToolIds()) {
      if (ValueReaders.boolValue(toolEnabled[toolId])) {
        result.add(toolId);
      }
    }
    return result;
  }

  bool isToolEnabled(JsonMap settings, String toolId) {
    // 中文注释: fallback 工具解析和执行前都应走同一开关判断，避免绕过 schema 暴露的限制。
    return enabledToolIds(settings).contains(toolId);
  }

  JsonMap requestOptionsForIntent(JsonMap settings, String intent) {
    // 中文注释: 请求级策略只返回纯选项，不直接触发真实工具调用。
    final normalized = normalize(settings);
    final options = <String, Object?>{
      'allow_inline_tools':
          ValueReaders.boolValue(normalized['enabled'], true) &&
          ValueReaders.boolValue(normalized['allow_inline_fallback'], true),
    };
    if (!ValueReaders.boolValue(normalized['enabled'], true)) {
      return options;
    }
    if (ValueReaders.boolValue(normalized['force_tool_choice']) &&
        intent == 'user_options' &&
        ValueReaders.boolValue(normalized['auto_present_options'], true) &&
        isToolEnabled(normalized, 'present_user_options')) {
      options['force_tool_choice'] = true;
      options['preferred_tool'] = 'present_user_options';
    }
    return options;
  }

  String modeLabel(String mode) {
    // 中文注释: 模式标签是策略域自己的职责，不应该交给外层通过 if/else 自拼。
    switch (mode) {
      case ToolStrategyMode.conservative:
        return '保守';
      case ToolStrategyMode.proactive:
        return '主动';
      default:
        return '平衡';
    }
  }

  String modePromptNote(String mode) {
    // 中文注释: 这里输出给模型看的行为倾向说明，确保模式切换真正影响 prompt 行为。
    switch (mode) {
      case ToolStrategyMode.conservative:
        return '偏向少写入、多确认；除非用户明确要求保存，否则不要主动写文件。';
      case ToolStrategyMode.proactive:
        return '可以更主动读取项目结构、规划任务，并保存明确的正式产物；仍需避免把头脑风暴写入正文。';
      default:
        return '在效率与安全之间保持平衡：需要上下文就读取，需要正式产物才写入。';
    }
  }

  Map<String, String> toolDescriptionMap() {
    // 中文注释: 工具描述字典给 prompt 构建器复用，避免再维护第二套文案来源。
    return {
      for (final tool in BuiltinToolCatalog.definitions)
        tool.id: tool.description,
    };
  }

  JsonMap _defaultToolEnabled() {
    // 中文注释: 默认开关严格来自工具目录定义，后续增加工具时不用再到多个位置同步。
    return <String, Object?>{
      for (final tool in BuiltinToolCatalog.definitions)
        tool.id: tool.enabledByDefault,
    };
  }

  List<String> _catalogToolIds() {
    // 中文注释: 工具 ID 顺序需要稳定，这里直接按目录定义顺序输出。
    return BuiltinToolCatalog.definitions
        .map((tool) => tool.id)
        .toList(growable: false);
  }
}
