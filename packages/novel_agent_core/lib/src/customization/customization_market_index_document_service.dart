import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';

class CustomizationMarketIndexDocumentService {
  const CustomizationMarketIndexDocumentService();

  JsonMap buildLocalIndex(List<JsonMap> bundles) {
    // 中文注释: 市场索引只提炼 bundle 摘要，避免把整份技能或智能体正文再复制一遍。
    final entries =
        bundles
            .map(_entryFromBundle)
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false)
          ..sort((left, right) {
            return ValueReaders.stringValue(
              left['title'],
            ).toLowerCase().compareTo(
              ValueReaders.stringValue(right['title']).toLowerCase(),
            );
          });
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'novel_agent_local_market_index',
      'entries': entries,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String encodeIndex(JsonMap index) {
    // 中文注释: JSON 索引用于机器消费，保持稳定缩进方便对比。
    return '${const JsonEncoder.withIndent('  ').convert(index)}\n';
  }

  String renderMarkdown(JsonMap index) {
    // 中文注释: Markdown 索引用于人工浏览，保留最关键的路径、描述和条目数信息即可。
    final lines = <String>[
      '# 本地生态市场索引',
      '',
      '- 更新时间：${ValueReaders.stringValue(index['updated_at'])}',
      '- 条目数：${ValueReaders.objectList(index['entries']).length}',
      '',
    ];
    final entries = ValueReaders.objectList(index['entries'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      lines.add('当前项目 exports/ 下还没有 `.customization.json` 生态包。');
      return '${lines.join('\n')}\n';
    }
    for (final entry in entries) {
      lines.add('## ${ValueReaders.stringValue(entry['title'])}');
      lines.add('');
      lines.add('- 路径：${ValueReaders.stringValue(entry['relative_path'])}');
      lines.add('- 描述：${ValueReaders.stringValue(entry['description'])}');
      lines.add(
        '- 内容：智能体 ${ValueReaders.intValue(entry['agent_count'])} / 技能 ${ValueReaders.intValue(entry['skill_count'])} / 技能组 ${ValueReaders.intValue(entry['skill_group_count'])} / 智能体组 ${ValueReaders.intValue(entry['agent_group_count'])}',
      );
      lines.add('');
    }
    return '${lines.join('\n')}\n';
  }

  JsonMap _entryFromBundle(JsonMap bundle) {
    final relativePath = ValueReaders.stringValue(
      bundle['relative_path'],
    ).trim();
    if (relativePath.isEmpty) {
      return const <String, Object?>{};
    }
    final fileName = relativePath.split('/').last;
    final fileStem = fileName.endsWith('.customization.json')
        ? fileName.substring(0, fileName.length - '.customization.json'.length)
        : fileName;
    return <String, Object?>{
      'id': _safeId(fileStem),
      'title': ValueReaders.stringValue(bundle['title'], fileName),
      'description': ValueReaders.stringValue(bundle['description']),
      'relative_path': relativePath,
      'source': 'local_project_exports',
      'schema_version': ValueReaders.intValue(bundle['schema_version'], 1),
      'agent_count': ValueReaders.mapList(bundle['agents']).length,
      'skill_count': ValueReaders.mapList(bundle['skills']).length,
      'skill_group_count': ValueReaders.mapList(bundle['skill_groups']).length,
      'agent_group_count': ValueReaders.mapList(bundle['agent_groups']).length,
      'created_at': ValueReaders.stringValue(bundle['created_at']),
    };
  }

  String _safeId(String value) {
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t ]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    if (result.isEmpty) {
      return 'customization_bundle';
    }
    return result.length <= 96 ? result : result.substring(0, 96);
  }
}
