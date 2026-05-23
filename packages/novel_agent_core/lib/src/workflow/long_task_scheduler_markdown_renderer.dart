import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskSchedulerMarkdownRenderer {
  String renderMarkdown(JsonMap plan) {
    // 中文注释: 调度 Markdown 用于 CLI 和日志观察，不参与任何自动控制分支。
    final taskIds = ValueReaders.stringList(plan['dispatch_task_ids']);
    final lines = <String>[
      '# 长任务后台调度',
      '',
      '- 状态：${_stateLabel(ValueReaders.stringValue(plan['worker_state']))}',
      '- 动作：${ValueReaders.stringValue(plan['action'])}',
      '- 原因：${ValueReaders.stringValue(plan['reason'])}',
      '- 说明：${ValueReaders.stringValue(plan['note'])}',
      '- 宿主命令：${ValueReaders.stringValue(plan['host_command'])}',
      '- 是否派发模型：${ValueReaders.boolValue(plan['should_dispatch']) ? '是' : '否'}',
    ];
    if (taskIds.isNotEmpty) {
      lines.add('- 本批任务：${taskIds.join('、')}');
    }
    return lines.join('\n');
  }

  String _stateLabel(String state) {
    // 中文注释: 调度状态标签保持与旧项目语义一致，供宿主直接展示。
    switch (state) {
      case 'ready':
        return '可运行';
      case 'blocked':
        return '受阻';
      case 'paused':
        return '已暂停';
      case 'finished':
        return '已结束';
      case 'disabled':
        return '未启用';
      case 'stopped':
        return '已停止';
      default:
        return '空闲';
    }
  }
}
