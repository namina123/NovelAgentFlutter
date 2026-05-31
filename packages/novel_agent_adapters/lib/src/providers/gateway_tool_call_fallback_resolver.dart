import 'package:novel_agent_core/novel_agent_core.dart';

class GatewayToolCallFallbackResolver {
  const GatewayToolCallFallbackResolver()
    : _parserService = const _DefaultToolCallParserService();

  final _ToolCallParserPort _parserService;

  List<JsonMap> parseFallbackToolCalls(JsonMap result) {
    return _parserService.parseToolCalls(result);
  }
}

abstract class _ToolCallParserPort {
  List<JsonMap> parseToolCalls(JsonMap result);
}

class _DefaultToolCallParserService implements _ToolCallParserPort {
  const _DefaultToolCallParserService();

  @override
  List<JsonMap> parseToolCalls(JsonMap result) {
    return ToolCallParserService().parseToolCalls(result);
  }
}
