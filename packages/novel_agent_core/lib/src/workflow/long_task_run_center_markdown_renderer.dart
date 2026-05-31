import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskRunCenterMarkdownRenderer {
  String renderMarkdown(JsonMap contract) {
    // 中文注释: 运行中心 Markdown 主要服务 CLI、日志和调试视图，不承担结构化决策。
    final progress = ValueReaders.mapValue(contract['progress']);
    final activeTask = ValueReaders.mapValue(contract['active_task']);
    final lines = <String>[
      '# 长任务运行中心',
      '',
      '- 运行 ID：${ValueReaders.stringValue(contract['run_id'])}',
      '- 状态：${ValueReaders.stringValue(contract['status_label'])}',
      '- 阶段：${ValueReaders.stringValue(contract['phase_label'])}',
      '- 原因：${ValueReaders.stringValue(contract['reason'])}',
      '- 说明：${ValueReaders.stringValue(contract['note'])}',
      '- 进度：${ValueReaders.intValue(progress['succeeded'])}/${ValueReaders.intValue(progress['task_count'])} 个任务',
    ];
    final message = ValueReaders.stringValue(contract['message']).trim();
    if (message.isNotEmpty) {
      lines.add('- 现场：$message');
    }
    if (activeTask.isNotEmpty) {
      lines.add(
        '- 当前任务：${ValueReaders.stringValue(activeTask['title'], ValueReaders.stringValue(activeTask['id']))}',
      );
    }
    lines.add('- ${ValueReaders.stringValue(contract['control_summary'])}');
    return lines.join('\n');
  }
}
