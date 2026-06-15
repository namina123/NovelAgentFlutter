import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';

import '../tool/hfvv_wave2_viewmodel_runner.dart';

void main() {
  test(
    'resolveHfvvWave2LaneIds keeps canonical order and supports filtering',
    () {
      expect(resolveHfvvWave2LaneIds(), <String>[
        'lane_f_harry_potter_fanfic_consumption',
        'lane_g_general_long_task_stability',
        'lane_h_general_long_task_multi_agent',
        'lane_i_high_variance_story_arc',
      ]);

      expect(
        resolveHfvvWave2LaneIds(
          enabledLaneIds: const <String>[
            'lane_h_general_long_task_multi_agent',
            'lane_g_general_long_task_stability',
          ],
        ),
        <String>[
          'lane_g_general_long_task_stability',
          'lane_h_general_long_task_multi_agent',
        ],
      );
    },
  );

  test('parseHfvvWave2RunConfig reads run_id and repeated lane filters', () {
    final config = parseHfvvWave2RunConfig(<String>[
      '--run-id=2026-06-10T21-30-00',
      '--lane=lane_g_general_long_task_stability',
      '--lane=lane_h_general_long_task_multi_agent',
      '--lane=lane_g_general_long_task_stability',
    ]);

    expect(config.runId, '2026-06-10T21-30-00');
    expect(config.enabledLaneIds, <String>{
      'lane_g_general_long_task_stability',
      'lane_h_general_long_task_multi_agent',
    });
  });

  test(
    'hasWave2ObservablePendingTaskCenterState waits for run snapshots during pending state',
    () {
      expect(
        hasWave2ObservablePendingTaskCenterState(
          _taskCenterViewData(
            status: '正在启动受控连续运行...',
            schedulerSummary: '调度计划不可用：Long task run not found.',
          ),
        ),
        isFalse,
      );

      expect(
        hasWave2ObservablePendingTaskCenterState(
          _taskCenterViewData(
            status: '正在启动受控连续运行...',
            taskQueueRuns: const <TaskCenterRunItemViewData>[
              TaskCenterRunItemViewData(
                relativePath: 'tracking/task_queue_runs/queue_new.json',
                title: '队列运行',
                subtitle: '',
              ),
            ],
          ),
        ),
        isTrue,
      );

      expect(
        hasWave2ObservablePendingTaskCenterState(
          _taskCenterViewData(status: '队列运行已推进。'),
        ),
        isTrue,
      );
    },
  );
}

TaskCenterViewData _taskCenterViewData({
  required String status,
  String schedulerSummary = '',
  List<TaskCenterRunItemViewData> longTaskRuns =
      const <TaskCenterRunItemViewData>[],
  List<TaskCenterRunItemViewData> taskQueueRuns =
      const <TaskCenterRunItemViewData>[],
  String selectedLongTaskRunPath = '',
  String selectedTaskQueueRunPath = '',
}) {
  return TaskCenterViewData(
    title: '',
    intro: '',
    help: '',
    status: status,
    runtimeBaselineTitle: '',
    runtimeModeLabel: '',
    runtimePolicyBadges: const <String>[],
    tasks: const <TaskCenterTaskItemViewData>[],
    selectedTaskId: '',
    detailBody: '',
    queueSummary: '',
    schedulerSummary: schedulerSummary,
    chainMarkdown: '',
    longTaskRuns: longTaskRuns,
    taskQueueRuns: taskQueueRuns,
    selectedLongTaskRunPath: selectedLongTaskRunPath,
    selectedTaskQueueRunPath: selectedTaskQueueRunPath,
    longTaskRunLog: '',
    taskQueueRunLog: '',
    resumeBriefBody: '',
    modeOptions: const <TaskRuntimeModeOptionViewData>[],
    defaultMode: '',
    defaultOutlinePath: '',
    defaultSeedPrompt: '',
    defaultChapterCount: 0,
    defaultCheckpointInterval: 0,
    defaultChapterLength:
        const TaskCenterChapterLengthConfigViewData.fallback(),
    actionGroups: const [],
    guidanceRevisitBody: '',
  );
}
