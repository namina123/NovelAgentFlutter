import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_run_compactor_service.dart';

class AgentToolMessageService {
  AgentToolMessageService({AgentRunCompactorService? compactorService})
    : _compactorService = compactorService ?? AgentRunCompactorService();

  final AgentRunCompactorService _compactorService;

  JsonMap assistantToolCallMessage(JsonMap llmResult, List<Object?> toolCalls) {
    // 中文注释: 这里生成 OpenAI-compatible assistant tool_calls 消息，让宿主不必关心协议细节。
    final rawMessage = ValueReaders.mapValue(llmResult['message']);
    final reasoning = ValueReaders.stringValue(
      llmResult['reasoning_content'],
    ).trim();
    final rawToolCalls = <Object?>[];
    for (final rawCall in toolCalls) {
      final call = ValueReaders.mapValue(rawCall);
      rawToolCalls.add(<String, Object?>{
        'id': ValueReaders.stringValue(call['id']),
        'type': 'function',
        'function': <String, Object?>{
          'name': ValueReaders.stringValue(call['name']),
          'arguments': jsonEncode(ValueReaders.mapValue(call['arguments'])),
        },
      });
    }
    final normalizedContent = _assistantContent(rawMessage['content']);
    return <String, Object?>{
      'role': ValueReaders.stringValue(rawMessage['role'], 'assistant'),
      'content': normalizedContent,
      'tool_calls': rawToolCalls,
      if (reasoning.isNotEmpty ||
          ValueReaders.stringValue(
            rawMessage['reasoning_content'],
          ).trim().isNotEmpty)
        'reasoning_content': reasoning.isNotEmpty
            ? reasoning
            : ValueReaders.stringValue(rawMessage['reasoning_content']).trim(),
    };
  }

  JsonMap toolResultMessage(JsonMap call, JsonMap result) {
    // 中文注释: tool 结果消息统一在核心序列化，避免宿主重复实现压缩和 JSON 编码。
    return <String, Object?>{
      'role': 'tool',
      'tool_call_id': ValueReaders.stringValue(call['id']),
      'name': ValueReaders.stringValue(call['name']),
      'content': jsonEncode(_compactorService.compactToolResultForLlm(result)),
    };
  }

  String _assistantContent(Object? value) {
    // 中文注释: assistant tool_call 回传给兼容网关时，content 统一收敛成纯字符串，避免把内部结构再次原样透传出去。
    if (value is String) {
      return value;
    }
    return '';
  }
}
