import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskCheckpointReviewMarkdownRenderer {
  const LongTaskCheckpointReviewMarkdownRenderer();

  String renderMarkdown(JsonMap review) {
    // 中文注释: 该渲染器面向用户直接阅读复盘结果，强调确认重点和下一步，而不是完整流水账。
    final task = ValueReaders.mapValue(review['task']);
    final lines = <String>[
      '# ${ValueReaders.stringValue(task['title'], '长任务检查点复盘')}',
      '',
      '- 任务类型：${ValueReaders.stringValue(review['task_type'])}',
      '- 模式：${ValueReaders.stringValue(review['mode'])}',
      '- 阶段：${ValueReaders.stringValue(review['stage'], '未标记')}',
      '- 风险级别：${ValueReaders.stringValue(review['severity_label'], ValueReaders.stringValue(review['severity'], '未评估'))}',
      '- 时间：${ValueReaders.stringValue(review['created_at'])}',
      '- 结果：${ValueReaders.boolValue(review['result_ok']) ? '成功' : '失败'}',
    ];
    final summary = ValueReaders.stringValue(review['summary']).trim();
    if (summary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 摘要')
        ..add(summary);
    }
    _appendList(lines, '当前产物', ValueReaders.stringList(review['output_paths']));
    _appendList(
      lines,
      '长期约束路径',
      ValueReaders.stringList(review['persistent_context_paths']),
    );
    _appendList(
      lines,
      '本轮关注点',
      ValueReaders.stringList(review['confirmation_focus']),
    );
    _appendList(
      lines,
      '漂移警戒',
      ValueReaders.stringList(review['drift_watch_items']),
    );
    _appendDriftSignals(lines, ValueReaders.mapList(review['drift_signals']));
    _appendList(
      lines,
      '风险依据',
      ValueReaders.stringList(review['severity_reasons']),
    );
    _appendList(
      lines,
      '下一步建议',
      ValueReaders.stringList(review['next_actions']),
    );
    _appendActionList(
      lines,
      '建议动作',
      ValueReaders.mapList(review['suggested_actions']),
    );
    _appendList(lines, '本轮工具', ValueReaders.stringList(review['tool_names']));
    final preview = ValueReaders.stringValue(review['response_preview']).trim();
    if (preview.isNotEmpty) {
      lines
        ..add('')
        ..add('## 返回摘要')
        ..add(preview);
    }
    final error = ValueReaders.stringValue(review['error']).trim();
    if (error.isNotEmpty) {
      lines
        ..add('')
        ..add('## 错误')
        ..add(error);
    }
    return lines.join('\n');
  }

  void _appendList(List<String> lines, String title, List<String> items) {
    if (items.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## $title');
    for (final item in items) {
      final text = item.trim();
      if (text.isNotEmpty) {
        lines.add('- $text');
      }
    }
  }

  void _appendActionList(
    List<String> lines,
    String title,
    List<JsonMap> items,
  ) {
    if (items.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## $title');
    for (final item in items) {
      final label = ValueReaders.stringValue(item['label']).trim();
      if (label.isEmpty) {
        continue;
      }
      final enabled = ValueReaders.boolValue(item['enabled']);
      final note = ValueReaders.stringValue(item['note']).trim();
      lines.add(
        '- ${enabled ? '[可用]' : '[不可用]'} $label${note.isEmpty ? '' : '：$note'}',
      );
    }
  }

  void _appendDriftSignals(List<String> lines, List<JsonMap> signals) {
    if (signals.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## 漂移信号');
    for (final signal in signals) {
      final domain = ValueReaders.stringValue(signal['domain']).trim();
      final severity = ValueReaders.stringValue(signal['severity']).trim();
      final title = ValueReaders.stringValue(signal['title']).trim();
      final note = ValueReaders.stringValue(signal['note']).trim();
      if (domain.isEmpty && title.isEmpty && note.isEmpty) {
        continue;
      }
      lines.add(
        '- ${title.isEmpty ? domain : title}'
        '${severity.isEmpty ? '' : ' [$severity]'}'
        '${note.isEmpty ? '' : '：$note'}',
      );
    }
  }
}
