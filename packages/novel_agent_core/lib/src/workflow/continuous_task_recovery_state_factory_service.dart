import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_run_status.dart';
import 'continuous_task_lifecycle_state.dart';
import 'continuous_task_lifecycle_stop_outcome_resolver_service.dart';
import 'long_task_recovery_state.dart';

class ContinuousTaskRecoveryStateFactoryService {
  const ContinuousTaskRecoveryStateFactoryService({
    ContinuousTaskLifecycleStopOutcomeResolverService?
    lifecycleStopOutcomeResolverService,
  }) : _lifecycleStopOutcomeResolverService =
           lifecycleStopOutcomeResolverService ??
           const ContinuousTaskLifecycleStopOutcomeResolverService();

  final ContinuousTaskLifecycleStopOutcomeResolverService
  _lifecycleStopOutcomeResolverService;

  LongTaskRecoveryState resumeReady({
    required ContinuousTaskLifecycleState lifecycleState,
    required String recommendedAction,
    String note = '',
    bool autoRetryEligible = false,
    bool blocksProgress = true,
    String taskId = '',
    String taskTitle = '',
    String taskPath = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final resolvedReason = lifecycleState.reason.trim().isNotEmpty
        ? lifecycleState.reason.trim()
        : lifecycleState.stopCategory.trim();
    final resolvedNote = note.trim().isNotEmpty ? note.trim() : resolvedReason;
    return LongTaskRecoveryState(
      present: true,
      state: LongTaskRecoveryStates.resumeReady,
      runStatus: LongTaskRunStatus.recovering.id,
      recommendedAction: recommendedAction.trim(),
      reason: resolvedReason,
      note: resolvedNote,
      autoRetryEligible: autoRetryEligible,
      blocksProgress: blocksProgress,
      taskId: taskId.trim(),
      taskTitle: taskTitle.trim(),
      taskPath: taskPath.trim(),
      stopOutcome: _lifecycleStopOutcomeResolverService.resolve(
        lifecycleState,
        note: resolvedNote,
      ),
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }
}
