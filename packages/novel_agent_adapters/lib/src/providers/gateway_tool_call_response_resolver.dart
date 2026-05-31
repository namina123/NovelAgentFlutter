import 'package:novel_agent_core/novel_agent_core.dart';

class GatewayToolCallResponseResolver {
  const GatewayToolCallResponseResolver._();

  static JsonMap resolveToolCalls(
    JsonMap result, {
    required List<JsonMap> Function(JsonMap result) fallbackParser,
  }) {
    final existing = ValueReaders.mapList(result['tool_calls']);
    if (existing.isNotEmpty) {
      return result;
    }
    final parsed = fallbackParser(result);
    if (parsed.isEmpty) {
      return result;
    }
    return withToolCalls(result, parsed);
  }

  static JsonMap withToolCalls(JsonMap result, List<JsonMap> toolCalls) {
    return <String, Object?>{
      ...result,
      'message': <String, Object?>{
        ...ValueReaders.mapValue(result['message']),
        'tool_calls': toolCalls,
      },
      'tool_calls': toolCalls,
    };
  }
}
