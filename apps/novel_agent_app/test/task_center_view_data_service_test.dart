import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/application/services/task_center_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('TaskCenterViewDataService projects long task run contract fields', () {
    const service = TaskCenterViewDataService();

    final viewData = service.build(
      tasks: const <JsonMap>[],
      modeDefinitions: const <JsonMap>[],
      selectedTaskId: '',
      detailBody: '',
      queueSummary: '',
      schedulerSummary: '',
      chainMarkdown: '',
      longTaskRuns: const <JsonMap>[
        <String, Object?>{
          'relative_path': 'tracking/long_task_runs/run_001.json',
          'status': 'running',
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'mode': 'human_outline_ai_draft',
          'updated_at': '2026-05-31T20:30:00Z',
          'run_center_contract': <String, Object?>{
            'status_label': '运行中',
            'phase_label': '执行当前任务',
            'waiting_user': true,
            'active_task_title': '第 8 章',
            'updated_at': '2026-05-31T20:31:00Z',
            'control_summary': '可操作：暂停、停止',
            'progress': <String, Object?>{'overall_percent': 42},
          },
        },
      ],
      taskQueueRuns: const <JsonMap>[],
      selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      selectedTaskQueueRunPath: '',
      longTaskRunLog: '',
      taskQueueRunLog: '',
    );

    expect(viewData.longTaskRuns, hasLength(1));
    final item = viewData.longTaskRuns.single;
    expect(item.statusLabel, '运行中');
    expect(item.phaseLabel, '执行当前任务');
    expect(item.progressPercent, 42);
    expect(item.activeTaskTitle, '第 8 章');
    expect(item.updatedAt, '2026-05-31T20:31:00Z');
    expect(item.isWaitingUser, isTrue);
    expect(item.controlSummary, '可操作：暂停、停止');
    expect(item.isSelected, isTrue);
    expect(item.subtitle, contains('执行当前任务'));
    expect(item.subtitle, contains('42%'));
    expect(item.subtitle, contains('第 8 章'));
    expect(item.subtitle, contains('等待确认'));
  });

  test('TaskCenterViewDataService renders resume brief from run contract', () {
    const service = TaskCenterViewDataService();

    final body = service.buildResumeBriefBody(
      const <String, Object?>{
        'run_center_contract': <String, Object?>{
          'resume_brief': <String, Object?>{
            'resume_title': '当前停在用户确认点',
            'resume_summary': '等待你确认检查点。',
            'last_step_summary': '最近停在：检查点（tasks/checkpoint.json）',
            'next_action_summary': '建议下一步：处理检查点',
            'requires_user_action': true,
            'action_package_available': true,
            'revision_resolution_available': false,
          },
        },
      },
      checkpointActionPackage: const <String, Object?>{'ok': true},
    );

    expect(body, contains('## 恢复现场'));
    expect(body, contains('当前停在用户确认点'));
    expect(body, contains('最近停在：检查点'));
    expect(body, contains('建议下一步：处理检查点'));
    expect(body, contains('检查点动作包'));
    expect(body, isNot(contains('run_center_contract')));
    expect(body, isNot(contains('requires_user_action')));
    expect(body, isNot(contains('action_package_available')));
    expect(body, isNot(contains('revision_resolution_available')));
  });
}
