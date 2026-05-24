import 'package:novel_agent_core/novel_agent_core.dart';

class CustomizationImportPreviewTextService {
  const CustomizationImportPreviewTextService();

  String buildPreviewText(JsonMap preview) {
    // 中文注释: 预检摘要只负责把结构化结果翻译成页面可读文本，不承担导入逻辑。
    if (preview.isEmpty) {
      return '';
    }
    final summary = ValueReaders.mapValue(preview['summary']);
    final lines = <String>[];
    final title = ValueReaders.stringValue(preview['title'], '生态包');
    lines.add('生态包预检：$title');
    lines.add(
      '总计 ${ValueReaders.intValue(summary["total"])} 项；新增 ${ValueReaders.intValue(summary["new"])}，项目冲突 ${ValueReaders.intValue(summary["project_conflicts"])}，覆盖 ${ValueReaders.intValue(summary["will_overwrite"])}，跳过 ${ValueReaders.intValue(summary["skipped"])}，内置遮蔽 ${ValueReaders.intValue(summary["builtin_overrides"])}，已阻止内置遮蔽 ${ValueReaders.intValue(summary["blocked_builtin_overrides"])}。',
    );
    final items = ValueReaders.objectList(preview['items'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final visibleCount = items.length < 8 ? items.length : 8;
    for (var index = 0; index < visibleCount; index += 1) {
      final item = items[index];
      final changedFields = ValueReaders.stringList(item['changed_fields']);
      final fieldNote = changedFields.isEmpty
          ? ''
          : '；差异字段：${changedFields.join(", ")}';
      lines.add(
        '- ${_kindLabel(ValueReaders.stringValue(item["kind"]))}/${ValueReaders.stringValue(item["id"])}：${_statusLabel(ValueReaders.stringValue(item["status"]))} -> ${_actionLabel(ValueReaders.stringValue(item["action"]))}$fieldNote',
      );
    }
    if (items.length > visibleCount) {
      lines.add('- 其余 ${items.length - visibleCount} 项已省略。');
    }
    return lines.join('\n');
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'skill':
        return '技能';
      case 'skill_group':
        return '技能组';
      case 'agent_group':
        return '智能体组';
      case 'agent':
      default:
        return '智能体';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return '新配置';
      case 'project_conflict':
        return '项目同 ID 冲突';
      case 'builtin_override':
        return '会遮蔽内置配置';
      case 'invalid':
        return '无效项';
      default:
        return status;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'create':
        return '写入';
      case 'overwrite':
        return '覆盖';
      case 'skip':
        return '跳过';
      case 'skip_builtin':
        return '跳过内置遮蔽';
      case 'create_override':
        return '创建项目覆盖';
      default:
        return action;
    }
  }
}
