import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'openai_attachment_bridge_policy.dart';

class AnthropicMessagesRequestPayloadBuilder {
  const AnthropicMessagesRequestPayloadBuilder({
    OpenAiAttachmentBridgePolicy? attachmentBridgePolicy,
  }) : _attachmentBridgePolicy =
           attachmentBridgePolicy ?? const OpenAiAttachmentBridgePolicy();

  final OpenAiAttachmentBridgePolicy _attachmentBridgePolicy;

  JsonMap build(ChatRequest request) {
    // 中文注释: Anthropic Messages 的 payload 必须按 system/messages/tools 三分，避免继续沿用 Chat Completions 的消息直传。
    _assertAttachmentBridgeReadiness(request);
    final options = ValueReaders.deepCopyMap(request.options);
    final messages = _requestMessages(request.messages);
    final payload = <String, Object?>{
      'model': request.modelId,
      'messages': messages,
      'max_tokens': ValueReaders.intValue(options.remove('max_tokens'), 4096),
      if (request.tools.isNotEmpty) 'tools': _requestTools(request.tools),
    };
    final systemBlocks = _systemBlocksOf(request.messages);
    if (systemBlocks.isNotEmpty) {
      payload['system'] = systemBlocks;
    }
    _copyIfPresent(options, payload, 'temperature');
    _copyIfPresent(options, payload, 'top_p');
    _copyIfPresent(options, payload, 'top_k');
    _copyIfPresent(options, payload, 'stop_sequences');
    _copyIfPresent(options, payload, 'metadata');
    _copyIfPresent(options, payload, 'tool_choice');
    _copyIfPresent(options, payload, 'thinking');
    _copyIfPresent(options, payload, 'reasoning_effort');
    if (ValueReaders.boolValue(options['stream'])) {
      payload['stream'] = true;
    }
    return payload;
  }

  List<JsonMap> _requestMessages(List<JsonMap> source) {
    // 中文注释: 旧式 role/message 消息在这里翻译成 Anthropic Messages 内容块。
    final result = <JsonMap>[]; 
    for (final rawMessage in source) {
      final message = ValueReaders.mapValue(rawMessage);
      final role = ValueReaders.stringValue(message['role']);
      if (role == 'system') {
        continue;
      }
      if (role == 'tool') {
        result.add(_toolResultMessage(message));
        continue;
      }
      if (role == 'assistant' &&
          ValueReaders.objectList(message['tool_calls']).isNotEmpty) {
        result.add(_assistantToolUseMessage(message));
        continue;
      }
      result.add(<String, Object?>{
        'role': role == 'assistant' ? 'assistant' : 'user',
        'content': _contentBlocksFromMessage(message),
      });
    }
    return result;
  }

  JsonMap _assistantToolUseMessage(JsonMap message) {
    // 中文注释: assistant tool_calls 需要翻译成 tool_use content blocks，Anthropic 不接受 OpenAI 的 tool_calls 原样传入。
    final blocks = <Object?>[];
    final text = _messageText(message['content']);
    if (text.isNotEmpty) {
      blocks.add(<String, Object?>{'type': 'text', 'text': text});
    }
    for (final rawToolCall in ValueReaders.objectList(message['tool_calls'])) {
      final call = ValueReaders.mapValue(rawToolCall);
      blocks.add(<String, Object?>{
        'type': 'tool_use',
        'id': ValueReaders.stringValue(call['id']),
        'name': ValueReaders.stringValue(
          call['name'],
          ValueReaders.stringValue(call['tool_name']),
        ),
        'input': ValueReaders.mapValue(call['arguments']),
      });
    }
    return <String, Object?>{'role': 'assistant', 'content': blocks};
  }

