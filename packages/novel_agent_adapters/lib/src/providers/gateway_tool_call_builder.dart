import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class GatewayToolCallBuilder {
  GatewayToolCallBuilder({
    required this.id,
    required this.name,
  });

  String id;
  String name;
  final StringBuffer _argumentsBuffer = StringBuffer();
  JsonMap _fallbackInput = const <String, Object?>{};

  void setId(String value) {
    if (value.isNotEmpty) {
      id = value;
    }
  }

  void setName(String value) {
    if (value.isNotEmpty) {
      name = value;
    }
  }

  void setFallbackInput(JsonMap value) {
    _fallbackInput = ValueReaders.deepCopyMap(value);
  }

  void appendPartialArguments(String chunk) {
    if (chunk.isEmpty) {
      return;
    }
    _argumentsBuffer.write(chunk);
  }

  void appendPartialJson(String chunk) {
    appendPartialArguments(chunk);
  }

  bool get hasArguments => _argumentsBuffer.isNotEmpty;

  void replaceArguments(String rawArguments) {
    // 中文注释: Responses 的 done 事件有时会给出完整 arguments，这里允许一次性替换掉增量结果。
    _argumentsBuffer.clear();
    if (rawArguments.isNotEmpty) {
      _argumentsBuffer.write(rawArguments);
    }
  }

  JsonMap build(Map<String, Object?> Function(Object? value) mapValue) {
    final rawArguments = _argumentsBuffer.toString();
    final parsedArguments = _parseArguments(rawArguments, mapValue);
    return <String, Object?>{
      'id': id,
      'name': name,
      'tool_name': name,
      'arguments': parsedArguments,
      'raw_arguments': rawArguments.isEmpty
          ? jsonEncode(_fallbackInput)
          : rawArguments,
      'status': 'pending',
    };
  }

  JsonMap _parseArguments(
    String rawArguments,
    Map<String, Object?> Function(Object? value) mapValue,
  ) {
    if (rawArguments.trim().isNotEmpty) {
      try {
        return mapValue(jsonDecode(rawArguments));
      } catch (_) {
        return mapValue(_fallbackInput);
      }
    }
    return mapValue(_fallbackInput);
  }
}
