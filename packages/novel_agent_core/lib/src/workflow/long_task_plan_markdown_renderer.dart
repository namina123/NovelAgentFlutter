import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskPlanMarkdownRenderer {
  String renderMarkdown(JsonMap plan) {
    // 中文注释: 计划 Markdown 供桌面、移动和 CLI 直接浏览生成出的任务队列概况。
    final createdTasks = ValueReaders.mapList(plan['created_tasks']);
    final lines = <String>[
      '# 长任务队列计划',
      '',
      '- 计划 ID：${ValueReaders.stringValue(plan['id'])}',
      '- 模式：${ValueReaders.stringValue(plan['mode'])}',
      '- 任务数：${createdTasks.length}',
      '- 创建时间：${ValueReaders.stringValue(plan['created_at'])}',
      '',
      '## 任务',
    ];
    for (final task in createdTasks) {
      lines.add(
        '- ${ValueReaders.intValue(task['sort_order']).toString().padLeft(3, '0')}'
        '｜${ValueReaders.stringValue(task['status'])}'
        '｜${ValueReaders.stringValue(task['task_type'])}'
        '｜${ValueReaders.stringValue(task['title'])}',
      );
      final dependencies = ValueReaders.stringList(task['depends_on']);
      if (dependencies.isNotEmpty) {
        lines.add('  依赖：${dependencies.join('、')}');
      }
      final outputs = ValueReaders.stringList(task['output_paths']);
      if (outputs.isNotEmpty) {
        lines.add('  输出：${outputs.join('、')}');
      }
    }
    return lines.join('\n');
  }
}
