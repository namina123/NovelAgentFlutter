import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/long_task_station/application/models/long_task_station_snapshot.dart';
import 'package:novel_agent_app/features/long_task_station/application/services/long_task_station_view_data_service.dart';
import 'package:novel_agent_app/shared/services/activity_time_label_service.dart';
import 'package:novel_agent_app/shared/services/runtime_exposure_policy_service.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'LongTaskStationViewDataService exposes project path and activity labels',
    () {
      final service = LongTaskStationViewDataService(
        activityTimeLabelService: _FixedActivityTimeLabelService(),
      );
      final now = DateTime(2026, 5, 27, 12, 0);
      final run = RunInstance(
        id: 'run-1',
        project: const RunProjectReference(
          projectId: 'project-1',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.failedManualAttention,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 20)),
        lastHeartbeatAt: now.subtract(const Duration(minutes: 3)),
        activeTaskTitle: '第 12 章返工',
        stopReason: 'manual_attention',
      );
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[run],
        selectedRunId: run.id,
        statusMessage: 'ok',
      );

      final viewData = service.build(snapshot);

      expect(viewData.runs.single.projectPath, 'D:/novel/project-a');
      expect(viewData.runs.single.recentActivityLabel, '3 分钟前');
      expect(viewData.runs.single.requiresAttention, isTrue);
      expect(viewData.selectedRun!.requiresManualAttention, isTrue);
      expect(viewData.scopeLabel, '全部项目');
      expect(viewData.canFilterToCurrentProject, isFalse);
    },
  );

  test('LongTaskStationViewDataService can project current project scope', () {
    final service = LongTaskStationViewDataService();
    final now = DateTime(2026, 5, 27, 12, 0);
    final runA = RunInstance(
      id: 'run-a',
      project: const RunProjectReference(
        projectId: 'project-a',
        projectKey: 'D:/novel/project-a',
        rootPath: 'D:/novel/project-a',
        title: '项目 A',
        projectTypeId: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      ),
      runtimeBaselineId: 'continuous_autonomous',
      modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
      workflowStrategyId: 'resumable_long_task',
      status: LongTaskRunStatus.running,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(minutes: 8)),
      activeTaskTitle: '第 5 章',
    );
    final runB = RunInstance(
      id: 'run-b',
      project: const RunProjectReference(
        projectId: 'project-b',
        projectKey: 'D:/novel/project-b',
        rootPath: 'D:/novel/project-b',
        title: '项目 B',
        projectTypeId: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      ),
      runtimeBaselineId: 'continuous_autonomous',
      modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
      workflowStrategyId: 'resumable_long_task',
      status: LongTaskRunStatus.paused,
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(minutes: 5)),
      activeTaskTitle: '第 2 章返工',
    );
    final snapshot = LongTaskStationSnapshot.initial().copyWith(
      runs: <RunInstance>[runA, runB],
      selectedRunId: runA.id,
      currentProjectPath: 'D:/novel/project-a',
      isCurrentProjectFilterActive: true,
      statusMessage: 'ok',
    );

    final viewData = service.build(snapshot);

    expect(viewData.scopeLabel, '当前项目');
    expect(viewData.canFilterToCurrentProject, isTrue);
    expect(viewData.isCurrentProjectFilterActive, isTrue);
    expect(viewData.totalCount, 1);
    expect(viewData.runs.single.title, '项目 A');
    expect(viewData.description, contains('当前项目'));
  });

  test('LongTaskStationViewDataService exposes narrative summary items', () {
    final service = LongTaskStationViewDataService();
    final now = DateTime(2026, 5, 27, 12, 0);
    final run = RunInstance(
      id: 'run-narrative',
      project: const RunProjectReference(
        projectId: 'project-a',
        projectKey: 'D:/novel/project-a',
        rootPath: 'D:/novel/project-a',
        title: '项目 A',
        projectTypeId: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      ),
      runtimeBaselineId: 'continuous_autonomous',
      modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
      workflowStrategyId: 'resumable_long_task',
      status: LongTaskRunStatus.running,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(minutes: 8)),
      activeTaskTitle: '第 5 章',
    );
    const detail = ProjectLongTaskStationDetail(
      activeTask: null,
      chain: null,
      latestCheckpointReview: null,
      latestReviewReport: null,
      latestRepairTask: null,
      narrativeSummary: ProjectLongTaskStationNarrativeSummary(
        activation: ProjectLongTaskStationItemSummary(
          id: 'activation',
          title: 'Activation',
          relativePath: 'tracking/chapter_atomic/ch05.activation_report.json',
          status: 'activation',
          subtitle: '上下文激活报告',
          summary: 'selected 6, omitted 1, files 6.',
        ),
        delivery: ProjectLongTaskStationItemSummary(
          id: 'delivery',
          title: 'Delivery',
          relativePath: 'chapters/ch05.md',
          status: 'delivered',
          subtitle: 'delivered · chapters/ch05.md',
          summary: 'delivered',
        ),
        review: ProjectLongTaskStationItemSummary(
          id: 'review',
          title: 'Review',
          relativePath: 'reviews/continuity/ch05.md',
          status: 'continuity',
          subtitle: 'chapters/ch05.md',
          summary: '需要补强结尾钩子。',
        ),
        continuity: ProjectLongTaskStationItemSummary(
          id: 'continuity',
          title: 'Continuity',
          relativePath: '',
          status: 'continuity',
          subtitle: '更新 3 项',
          summary: 'ledger 1 | claims 1 | reviews 1',
        ),
        information: ProjectLongTaskStationItemSummary(
          id: 'information',
          title: 'Information',
          relativePath: '',
          status: 'manual_attention',
          subtitle: 'knowledge 1 | design 1 | research 0 | reference 1',
          summary: '待研究 1 项，高风险引用 1 项，information 改动 8 项',
        ),
        projectionItems: <ProjectLongTaskStationItemSummary>[
          ProjectLongTaskStationItemSummary(
            id: 'projection_recent_changes',
            title: '最近状态变化',
            relativePath: 'continuity/最近状态变化.md',
            status: 'projection',
            subtitle: 'Readable projection',
            summary: '打开最近 claims 与 ledger 变化投影。',
          ),
          ProjectLongTaskStationItemSummary(
            id: 'projection_review_summary',
            title: '语义复核摘要',
            relativePath: 'reviews/语义复核摘要.md',
            status: 'projection',
            subtitle: 'Readable projection',
            summary: '打开当前语义复核投影。',
          ),
        ],
        permissionItems: <ProjectLongTaskStationItemSummary>[
          ProjectLongTaskStationItemSummary(
            id: 'permission_clarification',
            title: 'Clarification',
            relativePath:
                '.novel_agent/continuity/clarifications/clarification_call-5.json',
            status: 'needs_user_confirmation',
            subtitle: 'needs_user_confirmation · 选项 2',
            summary: '这个机制是否长期生效？',
          ),
        ],
        informationProjectionItems: <ProjectLongTaskStationItemSummary>[
          ProjectLongTaskStationItemSummary(
            id: 'knowledge_projection',
            title: '项目知识摘要',
            relativePath: 'knowledge/项目知识摘要.md',
            status: 'information_projection',
            subtitle: 'Information projection',
            summary: '打开当前 knowledge 卡片的可读投影。',
          ),
          ProjectLongTaskStationItemSummary(
            id: 'design_projection',
            title: '设计元素摘要',
            relativePath: 'knowledge/设计元素摘要.md',
            status: 'information_projection',
            subtitle: 'Information projection',
            summary: '打开当前 design element 的可读投影。',
          ),
        ],
        informationPermissionItems: <ProjectLongTaskStationItemSummary>[
          ProjectLongTaskStationItemSummary(
            id: 'knowledge_confirm',
            title: 'Knowledge Confirmation',
            relativePath:
                '.novel_agent/information/knowledge_cards/knowledge_card_1.json',
            status: 'proposed',
            subtitle: 'proposed · setting_fact · project.world',
            summary: '这条长期设定需要用户确认是否进入主知识层。',
          ),
          ProjectLongTaskStationItemSummary(
            id: 'research_pending',
            title: 'Research Pending',
            relativePath:
                '.novel_agent/information/research_requests/research_request_1.json',
            status: 'awaiting_user_confirmation',
            subtitle: 'awaiting_user_confirmation · needs_user_confirmation',
            summary: '旧城钟楼在北境民俗中的象征意义',
          ),
        ],
      ),
      blocker: ProjectLongTaskStationBlockerSummary(
        code: '',
        note: '当前没有明显阻塞。',
        detail: '',
        controlSummary: '',
        blockingCheckpointTitles: <String>[],
        runRecordPath: 'tracking/long_task_runs/run-narrative.json',
      ),
    );
    final snapshot = LongTaskStationSnapshot.initial().copyWith(
      runs: <RunInstance>[run],
      selectedRunId: run.id,
      selectedRunDetail: detail,
      statusMessage: 'ok',
    );

    final viewData = service.build(snapshot);

    expect(
      viewData.selectedRun!.narrativeActivation!.relativePath,
      'tracking/chapter_atomic/ch05.activation_report.json',
    );
    expect(viewData.selectedRun!.narrativeActivation!.title, '本轮上下文');
    expect(viewData.selectedRun!.narrativeDelivery!.title, '正文交付');
    expect(
      viewData.selectedRun!.narrativeDelivery!.subtitle,
      '已交付 · chapters/ch05.md',
    );
    expect(viewData.selectedRun!.narrativeDelivery!.summary, 'delivered');
    expect(viewData.selectedRun!.narrativeReview!.title, '审稿结果');
    expect(viewData.selectedRun!.narrativeReview!.subtitle, 'chapters/ch05.md');
    expect(viewData.selectedRun!.narrativeReview!.summary, '需要补强结尾钩子。');
    expect(viewData.selectedRun!.narrativeContinuity!.title, '连续性记录');
    expect(
      viewData.selectedRun!.narrativeContinuity!.summary,
      'ledger 1 | claims 1 | reviews 1',
    );
    expect(viewData.selectedRun!.informationSummary!.title, '资料与设定');
    expect(
      viewData.selectedRun!.informationSummary!.summary,
      '待研究 1 项，高风险引用 1 项，information 改动 8 项',
    );
    expect(viewData.selectedRun!.narrativeProjectionItems, hasLength(2));
    expect(
      viewData.selectedRun!.narrativeProjectionItems.first.relativePath,
      'continuity/最近状态变化.md',
    );
    expect(viewData.selectedRun!.narrativePermissionItems, hasLength(1));
    expect(
      viewData.selectedRun!.narrativePermissionItems.single.title,
      '待确认问题',
    );
    expect(
      viewData.selectedRun!.narrativePermissionItems.single.subtitle,
      '待你确认 · 选项 2',
    );
    expect(
      viewData.selectedRun!.narrativePermissionItems.single.actionLabel,
      '打开确认记录',
    );
    expect(viewData.selectedRun!.informationProjectionItems, hasLength(2));
    expect(
      viewData.selectedRun!.narrativeProjectionItems.first.subtitle,
      '可读投影',
    );
    expect(
      viewData.selectedRun!.informationProjectionItems.first.subtitle,
      '资料投影',
    );
    expect(
      viewData.selectedRun!.informationProjectionItems.first.relativePath,
      'knowledge/项目知识摘要.md',
    );
    expect(viewData.selectedRun!.informationPermissionItems, hasLength(2));
    expect(
      viewData.selectedRun!.informationPermissionItems.first.title,
      '待确认知识卡',
    );
    expect(
      viewData.selectedRun!.informationPermissionItems.last.title,
      '待确认调研请求',
    );
    expect(
      viewData.selectedRun!.informationPermissionItems.first.subtitle,
      '待确认 · 设定事实 · 项目世界观',
    );
    expect(
      viewData.selectedRun!.informationPermissionItems.last.subtitle,
      '等待确认 · 待你确认',
    );
    expect(
      viewData.selectedRun!.informationPermissionItems.first.actionLabel,
      '打开确认记录',
    );
    expect(
      viewData
          .selectedRun!
          .informationPermissionItems
          .last
          .pendingResearchRequestId,
      'research_pending',
    );
  });

  test(
    'LongTaskStationViewDataService projects user-facing and diagnostic tiers',
    () {
      final now = DateTime(2026, 5, 27, 12, 0);
      final run = RunInstance(
        id: 'run-exposure',
        project: const RunProjectReference(
          projectId: 'project-a',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.running,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
        activeTaskTitle: '第 5 章',
      );
      const detail = ProjectLongTaskStationDetail(
        activeTask: ProjectLongTaskStationItemSummary(
          id: 'active',
          title: '第 5 章',
          relativePath: 'tasks/ch05.md',
          status: 'running',
          subtitle: '正文推进',
          summary: '继续写作当前章节。',
        ),
        chain: null,
        latestCheckpointReview: null,
        latestReviewReport: null,
        latestRepairTask: null,
        narrativeSummary: ProjectLongTaskStationNarrativeSummary(
          activation: ProjectLongTaskStationItemSummary(
            id: 'activation',
            title: 'Activation',
            relativePath: 'tracking/ch05.activation_report.json',
            status: 'activation',
            subtitle: '上下文激活报告',
            summary: 'selected 6, omitted 1, files 6.',
          ),
          delivery: null,
          review: null,
          continuity: null,
          information: null,
          projectionItems: <ProjectLongTaskStationItemSummary>[],
          permissionItems: <ProjectLongTaskStationItemSummary>[],
          informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
          informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
        ),
        blocker: ProjectLongTaskStationBlockerSummary(
          code: '',
          note: '当前没有明显阻塞。',
          detail: '',
          controlSummary: '',
          blockingCheckpointTitles: <String>[],
          runRecordPath: 'tracking/long_task_runs/run-exposure.json',
        ),
      );
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[run],
        selectedRunId: run.id,
        selectedRunDetail: detail,
        statusMessage: 'ok',
      );

      final standard = LongTaskStationViewDataService().build(snapshot);
      final diagnostic = LongTaskStationViewDataService(
        exposureTier: RuntimeExposureTier.diagnostic,
      ).build(snapshot);

      expect(standard.selectedRun!.runtimeBaselineTitle, isEmpty);
      expect(standard.selectedRun!.workflowStrategyId, isEmpty);
      expect(standard.selectedRun!.diagnosticMetadata, isEmpty);
      expect(standard.selectedRun!.narrativeSectionTitle, '运行摘要');
      expect(standard.selectedRun!.narrativeActivation!.title, '本轮上下文');
      expect(standard.selectedRun!.narrativeActivationLabel, '本轮上下文');

      expect(diagnostic.selectedRun!.workflowStrategyId, 'resumable_long_task');
      expect(diagnostic.selectedRun!.diagnosticMetadata, isNotEmpty);
      expect(
        diagnostic.selectedRun!.diagnosticMetadata.first.label,
        anyOf('运行基准', '工作流 ID'),
      );
      expect(diagnostic.selectedRun!.narrativeSectionTitle, '开放叙事摘要');
      expect(diagnostic.selectedRun!.narrativeActivation!.title, '上下文激活');
      expect(diagnostic.selectedRun!.narrativeActivationLabel, '上下文激活');
    },
  );

  test(
    'LongTaskStationViewDataService projects user-facing recovery actions',
    () {
      final now = DateTime(2026, 5, 27, 12, 0);
      final failedRun = RunInstance(
        id: 'run-failed',
        project: const RunProjectReference(
          projectId: 'project-a',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.failedManualAttention,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
        activeTaskTitle: '第 5 章返工',
        stopReason: 'failed',
      );
      final failedSnapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[failedRun],
        selectedRunId: failedRun.id,
        selectedRunDetail: const ProjectLongTaskStationDetail(
          activeTask: ProjectLongTaskStationItemSummary(
            id: 'repair',
            title: '第 5 章返工',
            relativePath: 'tasks/ch05-repair.md',
            status: 'failed',
            subtitle: 'revision',
            summary: '修复上一轮审稿指出的问题。',
          ),
          chain: null,
          latestCheckpointReview: null,
          latestReviewReport: ProjectLongTaskStationItemSummary(
            id: 'review',
            title: '最近审稿报告',
            relativePath: 'reviews/ch05.md',
            status: 'continuity',
            subtitle: 'scope',
            summary: '结尾钩子不足。',
          ),
          latestRepairTask: null,
          narrativeSummary: null,
          blocker: ProjectLongTaskStationBlockerSummary(
            code: 'failed',
            note: '当前运行链有失败节点，需要先修复或重试。',
            detail: '',
            controlSummary: '建议先查看返工链或失败任务，再决定重试或修订。',
            blockingCheckpointTitles: <String>[],
            runRecordPath: 'tracking/long_task_runs/run-failed.json',
          ),
        ),
        statusMessage: 'ok',
      );
      final failedViewData = LongTaskStationViewDataService().build(
        failedSnapshot,
      );

      expect(failedViewData.selectedRun!.resumeActionLabel, '重试当前步骤');
      expect(failedViewData.selectedRun!.attentionCalloutTitle, '当前运行停在待处理节点。');
      expect(
        failedViewData.selectedRun!.attentionCalloutSummary,
        '当前运行链有失败节点，需要先修复或重试。 建议先查看返工链或失败任务，再决定重试或修订。',
      );
      expect(
        failedViewData.selectedRun!.preferredRecentOutput!.actionLabel,
        '查看最近产物',
      );

      final waitingRun = RunInstance(
        id: 'run-waiting',
        project: failedRun.project,
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.paused,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 4)),
        activeTaskTitle: '检查点确认',
        stopReason: 'waiting_user',
      );
      final waitingSnapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[waitingRun],
        selectedRunId: waitingRun.id,
        selectedRunDetail: const ProjectLongTaskStationDetail(
          activeTask: null,
          chain: null,
          latestCheckpointReview: null,
          latestReviewReport: null,
          latestRepairTask: null,
          narrativeSummary: ProjectLongTaskStationNarrativeSummary(
            activation: null,
            delivery: null,
            review: null,
            continuity: null,
            information: null,
            projectionItems: <ProjectLongTaskStationItemSummary>[],
            permissionItems: <ProjectLongTaskStationItemSummary>[
              ProjectLongTaskStationItemSummary(
                id: 'clarification',
                title: 'Clarification',
                relativePath:
                    '.novel_agent/continuity/clarifications/clarify.json',
                status: 'needs_user_confirmation',
                subtitle: 'needs_user_confirmation',
                summary: '这个设定是否继续沿用？',
              ),
            ],
            informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
            informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
          ),
          blocker: ProjectLongTaskStationBlockerSummary(
            code: 'waiting_user',
            note: '当前运行已经停在需要确认或复核的节点。',
            detail: '',
            controlSummary: '建议先跳到任务中心处理检查点或关口动作。',
            blockingCheckpointTitles: <String>[],
            runRecordPath: 'tracking/long_task_runs/run-waiting.json',
          ),
        ),
        statusMessage: 'ok',
      );
      final waitingViewData = LongTaskStationViewDataService().build(
        waitingSnapshot,
      );

      expect(waitingViewData.selectedRun!.pendingUserActionLabel, '等待确认');
      expect(
        waitingViewData.selectedRun!.attentionCalloutTitle,
        '当前运行停在待确认节点。',
      );
      expect(
        waitingViewData.selectedRun!.attentionCalloutSummary,
        '当前运行已经停在需要确认或复核的节点。 建议先跳到任务中心处理检查点或关口动作。',
      );
      expect(waitingViewData.selectedRun!.pendingUserAction!.title, '待确认问题');
      expect(waitingViewData.selectedRun!.overviewBlocks, hasLength(4));

      final checkpointWaitingRun = waitingRun.copyWith(
        id: 'run-waiting-checkpoint',
        stopReason: 'waiting_user_checkpoint',
      );
      final checkpointWaitingViewData = LongTaskStationViewDataService().build(
        LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[checkpointWaitingRun],
          selectedRunId: checkpointWaitingRun.id,
          selectedRunDetail: waitingSnapshot.selectedRunDetail,
          statusMessage: 'ok',
        ),
      );

      expect(
        checkpointWaitingViewData.selectedRun!.stopDiagnosis!.category,
        LongTaskStopOutcomeCategories.waitingUser,
      );
      expect(
        checkpointWaitingViewData.selectedRun!.stopDiagnosis!.label,
        '等待用户确认',
      );
    },
  );

  test(
    'LongTaskStationViewDataService dedupes recent output resources by underlying artifact',
    () {
      final now = DateTime(2026, 5, 27, 12, 0);
      final run = RunInstance(
        id: 'run-recent-output-dedupe',
        project: const RunProjectReference(
          projectId: 'project-a',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.failedManualAttention,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 6)),
        activeTaskTitle: '第 8 章审稿',
        stopReason: 'delivery_manual_attention',
      );
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[run],
        selectedRunId: run.id,
        selectedRunDetail: const ProjectLongTaskStationDetail(
          activeTask: null,
          chain: null,
          latestCheckpointReview: null,
          latestReviewReport: null,
          latestRepairTask: null,
          narrativeSummary: ProjectLongTaskStationNarrativeSummary(
            activation: null,
            delivery: ProjectLongTaskStationItemSummary(
              id: 'delivery-ch08',
              title: 'Delivery',
              relativePath: 'chapters/ch08.md',
              status: 'delivered',
              subtitle: 'delivered · chapters/ch08.md',
              summary: '第 8 章正文已交付。',
            ),
            review: null,
            continuity: null,
            information: null,
            projectionItems: <ProjectLongTaskStationItemSummary>[],
            permissionItems: <ProjectLongTaskStationItemSummary>[],
            informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
            informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
          ),
          blocker: ProjectLongTaskStationBlockerSummary(
            code: 'delivery_manual_attention',
            category: LongTaskStopOutcomeCategories.manualAttention,
            label: '需要人工处理',
            note: '当前运行需要先处理交付问题。',
            detail: '',
            controlSummary: '建议先查看最近产物。',
            blockingCheckpointTitles: <String>[],
            runRecordPath:
                'tracking/long_task_runs/run-recent-output-dedupe.json',
          ),
        ),
        statusMessage: 'ok',
      );

      final viewData = LongTaskStationViewDataService().build(snapshot);
      final recentOutputBlock = viewData.selectedRun!.overviewBlocks.last;

      expect(recentOutputBlock.title, '最近产物');
      expect(recentOutputBlock.resources, hasLength(1));
      expect(recentOutputBlock.resources.single.title, '正文交付');
      expect(
        recentOutputBlock.resources.single.relativePath,
        'chapters/ch08.md',
      );
    },
  );

  test(
    'LongTaskStationViewDataService keeps recent output block high-level when only bottom related results remain',
    () {
      final now = DateTime(2026, 5, 27, 12, 0);
      final run = RunInstance(
        id: 'run-recent-output-boundary',
        project: const RunProjectReference(
          projectId: 'project-a',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.paused,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        activeTaskTitle: '检查点确认',
        stopReason: 'waiting_user_checkpoint',
      );
      final snapshot = LongTaskStationSnapshot.initial().copyWith(
        runs: <RunInstance>[run],
        selectedRunId: run.id,
        selectedRunDetail: const ProjectLongTaskStationDetail(
          activeTask: null,
          chain: null,
          latestCheckpointReview: ProjectLongTaskStationItemSummary(
            id: 'checkpoint-ch08',
            title: '检查点确认',
            relativePath: 'tracking/checkpoints/ch08.json',
            status: 'waiting_user',
            subtitle: 'needs_user_confirmation',
            summary: '需要先确认本章检查点后再继续。',
          ),
          latestReviewReport: null,
          latestRepairTask: null,
          narrativeSummary: null,
          blocker: ProjectLongTaskStationBlockerSummary(
            code: 'waiting_user_checkpoint',
            category: LongTaskStopOutcomeCategories.waitingUser,
            label: '等待用户确认',
            note: '当前运行正在等待检查点确认。',
            detail: '',
            controlSummary: '建议先处理当前检查点。',
            blockingCheckpointTitles: <String>['检查点确认'],
            runRecordPath:
                'tracking/long_task_runs/run-recent-output-boundary.json',
          ),
        ),
        statusMessage: 'ok',
      );

      final viewData = LongTaskStationViewDataService().build(snapshot);
      final recentOutputBlock = viewData.selectedRun!.overviewBlocks.last;

      expect(recentOutputBlock.title, '最近产物');
      expect(recentOutputBlock.resources, isEmpty);
      expect(recentOutputBlock.summary, '最近审稿、检查点或返工结果已整理到下方最近关联结果。');
      expect(
        recentOutputBlock.entries
            .firstWhere((item) => item.label == '最近可查看内容')
            .value,
        '请看下方结果区',
      );
      expect(
        viewData.selectedRun!.latestCheckpointReview!.relativePath,
        'tracking/checkpoints/ch08.json',
      );
    },
  );

  test(
    'LongTaskStationViewDataService separates stop diagnosis from expression constraint status',
    () {
      final service = LongTaskStationViewDataService();
      final now = DateTime(2026, 5, 27, 12, 0);

      final budgetRun = RunInstance(
        id: 'run-budget',
        project: const RunProjectReference(
          projectId: 'project-a',
          projectKey: 'D:/novel/project-a',
          rootPath: 'D:/novel/project-a',
          title: '项目 A',
          projectTypeId: 'long_novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.paused,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
        activeTaskTitle: '第 6 章',
        stopReason: 'max_steps',
      );
      final budgetViewData = service.build(
        LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[budgetRun],
          selectedRunId: budgetRun.id,
          statusMessage: 'ok',
        ),
      );
      expect(
        budgetViewData.selectedRun!.stopDiagnosis!.category,
        LongTaskStopOutcomeCategories.budgetExhausted,
      );
      expect(budgetViewData.selectedRun!.stopDiagnosis!.label, '预算边界已到');

      final contentGateRun = budgetRun.copyWith(
        id: 'run-content-gate',
        status: LongTaskRunStatus.failedManualAttention,
        stopReason: 'delivery_manual_attention',
        activeTaskTitle: '第 6 章审查',
      );
      final contentGateDetail = const ProjectLongTaskStationDetail(
        activeTask: ProjectLongTaskStationItemSummary(
          id: 'chapter_review',
          title: '第 6 章审查',
          relativePath: 'tasks/ch06-review.json',
          status: 'failed',
          subtitle: 'review',
          summary: '当前章节需要先过内容质量关口。',
        ),
        chain: null,
        latestCheckpointReview: null,
        latestReviewReport: ProjectLongTaskStationItemSummary(
          id: 'review-ch06',
          title: '第06章审稿',
          relativePath: 'reviews/ch06.md',
          status: 'review',
          subtitle: 'quality gate',
          summary: '结尾冲突不足，需要人工复核。',
        ),
        latestRepairTask: null,
        narrativeSummary: ProjectLongTaskStationNarrativeSummary(
          activation: null,
          delivery: null,
          review: null,
          continuity: null,
          information: null,
          expressionConstraint: ProjectLongTaskStationItemSummary(
            id: 'expression-current',
            title: '表达限制',
            relativePath: 'tracking/ch06.execution.json',
            status: 'suggest_strengthen',
            subtitle: '建议加强 · adaptive · chapters/ch06.md',
            summary: '表达限制当前建议加强后续章节执行。',
          ),
          projectionItems: <ProjectLongTaskStationItemSummary>[],
          permissionItems: <ProjectLongTaskStationItemSummary>[],
          informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
          informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
          recentExpressionConstraintItems: <ProjectLongTaskStationItemSummary>[
            ProjectLongTaskStationItemSummary(
              id: 'chapters/ch06.md',
              title: '表达限制：ch06.md',
              relativePath: 'chapters/ch06.md',
              status: 'suggest_strengthen',
              subtitle: 'suggest_strengthen · adaptive · chapters/ch06.md',
              summary: '最近章节仍建议加强表达规则执行。',
            ),
            ProjectLongTaskStationItemSummary(
              id: 'chapters/ch05.md',
              title: '表达限制：ch05.md',
              relativePath: 'chapters/ch05.md',
              status: 'applied',
              subtitle: 'applied · adaptive · chapters/ch05.md',
              summary: '上一章表达规则已正常应用。',
            ),
          ],
        ),
        blocker: ProjectLongTaskStationBlockerSummary(
          code: 'delivery_manual_attention',
          category: LongTaskStopOutcomeCategories.manualAttention,
          label: '需要人工处理',
          note: '结尾冲突不足，需要人工复核。',
          detail: '当前任务：第 6 章审查（failed）',
          controlSummary: '建议先查看审稿结果，再决定返工或重试。',
          blockingCheckpointTitles: <String>[],
          runRecordPath: 'tracking/long_task_runs/run-content-gate.json',
        ),
      );
      final contentGateViewData = service.build(
        LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[contentGateRun],
          selectedRunId: contentGateRun.id,
          selectedRunDetail: contentGateDetail,
          statusMessage: 'ok',
        ),
      );
      expect(
        contentGateViewData.selectedRun!.stopDiagnosis!.category,
        LongTaskStopOutcomeCategories.manualAttention,
      );
      expect(
        contentGateViewData.selectedRun!.expressionConstraintStatus!.category,
        'suggest_strengthen',
      );
      expect(
        contentGateViewData.selectedRun!.expressionConstraintStatus!.label,
        '表达规则：建议加强',
      );
      expect(
        contentGateViewData
            .selectedRun!
            .expressionConstraintStatus!
            .currentItem!
            .subtitle,
        '建议加强 · 自适应 · chapters/ch06.md',
      );
      expect(
        contentGateViewData
            .selectedRun!
            .expressionConstraintStatus!
            .recentItems,
        hasLength(2),
      );
      expect(
        contentGateViewData
            .selectedRun!
            .expressionConstraintStatus!
            .recentItems
            .first
            .subtitle,
        '建议加强 · 自适应 · chapters/ch06.md',
      );
      expect(
        contentGateViewData
            .selectedRun!
            .expressionConstraintStatus!
            .recentItems
            .last
            .subtitle,
        '已应用 · 自适应 · chapters/ch05.md',
      );
      expect(
        contentGateViewData.selectedRun!.overviewBlocks.last.resources.any(
          (item) => item.title == '表达规则状态',
        ),
        isTrue,
      );

      final repairBlockedDetail = const ProjectLongTaskStationDetail(
        activeTask: ProjectLongTaskStationItemSummary(
          id: 'chapter_revision',
          title: '第 6 章返工',
          relativePath: 'tasks/ch06-repair.json',
          status: 'queued',
          subtitle: 'revision',
          summary: '需要先修复表达限制相关问题。',
        ),
        chain: null,
        latestCheckpointReview: null,
        latestReviewReport: null,
        latestRepairTask: null,
        narrativeSummary: ProjectLongTaskStationNarrativeSummary(
          activation: null,
          delivery: null,
          review: null,
          continuity: null,
          information: null,
          expressionConstraint: ProjectLongTaskStationItemSummary(
            id: 'expression-repair',
            title: '表达限制',
            relativePath: 'tracking/ch06.repair.json',
            status: 'repair_blocked',
            subtitle: '阻塞修订 · force · chapters/ch06.md',
            summary: '表达规则要求先修补当前章节后再继续。',
          ),
          projectionItems: <ProjectLongTaskStationItemSummary>[],
          permissionItems: <ProjectLongTaskStationItemSummary>[],
          informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
          informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
        ),
        blocker: ProjectLongTaskStationBlockerSummary(
          code: 'delivery_repair_required',
          category: LongTaskStopOutcomeCategories.constraintGatePause,
          label: '需修补后继续',
          note: '当前节点需要先修补后再继续。',
          detail: '当前任务：第 6 章返工（queued）',
          controlSummary: '建议先打开返工任务处理当前问题。',
          blockingCheckpointTitles: <String>[],
          runRecordPath: 'tracking/long_task_runs/run-repair-blocked.json',
        ),
      );
      final repairBlockedViewData = service.build(
        LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[contentGateRun],
          selectedRunId: contentGateRun.id,
          selectedRunDetail: repairBlockedDetail,
          statusMessage: 'ok',
        ),
      );
      expect(
        repairBlockedViewData
            .selectedRun!
            .expressionConstraintStatus!
            .blocksRepair,
        isTrue,
      );
      expect(
        repairBlockedViewData.selectedRun!.expressionConstraintStatus!.label,
        '表达规则：已阻塞修订',
      );
      expect(
        repairBlockedViewData
            .selectedRun!
            .expressionConstraintStatus!
            .currentItem!
            .subtitle,
        '阻塞修订 · 强制要求 · chapters/ch06.md',
      );

      final technicalRun = budgetRun.copyWith(
        id: 'run-technical',
        status: LongTaskRunStatus.paused,
        stopReason: 'step_failed',
        activeTaskTitle: '第 7 章',
      );
      final technicalViewData = service.build(
        LongTaskStationSnapshot.initial().copyWith(
          runs: <RunInstance>[technicalRun],
          selectedRunId: technicalRun.id,
          statusMessage: 'ok',
        ),
      );
      expect(
        technicalViewData.selectedRun!.stopDiagnosis!.category,
        'technical_failure',
      );
      expect(technicalViewData.selectedRun!.stopDiagnosis!.label, '技术失败');
    },
  );
}

class _FixedActivityTimeLabelService extends ActivityTimeLabelService {
  @override
  String labelForRecentActivity(DateTime? timestamp, {DateTime? now}) {
    return super.labelForRecentActivity(
      timestamp,
      now: DateTime(2026, 5, 27, 12, 0),
    );
  }
}
