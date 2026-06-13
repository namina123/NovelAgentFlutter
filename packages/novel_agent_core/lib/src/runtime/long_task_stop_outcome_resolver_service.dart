import '../common/json_types.dart';
import '../workflow/information_evidence_gate_signal.dart';
import '../workflow/expression_constraint_gate_signal.dart';
import '../workflow/writing_execution_outcome_statuses.dart';
import '../workflow/writing_execution_result.dart';
import 'long_task_stop_outcome.dart';

class LongTaskStopOutcomeResolverService {
  const LongTaskStopOutcomeResolverService();

  LongTaskStopOutcome fromLegacyStopReason(
    String legacyStopReason, {
    String summary = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 本轮先把最常见旧 stop_reason 收口到统一 taxonomy，未知字符串继续保留在 legacy 字段里等待后续 session 细化。
    final clean = legacyStopReason.trim();
    if (clean.isEmpty) {
      return const LongTaskStopOutcome();
    }
    return LongTaskStopOutcome(
      present: true,
      category: _categoryFromLegacyStopReason(clean),
      reason: clean,
      legacyStopReason: clean,
      summary: summary.trim(),
      completionReason: _completionReasonFromLegacyStopReason(clean),
      metadata: metadata,
    );
  }

  LongTaskStopOutcome fromWritingExecutionResult(
    WritingExecutionResult executionResult, {
    String legacyStopReason = '',
  }) {
    // 中文注释: shared writing result 已经区分 delivery/constraint/information/recovery，这里只做 taxonomy 归类，不重跑业务判断。
    final cleanLegacy = legacyStopReason.trim();
    final category = _categoryFromExecutionResult(
      executionResult,
      legacyStopReason: cleanLegacy,
    );
    if (category.isEmpty) {
      return const LongTaskStopOutcome();
    }
    final resolvedLegacy = cleanLegacy.isNotEmpty
        ? cleanLegacy
        : _fallbackLegacyStopReason(
            executionResult,
            category: category,
          );
    return LongTaskStopOutcome(
      present: true,
      category: category,
      reason: _reasonFromExecutionResult(
        executionResult,
        category: category,
        legacyStopReason: resolvedLegacy,
      ),
      legacyStopReason: resolvedLegacy,
      summary: executionResult.summary,
      completionReason:
          category == LongTaskStopOutcomeCategories.completedNaturally
          ? 'completed_naturally'
          : '',
      metadata: <String, Object?>{
        'overall_status': executionResult.overallStatus,
        'next_action': executionResult.nextAction,
        'delivery_state': executionResult.delivery.state,
        'delivery_reason': executionResult.delivery.reason,
        'recovery_reason': executionResult.recovery.reason,
        'constraint_hard_gate_reasons': executionResult.constraints
            .hardGateReasons,
        'information_risk_category': executionResult.information.riskCategory,
      },
    );
  }

  String _categoryFromExecutionResult(
    WritingExecutionResult executionResult, {
    required String legacyStopReason,
  }) {
    if (legacyStopReason == 'max_steps' || legacyStopReason == 'max_seconds') {
      return LongTaskStopOutcomeCategories.budgetExhausted;
    }
    if (executionResult.requiresUserAction ||
        executionResult.information.waitingUser ||
        executionResult.recovery.waitingUser) {
      return LongTaskStopOutcomeCategories.waitingUser;
    }
    if (executionResult.information.manualAttentionRequired ||
        executionResult.recovery.manualAttentionRequired) {
      return LongTaskStopOutcomeCategories.manualAttention;
    }
    if (_isInformationRepair(executionResult)) {
      return LongTaskStopOutcomeCategories.deliveryFailure;
    }
    if (_isConstraintGatePause(executionResult)) {
      return LongTaskStopOutcomeCategories.constraintGatePause;
    }
    if (_isDeliveryFailure(executionResult)) {
      return LongTaskStopOutcomeCategories.deliveryFailure;
    }
    if (_isRecoveryExhausted(executionResult, legacyStopReason: legacyStopReason)) {
      return LongTaskStopOutcomeCategories.recoveryExhausted;
    }
    if (executionResult.overallStatus ==
        WritingExecutionOutcomeStatuses.technicalFailure) {
      return LongTaskStopOutcomeCategories.technicalFailure;
    }
    if (executionResult.overallStatus == WritingExecutionOutcomeStatuses.success &&
        !executionResult.blocksProgress) {
      return LongTaskStopOutcomeCategories.completedNaturally;
    }
    if (executionResult.overallStatus ==
            WritingExecutionOutcomeStatuses.contentQualityIssue &&
        !_isConstraintGatePause(executionResult) &&
        !_isDeliveryFailure(executionResult)) {
      return LongTaskStopOutcomeCategories.manualAttention;
    }
    if (executionResult.overallStatus ==
        WritingExecutionOutcomeStatuses.recoverableFailure) {
      return LongTaskStopOutcomeCategories.deliveryFailure;
    }
    return '';
  }

  bool _isConstraintGatePause(WritingExecutionResult executionResult) {
    if (executionResult.constraints.hardConstraintTriggered ||
        executionResult.constraints.repairRequired) {
      return true;
    }
    final severity = executionResult.constraints.expressionConstraintGate.severity;
    final disposition = executionResult
        .constraints
        .expressionConstraintGate
        .recommendedDisposition;
    return severity == ExpressionConstraintGateSeverities.blocking ||
        disposition == 'repair' ||
        disposition == 'pause_for_manual_attention';
  }

  bool _isDeliveryFailure(WritingExecutionResult executionResult) {
    if (!executionResult.delivery.present) {
      return false;
    }
    if (executionResult.delivery.blocksProgress) {
      return true;
    }
    return executionResult.delivery.reason.trim().isNotEmpty &&
        executionResult.delivery.reason != 'accepted';
  }

  bool _isInformationRepair(WritingExecutionResult executionResult) {
    return executionResult.information.requiresRepair &&
        !executionResult.information.waitingUser &&
        !executionResult.information.manualAttentionRequired;
  }

  bool _isRecoveryExhausted(
    WritingExecutionResult executionResult, {
    required String legacyStopReason,
  }) {
    if (legacyStopReason == 'recovery_exhausted') {
      return true;
    }
    final reason = executionResult.recovery.reason.trim();
    final action = executionResult.recovery.recommendedAction.trim();
    return reason == 'recovery_exhausted' || action == 'stop_after_recovery_exhausted';
  }

  String _reasonFromExecutionResult(
    WritingExecutionResult executionResult, {
    required String category,
    required String legacyStopReason,
  }) {
    switch (category) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return 'completed_naturally';
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return 'budget_exhausted';
      case LongTaskStopOutcomeCategories.technicalFailure:
        return executionResult.recovery.reason.trim().isEmpty
            ? 'technical_failure'
            : executionResult.recovery.reason.trim();
      case LongTaskStopOutcomeCategories.deliveryFailure:
        if (_isInformationRepair(executionResult)) {
          return executionResult.information.reason.trim().isEmpty
              ? 'information_repair_required'
              : executionResult.information.reason.trim();
        }
        return executionResult.delivery.reason.trim().isEmpty
            ? 'delivery_failure'
            : executionResult.delivery.reason.trim();
      case LongTaskStopOutcomeCategories.constraintGatePause:
        final hardGateReasons = executionResult.constraints.hardGateReasons;
        if (hardGateReasons.isNotEmpty) {
          return hardGateReasons.first;
        }
        return 'constraint_gate_pause';
      case LongTaskStopOutcomeCategories.waitingUser:
        if (executionResult.information.evidenceGate.waitingUser) {
          return InformationEvidenceRecommendedDispositions
                  .checkpointUser ==
              executionResult.information.evidenceGate.recommendedDisposition
              ? 'information_waiting_user'
              : 'waiting_user';
        }
        if (executionResult.recovery.reason.trim().isNotEmpty) {
          return executionResult.recovery.reason.trim();
        }
        return legacyStopReason.isEmpty ? 'waiting_user' : legacyStopReason;
      case LongTaskStopOutcomeCategories.manualAttention:
        if (executionResult.information.manualAttentionRequired) {
          return 'information_manual_attention';
        }
        return executionResult.recovery.reason.trim().isEmpty
            ? 'manual_attention'
            : executionResult.recovery.reason.trim();
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return 'recovery_exhausted';
      default:
        return '';
    }
  }

