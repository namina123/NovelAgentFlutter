import '../common/json_types.dart';
import '../common/value_readers.dart';

class GenerationRecordService {
  JsonMap sanitizeProvider(Object? providerValue) {
    // 中文注释: provider 脱敏集中在这里，避免日志、记录和 UI 预览意外泄露密钥。
    final provider = ValueReaders.mapValue(providerValue);
    if (provider.isEmpty) {
      return <String, Object?>{};
    }
    final result = ValueReaders.deepCopyMap(provider);
    for (final key in <String>['api_key', 'key', 'secret', 'token']) {
      if (result.containsKey(key)) {
        result[key] = '***';
      }
    }
    return result;
  }

  JsonMap contextPackSummary(Object? contextPackValue) {
    // 中文注释: 生成记录只保留 context pack 摘要，避免运行日志把整包上下文无限复制。
    final contextPack = ValueReaders.mapValue(contextPackValue);
    if (contextPack.isEmpty) {
      return <String, Object?>{};
    }
    final sections = ValueReaders.objectList(contextPack['sections']);
    final omitted = ValueReaders.objectList(contextPack['omitted_sections']);
    return <String, Object?>{
      'id': contextPack['id'],
      'summary': contextPack['summary'],
      'intent': contextPack['intent'],
      'budget_chars': ValueReaders.intValue(contextPack['budget_chars']),
      'used_chars': ValueReaders.intValue(contextPack['used_chars']),
      'section_titles': _sectionTitles(sections),
      'omitted_count': omitted.length,
    };
  }

  JsonMap buildRecord(
    JsonMap data, {
    String runId = '',
    String createdAt = '',
  }) {
    // 中文注释: 生成记录构建只负责把一次运行的关键信息收束成稳定结构，不做任何存储。
    var resolvedRunId = runId.trim();
    if (resolvedRunId.isEmpty) {
      resolvedRunId = ValueReaders.stringValue(data['run_id']).trim();
    }
    if (resolvedRunId.isEmpty) {
      resolvedRunId = 'run_pending';
    }
    return <String, Object?>{
      'schema_version': 1,
      'run_id': resolvedRunId,
      'request_id': ValueReaders.stringValue(data['request_id'], resolvedRunId),
      'session_id': ValueReaders.stringValue(data['session_id']),
      'agent_id': ValueReaders.stringValue(data['agent_id']),
      'agent_name': ValueReaders.stringValue(data['agent_name']),
      'intent': ValueReaders.stringValue(data['intent']),
      'model_profile_id': ValueReaders.stringValue(data['model_profile_id']),
      'provider': sanitizeProvider(data['provider']),
      'prompt_summary': _clip(ValueReaders.stringValue(data['prompt']), 600),
      'context_pack_summary': contextPackSummary(data['context_pack']),
      'context_pack': ValueReaders.mapValue(data['context_pack']),
      'tool_calls': ValueReaders.objectList(data['tool_calls']),
      'output_markdown': ValueReaders.stringValue(data['output_markdown']),
      'output_paths': ValueReaders.stringList(data['output_paths']),
      'error': ValueReaders.mapValue(data['error']),
      'created_at': createdAt,
    };
  }

  JsonMap generationRecordSummary(JsonMap record, {String relativePath = ''}) {
    // 中文注释: 运行摘要只保留列表和索引需要的信息，不把大块正文和上下文重复带出来。
    final contextSummary = ValueReaders.mapValue(
      record['context_pack_summary'],
    );
    final error = ValueReaders.mapValue(record['error']);
    return <String, Object?>{
      'run_id': ValueReaders.stringValue(record['run_id']),
      'relative_path': relativePath,
      'created_at': ValueReaders.stringValue(record['created_at']),
      'agent_name': ValueReaders.stringValue(record['agent_name']),
      'intent': ValueReaders.stringValue(record['intent']),
      'model_profile_id': ValueReaders.stringValue(record['model_profile_id']),
      'context_pack_id': ValueReaders.stringValue(contextSummary['id']),
      'output_paths': ValueReaders.stringList(record['output_paths']),
      'has_error': error.isNotEmpty,
      'prompt_summary': ValueReaders.stringValue(record['prompt_summary']),
    };
  }

  String generationRunFilePath(JsonMap record, {String dateCompact = ''}) {
    // 中文注释: 运行记录路径规则集中在这里，后续换目录策略时不需要回头改宿主层。
    var date = dateCompact.trim();
    if (date.isEmpty) {
      date = 'undated';
    }
    return 'runs/$date/${_safeRunId(ValueReaders.stringValue(record['run_id']))}';
  }

  List<String> _sectionTitles(List<Object?> sections) {
    // 中文注释: 这里只提取 section 标题摘要，避免整个 context section 在记录索引里过重。
    return sections
        .map(ValueReaders.mapValue)
        .map((section) => ValueReaders.stringValue(section['title']))
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _clip(String value, int maxChars) {
    // 中文注释: prompt 摘要裁剪统一在这里处理，保证记录体量稳定。
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}...';
  }

  String _safeRunId(String value) {
    // 中文注释: run_id 写入路径前要转成安全片段，避免路径字符污染记录目录。
    var result = value.trim();
    for (final token in <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.isEmpty) {
      result = 'run_pending';
    }
    if (!result.endsWith('.json')) {
      result = '$result.json';
    }
    if (result.length > 96) {
      return result.substring(0, 96);
    }
    return result;
  }
}
