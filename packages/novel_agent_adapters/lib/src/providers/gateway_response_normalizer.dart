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
        try {
          parsedArguments = jsonDecode(argumentsValue);
        } catch (_) {
          parsedArguments = <String, Object?>{};
        }
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
}
