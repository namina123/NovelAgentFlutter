import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskRunMarkdownRenderer {
  String renderMarkdown(JsonMap record) {
    // 中文注释: 长任务运行 Markdown 用于任务中心和 CLI 直接浏览最近执行历史。
    final lines = <String>[
      '# 长任务运行记录',
      '',
      '- 运行 ID：${ValueReaders.stringValue(record['id'])}',
      '- 计划 ID：${ValueReaders.stringValue(record['plan_id'])}',
      '- 模式：${ValueReaders.stringValue(record['mode'])}',
      '- 状态：${ValueReaders.stringValue(record['status'])}',
      '- 停止原因：${ValueReaders.stringValue(record['stop_reason'])}',
      '- 已执行步数：${ValueReaders.intValue(record['completed_steps'])}',
      '- 更新时间：${ValueReaders.stringValue(record['updated_at'])}',
      '',
      '## 步骤',
    ];
    final steps = ValueReaders.mapList(record['steps']);
    if (steps.isEmpty) {
      lines.add('- 暂无步骤。');
    }
    for (final step in steps) {
      final task = ValueReaders.mapValue(step['task']);
      final detail = ValueReaders.boolValue(step['ok'])
          ? ValueReaders.stringList(step['output_paths']).join('、')
          : ValueReaders.stringValue(step['error']);
      final checkpointReviewPath = ValueReaders.stringValue(
        step['checkpoint_review_path'],
      ).trim();
      final activationReportPath = ValueReaders.stringValue(
        step['activation_report_path'],
      ).trim();
      final activationSummary = ValueReaders.stringValue(
        step['activation_report_summary'],
      ).trim();
      final deliveryState = ValueReaders.stringValue(
        step['chapter_delivery_state'],
      ).trim();
      final deliveryPath = ValueReaders.stringValue(
        step['chapter_delivery_path'],
      ).trim();
      lines.add(
        '- #${ValueReaders.intValue(step['index'])}'
        '｜${ValueReaders.stringValue(step['phase'])}'
        '｜${ValueReaders.stringValue(task['title'])}'
        '｜$detail',
      );
      if (activationReportPath.isNotEmpty) {
        lines.add('  激活报告：$activationReportPath');
      }
      if (activationSummary.isNotEmpty) {
        lines.add('  激活摘要：$activationSummary');
      }
      if (deliveryState.isNotEmpty) {
        lines.add('  交付状态：$deliveryState');
      }
      if (deliveryPath.isNotEmpty) {
        lines.add('  交付路径：$deliveryPath');
      }
      if (checkpointReviewPath.isNotEmpty) {
        lines.add('  复盘：$checkpointReviewPath');
      }
      final checkpointSeverity = ValueReaders.stringValue(
        step['checkpoint_review_severity'],
      ).trim();
      if (checkpointSeverity.isNotEmpty) {
        lines.add('  风险级别：$checkpointSeverity');
      }
      final checkpointActionSummary = ValueReaders.stringValue(
        step['checkpoint_review_action_summary'],
      ).trim();
      if (checkpointActionSummary.isNotEmpty) {
        lines.add('  动作建议：$checkpointActionSummary');
      }
      final informationSummary = ValueReaders.stringValue(
        step['information_summary'],
      ).trim();
      if (informationSummary.isNotEmpty) {
        lines.add('  Information：$informationSummary');
      }
    }
    return lines.join('\n');
  }
}
