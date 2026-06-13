import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/primary_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';

import '../tool/hfvv_wave2_user_decision_support.dart';

void main() {
  group('chooseWave2OpeningPrimaryAction', () {
    test('prefers direct long task start when available', () {
      final action = chooseWave2OpeningPrimaryAction(<PrimaryActionViewData>[
        const PrimaryActionViewData(
          id: 'launch',
          title: '启动长任务',
          description: '',
          commandId: 'opening.launch_long_task',
        ),
        const PrimaryActionViewData(
          id: 'start',
          title: '直接开跑',
          description: '',
          commandId: 'opening.start_long_task_run',
        ),
      ]);

      expect(action?.commandId, 'opening.start_long_task_run');
    });
  });

  group('chooseWave2TaskCenterSharedAction', () {
    test('prefers task user option before run control confirmation', () {
      final action =
          chooseWave2TaskCenterSharedAction(<TaskCenterContractActionViewData>[
            const TaskCenterContractActionViewData(
              id: 'confirm_checkpoint',
              label: '确认检查点',
              note: '',
              tone: 'neutral',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/checkpoint.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
            ),
            const TaskCenterContractActionViewData(
              id: 'task_user_option_0',
              label: '先确认方向',
              note: '',
              tone: 'accent',
              invocationKind: 'task_user_option',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/checkpoint.json',
              checkpointReviewPath: '',
              userOptionPrompt: '选择方向 A',
            ),
          ]);

      expect(action?.invocationKind, 'task_user_option');
      expect(action?.id, 'task_user_option_0');
    });

    test('prefers recommended enabled action', () {
      final action =
          chooseWave2TaskCenterSharedAction(<TaskCenterContractActionViewData>[
            const TaskCenterContractActionViewData(
              id: 'plain',
              label: '普通动作',
              note: '',
              tone: 'neutral',
              invocationKind: 'checkpoint_review',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/a.json',
              checkpointReviewPath: 'reviews/a.json',
            ),
            const TaskCenterContractActionViewData(
              id: 'recommended',
              label: '推荐动作',
              note: '',
              tone: 'positive',
              invocationKind: 'revision_resolution',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/b.json',
              checkpointReviewPath: 'reviews/b.json',
              isRecommended: true,
            ),
          ]);

      expect(action?.id, 'recommended');
    });

    test(
      'prefers checkpoint review recommendation over generic run controls',
      () {
        final action = chooseWave2TaskCenterSharedAction(
          <TaskCenterContractActionViewData>[
            const TaskCenterContractActionViewData(
              id: 'resume',
              label: '继续',
              note: '',
              tone: 'accent',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/run.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
              isRecommended: true,
            ),
            const TaskCenterContractActionViewData(
              id: 'continue_long_task',
              label: '继续主链',
              note: '',
              tone: 'success',
              invocationKind: 'checkpoint_review',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/checkpoint.json',
              checkpointReviewPath: 'tracking/checkpoint_reviews/review.json',
              isRecommended: true,
            ),
          ],
        );

        expect(action?.invocationKind, 'checkpoint_review');
        expect(action?.id, 'continue_long_task');
      },
    );

    test(
      'prefers confirm checkpoint run control before unrelated fallback',
      () {
        final action = chooseWave2TaskCenterSharedAction(
          <TaskCenterContractActionViewData>[
            const TaskCenterContractActionViewData(
              id: 'retry_failed',
              label: '重试失败任务',
              note: '',
              tone: 'neutral',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/failed.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
            ),
            const TaskCenterContractActionViewData(
              id: 'confirm_checkpoint',
              label: '确认检查点',
              note: '',
              tone: 'neutral',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/checkpoint.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
            ),
          ],
        );

        expect(action?.id, 'confirm_checkpoint');
      },
    );

    test('returns null when only generic pause or stop controls remain', () {
      final action =
          chooseWave2TaskCenterSharedAction(<TaskCenterContractActionViewData>[
            const TaskCenterContractActionViewData(
              id: 'pause',
              label: '暂停',
              note: '',
              tone: 'warm',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/run.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
            ),
            const TaskCenterContractActionViewData(
              id: 'stop',
              label: '停止',
              note: '',
              tone: 'danger',
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: 'tasks/run.json',
              checkpointReviewPath: '',
              longTaskRunPath: 'tracking/long_task_runs/run.json',
            ),
          ]);

      expect(action, isNull);
    });
  });

  group('chooseLaneFFanficPendingOption', () {
    test('prefers worldbuilding-style continuation when present', () {
      final option = chooseLaneFFanficPendingOption(<UserOptionViewData>[
        const UserOptionViewData(
          label: '先写第一章',
          description: '',
          prompt: '',
          sourceQuestion: '',
          allOptions: <Map<String, Object?>>[],
        ),
        const UserOptionViewData(
          label: '先整理世界观',
          description: '',
          prompt: '',
          sourceQuestion: '',
          allOptions: <Map<String, Object?>>[],
        ),
      ]);

      expect(option?.label, '先整理世界观');
    });
  });
}
