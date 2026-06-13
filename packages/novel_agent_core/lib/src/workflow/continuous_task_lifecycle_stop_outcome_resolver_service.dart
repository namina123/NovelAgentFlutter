import '../common/value_readers.dart';
import '../runtime/long_task_stop_outcome.dart';
import 'continuous_task_lifecycle_state.dart';
import 'continuous_task_stop_category.dart';

class ContinuousTaskLifecycleStopOutcomeResolverService {
  const ContinuousTaskLifecycleStopOutcomeResolverService();

  LongTaskStopOutcome resolve(
    ContinuousTaskLifecycleState lifecycleState, {
    String note = '',
  }) {
    final category = lifecycleState.stopCategory.trim();
    if (category.isEmpty) {
      return const LongTaskStopOutcome();
    }
    final reason = lifecycleState.reason.trim().isNotEmpty
        ? lifecycleState.reason.trim()
        : category;
    return LongTaskStopOutcome(
      present: true,
      category: category,
      reason: reason,
      legacyStopReason: legacyStopReason(lifecycleState),
      summary: note.trim().isNotEmpty ? note.trim() : reason,
      completionReason:
          category == LongTaskStopOutcomeCategories.completedNaturally
          ? reason
          : '',
      metadata: ValueReaders.deepCopyMap(lifecycleState.metadata),
    );
  }

  String legacyStopReason(ContinuousTaskLifecycleState lifecycleState) {
    switch (lifecycleState.stopCategory.trim()) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return 'completed';
      case ContinuousTaskStopCategories.cancelled:
        return 'cancelled';
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return 'budget_exhausted';
      case LongTaskStopOutcomeCategories.technicalFailure:
        return 'technical_failure';
      case LongTaskStopOutcomeCategories.deliveryFailure:
        return 'delivery_failure';
      case LongTaskStopOutcomeCategories.constraintGatePause:
        return 'constraint_gate_pause';
      case LongTaskStopOutcomeCategories.waitingUser:
        return 'waiting_user';
      case LongTaskStopOutcomeCategories.manualAttention:
        return 'manual_attention';
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return 'recovery_exhausted';
    }
    final reason = lifecycleState.reason.trim();
    return reason.isEmpty ? '' : reason;
  }
}
