import '../runtime/long_task_run_status.dart';
import '../runtime/long_task_stop_outcome.dart';
import '../runtime/long_task_stop_outcome_resolver_service.dart';
import 'continuous_task_lifecycle_state.dart';
import 'continuous_task_run_phase.dart';
import 'continuous_task_stop_category.dart';
import 'continuous_task_terminal_disposition.dart';

class ContinuousTaskLifecycleStateResolverService {
  const ContinuousTaskLifecycleStateResolverService({
    LongTaskStopOutcomeResolverService? stopOutcomeResolverService,
  }) : _stopOutcomeResolverService =
           stopOutcomeResolverService ??
           const LongTaskStopOutcomeResolverService();

  final LongTaskStopOutcomeResolverService _stopOutcomeResolverService;

  ContinuousTaskLifecycleState fromLongTask({
    required LongTaskRunStatus status,
    LongTaskStopOutcome stopOutcome = const LongTaskStopOutcome(),
    String legacyStopReason = '',
  }) {
    final phase = _phaseFromLongTaskStatus(status);
    final category = _resolveStopCategory(
      stopOutcome: stopOutcome,
      legacyStopReason: legacyStopReason,
    );
    final resolvedReason = stopOutcome.reason.trim().isNotEmpty
        ? stopOutcome.reason.trim()
        : legacyStopReason.trim();
    return ContinuousTaskLifecycleState(
      runPhase: phase,
      terminalDisposition: phase == ContinuousTaskRunPhases.stopped
          ? _terminalDispositionForCategory(category)
          : '',
      stopCategory: category,
      reason: resolvedReason,
      metadata: <String, Object?>{
        'source_contract': 'long_task_projection',
        'legacy_run_status': status.id,
        'legacy_stop_reason': legacyStopReason.trim(),
        'legacy_stop_outcome_present': stopOutcome.present,
      },
    );
  }

  String _phaseFromLongTaskStatus(LongTaskRunStatus status) {
    switch (status) {
      case LongTaskRunStatus.draftingGuidance:
        return ContinuousTaskRunPhases.draftingGuidance;
      case LongTaskRunStatus.readyToStart:
        return ContinuousTaskRunPhases.readyToStart;
      case LongTaskRunStatus.running:
        return ContinuousTaskRunPhases.running;
      case LongTaskRunStatus.waitingGate:
        return ContinuousTaskRunPhases.waitingUser;
      case LongTaskRunStatus.paused:
        return ContinuousTaskRunPhases.paused;
      case LongTaskRunStatus.recovering:
        return ContinuousTaskRunPhases.recovering;
      case LongTaskRunStatus.failedManualAttention:
        return ContinuousTaskRunPhases.manualAttention;
      case LongTaskRunStatus.stopped:
        return ContinuousTaskRunPhases.stopped;
    }
  }

  String _resolveStopCategory({
    required LongTaskStopOutcome stopOutcome,
    required String legacyStopReason,
  }) {
    final directCategory = stopOutcome.category.trim();
    if (directCategory.isNotEmpty) {
      return directCategory;
    }
    final cleanLegacyStopReason = legacyStopReason.trim();
    if (_isCancellationReason(cleanLegacyStopReason)) {
      return ContinuousTaskStopCategories.cancelled;
    }
    if (cleanLegacyStopReason.isEmpty) {
      return '';
    }
    return _stopOutcomeResolverService
        .fromLegacyStopReason(cleanLegacyStopReason)
        .category;
  }

  String _terminalDispositionForCategory(String category) {
    switch (category) {
      case ContinuousTaskStopCategories.completedNaturally:
        return ContinuousTaskTerminalDispositions.completed;
      case ContinuousTaskStopCategories.cancelled:
        return ContinuousTaskTerminalDispositions.cancelled;
      case ContinuousTaskStopCategories.technicalFailure:
      case ContinuousTaskStopCategories.deliveryFailure:
      case ContinuousTaskStopCategories.recoveryExhausted:
        return ContinuousTaskTerminalDispositions.failed;
      case ContinuousTaskStopCategories.budgetExhausted:
      case ContinuousTaskStopCategories.constraintGatePause:
      case ContinuousTaskStopCategories.waitingUser:
      case ContinuousTaskStopCategories.manualAttention:
      case '':
        return ContinuousTaskTerminalDispositions.stopped;
    }
    return ContinuousTaskTerminalDispositions.stopped;
  }

  bool _isCancellationReason(String value) {
    return value == 'cancelled' ||
        value == 'user_requested' ||
        value == 'user_cancelled' ||
        value == 'manual_cancel' ||
        value == 'host_cancelled';
  }
}
