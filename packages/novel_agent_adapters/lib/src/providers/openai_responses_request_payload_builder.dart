import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'openai_attachment_bridge_policy.dart';

class OpenAiResponsesRequestPayloadBuilder {
  const OpenAiResponsesRequestPayloadBuilder({
    OpenAiAttachmentBridgePolicy? attachmentBridgePolicy,
  }) : _attachmentBridgePolicy =
           attachmentBridgePolicy ?? const OpenAiAttachmentBridgePolicy();

  final OpenAiAttachmentBridgePolicy _attachmentBridgePolicy;

  JsonMap build(ChatRequest request) {
    // 中文注释: Responses 用 instructions + input 的正式合同，不再沿用 Chat Completions 的 messages 直传。
    _assertAttachmentBridgeReadiness(request);
    final payload = <String, Object?>{
      'model': request.modelId,
      if (_instructionsOf(request.messages).trim().isNotEmpty)
        'instructions': _instructionsOf(request.messages),
      'input': _inputItemsOf(request),
      if (request.tools.isNotEmpty) 'tools': _requestTools(request.tools),
    };
    request.options.forEach((key, value) {
      if (_reservedOptionKeys.contains(key)) {
        return;
      }
      payload[key] = value;
    });
    return payload;
  }

  Object _inputItemsOf(ChatRequest request) {
    final inputItems = <Object?>[];
    for (final rawMessage in request.messages) {
      final message = ValueReaders.mapValue(rawMessage);
      final role = ValueReaders.stringValue(message['role']).trim();
      if (role.isEmpty) {
        continue;
      }
      if (role == 'system' || role == 'developer') {
        continue;
      }
      if (role == 'tool') {
        final toolCallId = ValueReaders.stringValue(message['tool_call_id']);
        final fallbackCallId = ValueReaders.stringValue(message['call_id']);
        final fallbackMessageId = ValueReaders.stringValue(message['id']);
        final callId = ValueReaders.stringValue(
          toolCallId,
          ValueReaders.stringValue(fallbackCallId, fallbackMessageId),
        ).trim();
        if (callId.isEmpty) {
          continue;
        }
        inputItems.add(<String, Object?>{
          'type': 'function_call_output',
          'call_id': callId,
          'output': _textContentOf(message['content']),
        });
        continue;
      }
      if (role == 'assistant') {
        final toolCalls = ValueReaders.objectList(message['tool_calls']);
        if (toolCalls.isNotEmpty) {
          // 中文注释: Responses 要求工具回合里 assistant 的工具调用以 function_call item 出现（带 call_id），
          // 否则后续的 function_call_output 找不到前置调用而被服务端拒绝。
          final text = _textContentOf(message['content']);
          if (text.trim().isNotEmpty) {
            inputItems.add(<String, Object?>{
              'type': 'message',
              'role': 'assistant',
              'content': text,
            });
          }
          for (final rawCall in toolCalls) {
            final call = ValueReaders.mapValue(rawCall);
            final functionData = ValueReaders.mapValue(call['function']);
            inputItems.add(<String, Object?>{
              'type': 'function_call',
              'call_id': ValueReaders.stringValue(call['id']),
              'name': ValueReaders.stringValue(
                functionData['name'],
                ValueReaders.stringValue(call['name']),
              ),
              'arguments': ValueReaders.stringValue(
                functionData['arguments'],
                ValueReaders.stringValue(call['arguments']),
              ),
            });
          }
          continue;
        }
      }
      final entry = <String, Object?>{
        'type': 'message',
        'role': role == 'assistant' ? 'assistant' : 'user',
        'content': _messageContentOf(message['content']),
      };
      final phase = ValueReaders.stringValue(message['phase']).trim();
      if (phase.isNotEmpty) {
        entry['phase'] = phase;
      }
      final status = ValueReaders.stringValue(message['status']).trim();
      if (status.isNotEmpty) {
        entry['status'] = status;
      }
      inputItems.add(entry);
    }
    if (inputItems.isEmpty) {
      return '';
    }
    if (inputItems.length == 1 && inputItems.first is JsonMap) {
      final first = ValueReaders.mapValue(inputItems.first);
      if (first['type'] == 'message' &&
          ValueReaders.stringValue(first['role']) == 'user') {
        return first['content'] ?? '';
      }
    }
    return inputItems;
  }

  Object _messageContentOf(Object? value) {
    // 中文注释: message.content 既可以直接用字符串，也可以用 input_text 项列表；这里保守按字符串主路径输出。
    final text = _textContentOf(value);
    return text;
  }

  String _textContentOf(Object? value) {
    // 中文注释: Responses 的文本输入可以是 string 或输入项列表，这里统一抽成可读正文。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final part in value) {
        final partMap = ValueReaders.mapValue(part);
        final type = ValueReaders.stringValue(partMap['type']);
        if (type != 'input_text' && type != 'text') {
          continue;
        }
        final text = ValueReaders.stringValue(partMap['text']);
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

  List<JsonMap> _requestTools(List<JsonMap> source) {
    // 中文注释: Responses 工具定义是顶层 name/description/parameters 风格，不再包一层 chat function 对象。
    return source
        .map((rawTool) {
          final tool = ValueReaders.mapValue(rawTool);
          final function = ValueReaders.mapValue(tool['function']);
          final result = <String, Object?>{
            'type': 'function',
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
          };
          final strict = function['strict'];
          if (strict != null) {
            result['strict'] = strict;
          }
          return result;
        })
        .toList(growable: false);
  }

  void _assertAttachmentBridgeReadiness(ChatRequest request) {
    // 中文注释: 这里仍沿用附件桥接的稳定失败策略，避免 Responses 入口悄悄吞掉附件语义。
    final assessment = _attachmentBridgePolicy.assess(request);
    if (assessment.isRequestSupported) {
      return;
    }
    if (assessment.failureMessage.trim().isEmpty) {
      return;
    }
    throw UnsupportedError(assessment.failureMessage);
  }

  String _instructionsOf(List<JsonMap> messages) {
    // 中文注释: system / developer 指令收敛到 Responses 顶层 instructions，保持和官方映射一致。
    final buffer = StringBuffer();
    for (final rawMessage in messages) {
      final message = ValueReaders.mapValue(rawMessage);
      final role = ValueReaders.stringValue(message['role']).trim();
      if (role != 'system' && role != 'developer') {
        continue;
      }
      final text = GatewayContentExtractor.textFromContent(message['content']).trim();
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

  static const Set<String> _reservedOptionKeys = <String>{
    'prompt',
    'api_mode',
    'stream_scope',
    'sub_session_id',
    'allow_inline_tools',
    'force_tool_choice',
    'preferred_tool',
  };
}
