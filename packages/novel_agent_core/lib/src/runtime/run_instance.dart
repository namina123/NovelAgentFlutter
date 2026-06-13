import '../common/json_types.dart';
import '../workflow/long_task_recovery_state.dart';
import 'long_task_run_status.dart';
import 'long_task_stop_outcome.dart';
import 'run_project_reference.dart';

class RunInstance {
  const RunInstance({
    required this.id,
    required this.project,
    required this.runtimeBaselineId,
    required this.modeId,
    required this.workflowStrategyId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastHeartbeatAt,
    this.startedAt,
    this.stoppedAt,
    this.activeTaskId = '',
    this.activeTaskTitle = '',
    this.note = '',
    this.stopReason = '',
    this.stopOutcome = const LongTaskStopOutcome(),
    this.recoveryState = const LongTaskRecoveryState(),
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final RunProjectReference project;
  final String runtimeBaselineId;
  final String modeId;
  final String workflowStrategyId;
  final LongTaskRunStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastHeartbeatAt;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final String activeTaskId;
  final String activeTaskTitle;
  final String note;
  final String stopReason;
  final LongTaskStopOutcome stopOutcome;
  final LongTaskRecoveryState recoveryState;
  final JsonMap metadata;

  bool get isGlobal => true;

  bool get isActive => status.isActive;

  bool get requiresManualAttention => status.requiresManualAttention;

  bool get isTerminal => status.isTerminal;

  RunInstance copyWith({
    String? id,
    RunProjectReference? project,
    String? runtimeBaselineId,
    String? modeId,
    String? workflowStrategyId,
    LongTaskRunStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastHeartbeatAt,
    bool clearLastHeartbeatAt = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? stoppedAt,
    bool clearStoppedAt = false,
    String? activeTaskId,
    String? activeTaskTitle,
    String? note,
    String? stopReason,
    LongTaskStopOutcome? stopOutcome,
    LongTaskRecoveryState? recoveryState,
    JsonMap? metadata,
  }) {
    return RunInstance(
      id: id ?? this.id,
      project: project ?? this.project,
      runtimeBaselineId: runtimeBaselineId ?? this.runtimeBaselineId,
      modeId: modeId ?? this.modeId,
      workflowStrategyId: workflowStrategyId ?? this.workflowStrategyId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastHeartbeatAt: clearLastHeartbeatAt
          ? null
          : (lastHeartbeatAt ?? this.lastHeartbeatAt),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      stoppedAt: clearStoppedAt ? null : (stoppedAt ?? this.stoppedAt),
      activeTaskId: activeTaskId ?? this.activeTaskId,
      activeTaskTitle: activeTaskTitle ?? this.activeTaskTitle,
      note: note ?? this.note,
      stopReason: stopReason ?? this.stopReason,
      stopOutcome: stopOutcome ?? this.stopOutcome,
      recoveryState: recoveryState ?? this.recoveryState,
      metadata: metadata ?? this.metadata,
    );
  }
}
