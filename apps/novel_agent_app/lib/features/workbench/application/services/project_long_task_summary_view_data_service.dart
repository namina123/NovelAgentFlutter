import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/activity_time_label_service.dart';
import '../../../../shared/services/runtime_label_service.dart';
import '../../presentation/models/project_long_task_summary_view_data.dart';

class ProjectLongTaskSummaryViewDataService {
  const ProjectLongTaskSummaryViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RuntimeLabelService? runtimeLabelService,
    ActivityTimeLabelService? activityTimeLabelService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService(),
       _activityTimeLabelService =
           activityTimeLabelService ?? const ActivityTimeLabelService();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RuntimeLabelService _runtimeLabelService;
  final ActivityTimeLabelService _activityTimeLabelService;

  ProjectLongTaskSummaryViewData? build({
    required ProjectDescriptor? project,
    required List<RunInstance> runs,
    required bool isLoading,
  }) {
    if (project == null) {
      return null;
    }
    final orderedRuns = List<RunInstance>.from(runs)..sort(_compareRuns);
    final activeCount = orderedRuns.where((run) => run.isActive).length;
    final attentionCount = orderedRuns
        .where((run) => run.requiresManualAttention)
        .length;
    final summary = isLoading
        ? '正在读取当前项目的长任务运行状态...'
        : orderedRuns.isEmpty
        ? '当前项目还没有登记到全局运行站的长任务实例。'
        : '运行中 $activeCount · 待处理 $attentionCount · 共 ${orderedRuns.length} 条';
    return ProjectLongTaskSummaryViewData(
      title: '长任务运行',
      summary: summary,
      isLoading: isLoading,
      totalCount: orderedRuns.length,
      activeCount: activeCount,
      attentionCount: attentionCount,
      runs: orderedRuns.take(3).map(_entry).toList(growable: false),
    );
  }

  ProjectLongTaskRunSummaryViewData _entry(RunInstance run) {
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    final baselineTitle = baseline?.title ?? run.runtimeBaselineId;
    return ProjectLongTaskRunSummaryViewData(
      id: run.id,
      title: baselineTitle,
      subtitle: _runtimeLabelService.runtimeModeLabel(run.modeId),
      statusLabel: _runtimeLabelService.longTaskRunStatusLabel(run.status),
      taskLabel: run.activeTaskTitle.trim().isEmpty
          ? '当前无活动任务'
          : run.activeTaskTitle.trim(),
      recentActivityLabel: _activityTimeLabelService.labelForRecentActivity(
        run.lastHeartbeatAt ?? run.startedAt ?? run.updatedAt,
      ),
      requiresAttention: run.requiresManualAttention,
      isActive: run.isActive,
    );
  }

  int _compareRuns(RunInstance left, RunInstance right) {
    if (left.requiresManualAttention != right.requiresManualAttention) {
      return left.requiresManualAttention ? -1 : 1;
    }
    if (left.isActive != right.isActive) {
      return left.isActive ? -1 : 1;
    }
    final leftTime = left.lastHeartbeatAt ?? left.startedAt ?? left.updatedAt;
    final rightTime =
        right.lastHeartbeatAt ?? right.startedAt ?? right.updatedAt;
    return rightTime.compareTo(leftTime);
  }
}
