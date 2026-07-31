import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/activity_time_label_service.dart';
import '../../../../shared/services/long_task_station_item_humanizer_service.dart';
import '../../../../shared/services/runtime_label_service.dart';
import '../../presentation/models/project_long_task_summary_view_data.dart';

class ProjectLongTaskSummaryViewDataService {
  const ProjectLongTaskSummaryViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RuntimeLabelService? runtimeLabelService,
    ActivityTimeLabelService? activityTimeLabelService,
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
    LongTaskStationItemHumanizerService? itemHumanizerService,
    LongTaskRunStateMachine? longTaskRunStateMachine,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService(),
       _activityTimeLabelService =
           activityTimeLabelService ?? const ActivityTimeLabelService(),
       _stopDiagnosisProjectionService =
           stopDiagnosisProjectionService ??
           const LongTaskStopDiagnosisProjectionService(),
       _itemHumanizerService =
           itemHumanizerService ?? const LongTaskStationItemHumanizerService(),
       _longTaskRunStateMachine =
           longTaskRunStateMachine ?? const LongTaskRunStateMachine();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RuntimeLabelService _runtimeLabelService;
  final ActivityTimeLabelService _activityTimeLabelService;
  final LongTaskStopDiagnosisProjectionService _stopDiagnosisProjectionService;
  final LongTaskStationItemHumanizerService _itemHumanizerService;
  final LongTaskRunStateMachine _longTaskRunStateMachine;

  ProjectLongTaskSummaryViewData? build({
    required ProjectDescriptor? project,
    required List<RunInstance> runs,
    Map<String, ProjectLongTaskStationDetail> runDetails =
        const <String, ProjectLongTaskStationDetail>{},
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
      runs: orderedRuns
          .take(3)
          .map((run) => _entry(run, detail: runDetails[run.id]))
          .toList(growable: false),
    );
  }

  ProjectLongTaskRunSummaryViewData _entry(
    RunInstance run, {
    required ProjectLongTaskStationDetail? detail,
  }) {
    final baseline = _runtimeBaselineCatalogService.byId(run.runtimeBaselineId);
    final baselineTitle = baseline?.title ?? run.runtimeBaselineId;
    final blockerCode = detail?.blocker.code ?? run.stopReason;
    final diagnosis = _stopDiagnosisProjectionService.project(
      stopOutcome: run.stopOutcome,
      recoveryState: run.recoveryState,
      legacyReason: blockerCode,
      runStatus: run.status.id,
      note: detail?.blocker.note ?? run.note,
      reviewSummary: _isWaitingForUser(blockerCode)
          ? ''
          : _firstNonBlank(<String>[
              detail?.latestReviewReport?.summary ?? '',
              detail?.latestCheckpointReview?.summary ?? '',
              detail?.narrativeSummary?.review?.summary ?? '',
            ]),
      informationSummary: _firstNonBlank(<String>[
        detail?.narrativeSummary?.information?.summary ?? '',
      ]),
      detail: detail?.blocker.detail ?? '',
      metadata: const <String, Object?>{
        'source': 'project_long_task_summary_view_data',
      },
    );
    final category = diagnosis.category.trim();
    final pendingSummaryLine = _pendingSummaryLine(run, detail: detail);
    final nextStepSummary = _nextStepSummary(category, run: run, detail: detail);
    final reviewSummaryLine = _reviewSummaryLine(detail);
    final repairSummaryLine = _repairSummaryLine(detail);
    final checkpointSummaryLine = _checkpointSummaryLine(detail);
    final statusLabel = _statusLabel(
      run,
      category,
      diagnosis.label,
    );
    final attentionCalloutTitle = _attentionCalloutTitle(
      category,
      pendingSummaryLine: pendingSummaryLine,
      requiresAttention: run.requiresManualAttention,
    );
    final canResume = !run.isActive &&
        _longTaskRunStateMachine.canTransition(
          run.status,
          LongTaskRunStatus.running,
        );
    final resumeActionLabel =
        run.requiresManualAttention ? '重试当前步骤' : '恢复推进';
    return ProjectLongTaskRunSummaryViewData(
      id: run.id,
      title: baselineTitle,
      subtitle: _runtimeLabelService.runtimeModeLabel(run.modeId),
      statusLabel: statusLabel,
      taskLabel: run.activeTaskTitle.trim().isEmpty
          ? '当前无活动任务'
          : run.activeTaskTitle.trim(),
      recentActivityLabel: _activityTimeLabelService.labelForRecentActivity(
        run.lastHeartbeatAt ?? run.startedAt ?? run.updatedAt,
      ),
      requiresAttention: run.requiresManualAttention,
      isActive: run.isActive,
      canResume: canResume,
      resumeActionLabel: resumeActionLabel,
      attentionCalloutTitle: attentionCalloutTitle,
      attentionCalloutSummary: _attentionCalloutSummary(
        run: run,
        diagnosisSummary: diagnosis.summary,
        nextStepSummary: nextStepSummary,
      ),
      diagnosisLabel: _diagnosisLabel(
        category,
        diagnosis.label,
        attentionCalloutTitle: attentionCalloutTitle,
      ),
      diagnosisSummary: diagnosis.summary,
      nextStepLabel: category.isEmpty ? '' : '下一步',
      nextStepSummary: nextStepSummary,
      reviewSummaryLine: reviewSummaryLine,
      repairSummaryLine: repairSummaryLine,
      checkpointSummaryLine: checkpointSummaryLine,
      pendingSummaryLine: pendingSummaryLine,
    );
  }

