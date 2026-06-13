import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_action_group_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/widgets/task_center_shared_actions_panel.dart';

void main() {
  testWidgets(
    'TaskCenterSharedActionsPanel shows materialized actions and disabled guidance cleanly',
    (tester) async {
      TaskCenterContractActionViewData? requestedAction;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: TaskCenterSharedActionsPanel(
                groups: const <TaskCenterActionGroupViewData>[
                  TaskCenterActionGroupViewData(
                    id: 'checkpoint_review',
                    title: '检查点动作｜高风险',
                    summary: '建议先生成后续审稿，再决定是否继续主链。',
                    actions: <TaskCenterContractActionViewData>[
                      TaskCenterContractActionViewData(
                        id: 'create_followup_review_tasks',
                        label: '生成后续审稿',
                        note: '物化 follow-up review。',
                        tone: 'accent',
                        invocationKind: 'checkpoint_review',
                        enabled: true,
                        disabledReason: '',
                        ownerTaskPath: 'tasks/ch01.task.json',
                        checkpointReviewPath:
                            'tracking/checkpoint_reviews/ch01.json',
                        isRecommended: true,
                      ),
                      TaskCenterContractActionViewData(
                        id: 'continue_long_task',
                        label: '继续主链',
                        note: '继续推进。',
                        tone: 'success',
                        invocationKind: 'checkpoint_review',
                        enabled: false,
                        disabledReason: '当前图形界面还未接通该建议动作。',
                        ownerTaskPath: 'tasks/ch01.task.json',
                        checkpointReviewPath:
                            'tracking/checkpoint_reviews/ch01.json',
                      ),
                    ],
                  ),
                ],
                onActionRequested: (action) {
                  requestedAction = action;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('上下文动作'), findsOneWidget);
      expect(find.text('检查点动作｜高风险'), findsOneWidget);
      expect(find.text('建议先生成后续审稿，再决定是否继续主链。'), findsOneWidget);
      expect(find.text('生成后续审稿（推荐）'), findsOneWidget);
      expect(
        find.text('- 继续主链：当前图形界面还未接通该建议动作。'),
        findsOneWidget,
      );
      expect(find.text('继续主链'), findsNothing);

      await tester.tap(find.text('生成后续审稿（推荐）'));
      await tester.pumpAndSettle();

      expect(requestedAction, isNotNull);
      expect(requestedAction!.id, 'create_followup_review_tasks');
      expect(
        requestedAction!.checkpointReviewPath,
        'tracking/checkpoint_reviews/ch01.json',
      );
    },
  );
}
