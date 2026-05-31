import 'package:flutter_test/flutter_test.dart';
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
  });
}
