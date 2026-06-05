import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/contracts/long_task_station_action_handler.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/models/long_task_station_view_data.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long task detail panel shows information summary and entries', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final handler = _FakeLongTaskStationActionHandler();
    final detail = LongTaskRunDetailViewData(
      id: 'run-1',
      projectTitle: '风雪旧城',
      projectPath: 'D:/novel/project-a',
      runtimeBaselineTitle: '连续推进',
      runtimeBaselineDescription: '自动推进当前长任务链。',
      modeId: 'seed_to_full_novel',
      workflowStrategyId: 'resumable_long_task',
      statusLabel: '待处理',
      stopReasonLabel: '需要确认',
      storageStrategyLabel: 'Markdown Project',
      runtimeModeLabel: '长篇模式',
      policyBadges: const <String>[],
      activeTaskLabel: '检查点：第一卷收束',
      activeTaskPath: '',
      activeTaskStatusLabel: '',
      activeTaskSummary: '',
      note: '暂无备注。',
      createdAtLabel: '2026-06-05 10:00:00',
      updatedAtLabel: '2026-06-05 10:05:00',
      lastHeartbeatAtLabel: '2026-06-05 10:05:30',
      startedAtLabel: '2026-06-05 10:00:00',
      stoppedAtLabel: '未记录',
      detailStatusMessage: 'ok',
      isDetailLoading: false,
      blockerLabel: '等待确认',
      blockerNote: '当前运行已经停在需要确认的节点。',
      blockerDetail: '',
      blockerActionHint: '',
      taskChainTitle: '当前任务链',
      taskChainSubtitle: '节点 3',
      taskChainItems: const <LongTaskRunChainItemViewData>[],
      latestCheckpointReview: null,
      latestReviewReport: null,
      latestRepairTask: null,
      narrativeActivation: null,
      narrativeDelivery: null,
      narrativeReview: null,
      narrativeContinuity: null,
      informationSummary: const LongTaskRunRelatedItemViewData(
        title: 'Information',
        subtitle: 'knowledge 1 | design 1 | research 0 | reference 1',
        summary: '待研究 1 项，高风险引用 1 项，information 改动 8 项',
        relativePath: '',
        actionLabel: '查看信息摘要',
      ),
      narrativeProjectionItems: const <LongTaskRunRelatedItemViewData>[],
      narrativePermissionItems: const <LongTaskRunRelatedItemViewData>[],
      informationProjectionItems: const <LongTaskRunRelatedItemViewData>[
        LongTaskRunRelatedItemViewData(
          title: '项目知识摘要',
          subtitle: 'Information projection',
          summary: '打开当前 knowledge 卡片的可读投影。',
          relativePath: 'knowledge/项目知识摘要.md',
          actionLabel: '打开投影',
        ),
      ],
      informationPermissionItems: const <LongTaskRunRelatedItemViewData>[
        LongTaskRunRelatedItemViewData(
          title: 'Research Pending',
          subtitle: 'awaiting_user_confirmation',
          summary: '旧城钟楼在北境民俗中的象征意义',
          relativePath:
              '.novel_agent/information/research_requests/research_request_1.json',
          actionLabel: '打开确认记录',
        ),
      ],
      requiresManualAttention: true,
      canPause: false,
      canResume: true,
      canStop: true,
      overviewBlocks: const <LongTaskRunOverviewBlockViewData>[
        LongTaskRunOverviewBlockViewData(
          title: '当前进度',
          summary: '已经完成上一轮正文，正准备进入确认阶段。',
          entries: <LongTaskRunMetaItemViewData>[
            LongTaskRunMetaItemViewData(label: '当前状态', value: '待处理'),
          ],
        ),
        LongTaskRunOverviewBlockViewData(
          title: '当前动作',
          summary: '检查点确认',
          entries: <LongTaskRunMetaItemViewData>[
            LongTaskRunMetaItemViewData(label: '正在处理', value: '检查点：第一卷收束'),
          ],
        ),
        LongTaskRunOverviewBlockViewData(
          title: '需要你处理',
          summary: '这个确认会影响后续章节是否自动推进。',
          resources: <LongTaskRunRelatedItemViewData>[
            LongTaskRunRelatedItemViewData(
              title: 'Clarification',
              subtitle: 'needs_user_confirmation',
              summary: '是否让旧城钟楼设定长期生效？',
              relativePath:
                  '.novel_agent/continuity/clarifications/clarification_call-5.json',
              actionLabel: '等待确认',
            ),
          ],
        ),
        LongTaskRunOverviewBlockViewData(
          title: '最近产物',
          summary: '可以直接打开最近生成的正文、审稿或检查点结果。',
          resources: <LongTaskRunRelatedItemViewData>[
            LongTaskRunRelatedItemViewData(
              title: '正文交付',
              subtitle: 'delivered',
              summary: '查看刚生成的章节正文。',
              relativePath: 'chapters/ch05.md',
              actionLabel: '查看最近产物',
            ),
          ],
        ),
      ],
      resumeActionLabel: '继续推进',
      pendingUserActionLabel: '等待确认',
      pendingUserAction: const LongTaskRunRelatedItemViewData(
        title: 'Clarification',
        subtitle: 'needs_user_confirmation',
        summary: '是否让旧城钟楼设定长期生效？',
        relativePath:
            '.novel_agent/continuity/clarifications/clarification_call-5.json',
        actionLabel: '等待确认',
      ),
      preferredRecentOutput: const LongTaskRunRelatedItemViewData(
        title: '正文交付',
        subtitle: 'delivered',
        summary: '查看刚生成的章节正文。',
        relativePath: 'chapters/ch05.md',
        actionLabel: '查看最近产物',
      ),
      primaryMetadata: const <LongTaskRunMetaItemViewData>[
        LongTaskRunMetaItemViewData(label: '项目路径', value: 'D:/novel/project-a'),
      ],
      diagnosticMetadata: const <LongTaskRunMetaItemViewData>[
        LongTaskRunMetaItemViewData(
          label: '工作流 ID',
          value: 'resumable_long_task',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LongTaskRunDetailPanel(detail: detail, actionHandler: handler),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前进度'), findsOneWidget);
    expect(find.text('当前动作'), findsOneWidget);
    expect(find.text('需要你处理'), findsOneWidget);
    expect(find.text('最近产物'), findsOneWidget);
    expect(find.textContaining('项目知识摘要'), findsWidgets);
    expect(find.textContaining('Research Pending'), findsOneWidget);
    expect(find.text('运行诊断'), findsOneWidget);
    expect(find.text('工作流 ID'), findsNothing);
    expect(find.text('等待确认'), findsWidgets);
    expect(find.text('查看最近产物'), findsWidgets);

    await tester.tap(find.text('打开投影').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开确认记录').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行诊断'));
    await tester.pumpAndSettle();

    expect(handler.requestedPaths, <String>[
      'knowledge/项目知识摘要.md',
      '.novel_agent/information/research_requests/research_request_1.json',
    ]);
    expect(find.text('工作流 ID'), findsOneWidget);
  });
}

class _FakeLongTaskStationActionHandler
    implements LongTaskStationActionHandler {
  final List<String> requestedPaths = <String>[];

  @override
  void onLongTaskStationCurrentProjectFilterToggled(bool selected) {}

  @override
  void onLongTaskStationOpenProjectRequested(String runId) {}

  @override
  void onLongTaskStationPauseRequested(String runId) {}

  @override
  void onLongTaskStationRefreshRequested() {}

  @override
  void onLongTaskStationResourceRequested(String runId, String relativePath) {
    requestedPaths.add(relativePath);
  }

  @override
  void onLongTaskStationResumeRequested(String runId) {}

  @override
  void onLongTaskStationRunSelected(String runId) {}

  @override
  void onLongTaskStationStopRequested(String runId) {}
}
