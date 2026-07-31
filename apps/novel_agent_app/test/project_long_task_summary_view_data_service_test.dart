import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_long_task_summary_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('ProjectLongTaskSummaryViewDataService prioritizes attention runs', () {
    const service = ProjectLongTaskSummaryViewDataService();
    final project = const ProjectDescriptor(
      id: 'project-1',
      name: '项目 A',
      rootPath: 'D:/novel/project-a',
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
    );
    final now = DateTime.now();
    final runs = <RunInstance>[
      RunInstance(
        id: 'run-active',
        project: RunProjectReference.fromProject(project),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.running,
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
        lastHeartbeatAt: now.subtract(const Duration(minutes: 2)),
        activeTaskTitle: '第 8 章',
      ),
      RunInstance(
        id: 'run-attention',
        project: RunProjectReference.fromProject(project),
        runtimeBaselineId: 'chapter_collaboration_autorun',
        modeId: TaskRuntimeConstants.modeSupervisedChapterQueue,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.failedManualAttention,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(minutes: 12)),
        lastHeartbeatAt: now.subtract(const Duration(minutes: 4)),
        activeTaskTitle: '第 9 章返工',
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.manualAttention,
          reason: 'delivery_manual_attention',
          summary: '第 9 章审稿要求人工复核。',
        ),
      ),
    ];

    final viewData = service.build(
      project: project,
      runs: runs,
      isLoading: false,
    )!;

    expect(viewData.totalCount, 2);
    expect(viewData.attentionCount, 1);
    expect(viewData.runs.first.id, 'run-attention');
    expect(viewData.runs.first.requiresAttention, isTrue);
    expect(viewData.runs.first.statusLabel, '需要人工处理');
    expect(viewData.runs.first.attentionCalloutTitle, '当前运行停在待处理节点。');
    expect(viewData.runs.first.diagnosisLabel, '');
    expect(viewData.runs.first.diagnosisSummary, '第 9 章审稿要求人工复核。');
    expect(viewData.runs.first.nextStepSummary, contains('人工处理'));
    expect(viewData.runs.first.attentionCalloutSummary, '');
    // canResume：failedManualAttention 可恢复（重试当前步骤），running 不可（已在跑）。
    expect(viewData.runs.first.canResume, isTrue);
    expect(viewData.runs.first.resumeActionLabel, '重试当前步骤');
    expect(viewData.runs.last.canResume, isFalse);
  });

  test(
    'ProjectLongTaskSummaryViewDataService explains waiting-user runs with next step guidance',
    () {
      const service = ProjectLongTaskSummaryViewDataService();
      final project = const ProjectDescriptor(
        id: 'project-1',
        name: '项目 A',
        rootPath: 'D:/novel/project-a',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      );
      final run = RunInstance(
        id: 'run-waiting',
        project: RunProjectReference.fromProject(project),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.paused,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        activeTaskTitle: '检查点确认',
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.waitingUser,
          reason: 'waiting_user_checkpoint',
          summary: '当前运行正在等待用户确认。',
        ),
      );

      final viewData = service.build(
        project: project,
        runs: <RunInstance>[run],
        runDetails: <String, ProjectLongTaskStationDetail>{
          'run-waiting': const ProjectLongTaskStationDetail(
            activeTask: null,
            chain: null,
            latestCheckpointReview: ProjectLongTaskStationItemSummary(
              id: 'checkpoint-1',
              title: '检查点确认',
              relativePath: '.novel_agent/checkpoints/checkpoint-1.md',
              status: TaskRuntimeConstants.statusWaitingUser,
              subtitle: '等待确认',
              summary: '需要先确认本章检查点再继续。',
            ),
            latestReviewReport: ProjectLongTaskStationItemSummary(
              id: 'review-1',
              title: '第 12 章审稿',
              relativePath: '.novel_agent/reviews/review-1.md',
              status: TaskRuntimeConstants.statusSucceeded,
              subtitle: '审稿完成',
              summary: '建议补强冲突并确认结尾停点。',
            ),
            latestRepairTask: ProjectLongTaskStationItemSummary(
              id: 'repair-1',
              title: '第 12 章返工',
              relativePath: 'tasks/repair-1.md',
              status: TaskRuntimeConstants.statusWaitingUser,
              subtitle: 'needs_user_confirmation · revision',
              summary: '待确认后进入返工。',
            ),
            narrativeSummary: ProjectLongTaskStationNarrativeSummary(
              activation: null,
              delivery: null,
              review: null,
              continuity: null,
              information: null,
              projectionItems: <ProjectLongTaskStationItemSummary>[],
              permissionItems: <ProjectLongTaskStationItemSummary>[
                ProjectLongTaskStationItemSummary(
                  id: 'permission-1',
                  title: 'Clarification',
                  relativePath:
                      '.novel_agent/continuity/clarifications/permission-1.md',
                  status: TaskRuntimeConstants.statusWaitingUser,
                  subtitle: 'needs_user_confirmation',
                  summary: '请先确认是否接受当前审稿建议。',
                ),
              ],
              informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
              informationPermissionItems: <ProjectLongTaskStationItemSummary>[],
            ),
            blocker: ProjectLongTaskStationBlockerSummary(
              code: 'waiting_user_checkpoint',
              note: '当前运行正在等待用户确认。',
              detail: '',
              controlSummary: '先确认当前检查点和审稿意见，再继续推进。',
              blockingCheckpointTitles: <String>['检查点确认'],
              runRecordPath: 'tracking/long_task_runs/run-waiting.json',
            ),
          ),
        },
        isLoading: false,
      )!;

      expect(viewData.runs.single.diagnosisLabel, '');
      expect(viewData.runs.single.diagnosisSummary, '当前运行正在等待用户确认。');
      expect(viewData.runs.single.statusLabel, '等待用户确认');
      expect(viewData.runs.single.attentionCalloutTitle, '当前运行停在待确认节点。');
      expect(viewData.runs.single.nextStepLabel, '下一步');
      expect(viewData.runs.single.nextStepSummary, '先确认当前检查点和审稿意见，再继续推进。');
      expect(viewData.runs.single.attentionCalloutSummary, '');
      expect(
        viewData.runs.single.reviewSummaryLine,
        '最近审稿：第 12 章审稿，建议补强冲突并确认结尾停点。',
      );
      expect(
        viewData.runs.single.repairSummaryLine,
        '返工状态：等待确认 · 第 12 章返工，待确认后进入返工。',
      );
      expect(
        viewData.runs.single.checkpointSummaryLine,
        '最近检查点：检查点确认，需要先确认本章检查点再继续。',
      );
      expect(
        viewData.runs.single.pendingSummaryLine,
        '待确认事项：待确认问题，请先确认是否接受当前审稿建议。',
      );
      // canResume：paused（等待用户确认）可恢复；这类 run requiresManualAttention=true，
      // 故文案与总站同源为「重试当前步骤」。
      expect(viewData.runs.single.canResume, isTrue);
      expect(viewData.runs.single.resumeActionLabel, '重试当前步骤');
    },
  );

  test(
    'ProjectLongTaskSummaryViewDataService humanizes summary item titles and subtitles consistently with station detail',
    () {
      const service = ProjectLongTaskSummaryViewDataService();
      final project = const ProjectDescriptor(
        id: 'project-1',
        name: '项目 A',
        rootPath: 'D:/novel/project-a',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      );
      final run = RunInstance(
        id: 'run-humanized',
        project: RunProjectReference.fromProject(project),
        runtimeBaselineId: 'continuous_autonomous',
        modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
        workflowStrategyId: 'resumable_long_task',
        status: LongTaskRunStatus.paused,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        activeTaskTitle: '资料确认',
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.waitingUser,
          reason: 'information_waiting_user',
          summary: '当前运行正在等待资料确认。',
        ),
      );

      final viewData = service.build(
        project: project,
        runs: <RunInstance>[run],
        runDetails: <String, ProjectLongTaskStationDetail>{
          'run-humanized': const ProjectLongTaskStationDetail(
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
              permissionItems: <ProjectLongTaskStationItemSummary>[],
              informationProjectionItems: <ProjectLongTaskStationItemSummary>[],
              informationPermissionItems: <ProjectLongTaskStationItemSummary>[
                ProjectLongTaskStationItemSummary(
                  id: 'research-1',
                  title: 'Research Pending',
                  relativePath:
                      '.novel_agent/information/research_requests/research-1.json',
                  status: 'awaiting_user_confirmation',
                  subtitle:
                      'awaiting_user_confirmation · needs_user_confirmation',
                  summary: '',
                ),
              ],
            ),
            blocker: ProjectLongTaskStationBlockerSummary(
              code: 'information_waiting_user',
              note: '当前运行正在等待资料确认。',
              detail: '',
              controlSummary: '',
              blockingCheckpointTitles: <String>[],
              runRecordPath: 'tracking/long_task_runs/run-humanized.json',
            ),
          ),
        },
        isLoading: false,
      )!;

      expect(
        viewData.runs.single.pendingSummaryLine,
        '待确认事项：待确认调研请求，等待确认 · 待你确认',
      );
      expect(viewData.runs.single.attentionCalloutTitle, '当前运行停在待确认节点。');
    },
  );
}
