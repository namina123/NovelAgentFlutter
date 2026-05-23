import '../common/json_types.dart';
import '../common/value_readers.dart';

class TaskQueueRecordRenderer {
  JsonMap runSummary(JsonMap record) {
    // 中文注释: 运行摘要只保留列表和调试需要的轻量字段，避免任务中心加载完整大记录。
    final steps = ValueReaders.objectList(record['steps']);
    return <String, Object?>{
      'id': ValueReaders.stringValue(record['id']),
      'relative_path': ValueReaders.stringValue(record['relative_path']),
      'summary_path': ValueReaders.stringValue(record['summary_path']),
      'status': ValueReaders.stringValue(record['status']),
      'stop_reason': ValueReaders.stringValue(record['stop_reason']),
      'stop_note': ValueReaders.stringValue(record['stop_note']),
      'completed_steps': steps.length,
      'last_task_id': ValueReaders.stringValue(record['last_task_id']),
      'last_task_relative_path': ValueReaders.stringValue(
        record['last_task_relative_path'],
      ),
      'updated_at': ValueReaders.stringValue(record['updated_at']),
    };
  }

  String renderMarkdown(JsonMap record) {
    // 中文注释: 队列运行 Markdown 只负责可读摘要，不参与状态判断或停止决策。
    final lines = <String>[
      '# 受控连续任务运行',
      '',
      '- 运行 ID：${ValueReaders.stringValue(record['id'])}',
      '- 状态：${ValueReaders.stringValue(record['status'])}',
      '- 停止原因：${ValueReaders.stringValue(record['stop_reason'])}',
      '- 停止说明：${ValueReaders.stringValue(record['stop_note'])}',
      '- 已执行步数：${ValueReaders.intValue(record['completed_steps'])}',
      '- 创建时间：${ValueReaders.stringValue(record['created_at'])}',
      '- 更新时间：${ValueReaders.stringValue(record['updated_at'])}',
      '',
      '## 参数',
    ];
    final options = ValueReaders.mapValue(record['options']);
    for (final key in options.keys) {
      lines.add('- $key：${options[key]}');
    }
    lines.add('');
    lines.add('## 步骤');
    final steps = ValueReaders.objectList(record['steps']);
    if (steps.isEmpty) {
      lines.add('- 暂无步骤。');
    } else {
      for (final rawStep in steps) {
        final step = ValueReaders.mapValue(rawStep);
        final body = ValueReaders.boolValue(step['ok'])
            ? _joinStrings(step['output_paths'])
            : ValueReaders.stringValue(step['error']);
        lines.add(
          '- #${ValueReaders.intValue(step['index'])} ${ValueReaders.stringValue(step['task_status_after'])}｜${ValueReaders.stringValue(step['task_title'])}｜$body',
        );
      }
    }
    return lines.join('\n');
  }

  String _joinStrings(Object? value) {
    // 中文注释: 数组路径渲染集中在这里，避免 Markdown 摘要里出现空白尾巴。
    final values = ValueReaders.stringList(value);
    if (values.isEmpty) {
      return '无输出路径';
    }
    return values.join('、');
  }
}
