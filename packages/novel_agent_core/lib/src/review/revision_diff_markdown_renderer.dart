import '../common/json_types.dart';
import '../common/value_readers.dart';

class RevisionDiffMarkdownRenderer {
  String renderMarkdown(JsonMap report) {
    // 中文注释: Markdown 渲染只负责把已有报告结构转成人类可读文本，不参与 diff 计算。
    final lines = <String>[
      '# 修复任务 Diff 报告',
      '',
      '- 任务：${ValueReaders.stringValue(report['task_title'], '修复任务')}',
      '- 任务 ID：${ValueReaders.stringValue(report['task_id'])}',
      '- 任务文件：${ValueReaders.stringValue(report['task_relative_path'])}',
      '- 时间：${ValueReaders.stringValue(report['created_at'])}',
      '- 摘要：${ValueReaders.stringValue(report['summary'])}',
    ];
    for (final rawPair in ValueReaders.objectList(report['pairs'])) {
      final pair = ValueReaders.mapValue(rawPair);
      lines.add('');
      lines.add('## ${ValueReaders.stringValue(pair['target_path'], '未命名目标')}');
      lines.add('');
      lines.add(
        '- 备份：${_displayOrNone(ValueReaders.stringValue(pair['backup_path']))}',
      );
      lines.add('- 状态：${ValueReaders.stringValue(pair['status'])}');
      lines.add(
        '- 修订前：${ValueReaders.intValue(pair['before_lines'])} 行 / ${ValueReaders.intValue(pair['before_chars'])} 字',
      );
      lines.add(
        '- 修订后：${ValueReaders.intValue(pair['after_lines'])} 行 / ${ValueReaders.intValue(pair['after_chars'])} 字',
      );
      lines.add(
        '- 估算变更行：${ValueReaders.intValue(pair['changed_line_estimate'])}',
      );
      final note = ValueReaders.stringValue(pair['note']).trim();
      if (note.isNotEmpty) {
        lines.add('- 备注：$note');
      }
      final preview = ValueReaders.stringValue(pair['preview']).trim();
      if (preview.isNotEmpty) {
        lines.add('');
        lines.add('```diff');
        lines.add(preview);
        lines.add('```');
      }
    }
    return lines.join('\n');
  }

  String _displayOrNone(String value) {
    // 中文注释: 空路径用可读占位词代替，避免 Markdown 看起来像渲染失败。
    return value.trim().isNotEmpty ? value : '无';
  }
}
