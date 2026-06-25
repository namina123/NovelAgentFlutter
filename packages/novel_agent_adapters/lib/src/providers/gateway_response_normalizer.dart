import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class GatewayResponseNormalizer {
  const GatewayResponseNormalizer._();

  static JsonMap buildEnvelope({
    required String content,
    required String reasoningContent,
    required List<JsonMap> toolCalls,
    required JsonMap rawResponse,
  }) {
    return <String, Object?>{
      'ok': true,
      'content': content,
      'reasoning_content': reasoningContent,
      'message': <String, Object?>{
        'role': 'assistant',
        'content': content,
        'tool_calls': toolCalls,
      },
      'tool_calls': toolCalls,
      'raw_response': rawResponse,
    };
  }

  static JsonMap buildToolCallRecord({
    required String id,
    required String name,
    required Object? arguments,
    String rawArguments = '',
  }) {
    final normalizedArguments = ValueReaders.mapValue(arguments);
    final effectiveRawArguments = rawArguments.isNotEmpty
        ? rawArguments
        : (arguments is String ? arguments : jsonEncode(normalizedArguments));
    return <String, Object?>{
      'id': id,
      'name': name,
      'tool_name': name,
      'arguments': normalizedArguments,
      'raw_arguments': effectiveRawArguments,
      'status': 'pending',
    };
  }

  static List<JsonMap> normalizeOpenAiToolCalls(Object? value) {
    final result = <JsonMap>[];
    if (value is! List) {
      return result;
    }
    for (final rawCall in value) {
      final call = ValueReaders.mapValue(rawCall);
      final functionData = ValueReaders.mapValue(call['function']);
      final argumentsValue = functionData['arguments'];
      Object? parsedArguments = argumentsValue;
      if (argumentsValue is String && argumentsValue.trim().isNotEmpty) {
        parsedArguments = _parseToolCallArguments(argumentsValue);
      }
      result.add(
        buildToolCallRecord(
          id: ValueReaders.stringValue(call['id']),
          name: ValueReaders.stringValue(functionData['name']),
          arguments: parsedArguments,
          rawArguments: ValueReaders.stringValue(argumentsValue),
        ),
      );
    }
    return result;
  }

  static Object _parseToolCallArguments(String raw) {
    // 中文注释: 兼容模式（deepseek/qwen/第三方网关）常把 arguments 用 ```json``` 代码块包裹，
    // 直接 jsonDecode 会抛异常并静默清空参数，导致工具收到空入参。这里先剥离代码块再解析，全部失败才退回空 map
    // （原始串仍保留在 raw_arguments 字段，供后续诊断/二次解析）。
    final trimmed = raw.trim();
    final candidates = <String>[trimmed];
    final stripped = _stripCodeFence(trimmed);
    if (stripped.isNotEmpty && stripped != trimmed) {
      candidates.add(stripped);
    }
    for (final candidate in candidates) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map) {
          return ValueReaders.mapValue(decoded);
        }
      } catch (_) {
        // 继续尝试下一个候选（剥离代码块后再解析一次）。
      }
    }
    return <String, Object?>{};
  }

  static String _stripCodeFence(String value) {
    // 中文注释: 去掉 ```json ... ``` / ``` ... ``` 代码块包裹，兼容只开头或只结尾的半包裹。
    var result = value.trim();
    if (!result.startsWith('```')) {
      return result;
    }
    final firstNewline = result.indexOf('\n');
    if (firstNewline > 0) {
      result = result.substring(firstNewline + 1);
    }
    if (result.endsWith('```')) {
      result = result.substring(0, result.length - 3);
    }
    return result.trim();
  }
}