  String _attentionCalloutTitle(
    String category, {
    required String pendingSummaryLine,
    required bool requiresAttention,
  }) {
    if (pendingSummaryLine.trim().isNotEmpty ||
        category == LongTaskStopOutcomeCategories.waitingUser) {
      return '当前运行停在待确认节点。';
    }
    if (requiresAttention) {
      return '当前运行停在待处理节点。';
    }
    return '这里有一条建议操作链。';
  }

  String _statusLabel(
    RunInstance run,
    String category,
    String diagnosisLabel,
  ) {
    final normalizedDiagnosisLabel = diagnosisLabel.trim();
    if (normalizedDiagnosisLabel.isNotEmpty &&
        (category == LongTaskStopOutcomeCategories.waitingUser ||
            category == LongTaskStopOutcomeCategories.manualAttention)) {
      return normalizedDiagnosisLabel;
    }
    return _runtimeLabelService.longTaskRunStatusLabel(run.status);
  }

  String _diagnosisLabel(
    String category,
    String diagnosisLabel, {
    required String attentionCalloutTitle,
  }) {
    if (attentionCalloutTitle.trim().isNotEmpty &&
        (category == LongTaskStopOutcomeCategories.waitingUser ||
            category == LongTaskStopOutcomeCategories.manualAttention)) {
      return '';
    }
    return diagnosisLabel;
  }

  String _attentionCalloutSummary({
    required RunInstance run,
    required String diagnosisSummary,
    required String nextStepSummary,
  }) {
    final diagnosis = diagnosisSummary.trim();
    if (diagnosis.isNotEmpty) {
      return '';
    }
    final nextStep = nextStepSummary.trim();
    if (nextStep.isNotEmpty) {
      return nextStep;
    }
    return run.isActive
        ? '当前运行仍在推进，可以继续打开总站查看详细现场。'
        : '可以先打开总站查看当前任务和最近结果。';
  }

