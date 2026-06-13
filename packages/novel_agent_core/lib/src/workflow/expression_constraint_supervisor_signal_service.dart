import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_review_projection.dart';
import 'expression_constraint_gate_signal.dart';
import 'expression_constraint_gate_signal_service.dart';
import 'writing_execution_constraint_bridge_result.dart';
import 'writing_execution_constraint_summary.dart';

class ExpressionConstraintSupervisorSignalService {
  const ExpressionConstraintSupervisorSignalService({
    ExpressionConstraintGateSignalService? gateSignalService,
  }) : _gateSignalService =
           gateSignalService ?? const ExpressionConstraintGateSignalService();

  final ExpressionConstraintGateSignalService _gateSignalService;

  JsonMap projectionFromBridgeResult(
    WritingExecutionConstraintBridgeResult bridgeResult,
  ) {
    final policyMode = _policyMode(bridgeResult.expressionConstraintPolicyMode);
    final disabled =
        policyMode == ExpressionConstraintExecutionPolicyModes.disabled;
    final skipped =
        !disabled &&
        !bridgeResult.expressionConstraintApplied &&
        (bridgeResult.expressionConstraintTechnicalTurnExcluded ||
            bridgeResult.expressionConstraintSkippedReasons.isNotEmpty);
    return <String, Object?>{
      'present': true,
      'policy_mode': policyMode,
      'injection_strength': bridgeResult.expressionConstraintInjectionStrength,
      'injection_mode': bridgeResult.expressionConstraintInjectionMode,
      'review_requirement': bridgeResult.expressionConstraintReviewRequirement,
      'review_required': bridgeResult.expressionConstraintReviewRequired,
      'violation_disposition':
          bridgeResult.expressionConstraintViolationDisposition,
      'applied': bridgeResult.expressionConstraintApplied,
      'disabled': disabled,
      'skipped': skipped,
      'runtime_escalated': bridgeResult.expressionConstraintRuntimeEscalated,
      'technical_turn_excluded':
          bridgeResult.expressionConstraintTechnicalTurnExcluded,
      'profile_count': bridgeResult.expressionConstraintProfiles.length,
      'binding_count': bridgeResult.projectExpressionConstraintBindings.length,
      'applied_reasons': ValueReaders.deepCopyList(
        bridgeResult.expressionConstraintAppliedReasons.cast<Object?>(),
      ),
      'skipped_reasons': ValueReaders.deepCopyList(
        bridgeResult.expressionConstraintSkippedReasons.cast<Object?>(),
      ),
      'runtime_report': ValueReaders.deepCopyMap(bridgeResult.runtimeReport),
    };
  }

  JsonMap signalFromBridgeResult({
    required WritingExecutionConstraintBridgeResult bridgeResult,
    required ExpressionConstraintReviewProjection review,
  }) {
    final gateSignal = _gateSignalFromBridgeResult(
      bridgeResult: bridgeResult,
      review: review,
    );
    return _signal(
      policyMode: _policyMode(bridgeResult.expressionConstraintPolicyMode),
      injectionStrength: bridgeResult.expressionConstraintInjectionStrength,
      injectionMode: bridgeResult.expressionConstraintInjectionMode,
      reviewRequirement: bridgeResult.expressionConstraintReviewRequirement,
      reviewRequired: bridgeResult.expressionConstraintReviewRequired,
      reviewProvided: !review.isEmpty,
      applied: bridgeResult.expressionConstraintApplied,
      runtimeEscalated: bridgeResult.expressionConstraintRuntimeEscalated,
      technicalTurnExcluded:
          bridgeResult.expressionConstraintTechnicalTurnExcluded,
      skippedReasons: bridgeResult.expressionConstraintSkippedReasons,
      appliedReasons: bridgeResult.expressionConstraintAppliedReasons,
      gateSignal: gateSignal,
      profileCount: bridgeResult.expressionConstraintProfiles.length,
      bindingCount: bridgeResult.projectExpressionConstraintBindings.length,
    );
  }

  JsonMap signalFromSummary(WritingExecutionConstraintSummary summary) {
    return _signal(
      policyMode: _policyMode(summary.expressionConstraintPolicyMode),
      injectionStrength: summary.expressionConstraintInjectionStrength,
      injectionMode: summary.expressionConstraintInjectionMode,
      reviewRequirement: summary.expressionConstraintReviewRequirement,
      reviewRequired: summary.expressionConstraintReviewRequired,
      reviewProvided: summary.expressionConstraintReviewProvided,
      applied: summary.expressionConstraintApplied,
      runtimeEscalated: summary.expressionConstraintRuntimeEscalated,
      technicalTurnExcluded: summary.expressionConstraintTechnicalTurnExcluded,
      skippedReasons: summary.expressionConstraintSkippedReasons,
      appliedReasons: summary.expressionConstraintAppliedReasons,
      gateSignal: summary.expressionConstraintGate,
      profileCount: summary.expressionConstraintProfileCount,
      bindingCount: summary.expressionConstraintBindingCount,
    );
  }

