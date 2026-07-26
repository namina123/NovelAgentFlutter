import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/contracts/long_task_station_action_handler.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/models/long_task_station_view_data.dart';
import 'package:novel_agent_app/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/pending_research_action_handler.dart';

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
        title: '资料与设定',
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
          subtitle: '知识卡片',
          summary: '打开当前 knowledge 卡片的可读摘要。',
          relativePath: 'knowledge/项目知识摘要.md',
          actionLabel: '打开摘要',
        ),
      ],
      informationPermissionItems: const <LongTaskRunRelatedItemViewData>[
        LongTaskRunRelatedItemViewData(
          title: '待确认调研请求',
          subtitle: '等待确认',
          summary: '旧城钟楼在北境民俗中的象征意义',
          relativePath:
              '.novel_agent/information/research_requests/research_request_1.json',
          actionLabel: '打开确认记录',
          pendingResearchRequestId: 'research_request_1',
        ),
      ],
      requiresManualAttention: true,
      canPause: false,
      canResume: true,
      canStop: true,
      stopDiagnosis: const LongTaskRunStopDiagnosisViewData(
        code: 'waiting_user_checkpoint',
        category: 'waiting_user',
        label: '等待用户确认',
        summary: '当前运行已经停在需要确认的节点。',
      ),
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
              title: '待确认问题',
              subtitle: '待你确认',
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
              subtitle: '已交付',
              summary: '查看刚生成的章节正文。',
              relativePath: 'chapters/ch05.md',
              actionLabel: '查看最近产物',
            ),
          ],
        ),
      ],
      resumeActionLabel: '恢复推进',
      attentionCalloutTitle: '当前运行停在待确认节点。',
      attentionCalloutSummary: '当前运行已经停在需要确认的节点。 建议先确认这一项，再决定是否继续自动推进。',
      pendingUserActionLabel: '等待确认',
      pendingUserAction: const LongTaskRunRelatedItemViewData(
        title: '待确认问题',
        subtitle: '待你确认',
        summary: '是否让旧城钟楼设定长期生效？',
        relativePath:
            '.novel_agent/continuity/clarifications/clarification_call-5.json',
        actionLabel: '等待确认',
      ),
      preferredRecentOutput: const LongTaskRunRelatedItemViewData(
        title: '正文交付',
        subtitle: '已交付',
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
          body: LongTaskRunDetailPanel(
            detail: detail,
            actionHandler: handler,
            pendingResearchActionHandler: handler,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前进度'), findsOneWidget);
    expect(find.text('当前动作'), findsOneWidget);
    expect(find.text('需要你处理'), findsOneWidget);
    expect(find.text('最近产物'), findsOneWidget);
    expect(find.textContaining('项目知识摘要'), findsWidgets);
    expect(find.textContaining('待确认调研请求'), findsOneWidget);
    expect(find.text('资料摘要'), findsOneWidget);
    expect(find.text('待你确认'), findsWidgets);
    expect(find.text('已交付'), findsOneWidget);
    expect(find.text('运行诊断'), findsOneWidget);
    expect(find.text('补充原因', skipOffstage: false), findsNothing);
    expect(find.text('停止/阻塞原因', skipOffstage: false), findsNothing);
    expect(find.text('工作流 ID'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '等待确认'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '查看最近产物'), findsOneWidget);
    expect(find.text('当前运行停在待确认节点。'), findsOneWidget);
    expect(find.textContaining('当前运行已经停在需要确认的节点。 建议先确认这一项'), findsOneWidget);
    expect(find.textContaining('先处理：待确认问题'), findsNothing);
    expect(find.textContaining('最近相关结果：正文交付'), findsNothing);

    await tester.tap(find.text('打开摘要').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开确认记录').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('拒绝').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行诊断'));
    await tester.pumpAndSettle();

    expect(handler.requestedPaths, <String>[
      'knowledge/项目知识摘要.md',
      '.novel_agent/information/research_requests/research_request_1.json',
    ]);
    expect(handler.approvedRequestIds, <String>['research_request_1']);
    expect(handler.rejectedRequestIds, <String>['research_request_1']);
    expect(find.text('工作流 ID'), findsOneWidget);
  });

  testWidgets(
    'long task detail panel wires pause resume stop and context actions to shared handlers',
    (WidgetTester tester) async {
      final handler = _FakeLongTaskStationActionHandler();
      final detail = LongTaskRunDetailViewData(
        id: 'run-actions',
        projectTitle: '风雪旧城',
        projectPath: 'D:/novel/project-a',
        runtimeBaselineTitle: '连续推进',
        runtimeBaselineDescription: '自动推进当前长任务链。',
        modeId: 'seed_to_full_novel',
        workflowStrategyId: 'resumable_long_task',
        statusLabel: '待处理',
        storageStrategyLabel: 'Markdown Project',
        runtimeModeLabel: '长篇模式',
        policyBadges: const <String>[],
        activeTaskLabel: '检查点确认',
        activeTaskPath: 'tasks/checkpoint_01.json',
        activeTaskStatusLabel: '等待确认',
        activeTaskSummary: '需要先确认当前检查点。',
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
        blockerActionHint: '建议先确认检查点。',
        taskChainTitle: '当前任务链',
        taskChainSubtitle: '节点 2',
        taskChainItems: const <LongTaskRunChainItemViewData>[],
        latestCheckpointReview: const LongTaskRunRelatedItemViewData(
          title: '最近检查点',
          subtitle: '等待确认',
          summary: '查看本轮检查点结论。',
          relativePath: 'tracking/checkpoint_reviews/ch01.json',
          actionLabel: '查看检查点',
        ),
        latestReviewReport: const LongTaskRunRelatedItemViewData(
          title: '最近审稿',
          subtitle: '审稿完成',
          summary: '查看上一轮审稿结果。',
          relativePath: 'reviews/ch01.md',
          actionLabel: '查看审稿结果',
        ),
        latestRepairTask: null,
        narrativeActivation: null,
        narrativeDelivery: null,
        narrativeReview: null,
        narrativeContinuity: null,
        informationSummary: null,
        narrativeProjectionItems: const <LongTaskRunRelatedItemViewData>[],
        narrativePermissionItems: const <LongTaskRunRelatedItemViewData>[],
        informationProjectionItems: const <LongTaskRunRelatedItemViewData>[],
        informationPermissionItems: const <LongTaskRunRelatedItemViewData>[],
        requiresManualAttention: true,
        canPause: true,
        canResume: true,
        canStop: true,
        overviewBlocks: const <LongTaskRunOverviewBlockViewData>[],
        resumeActionLabel: '恢复推进',
        attentionCalloutTitle: '当前运行停在待确认节点。',
        attentionCalloutSummary: '当前运行已经停在需要确认的节点。 建议先确认检查点。',
        pendingUserActionLabel: '等待确认',
        pendingUserAction: const LongTaskRunRelatedItemViewData(
          title: '待确认问题',
          subtitle: '待你确认',
          summary: '是否接受当前检查点建议？',
          relativePath:
              '.novel_agent/continuity/clarifications/clarification_call-6.json',
          actionLabel: '等待确认',
        ),
        preferredRecentOutput: const LongTaskRunRelatedItemViewData(
          title: '正文交付',
          subtitle: '已交付',
          summary: '查看最近正文。',
          relativePath: 'chapters/ch06.md',
          actionLabel: '查看最近产物',
        ),
        primaryMetadata: const <LongTaskRunMetaItemViewData>[],
        diagnosticMetadata: const <LongTaskRunMetaItemViewData>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: LongTaskRunDetailPanel(
              detail: detail,
              actionHandler: handler,
              pendingResearchActionHandler: handler,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, '暂停'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '恢复推进'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '恢复推进'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '停止'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '查看当前任务'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '等待确认'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '查看最近产物'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '查看审稿结果'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '暂停'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '恢复推进'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '恢复推进'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '停止'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '查看当前任务'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '等待确认'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '查看最近产物'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '查看审稿结果'));
      await tester.pumpAndSettle();

      expect(handler.pauseRequestedRunIds, <String>['run-actions']);
      expect(handler.resumeRequestedRunIds, <String>[
        'run-actions',
        'run-actions',
      ]);
      expect(handler.stopRequestedRunIds, <String>['run-actions']);
      expect(handler.requestedPaths, <String>[
        'tasks/checkpoint_01.json',
        '.novel_agent/continuity/clarifications/clarification_call-6.json',
        'chapters/ch06.md',
        'reviews/ch01.md',
      ]);
    },
  );

  testWidgets(
    'long task detail panel keeps callout fallback summary high-level when summary is empty',
    (WidgetTester tester) async {
      final handler = _FakeLongTaskStationActionHandler();
      final detail = LongTaskRunDetailViewData(
        id: 'run-fallback',
        projectTitle: '风雪旧城',
        projectPath: 'D:/novel/project-a',
        runtimeBaselineTitle: '连续推进',
        runtimeBaselineDescription: '自动推进当前长任务链。',
        modeId: 'seed_to_full_novel',
        workflowStrategyId: 'resumable_long_task',
        statusLabel: '待处理',
        storageStrategyLabel: 'Markdown Project',
        runtimeModeLabel: '长篇模式',
        policyBadges: const <String>[],
        activeTaskLabel: '第 5 章返工',
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
        blockerLabel: '需要人工处理',
        blockerNote: '当前运行需要先处理交付问题。',
        blockerDetail: '',
        blockerActionHint: '建议先查看返工链或失败任务。',
        taskChainTitle: '当前任务链',
        taskChainSubtitle: '节点 3',
        taskChainItems: const <LongTaskRunChainItemViewData>[],
        latestCheckpointReview: null,
        latestReviewReport: const LongTaskRunRelatedItemViewData(
          title: '最近审稿报告',
          subtitle: '审稿结果',
          summary: '需要补强结尾冲突。',
          relativePath: 'reviews/ch05.md',
          actionLabel: '查看审稿结果',
        ),
        latestRepairTask: null,
        narrativeActivation: null,
        narrativeDelivery: null,
        narrativeReview: null,
        narrativeContinuity: null,
        informationSummary: null,
        narrativeProjectionItems: const <LongTaskRunRelatedItemViewData>[],
        narrativePermissionItems: const <LongTaskRunRelatedItemViewData>[],
        informationProjectionItems: const <LongTaskRunRelatedItemViewData>[],
        informationPermissionItems: const <LongTaskRunRelatedItemViewData>[],
        requiresManualAttention: true,
        canPause: false,
        canResume: false,
        canStop: true,
        overviewBlocks: const <LongTaskRunOverviewBlockViewData>[
          LongTaskRunOverviewBlockViewData(
            title: '当前进度',
            summary: '正在等待处理最近失败结果。',
          ),
        ],
        resumeActionLabel: '恢复推进',
        attentionCalloutTitle: '当前运行停在待处理节点。',
        attentionCalloutSummary: '',
        pendingUserActionLabel: '等待确认',
        pendingUserAction: null,
        preferredRecentOutput: null,
        primaryMetadata: const <LongTaskRunMetaItemViewData>[],
        diagnosticMetadata: const <LongTaskRunMetaItemViewData>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: LongTaskRunDetailPanel(
              detail: detail,
              actionHandler: handler,
              pendingResearchActionHandler: handler,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前运行需要先处理交付问题。 建议先查看返工链或失败任务。'), findsOneWidget);
      expect(find.textContaining('最近返工任务：'), findsNothing);
      expect(find.textContaining('最近审稿：'), findsNothing);
      expect(find.textContaining('查看当前任务与最近的审稿结果'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '查看审稿结果'), findsOneWidget);
    },
  );
}

class _FakeLongTaskStationActionHandler
    implements LongTaskStationActionHandler, PendingResearchActionHandler {
  final List<String> requestedPaths = <String>[];
  final List<String> approvedRequestIds = <String>[];
  final List<String> rejectedRequestIds = <String>[];
  final List<String> pauseRequestedRunIds = <String>[];
  final List<String> resumeRequestedRunIds = <String>[];
  final List<String> stopRequestedRunIds = <String>[];

  @override
  void onLongTaskStationCurrentProjectFilterToggled(bool selected) {}

  @override
  void onLongTaskStationOpenProjectRequested(String runId) {}

  @override
  void onLongTaskStationTaskCenterRequested() {}

  @override
  void onLongTaskStationPauseRequested(String runId) {
    pauseRequestedRunIds.add(runId);
  }

  @override
  void onLongTaskStationRefreshRequested() {}

  @override
  void onLongTaskStationResourceRequested(String runId, String relativePath) {
    requestedPaths.add(relativePath);
  }

  @override
  void onLongTaskStationResumeRequested(String runId) {
    resumeRequestedRunIds.add(runId);
  }

  @override
  void onLongTaskStationRunSelected(String runId) {}

  @override
  void onLongTaskStationStopRequested(String runId) {
    stopRequestedRunIds.add(runId);
  }

  @override
  Future<void> onPendingResearchApproved(String requestId) async {
    approvedRequestIds.add(requestId);
  }

  @override
  Future<void> onPendingResearchRejected(String requestId) async {
    rejectedRequestIds.add(requestId);
  }
}
