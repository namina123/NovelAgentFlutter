import 'package:novel_agent_core/novel_agent_core.dart';

class GeminiNativeRequestPayloadBuilder {
  const GeminiNativeRequestPayloadBuilder();

  JsonMap build(ChatRequest request) {
    // 中文注释: Gemini native payload 只做最小正式映射，保留 contents/parts 与 tools/functionDeclarations 的原生结构。
    final systemInstruction = _systemInstructionOf(request.messages);
    final payload = <String, Object?>{
      'contents': _contents(request),
      if (request.tools.isNotEmpty) 'tools': _tools(request.tools),
      if (systemInstruction.isNotEmpty)
        'systemInstruction': <String, Object?>{
          'parts': <Object?>[
            <String, Object?>{'text': systemInstruction},
          ],
        },
    };
    final generationConfig = _generationConfig(request.options);
    if (generationConfig.isNotEmpty) {
      payload['generationConfig'] = generationConfig;
    }
    return payload;
  }

  List<JsonMap> _contents(ChatRequest request) {
    // 中文注释: Gemini native 的 contents 以用户/模型角色分组，这里把通用 ChatRequest 稳定投影过去。
    final result = <JsonMap>[];
    for (final message in request.messages) {
      final role = ValueReaders.stringValue(message['role']);
      if (role == 'system') {
        continue;
      }
      if (role == 'tool') {
        result.add(
          <String, Object?>{
            'role': 'user',
            'parts': <Object?>[
              <String, Object?>{
                'functionResponse': <String, Object?>{
                  'name': ValueReaders.stringValue(message['tool_name']),
                  'response': <String, Object?>{
                    'content': ValueReaders.stringValue(message['content']),
                  },
                },
              },
            ],
          },
        );
        continue;
      }
      if (role == 'assistant' &&
          ValueReaders.objectList(message['tool_calls']).isNotEmpty) {
        result.add(_assistantToolCallContent(message));
        continue;
      }
      result.add(
        <String, Object?>{
          'role': role == 'assistant' ? 'model' : 'user',
          'parts': _partsFromMessage(message),
        },
      );
    }
    return result;
  }

  JsonMap _assistantToolCallContent(JsonMap message) {
    // 中文注释: Gemini native tool call 用 functionCall parts 表达，避免继续沿用 OpenAI 的 tool_calls。
    final parts = <Object?>[];
    final text = _messageText(message['content']);
    if (text.isNotEmpty) {
      parts.add(<String, Object?>{'text': text});
    }
    for (final rawToolCall in ValueReaders.objectList(message['tool_calls'])) {
      final call = ValueReaders.mapValue(rawToolCall);
      parts.add(
        <String, Object?>{
          'functionCall': <String, Object?>{
            'name': ValueReaders.stringValue(call['name']),
            'args': ValueReaders.mapValue(call['arguments']),
          },
        },
      );
    }
    return <String, Object?>{
      'role': 'model',
      'parts': parts,
    };
  }

  List<Object?> _partsFromMessage(JsonMap message) {
    // 中文注释: 普通消息统一按 text parts 输出，保留内容块结构，避免把内容压成单一字符串。
    final content = message['content'];
    if (content is List) {
      return content
          .map<Object?>((part) {
            final partMap = ValueReaders.mapValue(part);
            final type = ValueReaders.stringValue(partMap['type'], 'text');
            if (type == 'text') {
              return <String, Object?>{
                'text': ValueReaders.stringValue(partMap['text']),
              };
            }
            return partMap;
          })
          .toList(growable: false);
    }
    final text = _messageText(content);
    return <Object?>[
      <String, Object?>{'text': text},
    ];
  }

  List<JsonMap> _tools(List<JsonMap> tools) {
    // 中文注释: Gemini native 使用 functionDeclarations，这里只做 schema 重映射，不改工具语义。
    return tools
        .map((rawTool) {
          final tool = ValueReaders.mapValue(rawTool);
          final function = ValueReaders.mapValue(tool['function']);
          return <String, Object?>{
            'functionDeclarations': <Object?>[
              <String, Object?>{
                'name': ValueReaders.stringValue(
                  function['name'],
                  ValueReaders.stringValue(tool['name']),
                ),
                'description': ValueReaders.stringValue(
                  function['description'],
                  ValueReaders.stringValue(tool['description']),
                ),
                'parameters': ValueReaders.mapValue(
                  function['parameters'] ?? tool['input_schema'],
                ),
              },
            ],
          };
        })
        .toList(growable: false);
  }

  JsonMap _generationConfig(JsonMap options) {
    // 中文注释: generationConfig 只收 Gemini native 语义字段，其他网关级字段保留在外层 request options。
    final result = <String, Object?>{};
    if (options.containsKey('temperature')) {
      result['temperature'] = ValueReaders.doubleValue(options['temperature']);
    }
    if (options.containsKey('top_p')) {
      result['topP'] = ValueReaders.doubleValue(options['top_p']);
    }
    if (options.containsKey('top_k')) {
      result['topK'] = ValueReaders.intValue(options['top_k']);
    }
    final thinkingEnabled = options['thinking_enabled'];
    if (thinkingEnabled != null) {
      result['thinkingConfig'] = <String, Object?>{
        'thinkingBudget': ValueReaders.boolValue(thinkingEnabled) ? 1024 : 0,
      };
    }
    final thinkingEffort = ValueReaders.stringValue(options['thinking_effort']).trim();
    if (thinkingEffort.isNotEmpty) {
      final thinkingConfig = ValueReaders.mapValue(result['thinkingConfig']);
      thinkingConfig['thinkingBudget'] = _thinkingBudgetForEffort(thinkingEffort);
      result['thinkingConfig'] = thinkingConfig;
    }
    return result;
  }

  int _thinkingBudgetForEffort(String effort) {
    // 中文注释: Gemini native 这里只做轻量预算映射，避免把 OpenAI 的 reasoning_effort 直接当原生协议值。
    switch (effort.toLowerCase()) {
      case 'low':
        return 512;
      case 'medium':
        return 1024;
      case 'high':
        return 2048;
      case 'max':
        return 4096;
      case 'dynamic':
        return -1;
      default:
        return 1024;
    }
  }

  String _systemInstructionOf(List<JsonMap> messages) {
    // 中文注释: system 消息收敛到顶层 systemInstruction，避免重复塞进 contents。
    final buffer = StringBuffer();
    for (final message in messages) {
      if (ValueReaders.stringValue(message['role']) != 'system') {
        continue;
      }
      final text = _messageText(message['content']).trim();
      if (text.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(text);
    }
    return buffer.toString();
  }

  String _messageText(Object? value) {
    // 中文注释: content 可能是字符串或 block 列表，这里统一抽成可读文本供 system/tool 回填。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final rawPart in value) {
        final part = ValueReaders.mapValue(rawPart);
        final text = ValueReaders.stringValue(part['text']);
        if (text.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(text);
      }
      return buffer.toString();
    }
    return ValueReaders.stringValue(value);
  }
}
