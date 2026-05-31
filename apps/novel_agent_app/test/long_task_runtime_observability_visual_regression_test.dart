import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/task_center/presentation/widgets/task_center_detail_panel.dart';
import 'package:novel_agent_app/features/task_center/presentation/widgets/task_center_diagnostics_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures LTO-09 runtime observability screenshots', (
    tester,
  ) async {
    final artifactsDir = Directory(
      '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}long_task_runtime_observability_screenshots',
    )..createSync(recursive: true);
    expect(artifactsDir.existsSync(), isTrue);

    await _captureRunningState(tester);
    await _capturePausedState(tester);
    await _captureWaitingCheckpointState(tester);
    await _captureFailedState(tester);
    await _captureCompletedState(tester);

    for (final fileName in const <String>[
      'lto09_running_long_task.png',
      'lto09_paused_long_task.png',
      'lto09_waiting_checkpoint.png',
      'lto09_failed_step.png',
      'lto09_completed_stopped.png',
    ]) {
      expect(
        File(
          '${artifactsDir.path}${Platform.pathSeparator}$fileName',
        ).existsSync(),
        isTrue,
        reason: '缺少截图产物：$fileName',
      );
    }
  });
}

Future<void> _captureRunningState(WidgetTester tester) async {
  _setViewport(tester, const Size(1360, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('lto09_running_runtime'),
            child: SizedBox(
              width: 1160,
              height: 720,
              child: TaskCenterDiagnosticsPanel(
                chainMarkdown: '# 任务链路\n\n- 第 8 章正在执行',
                longTaskRuns: const <TaskCenterRunItemViewData>[
                  TaskCenterRunItemViewData(
                    relativePath: 'tracking/long_task_runs/run_running.json',
                    title: '长任务｜运行中',
                    subtitle: '执行当前任务｜42%｜第 8 章',
                    statusLabel: '运行中',
                    phaseLabel: '执行当前任务',
                    progressPercent: 42,
                    activeTaskTitle: '第 8 章',
                    updatedAt: '2026-05-31T20:31:00Z',
                    isWaitingUser: false,
                    controlSummary: '可操作：暂停、停止',
                    isSelected: true,
                  ),
                ],
                taskQueueRuns: const <TaskCenterRunItemViewData>[],
                longTaskRunLog: '# 运行日志\n\n当前正在执行第 8 章，模型输出稳定推进。',
                taskQueueRunLog: '',
                onLongTaskRunSelected: _noop,
                onTaskQueueRunSelected: _noop,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('长任务运行'));
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(const ValueKey<String>('lto09_running_runtime')),
    matchesGoldenFile(
      '../../../artifacts/long_task_runtime_observability_screenshots/lto09_running_long_task.png',
    ),
  );
}

Future<void> _capturePausedState(WidgetTester tester) async {
  _setViewport(tester, const Size(1360, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('lto09_paused_runtime'),
            child: SizedBox(
              width: 1160,
              height: 720,
              child: TaskCenterDiagnosticsPanel(
                chainMarkdown: '# 任务链路\n\n- 当前运行已被人工暂停',
                longTaskRuns: const <TaskCenterRunItemViewData>[
                  TaskCenterRunItemViewData(
                    relativePath: 'tracking/long_task_runs/run_paused.json',
                    title: '长任务｜已暂停',
                    subtitle: '已暂停｜58%｜第 11 章',
                    statusLabel: '已暂停',
                    phaseLabel: '暂停等待恢复',
                    progressPercent: 58,
                    activeTaskTitle: '第 11 章',
                    updatedAt: '2026-05-31T21:05:00Z',
                    isWaitingUser: false,
                    controlSummary: '可操作：恢复、停止',
                    isSelected: true,
                  ),
                ],
                taskQueueRuns: const <TaskCenterRunItemViewData>[],
                longTaskRunLog: '# 运行日志\n\n当前运行被用户暂停，等待恢复。',
                taskQueueRunLog: '',
                onLongTaskRunSelected: _noop,
                onTaskQueueRunSelected: _noop,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('长任务运行'));
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(const ValueKey<String>('lto09_paused_runtime')),
    matchesGoldenFile(
      '../../../artifacts/long_task_runtime_observability_screenshots/lto09_paused_long_task.png',
    ),
  );
}

Future<void> _captureWaitingCheckpointState(WidgetTester tester) async {
  _setViewport(tester, const Size(1200, 860));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: ValueKey<String>('lto09_waiting_checkpoint'),
            child: SizedBox(
              width: 920,
              height: 680,
              child: TaskCenterDetailPanel(
                title: '任务详情',
                subtitle: 'tasks/ch08_gate_review.json',
                detailBody:
                    '# 当前任务\n\n- 状态：待确认\n- 类型：chapter_gate_review\n- 路径：tasks/ch08_gate_review.json',
                resumeBriefBody:
                    '## 恢复现场\n当前停在第 8 章检查点，系统等待你确认是否放行。\n\n最近停点：模型草稿和关口审稿已经完成。\n\n建议下一步：先处理检查点动作，再决定是否继续自动推进。',
                queueSummary: '可运行：否\n阻塞原因：等待检查点',
                schedulerSummary: '调度动作：等待用户确认\n执行器状态：已停在检查点',
                guidanceRevisitBody: '',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(const ValueKey<String>('lto09_waiting_checkpoint')),
    matchesGoldenFile(
      '../../../artifacts/long_task_runtime_observability_screenshots/lto09_waiting_checkpoint.png',
    ),
  );
}

Future<void> _captureFailedState(WidgetTester tester) async {
  _setViewport(tester, const Size(1200, 860));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: ValueKey<String>('lto09_failed_step'),
            child: SizedBox(
              width: 920,
              height: 680,
              child: TaskCenterDetailPanel(
                title: '任务详情',
                subtitle: 'tasks/ch09_revision.json',
                detailBody:
                    '# 当前任务\n\n- 状态：失败\n- 类型：revision\n- 路径：tasks/ch09_revision.json',
                resumeBriefBody:
                    '## 恢复现场\n第 9 章修订任务在返工阶段失败，需要人工查看原因。\n\n最近停点：审稿报告已生成，但修订稿写入失败。\n\n建议下一步：先检查失败节点，再决定重试还是改走修订动作。',
                queueSummary: '可运行：否\n阻塞原因：当前步骤失败',
                schedulerSummary: '调度动作：停止\n执行器状态：失败待人工处理',
                guidanceRevisitBody: '## 回看提示\n请重点检查失败节点的输出文件与修订摘要是否一致。',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(const ValueKey<String>('lto09_failed_step')),
    matchesGoldenFile(
      '../../../artifacts/long_task_runtime_observability_screenshots/lto09_failed_step.png',
    ),
  );
}

Future<void> _captureCompletedState(WidgetTester tester) async {
  _setViewport(tester, const Size(1360, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('lto09_completed_runtime'),
            child: SizedBox(
              width: 1160,
              height: 720,
              child: TaskCenterDiagnosticsPanel(
                chainMarkdown: '# 任务链路\n\n- 当前长任务已完成并停止',
                longTaskRuns: const <TaskCenterRunItemViewData>[
                  TaskCenterRunItemViewData(
                    relativePath: 'tracking/long_task_runs/run_completed.json',
                    title: '长任务｜已停止',
                    subtitle: '已完成｜100%｜终稿收口',
                    statusLabel: '已停止',
                    phaseLabel: '已完成',
                    progressPercent: 100,
                    activeTaskTitle: '终稿收口',
                    updatedAt: '2026-05-31T22:40:00Z',
                    isWaitingUser: false,
                    controlSummary: '可操作：查看记录',
                    isSelected: true,
                  ),
                ],
                taskQueueRuns: const <TaskCenterRunItemViewData>[],
                longTaskRunLog: '# 运行日志\n\n全部章节已完成，当前运行已停止并保留恢复记录。',
                taskQueueRunLog: '',
                onLongTaskRunSelected: _noop,
                onTaskQueueRunSelected: _noop,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('长任务运行'));
  await tester.pumpAndSettle();

  await expectLater(
    find.byKey(const ValueKey<String>('lto09_completed_runtime')),
    matchesGoldenFile(
      '../../../artifacts/long_task_runtime_observability_screenshots/lto09_completed_stopped.png',
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

String _resolveRepoRoot() {
  final scriptDir = Directory.current.path;
  return Directory(scriptDir).parent.parent.path;
}

void _noop(String _) {}
