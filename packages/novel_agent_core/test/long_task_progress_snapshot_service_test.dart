import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  late LongTaskProgressSnapshotService service;

  setUp(() {
    final modeService = LongTaskModeService();
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    final profileService = LongTaskControllerProfileService(
      modeService: modeService,
      strategyService: strategyService,
    );
    service = LongTaskProgressSnapshotService(
      nextBatchPlanService: LongTaskNextBatchPlanService(
        modeService: modeService,
        profileService: profileService,
        unattendedStrategyService: LongTaskUnattendedStrategyService(
          modeService: modeService,
          strategyService: strategyService,
          profileService: profileService,
        ),
        taskSummaryService: LongTaskTaskSummaryService(),
        taskSelectionService: TaskSelectionService(
          taskDefinitionService: TaskDefinitionService(),
        ),
      ),
      taskSummaryService: LongTaskTaskSummaryService(),
    );
  });

  test('builds running snapshot from runnable task batch', () {
    final snapshot = service.build(_record(), <Object?>[
      _task(id: 't1', status: TaskRuntimeConstants.statusSucceeded),
      _task(id: 't2', status: TaskRuntimeConstants.statusQueued, title: '第2章'),
    ]);

    expect(snapshot['phase'], 'running_task');
    expect(snapshot['phase_label'], '执行任务');
    expect(snapshot['active_task_title'], '第2章');
    expect(snapshot['overall_percent'], 50);
    expect(snapshot['waiting_user'], false);
    expect(snapshot['blocked'], false);
  });

  test('builds waiting checkpoint snapshot', () {
    final snapshot = service.build(_record(), <Object?>[
      _task(
        id: 'cp1',
        status: TaskRuntimeConstants.statusWaitingUser,
        taskType: 'checkpoint',
        title: '检查点确认',
      ),
    ]);

    expect(snapshot['phase'], 'waiting_checkpoint');
    expect(snapshot['waiting_user'], true);
    expect(snapshot['recommended_action_label'], '处理检查点');
  });

  test('builds paused snapshot from manual pause', () {
    final snapshot = service.build(
      _record(
        status: TaskRuntimeConstants.statusPaused,
        stopReason: 'manual_pause',
      ),
      <Object?>[_task(id: 't1', status: TaskRuntimeConstants.statusQueued)],
    );

    expect(snapshot['phase'], 'paused');
    expect(snapshot['phase_label'], '已暂停');
    expect(snapshot['recommended_action_label'], '继续运行');
  });

  test('builds failed snapshot from failed task', () {
    final snapshot = service.build(_record(), <Object?>[
      _task(id: 't1', status: TaskRuntimeConstants.statusFailed, title: '第5章'),
    ]);

    expect(snapshot['phase'], 'failed');
    expect(snapshot['blocked'], true);
    expect(snapshot['active_task_title'], '第5章');
    expect(snapshot['recommended_action_label'], '处理失败任务');
  });
}

JsonMap _record({
  String status = TaskRuntimeConstants.statusRunning,
  String stopReason = '',
}) {
  return <String, Object?>{
    'id': 'run_demo',
    'relative_path': 'tracking/long_task_runs/run_demo.json',
    'status': status,
    'stop_reason': stopReason,
    'mode': TaskRuntimeConstants.modeSeedToFullNovel,
    'completed_steps': 1,
    'updated_at': '2026-05-31T12:00:00.000Z',
  };
}

JsonMap _task({
  required String id,
  required String status,
  String taskType = 'chapter',
  String title = '任务',
}) {
  return <String, Object?>{
    'id': id,
    'status': status,
    'task_type': taskType,
    'title': title,
    'relative_path': 'tasks/$id.json',
    'sort_order': 1,
    'depends_on': <Object?>[],
    'metadata': <String, Object?>{},
  };
}
