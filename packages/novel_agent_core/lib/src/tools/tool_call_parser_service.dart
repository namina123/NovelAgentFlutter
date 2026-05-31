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
    calls.addAll(_parseFunctionCallLikeToolCalls(content));
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
    if (ValueReaders.mapValue(map['function']).isNotEmpty) {
      return <JsonMap>[_normalizerService.normalizeToolCall(map)];
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

  List<JsonMap> _parseFunctionCallLikeToolCalls(String content) {
    // 中文注释: 部分 Anthropic 兼容中转会把工具调用降级成文本标签，这里把几种稳定变体补回正式调用。
    final result = <JsonMap>[];
    result.addAll(_parseFunctionCallJsonTags(content));
    result.addAll(_parseInvokeParameterTags(content));
    result.addAll(_parseFunctionInvocationText(content));
    result.addAll(_parseNamedArgumentInvocationText(content));
    result.addAll(_parseWrappedToolCallInvocationText(content));
    result.addAll(_parseSimpleToolTags(content));
    return result;
  }

  List<JsonMap> _parseFunctionCallJsonTags(String content) {
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'<functioncall>\s*([\s\S]*?)\s*</functioncall>',
      caseSensitive: false,
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final rawText = match.group(1)?.trim() ?? '';
      final parsed = _decodeToolLikeValue(rawText);
      result.addAll(_callsFromDecoded(parsed));
    }
    return result;
  }

  List<JsonMap> _parseInvokeParameterTags(String content) {
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'<invoke\s+name="([^"]+)">([\s\S]*?)</invoke>',
      caseSensitive: false,
      multiLine: true,
    );
    final parameterPattern = RegExp(
      r'<parameter\s+name="([^"]+)"(?:\s+string="true")?>([\s\S]*?)</parameter>',
      caseSensitive: false,
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final name = match.group(1)?.trim() ?? '';
      final body = match.group(2)?.trim() ?? '';
      if (name.isEmpty || body.isEmpty) {
        continue;
      }
      final arguments = <String, Object?>{};
      for (final parameter in parameterPattern.allMatches(body)) {
        final key = parameter.group(1)?.trim() ?? '';
        final value = parameter.group(2)?.trim() ?? '';
        if (key.isEmpty) {
          continue;
        }
        arguments[key] = value;
      }
      if (arguments.isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalizeToolCall(<String, Object?>{
          'name': name,
          'arguments': arguments,
        }),
      );
    }
    return result;
  }

  List<JsonMap> _parseFunctionInvocationText(String content) {
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*(\{[\s\S]*\})\s*\)',
      caseSensitive: false,
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final name = match.group(1)?.trim() ?? '';
      final rawArguments = match.group(2)?.trim() ?? '';
      if (name.isEmpty || rawArguments.isEmpty) {
        continue;
      }
      final decoded = _decodeToolLikeValue(rawArguments);
      final arguments = ValueReaders.mapValue(decoded);
      if (arguments.isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalizeToolCall(<String, Object?>{
          'name': name,
          'arguments': arguments,
        }),
      );
    }
    return result;
  }

  List<JsonMap> _parseNamedArgumentInvocationText(String content) {
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*([A-Za-z_][A-Za-z0-9_]*\s*=\s*"[^"]*"(?:\s*,\s*[A-Za-z_][A-Za-z0-9_]*\s*=\s*"[^"]*")*)\s*\)',
      caseSensitive: false,
      multiLine: true,
    );
    final argumentPattern = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"',
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(content)) {
      final name = match.group(1)?.trim() ?? '';
      final rawArguments = match.group(2)?.trim() ?? '';
      if (name.isEmpty || rawArguments.isEmpty) {
        continue;
      }
      final arguments = <String, Object?>{};
      for (final argMatch in argumentPattern.allMatches(rawArguments)) {
        final key = argMatch.group(1)?.trim() ?? '';
        if (key.isEmpty) {
          continue;
        }
        arguments[key] = argMatch.group(2) ?? '';
      }
      if (arguments.isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalizeToolCall(<String, Object?>{
          'name': name,
          'arguments': arguments,
        }),
      );
    }
    return result;
  }

  List<JsonMap> _parseWrappedToolCallInvocationText(String content) {
    // 中文注释: 某些兼容层会输出 tool_call(name="...", arguments={...}) 包装，这里拆回标准调用。
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'tool_call\s*\(\s*name\s*=\s*"([^"]+)"\s*,\s*arguments\s*=\s*(\{[\s\S]*?\})\s*\)',
      caseSensitive: false,
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final name = match.group(1)?.trim() ?? '';
      final rawArguments = match.group(2)?.trim() ?? '';
      if (name.isEmpty || rawArguments.isEmpty) {
        continue;
      }
      final decoded = _decodeToolLikeValue(rawArguments);
      final arguments = ValueReaders.mapValue(decoded);
      if (arguments.isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalizeToolCall(<String, Object?>{
          'name': name,
          'arguments': arguments,
        }),
      );
    }
    return result;
  }

  List<JsonMap> _parseSimpleToolTags(String content) {
    // 中文注释: 某些上游会直接输出 <read_file>path</read_file> 这类极简标签，这里按工具语义补回参数。
    final result = <JsonMap>[];
    final pattern = RegExp(
      r'<([A-Za-z_][A-Za-z0-9_]*)>([\s\S]*?)</\1>',
      caseSensitive: false,
      multiLine: true,
    );
    for (final match in pattern.allMatches(content)) {
      final name = match.group(1)?.trim() ?? '';
      final body = match.group(2)?.trim() ?? '';
      if (name.isEmpty || body.isEmpty) {
        continue;
      }
      final loweredName = name.toLowerCase();
      if (loweredName == 'functioncall' ||
          loweredName == 'tool_call' ||
          loweredName == 'invoke') {
        continue;
      }
      final decoded = _decodeToolLikeValue(body);
      if (decoded != null) {
        final parsed = _callsFromDecoded(<String, Object?>{
          'name': name,
          'arguments': decoded,
        });
        if (parsed.isNotEmpty) {
          result.addAll(parsed);
          continue;
        }
      }
      final arguments = _stringBodyArgumentsFor(name, body);
      if (arguments.isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalizeToolCall(<String, Object?>{
          'name': name,
          'arguments': arguments,
        }),
      );
    }
    return result;
  }

  JsonMap _stringBodyArgumentsFor(String toolName, String body) {
    final normalizedName = toolName.trim().toLowerCase();
    switch (normalizedName) {
      case 'read_file':
      case 'read_project_file':
      case 'list_directory':
      case 'list_project_files':
      case 'get_file_info':
      case 'get_project_file_info':
      case 'delete_file':
      case 'delete_project_file':
      case 'create_backup':
        return <String, Object?>{'relative_path': body};
      default:
        return <String, Object?>{};
    }
  }
}
