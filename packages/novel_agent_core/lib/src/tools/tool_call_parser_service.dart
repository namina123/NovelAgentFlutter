import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'tool_call_normalizer_service.dart';

class ToolCallParserService {
  ToolCallParserService({ToolCallNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? ToolCallNormalizerService();

  final ToolCallNormalizerService _normalizerService;

  List<JsonMap> parseToolCalls(
    JsonMap llmResult, {
    bool allowInlineFallback = true,
  }) {
    // 中文注释: 工具调用解析统一支持原生 tool_calls 和正文 fallback，宿主只消费规范结果。
    final calls = <JsonMap>[];
    calls.addAll(
      _normalizerService.normalizeToolCalls(
        llmResult['tool_calls'] ??
            ValueReaders.mapValue(llmResult['message'])['tool_calls'],
      ),
    );
    if (!allowInlineFallback) {
      return _dedupeCalls(calls);
    }
    final content = ValueReaders.stringValue(llmResult['content']);
    calls.addAll(_parseTaggedToolCalls(content));
    calls.addAll(_parsePipedToolCalls(content));
    calls.addAll(_parseJsonToolCalls(content));
    return _dedupeCalls(calls);
  }

  List<JsonMap> _parseTaggedToolCalls(String content) {
    // 中文注释: 旧项目常用 <tool_call> 包裹 JSON，这里直接抽出内部对象再走统一归一化。
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'<tool_call>([\s\S]*?)</tool_call>',
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final rawText = match.group(1)?.trim() ?? '';
      final parsed = _decodeToolLikeValue(rawText);
      result.addAll(_callsFromDecoded(parsed));
    }
    return result;
  }

  List<JsonMap> _parsePipedToolCalls(String content) {
    // 中文注释: 管道标签格式让不支持原生工具的模型也能稳定输出名称和参数块。
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'<\|tool\|([^>]+)>([\s\S]*?)</\|tool\|\1>',
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final toolName = match.group(1)?.trim() ?? '';
      final rawText = match.group(2)?.trim() ?? '';
      final decoded = _decodeToolLikeValue(rawText);
      if (decoded is Map) {
        result.add(
          _normalizerService.normalizeToolCall(<String, Object?>{
            'name': toolName,
            'arguments': decoded,
          }),
        );
      }
    }
    return result;
  }

  List<JsonMap> _parseJsonToolCalls(String content) {
    // 中文注释: 这里兼容 ```json``` 代码块中的单个 tool_call 或 tool_calls 数组。
    final result = <JsonMap>[];
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    for (final match in fenced.allMatches(content)) {
      final rawText = match.group(1)?.trim() ?? '';
      final parsed = _decodeToolLikeValue(rawText);
      result.addAll(_callsFromDecoded(parsed));
    }
    final direct = _decodeToolLikeValue(content.trim());
    result.addAll(_callsFromDecoded(direct));
    return result;
  }

  Object? _decodeToolLikeValue(String rawText) {
    // 中文注释: JSON 解析失败时直接放弃该片段，避免把普通正文误判成工具调用。
    if (rawText.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(rawText);
    } catch (_) {
      return null;
    }
  }

  List<JsonMap> _callsFromDecoded(Object? decoded) {
    // 中文注释: fallback JSON 可能是单个调用、tool_calls 容器或数组，这里统一展开。
    if (decoded == null) {
      return const <JsonMap>[];
    }
    if (decoded is List) {
      return decoded
          .map(ValueReaders.mapValue)
          .where((entry) => entry.isNotEmpty)
          .map(_normalizerService.normalizeToolCall)
          .toList(growable: false);
    }
    final map = ValueReaders.mapValue(decoded);
    if (map.isEmpty) {
      return const <JsonMap>[];
    }
    if (map.containsKey('tool_calls')) {
      return _normalizerService.normalizeToolCalls(map['tool_calls']);
    }
    if (map.containsKey('tool_call')) {
      return _normalizerService.normalizeToolCalls(<Object?>[map['tool_call']]);
    }
    if (ValueReaders.stringValue(map['name']).trim().isNotEmpty ||
        ValueReaders.stringValue(map['tool_name']).trim().isNotEmpty ||
        ValueReaders.stringValue(map['recipient_name']).trim().isNotEmpty) {
      return <JsonMap>[_normalizerService.normalizeToolCall(map)];
    }
    return const <JsonMap>[];
  }

  List<JsonMap> _dedupeCalls(List<JsonMap> calls) {
    // 中文注释: 去重避免同一个原生 tool_call 又被 fallback 文本重复解析执行两次。
    final result = <JsonMap>[];
    final seenExact = <String>{};
    final seenByNameAndArguments = <String>{};
    for (final call in calls) {
      final exactSignature = jsonEncode(<String, Object?>{
        'id': call['id'],
        'name': call['name'],
        'arguments': call['arguments'],
      });
      final semanticSignature = jsonEncode(<String, Object?>{
        'name': call['name'],
        'arguments': call['arguments'],
      });
      if (!seenExact.add(exactSignature)) {
        continue;
      }
      if (!seenByNameAndArguments.add(semanticSignature)) {
        continue;
      }
      result.add(call);
    }
    return result;
  }
}