  JsonMap _toolResultMessage(JsonMap message) {
    // 中文注释: tool 结果必须作为 user content block 的 tool_result 回传，不能继续沿用 tool 角色消息。
    final toolCallId = ValueReaders.stringValue(message['tool_call_id']);
    final text = _messageText(message['content']);
    return <String, Object?>{
      'role': 'user',
      'content': <Object?>[
        <String, Object?>{
          'type': 'tool_result',
          'tool_use_id': toolCallId,
          'content': text,
        },
      ],
    };
  }

  List<Object?> _contentBlocksFromMessage(JsonMap message) {
    // 中文注释: 普通消息内容保守映射成 text content blocks，保留已有 content list 结构。
    final content = message['content'];
    if (content is List) {
      return content
          .map<Object?>((part) {
            final partMap = ValueReaders.mapValue(part);
            final type = ValueReaders.stringValue(partMap['type'], 'text');
            if (type == 'text') {
              return <String, Object?>{
                'type': 'text',
                'text': ValueReaders.stringValue(partMap['text']),
              };
            }
            return partMap;
          })
          .toList(growable: false);
    }
    final text = _messageText(content);
    return <Object?>[
      <String, Object?>{'type': 'text', 'text': text},
    ];
  }

  List<Object?> _systemBlocksOf(List<JsonMap> source) {
    // 中文注释: 把所有 system 消息映射成 Anthropic 的 system content blocks 数组。
    // 第一个 block（=稳定前缀）加 cache_control: ephemeral，缓存 [tools + 稳定 system]。
    // 后续 block（=易变后缀：文件树/约束/压力）不加断点——它们在断点之后，每轮重发不缓存。
    final blocks = <Object?>[];
    for (final rawMessage in source) {
      final message = ValueReaders.mapValue(rawMessage);
      if (ValueReaders.stringValue(message['role']) != 'system') {
        continue;
      }
      final text = _messageText(message['content']);
      if (text.isEmpty) {
        continue;
      }
      blocks.add(<String, Object?>{
        'type': 'text',
        'text': text,
        if (blocks.isEmpty)
          'cache_control': <String, Object?>{'type': 'ephemeral'},
      });
    }
    return blocks;
  }

  List<JsonMap> _requestTools(List<JsonMap> source) {
    // 中文注释: Anthropic 工具定义依然是 function 风格，但需要单独映射成 Messages API 需要的 schema 形状。
    return source
        .map((rawTool) {
          final tool = ValueReaders.mapValue(rawTool);
          final function = ValueReaders.mapValue(tool['function']);
          return <String, Object?>{
            'type': 'function',
            'function': <String, Object?>{
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
          };
        })
        .toList(growable: false);
  }

  String _messageText(Object? value) {
    // 中文注释: Anthropic Messages 同时接受 string 和 content blocks，这里统一抽成可读文本。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final rawPart in value) {
        final part = ValueReaders.mapValue(rawPart);
        final type = ValueReaders.stringValue(part['type'], 'text');
        if (type == 'text') {
          final text = ValueReaders.stringValue(part['text']);
          if (text.isEmpty) {
            continue;
          }
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
          continue;
        }
        if (type == 'tool_result') {
          final text = ValueReaders.stringValue(part['content']);
          if (text.isEmpty) {
            continue;
          }
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
        }
      }
      return buffer.toString();
    }
    return GatewayContentExtractor.textFromContent(value);
  }

  void _copyIfPresent(JsonMap source, JsonMap target, String key) {
    // 中文注释: 只把明确提供的参数透传给 Anthropic，不在 builder 里引入隐式默认值。
    if (!source.containsKey(key)) {
      return;
    }
    final value = source[key];
    if (value == null) {
      return;
    }
    target[key] = value;
  }

  void _assertAttachmentBridgeReadiness(ChatRequest request) {
    // 中文注释: 附件桥接没实现前，保持稳定失败而不是悄悄吞掉输入。
    final assessment = _attachmentBridgePolicy.assess(request);
    if (assessment.isRequestSupported) {
      return;
    }
    if (assessment.failureMessage.trim().isEmpty) {
      return;
    }
    throw UnsupportedError(assessment.failureMessage);
  }
}
