import 'package:novel_agent_core/novel_agent_core.dart';

class WorkflowOutputSummaryService {
  const WorkflowOutputSummaryService();

  JsonMap extractRunCenterContract(JsonMap result) {
    // 中文注释: CLI 只读取运行结果里已经投影好的 run center 合同，不再自己推断状态。
    final direct = ValueReaders.mapValue(
      result['long_task_run_center_contract'],
    );
    if (direct.isNotEmpty) {
      return direct;
    }
    final nested = ValueReaders.mapValue(result['run_center_contract']);
    if (nested.isNotEmpty) {
      return nested;
    }
    final record = ValueReaders.mapValue(result['record']);
    if (record.isNotEmpty) {
      return ValueReaders.mapValue(record['run_center_contract']);
    }
    return const <String, Object?>{};
  }

  List<String> runCenterBriefLines(JsonMap contract) {
    // 中文注释: CLI 的摘要只做“阶段/进度/当前任务/下一步”这类短信息提炼，不改运行逻辑。
    final lines = <String>[];
    final phaseLabel = ValueReaders.stringValue(contract['phase_label']).trim();
    final statusLabel = ValueReaders.stringValue(
      contract['status_label'],
    ).trim();
    final activeTask = ValueReaders.mapValue(contract['active_task']);
    final activeTaskTitle = ValueReaders.stringValue(
      activeTask['title'],
      ValueReaders.stringValue(contract['active_task_title']),
    ).trim();
    final progress = ValueReaders.mapValue(contract['progress']);
    final percent = ValueReaders.intValue(
      progress['overall_percent'],
      ValueReaders.intValue(progress['percent']),
    );
    final blocker = ValueReaders.stringValue(contract['blocker']).trim();
    final reason = ValueReaders.stringValue(contract['reason']).trim();
    final nextAction = ValueReaders.stringValue(
      contract['recommended_action_label'],
    ).trim();
    final resumeBrief = ValueReaders.mapValue(contract['resume_brief']);
    if (statusLabel.isNotEmpty) {
      lines.add('状态：$statusLabel');
    }
    if (phaseLabel.isNotEmpty) {
      lines.add('阶段：$phaseLabel');
    }
    if (percent > 0) {
      lines.add('进度：$percent%');
    }
    if (activeTaskTitle.isNotEmpty) {
      lines.add('当前任务：$activeTaskTitle');
    }
    if (reason.isNotEmpty) {
      lines.add('停止原因：$reason');
    } else if (blocker.isNotEmpty) {
      lines.add('阻塞原因：$blocker');
    }
    if (nextAction.isNotEmpty) {
      lines.add('下一步：$nextAction');
    }
    if (resumeBrief.isNotEmpty) {
      final title = ValueReaders.stringValue(
        resumeBrief['resume_title'],
      ).trim();
      final summary = ValueReaders.stringValue(
        resumeBrief['resume_summary'],
      ).trim();
      final lastStep = ValueReaders.stringValue(
        resumeBrief['last_step_summary'],
      ).trim();
      final nextActionSummary = ValueReaders.stringValue(
        resumeBrief['next_action_summary'],
      ).trim();
      if (title.isNotEmpty) {
        lines.add('恢复标题：$title');
      }
      if (summary.isNotEmpty) {
        lines.add(summary);
      }
      if (lastStep.isNotEmpty) {
        lines.add(lastStep);
      }
      if (nextActionSummary.isNotEmpty) {
        lines.add(nextActionSummary);
      }
    }
    return lines;
  }
}
