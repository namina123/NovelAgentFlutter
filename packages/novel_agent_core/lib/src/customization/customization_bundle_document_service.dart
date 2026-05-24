import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';

class CustomizationBundleDocumentService {
  const CustomizationBundleDocumentService();

  JsonMap buildBundle({
    required List<JsonMap> agents,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required List<JsonMap> agentGroups,
    String title = '',
    String description = '',
  }) {
    // 中文注释: 生态包导出文档统一从这里构建，确保 GUI 和 CLI 导出的结构完全一致。
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'novel_agent_customization_bundle',
      'title': title.trim().isEmpty ? 'NOVEL Agent 自定义生态包' : title.trim(),
      'description': description.trim(),
      'agents': _cleanEntries(agents),
      'skills': _cleanEntries(skills),
      'skill_groups': _cleanEntries(skillGroups),
      'agent_groups': _cleanEntries(agentGroups),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  String encodeBundle(JsonMap bundle) {
    // 中文注释: bundle 文本统一使用稳定缩进，便于版本管理和人工检查。
    return '${const JsonEncoder.withIndent('  ').convert(bundle)}\n';
  }

  List<JsonMap> _cleanEntries(List<JsonMap> entries) {
    return entries
        .map(ValueReaders.deepCopyMap)
        .map(_removeTransientFields)
        .toList(growable: false);
  }

  JsonMap _removeTransientFields(JsonMap value) {
    final next = ValueReaders.deepCopyMap(value);
    next.remove('relative_path');
    next.remove('project_relative_path');
    next.remove('entry_file_path');
    return next;
  }
}