  String _fallbackLegacyStopReason(
    WritingExecutionResult executionResult, {
    required String category,
  }) {
    switch (category) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return 'completed';
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return 'max_steps';
      case LongTaskStopOutcomeCategories.technicalFailure:
        return 'step_failed';
      case LongTaskStopOutcomeCategories.deliveryFailure:
        if (_isInformationRepair(executionResult)) {
          return 'information_repair_required';
        }
        return executionResult.delivery.blocksProgress
            ? 'delivery_repair_required'
            : 'delivery_failure';
      case LongTaskStopOutcomeCategories.constraintGatePause:
        return 'constraint_gate_pause';
      case LongTaskStopOutcomeCategories.waitingUser:
        return 'waiting_user_checkpoint';
      case LongTaskStopOutcomeCategories.manualAttention:
        return 'delivery_manual_attention';
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return 'recovery_exhausted';
      default:
        return '';
    }
  }

  String _categoryFromLegacyStopReason(String legacyStopReason) {
    switch (legacyStopReason) {
      case 'completed':
      case 'completed_naturally':
      case 'natural_completion':
      case 'no_runnable_task':
        return LongTaskStopOutcomeCategories.completedNaturally;
      case 'max_steps':
      case 'max_seconds':
      case 'budget_exhausted':
        return LongTaskStopOutcomeCategories.budgetExhausted;
      case 'step_failed':
      case 'technical_failure':
        return LongTaskStopOutcomeCategories.technicalFailure;
      case 'delivery_repair_required':
      case 'delivery_failure':
      case 'delivery_waiting_user_choice':
      case 'information_repair_required':
      case 'information_gateway_failed':
      case 'information_required_omitted':
      case 'information_external_fact_unverified':
      case 'information_rigorous_source_insufficient':
        return LongTaskStopOutcomeCategories.deliveryFailure;
      case 'constraint_gate_pause':
      case 'expression_constraint_review_missing':
      case 'expression_constraint_light_repair':
        return LongTaskStopOutcomeCategories.constraintGatePause;
      case 'waiting_user':
      case 'waiting_user_checkpoint':
      case 'waiting_user_choice':
      case 'information_waiting_user':
      case 'permission_waiting_user':
        return LongTaskStopOutcomeCategories.waitingUser;
      case 'manual_attention':
      case 'delivery_manual_attention':
      case 'semantic_review_manual_attention':
      case 'chapter_gate_manual_attention':
      case 'information_manual_attention':
        return LongTaskStopOutcomeCategories.manualAttention;
      case 'recovery_exhausted':
        return LongTaskStopOutcomeCategories.recoveryExhausted;
      default:
        return '';
    }
  }

  String _completionReasonFromLegacyStopReason(String legacyStopReason) {
    switch (legacyStopReason) {
      case 'completed':
      case 'completed_naturally':
      case 'natural_completion':
      case 'no_runnable_task':
        return 'completed_naturally';
      default:
        return '';
    }
  }
}
