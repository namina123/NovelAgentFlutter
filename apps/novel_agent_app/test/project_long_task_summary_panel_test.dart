import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_long_task_summary_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/project_long_task_summary_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'summary panel shows resume CTA for a resumable run and fires the callback',
    (tester) async {
      String? resumedId;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ProjectLongTaskSummaryPanel(
              summary: const ProjectLongTaskSummaryViewData(
                title: '长任务运行',
                summary: '运行中 0 · 待处理 0 · 共 1',
                isLoading: false,
                totalCount: 1,
                activeCount: 0,
                attentionCount: 0,
                runs: <ProjectLongTaskRunSummaryViewData>[
                  ProjectLongTaskRunSummaryViewData(
                    id: 'run-1',
                    title: '连续托管式',
                    subtitle: '逐章协作',
                    statusLabel: '已暂停',
                    taskLabel: '第 1 章',
                    recentActivityLabel: '刚刚',
                    requiresAttention: false,
                    isActive: false,
                    canResume: true,
                    resumeActionLabel: '恢复推进',
                  ),
                ],
              ),
              onResumeRequested: (runId) => resumedId = runId,
            ),
          ),
        ),
      );

      final button = find.widgetWithText(FilledButton, '恢复推进');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      expect(resumedId, 'run-1');
    },
  );

  testWidgets(
    'summary panel omits resume CTA when the run is already active',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ProjectLongTaskSummaryPanel(
              summary: const ProjectLongTaskSummaryViewData(
                title: '长任务运行',
                summary: '运行中 1 · 共 1',
                isLoading: false,
                totalCount: 1,
                activeCount: 1,
                attentionCount: 0,
                runs: <ProjectLongTaskRunSummaryViewData>[
                  ProjectLongTaskRunSummaryViewData(
                    id: 'run-active',
                    title: '连续托管式',
                    subtitle: '逐章协作',
                    statusLabel: '运行中',
                    taskLabel: '第 2 章',
                    recentActivityLabel: '刚刚',
                    requiresAttention: false,
                    isActive: true,
                    canResume: false,
                    resumeActionLabel: '恢复推进',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(FilledButton, '恢复推进'), findsNothing);
    },
  );
}
