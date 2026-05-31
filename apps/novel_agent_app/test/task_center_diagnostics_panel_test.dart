import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/widgets/task_center_diagnostics_panel.dart';

void main() {
  testWidgets('TaskCenterDiagnosticsPanel shows long task runtime summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 700,
            child: TaskCenterDiagnosticsPanel(
              chainMarkdown: '',
              longTaskRuns: const <TaskCenterRunItemViewData>[
                TaskCenterRunItemViewData(
                  relativePath: 'tracking/long_task_runs/run_001.json',
                  title: '长任务｜运行中',
                  subtitle: '执行当前任务｜42%｜第 8 章｜等待确认',
                  statusLabel: '运行中',
                  phaseLabel: '执行当前任务',
                  progressPercent: 42,
                  activeTaskTitle: '第 8 章',
                  updatedAt: '2026-05-31T20:31:00Z',
                  isWaitingUser: true,
                  controlSummary: '可操作：暂停、停止',
                  isSelected: true,
                ),
              ],
              taskQueueRuns: const <TaskCenterRunItemViewData>[],
              longTaskRunLog: '# 运行日志\n\n当前正在执行第 8 章。',
              taskQueueRunLog: '',
              onLongTaskRunSelected: _noop,
              onTaskQueueRunSelected: _noop,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('长任务运行'));
    await tester.pumpAndSettle();

    expect(find.text('运行中'), findsOneWidget);
    expect(find.text('执行当前任务'), findsAtLeastNWidgets(1));
    expect(find.text('42%'), findsWidgets);
    expect(find.text('第 8 章'), findsAtLeastNWidgets(1));
    expect(find.text('等待确认'), findsWidgets);
    expect(find.textContaining('长任务现场｜'), findsOneWidget);
    expect(find.textContaining('可操作：暂停、停止'), findsAtLeastNWidgets(1));
  });
}

void _noop(String _) {}