  String _nextStepSummary(
    String category, {
    required RunInstance run,
    required ProjectLongTaskStationDetail? detail,
  }) {
    final blockerControl = detail?.blocker.controlSummary.trim() ?? '';
    if (blockerControl.isNotEmpty) {
      return blockerControl;
    }
    switch (category) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return '当前主链已经自然收尾，可以回到总站查看结果或开启下一轮。';
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return '如果还要继续，请重新启动或恢复这一轮预算。';
      case LongTaskStopOutcomeCategories.technicalFailure:
        return '先查看失败链路，再决定是否重试当前步骤。';
      case LongTaskStopOutcomeCategories.deliveryFailure:
        return '先修复章节交付问题，再继续推进。';
      case LongTaskStopOutcomeCategories.constraintGatePause:
        return '先处理复核或返工要求，任务才会继续。';
      case LongTaskStopOutcomeCategories.waitingUser:
        return '先完成待确认事项，任务才会继续。';
      case LongTaskStopOutcomeCategories.manualAttention:
        return '先人工处理当前卡点，再决定返工或重试。';
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return '自动恢复次数已耗尽，需要人工决定下一步。';
      default:
        return run.isActive ? '当前运行仍在推进，可继续到总站查看详细现场。' : '';
    }
  }

  String _reviewSummaryLine(ProjectLongTaskStationDetail? detail) {
    final review = detail?.latestReviewReport;
    if (review == null) {
      return '';
    }
    return '最近审稿：${_itemHumanSummary(review)}';
  }

  String _repairSummaryLine(ProjectLongTaskStationDetail? detail) {
    final repair = detail?.latestRepairTask;
    if (repair == null) {
      return '';
    }
    final statusLabel = _runtimeLabelService.taskStatusLabel(repair.status);
    return '返工状态：$statusLabel · ${_itemHumanSummary(repair)}';
  }

  String _checkpointSummaryLine(ProjectLongTaskStationDetail? detail) {
    final checkpoint = detail?.latestCheckpointReview;
    if (checkpoint == null) {
      return '';
    }
    return '最近检查点：${_itemHumanSummary(checkpoint)}';
  }

  String _pendingSummaryLine(
    RunInstance run, {
    required ProjectLongTaskStationDetail? detail,
  }) {
    if (detail == null) {
      return '';
    }
    final blockerCode = detail.blocker.code.trim();
    if (_isWaitingForUser(blockerCode)) {
      final pendingItem = _firstPendingItem(detail);
      if (pendingItem != null) {
        return '待确认事项：${_itemHumanSummary(pendingItem)}';
      }
      final blockerNote = detail.blocker.note.trim();
      if (blockerNote.isNotEmpty) {
        return '待确认事项：$blockerNote';
      }
    }
    if (run.requiresManualAttention) {
      final blockerNote = detail.blocker.note.trim();
      if (blockerNote.isNotEmpty) {
        return '当前卡点：$blockerNote';
      }
    }
    return '';
  }

  ProjectLongTaskStationItemSummary? _firstPendingItem(
    ProjectLongTaskStationDetail detail,
  ) {
    final narrativeSummary = detail.narrativeSummary;
    if (narrativeSummary?.permissionItems.isNotEmpty == true) {
      return narrativeSummary!.permissionItems.first;
    }
    if (narrativeSummary?.informationPermissionItems.isNotEmpty == true) {
      return narrativeSummary!.informationPermissionItems.first;
    }
    return detail.latestCheckpointReview;
  }

  String _itemHumanSummary(ProjectLongTaskStationItemSummary item) {
    final title = _itemHumanizerService.title(item);
    final summary = item.summary.trim();
    if (summary.isNotEmpty) {
      return '$title，$summary';
    }
    final subtitle = _itemHumanizerService.subtitle(item);
    if (subtitle.isNotEmpty) {
      return '$title，$subtitle';
    }
    return title;
  }

  bool _isWaitingForUser(String code) {
    final normalized = code.trim();
    return normalized == 'waiting_user' ||
        normalized == 'waiting_user_checkpoint' ||
        normalized == 'waiting_gate' ||
        normalized == 'waiting_user_choice' ||
        normalized == 'information_waiting_user' ||
        normalized == 'delivery_waiting_user_choice';
  }

  String _firstNonBlank(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
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
