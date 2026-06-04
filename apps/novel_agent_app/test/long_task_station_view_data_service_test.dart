import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/long_task_station/application/models/long_task_station_snapshot.dart';
import 'package:novel_agent_app/features/long_task_station/application/services/long_task_station_view_data_service.dart';
import 'package:novel_agent_app/shared/services/activity_time_label_service.dart';
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
    expect(
      viewData.selectedRun!.narrativeDelivery!.summary,
      'delivered',
    );
    expect(
      viewData.selectedRun!.narrativeReview!.summary,
      '需要补强结尾钩子。',
    );
    expect(
      viewData.selectedRun!.narrativeContinuity!.summary,
      'ledger 1 | claims 1 | reviews 1',
    );
    expect(viewData.selectedRun!.narrativeProjectionItems, hasLength(2));
    expect(
      viewData.selectedRun!.narrativeProjectionItems.first.relativePath,
      'continuity/最近状态变化.md',
    );
    expect(viewData.selectedRun!.narrativePermissionItems, hasLength(1));
    expect(
      viewData.selectedRun!.narrativePermissionItems.single.actionLabel,
      '打开确认记录',
    );
  });
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