  ExpressionConstraintGateSignal _gateSignalFromBridgeResult({
    required WritingExecutionConstraintBridgeResult bridgeResult,
    required ExpressionConstraintReviewProjection review,
  }) {
    return _gateSignalService.build(bridgeResult: bridgeResult, review: review);
  }

  JsonMap _signal({
    required String policyMode,
    required String injectionStrength,
    required String injectionMode,
    required String reviewRequirement,
    required bool reviewRequired,
    required bool reviewProvided,
    required bool applied,
    required bool runtimeEscalated,
    required bool technicalTurnExcluded,
    required List<String> skippedReasons,
    required List<String> appliedReasons,
    required ExpressionConstraintGateSignal gateSignal,
    required int profileCount,
    required int bindingCount,
  }) {
    final disabled =
        policyMode == ExpressionConstraintExecutionPolicyModes.disabled;
    final skipped =
        !disabled &&
        !applied &&
        (technicalTurnExcluded || skippedReasons.isNotEmpty);
    final waitingReviewEvidence =
        reviewRequired &&
        !reviewProvided &&
        (applied ||
            gateSignal.reason == 'expression_constraint_review_missing');
    final category = disabled
        ? 'policy_disabled'
        : waitingReviewEvidence
        ? 'waiting_review_evidence'
        : gateSignal.repairRequired
        ? 'light_repair'
        : gateSignal.adjustNextChapter
        ? 'suggest_strengthen'
        : gateSignal.present && gateSignal.riskSignals.isNotEmpty
        ? _advisoryCategoryForGateSignal(gateSignal)
        : skipped
        ? 'skipped'
        : applied
        ? 'applied'
        : 'inactive';
    final summary = _summaryForCategory(
      category: category,
      reviewRequired: reviewRequired,
      injectionMode: injectionMode,
      gateSignal: gateSignal,
    );
    return <String, Object?>{
      'present': disabled || skipped || applied || reviewRequired,
      'category': category,
      'summary': summary,
      'policy_mode': policyMode,
      'injection_strength': injectionStrength,
      'injection_mode': injectionMode,
      'review_requirement': reviewRequirement,
      'review_required': reviewRequired,
      'review_provided': reviewProvided,
      'applied': applied,
      'disabled': disabled,
      'skipped': skipped,
      'runtime_escalated': runtimeEscalated,
      'technical_turn_excluded': technicalTurnExcluded,
      'adjust_next_chapter': gateSignal.adjustNextChapter,
      'repair_required':
          category == 'waiting_review_evidence' || category == 'light_repair',
      'risk_signals': ValueReaders.deepCopyList(
        gateSignal.riskSignals.cast<Object?>(),
      ),
      'gate_disposition': gateSignal.recommendedDisposition,
      'gate_reason': gateSignal.reason,
      'profile_count': profileCount,
      'binding_count': bindingCount,
      'applied_reasons': ValueReaders.deepCopyList(
        appliedReasons.cast<Object?>(),
      ),
      'skipped_reasons': ValueReaders.deepCopyList(
        skippedReasons.cast<Object?>(),
      ),
    };
  }

  String _advisoryCategoryForGateSignal(ExpressionConstraintGateSignal gate) {
    // 中文注释: remind 级表达限制信号只应提示后续加强，不应直接升级成 repair。
    if (gate.recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.remind) {
      return 'suggest_strengthen';
    }
    return 'applied';
  }

  String _policyMode(String policyMode) {
    final clean = policyMode.trim();
    return clean.isEmpty
        ? ExpressionConstraintExecutionPolicyModes.disabled
        : clean;
  }

  String _summaryForCategory({
    required String category,
    required bool reviewRequired,
    required String injectionMode,
    required ExpressionConstraintGateSignal gateSignal,
  }) {
    switch (category) {
      case 'policy_disabled':
        return '表达限制策略当前已关闭，本轮不要求额外复核。';
      case 'waiting_review_evidence':
        return gateSignal.summary.trim().isNotEmpty
            ? gateSignal.summary
            : '表达限制已启用，但当前缺少可用的复核证据。';
      case 'suggest_strengthen':
        return gateSignal.summary.trim().isNotEmpty
            ? gateSignal.summary
            : '表达限制风险开始连续出现，建议下一章优先加强。';
      case 'light_repair':
        return gateSignal.summary.trim().isNotEmpty
            ? gateSignal.summary
            : '表达限制出现轻量风险，建议补一轮小修后继续。';
      case 'skipped':
        return '当前轮次未注入表达限制，已记录跳过原因。';
      case 'applied':
        if (gateSignal.summary.trim().isNotEmpty) {
          return gateSignal.summary;
        }
        if (reviewRequired) {
          return '表达限制已按 $injectionMode 接入并完成当前轮次摘要。';
        }
        return '表达限制已接入，本轮无需额外复核。';
      default:
        return '当前没有额外的表达限制 supervisor 信号。';
    }
  }
}
