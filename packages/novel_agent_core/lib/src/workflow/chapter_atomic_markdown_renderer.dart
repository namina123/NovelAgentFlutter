import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_atomic_constants.dart';

class ChapterAtomicMarkdownRenderer {
  String renderMarkdown(JsonMap execution) {
    // 中文注释: Markdown 清单让 GUI、CLI 和调试输出都能直接展示执行包，不必读 JSON。
    final lines = <String>[
      '# 章节原子任务执行包',
      '',
      '- 任务：${ValueReaders.stringValue(execution['task_title'], '未命名任务')}',
      '- 任务 ID：${ValueReaders.stringValue(execution['task_id'])}',
      '- 状态：${ValueReaders.stringValue(execution['status'])}',
      '- 模式：${ValueReaders.stringValue(execution['mode'])}',
      '- 类型：${ValueReaders.stringValue(execution['task_type'])}',
      '- 上下文包：${ValueReaders.stringValue(execution['context_pack_id'])}',
      '- 执行包：${ValueReaders.stringValue(execution['relative_path'])}',
      '- 创建时间：${ValueReaders.stringValue(execution['created_at'])}',
      '',
      '## 任务目标',
      ValueReaders.stringValue(execution['goal'], '未填写。'),
    ];
    final brief = ValueReaders.stringValue(execution['brief']).trim();
    if (brief.isNotEmpty) {
      lines
        ..add('')
        ..add('## 简述')
        ..add(brief);
    }
    lines
      ..add('')
      ..add('## 拟写入路径');
    final outputs = ValueReaders.mapValue(execution['proposed_output_paths']);
    if (outputs.isEmpty) {
      lines.add('- 暂无。');
    } else {
      for (final entry in outputs.entries) {
        lines.add('- ${entry.key}：${ValueReaders.stringValue(entry.value)}');
      }
    }
    final actualOutputs = ValueReaders.stringList(execution['output_paths']);
    if (actualOutputs.isNotEmpty) {
      lines
        ..add('')
        ..add('## 已写入路径');
      for (final path in actualOutputs) {
        lines.add('- $path');
      }
    }
    lines
      ..add('')
      ..add('## 步骤');
    for (final rawStep in ValueReaders.objectList(execution['steps'])) {
      final step = ValueReaders.mapValue(rawStep);
      if (step.isEmpty) {
        continue;
      }
      lines.add(
        '- [${ValueReaders.stringValue(step['status'], ChapterAtomicConstants.stepPending)}] '
        '${ValueReaders.stringValue(step['title'], ValueReaders.stringValue(step['id']))}：'
        '${ValueReaders.stringValue(step['description'])}',
      );
    }
    lines
      ..add('')
      ..add('## 上下文摘要')
      ..add(ValueReaders.stringValue(execution['context_pack_summary']));
    final responseSummary = ValueReaders.stringValue(
      execution['last_response_summary'],
    ).trim();
    if (responseSummary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 最近模型输出摘要')
        ..add(responseSummary);
    }
    return lines.join('\n');
  }
}
