import 'dart:io';

import 'package:novel_agent_cli/commands/workflow/workflow_output_summary_service.dart';

void main() {
  const service = WorkflowOutputSummaryService();
  final contract = service.extractRunCenterContract(const <String, Object?>{
    'long_task_run_center_contract': <String, Object?>{
      'status_label': '已暂停',
      'phase_label': '已暂停',
      'reason': 'manual_pause',
      'recommended_action_label': '继续运行',
      'progress': <String, Object?>{'overall_percent': 42},
      'active_task': <String, Object?>{'title': '第 8 章'},
      'resume_brief': <String, Object?>{
        'resume_title': '长任务已暂停',
        'resume_summary': '当前运行被手动暂停，主链不会继续推进，直到你主动恢复。',
        'last_step_summary': '最近停在：第 8 章（tasks/ch08.json）',
        'next_action_summary': '建议下一步：继续运行',
      },
    },
  });
  final lines = service.runCenterBriefLines(contract);
  final expected = <String>[
    '状态：已暂停',
    '阶段：已暂停',
    '进度：42%',
    '当前任务：第 8 章',
    '停止原因：manual_pause',
    '下一步：继续运行',
    '恢复标题：长任务已暂停',
  ];
  for (final item in expected) {
    if (!lines.contains(item)) {
      stderr.writeln('workflow_output_summary_probe: missing line -> $item');
      stderr.writeln(lines.join('\n'));
      exitCode = 1;
      return;
    }
  }
  stdout.writeln('workflow_output_summary_probe: PASS');
}
