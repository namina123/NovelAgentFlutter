import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'tool_alias_service.dart';

class ToolCallNormalizerService {
  ToolCallNormalizerService({ToolAliasService? aliasService})
    : _aliasService = aliasService ?? ToolAliasService();

  final ToolAliasService _aliasService;

  JsonMap normalizeToolCall(JsonMap rawCall) {
    // 中文注释: 这里统一兼容 OpenAI、Anthropic、旧项目 fallback JSON 和宿主自造结构。
    final functionData = ValueReaders.mapValue(rawCall['function']);
    var name = ValueReaders.stringValue(
      rawCall['name'],
      ValueReaders.stringValue(
        rawCall['tool_name'],
        ValueReaders.stringValue(
          rawCall['tool'],
          ValueReaders.stringValue(
            rawCall['action'],
            ValueReaders.stringValue(functionData['name']),
          ),
        ),
      ),
    );
    if (name.trim().isEmpty) {
      final recipientName = ValueReaders.stringValue(
        rawCall['recipient_name'],
      ).trim();
      if (recipientName.isNotEmpty) {
        final parts = recipientName.split('.');
        name = parts.isEmpty ? recipientName : parts.last;
      }
    }
    final originalName = name.trim();
    final canonicalName = _aliasService.canonicalToolName(originalName);
    final rawArguments = ValueReaders.stringValue(
      rawCall['raw_arguments'],
      ValueReaders.stringValue(functionData['arguments']),
    );
    final arguments = _normalizeArguments(
      canonicalName,
      _readArguments(rawCall, functionData),
      originalToolName: originalName,
    );
    return <String, Object?>{
      'id': ValueReaders.stringValue(
        rawCall['id'],
        'tool_call_${DateTime.now().microsecondsSinceEpoch}',
      ),
      'name': canonicalName,
      'tool_name': canonicalName,
      'arguments': arguments,
      'raw_arguments': rawArguments,
      'status': ValueReaders.stringValue(rawCall['status'], 'pending'),
    };
  }

  List<JsonMap> normalizeToolCalls(Object? rawCalls) {
    // 中文注释: 批量规范化结果只返回有效工具调用，供调度层直接执行。
    return ValueReaders.objectList(rawCalls)
        .map(ValueReaders.mapValue)
        .where((call) => call.isNotEmpty)
        .map(normalizeToolCall)
        .where(
          (call) => ValueReaders.stringValue(call['name']).trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  JsonMap _readArguments(JsonMap rawCall, JsonMap functionData) {
    // 中文注释: 参数读取在这里把字符串 JSON 和对象结构收拢成一个字典。
    final directArguments = rawCall.containsKey('arguments')
        ? rawCall['arguments']
        : rawCall.containsKey('input')
        ? rawCall['input']
        : rawCall.containsKey('parameters')
        ? rawCall['parameters']
        : rawCall['action_input'];
    if (directArguments is Map<String, Object?>) {
      return Map<String, Object?>.from(directArguments);
    }
    if (directArguments is Map) {
      return directArguments.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    final functionArguments = functionData['arguments'];
    if (functionArguments is String && functionArguments.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(functionArguments);
        return ValueReaders.mapValue(decoded);
      } catch (_) {
        return <String, Object?>{};
      }
    }
    return ValueReaders.mapValue(functionArguments);
  }

  JsonMap _normalizeArguments(
    String canonicalName,
    JsonMap arguments, {
    required String originalToolName,
  }) {
    // 中文注释: 这里把旧字段名统一成当前核心约定，避免每个执行器重复兼容 path/query/newName。
    final normalized = ValueReaders.deepCopyMap(arguments);
    _copyIfMissing(normalized, 'relative_path', <String>[
      'relativePath',
      'path',
      'file_path',
      'filePath',
    ]);
    _copyIfMissing(normalized, 'target_relative_path', <String>[
      'targetRelativePath',
      'targetPath',
      'target_path',
      'destination_path',
      'destinationPath',
    ]);
    _copyIfMissing(normalized, 'new_name', <String>[
      'newName',
      'file_name',
      'fileName',
    ]);
    _copyIfMissing(normalized, 'pattern', <String>[
      'query',
      'keyword',
      'needle',
    ]);
    _copyIfMissing(normalized, 'content', <String>[
      'text',
      'body',
      'replacement',
      'new_text',
      'newText',
    ]);
    _copyIfMissing(normalized, 'old_text', <String>[
      'oldText',
      'search',
      'search_text',
      'searchText',
      'anchor',
    ]);
    _copyIfMissing(normalized, 'start_line', <String>[
      'startLine',
      'from_line',
      'fromLine',
    ]);
    _copyIfMissing(normalized, 'end_line', <String>[
      'endLine',
      'to_line',
      'toLine',
    ]);
    _copyIfMissing(normalized, 'target_line', <String>[
      'targetLine',
      'insert_line',
      'insertLine',
    ]);
    _copyIfMissing(normalized, 'overwrite', <String>['force']);
    if (canonicalName == 'request_gateway_tool' &&
        ValueReaders.stringValue(normalized['gateway_tool']).trim().isEmpty) {
      normalized['gateway_tool'] = originalToolName;
    }
    if (canonicalName == 'create_project_entry' &&
        !normalized.containsKey('is_folder')) {
      final path = ValueReaders.stringValue(normalized['relative_path']).trim();
      final content = ValueReaders.stringValue(normalized['content']).trim();
      if (path.isNotEmpty &&
          !path.split('/').last.contains('.') &&
          content.isEmpty) {
        normalized['is_folder'] = true;
      }
    }
    return normalized;
  }

  void _copyIfMissing(
    JsonMap target,
    String canonicalKey,
    List<String> aliases,
  ) {
    // 中文注释: 只有目标字段缺失时才回填别名，避免覆盖已经被上游显式标准化的值。
    if (target.containsKey(canonicalKey)) {
      return;
    }
    for (final alias in aliases) {
      if (target.containsKey(alias)) {
        target[canonicalKey] = target[alias];
        return;
      }
    }
  }
}
