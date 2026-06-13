import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../review/review_basis.dart';
import '../review/review_contract.dart';
import '../review/review_contract_catalog.dart';
import '../review/review_finding_contract.dart';
import '../review/review_reviewer_ref.dart';
import '../review/review_type_constants.dart';
import '../workflow/expression_constraint_gate_signal.dart';
import '../workflow/writing_execution_constraint_bridge_result.dart';

class ExpressionConstraintReviewContractMapperService {
  const ExpressionConstraintReviewContractMapperService();

  ReviewContract? buildReview({
    required String executionId,
    required WritingExecutionConstraintBridgeResult bridgeResult,
    required ExpressionConstraintReviewProjection review,
    required ExpressionConstraintGateSignal gateSignal,
    List<String> sourcePaths = const <String>[],
    List<String> targetPaths = const <String>[],
    List<String> evidencePaths = const <String>[],
    String createdAt = '',
  }) {
    // 中文注释: 这里把表达限制复核信号正式映射成共享审稿合同，避免继续停留在 expression 专用 gate 方言。
    final active = bridgeResult.projectExpressionConstraintBindings.isNotEmpty;
    final policyMode = bridgeResult.expressionConstraintPolicyMode.trim().isEmpty
        ? ExpressionConstraintExecutionPolicyModes.disabled
        : bridgeResult.expressionConstraintPolicyMode.trim();
    final disabled =
        policyMode == ExpressionConstraintExecutionPolicyModes.disabled;
    final applied = active && bridgeResult.expressionConstraintApplied;
    final skipped =
        active &&
        !disabled &&
        !applied &&
        (bridgeResult.expressionConstraintSkippedReasons.isNotEmpty ||
            bridgeResult.expressionConstraintTechnicalTurnExcluded);
    final reviewProvided = !review.isEmpty;
    final reviewRequired =
        applied &&
        bridgeResult.expressionConstraintReviewRequirement.trim() !=
            ExpressionConstraintReviewRequirements.none;
    final evidenceMissing = reviewRequired && !reviewProvided;
    final shouldEmit =
        active &&
        !disabled &&
        !skipped &&
        (evidenceMissing || reviewProvided || gateSignal.present);
    if (!shouldEmit) {
      return null;
    }

    final cleanExecutionId = executionId.trim().isEmpty ? 'unknown' : executionId.trim();
    final normalizedSourcePaths = _unique(sourcePaths);
    final normalizedTargetPaths = _unique(targetPaths);
    final normalizedEvidencePaths = _buildEvidencePaths(
      executionId: cleanExecutionId,
      sourcePaths: normalizedSourcePaths,
      targetPaths: normalizedTargetPaths,
      evidencePaths: evidencePaths,
    );
    final disposition = _recommendedDisposition(
      gateSignal: gateSignal,
      evidenceMissing: evidenceMissing,
    );
    final findings = _buildFindings(
      gateSignal: gateSignal,
      review: review,
      evidenceMissing: evidenceMissing,
      disposition: disposition,
    );
    final summary = _summaryText(
      gateSignal: gateSignal,
      review: review,
      evidenceMissing: evidenceMissing,
      disposition: disposition,
    );
    final repairBrief = _repairBrief(
      gateSignal: gateSignal,
      evidenceMissing: evidenceMissing,
      disposition: disposition,
    );
    return ReviewContract(
      reviewId: 'expression_constraint_review_$cleanExecutionId',
      reviewType: ReviewTypeConstants.style,
      reviewer: const ReviewReviewerRef(
        reviewerId: 'expression_constraint_supervisor',
        reviewerRole: 'constraint_reviewer',
        label: '表达限制复核',
      ),
      basis: ReviewBasis(
        basisType: 'expression_constraint',
        summary: _basisSummary(
          bridgeResult: bridgeResult,
          review: review,
          evidenceMissing: evidenceMissing,
        ),
        sourcePaths: normalizedSourcePaths,
        targetPaths: normalizedTargetPaths,
        policyRefs: _policyRefs(bridgeResult),
      ),
      findings: findings,
      riskLevel: _riskLevel(
        gateSignal: gateSignal,
        evidenceMissing: evidenceMissing,
        disposition: disposition,
        bridgeResult: bridgeResult,
      ),
      recommendedDisposition: disposition,
      repairBrief: repairBrief,
      summary: summary,
      evidencePaths: normalizedEvidencePaths,
      createdAt: createdAt.trim(),
      metadata: <String, Object?>{
        'origin': 'expression_constraint_review_contract_mapper',
        'execution_id': cleanExecutionId,
        'policy_mode': policyMode,
        'injection_strength': bridgeResult.expressionConstraintInjectionStrength,
        'review_requirement': bridgeResult.expressionConstraintReviewRequirement,
        'violation_disposition':
            bridgeResult.expressionConstraintViolationDisposition,
        'review_required': reviewRequired,
        'review_provided': reviewProvided,
        'review_evidence_missing': evidenceMissing,
        'gate_severity': gateSignal.severity,
        'gate_reason': gateSignal.reason,
        'gate_disposition': gateSignal.recommendedDisposition,
        'gate_present': gateSignal.present,
        'authenticity_pass_level': review.authenticityPassLevel,
        'runtime_escalated': bridgeResult.expressionConstraintRuntimeEscalated,
        'technical_turn_excluded':
            bridgeResult.expressionConstraintTechnicalTurnExcluded,
      },
    );
  }

  List<ReviewFindingContract> _buildFindings({
    required ExpressionConstraintGateSignal gateSignal,
    required ExpressionConstraintReviewProjection review,
    required bool evidenceMissing,
    required String disposition,
  }) {
    // 中文注释: findings 只承载真正影响统一处置的风险证据，避免把 review focus 误写成已确认问题。
    final findings = <ReviewFindingContract>[];
    if (evidenceMissing) {
      findings.add(
        const ReviewFindingContract(
          findingId: 'expression_constraint_review_missing',
          severity: ReviewFindingSeverities.blocking,
          summary: '表达限制要求复核，但当前缺少复核证据。',
          suggestedAction: '补充表达限制复核证据后再决定是否继续主链。',
        ),
      );
    }

    final riskSeverity = _findingSeverityForDisposition(disposition);
    final riskSignals = _unique(<String>[
      ...gateSignal.riskSignals,
      ...review.continuityWatchItems,
      ...review.miniRecheckItems,
    ]);
    for (var index = 0; index < riskSignals.length; index++) {
      findings.add(
        ReviewFindingContract(
          findingId: 'expression_constraint_risk_${index + 1}',
          severity: riskSeverity,
          summary: riskSignals[index],
          suggestedAction: _suggestedActionForDisposition(disposition),
        ),
      );
    }

    if (!evidenceMissing &&
        findings.isEmpty &&
        disposition == ReviewRecommendedDispositions.accept &&
        gateSignal.summary.trim().isNotEmpty) {
      findings.add(
        ReviewFindingContract(
          findingId: 'expression_constraint_review_note',
          severity: ReviewFindingSeverities.info,
          summary: gateSignal.summary.trim(),
          suggestedAction: '记录当前复核结论，继续后续流程。',
        ),
      );
    }
    return List<ReviewFindingContract>.unmodifiable(findings);
  }

  String _recommendedDisposition({
    required ExpressionConstraintGateSignal gateSignal,
    required bool evidenceMissing,
  }) {
    if (evidenceMissing ||
        gateSignal.recommendedDisposition ==
            ExpressionConstraintGateRecommendedDispositions.repair) {
      return ReviewRecommendedDispositions.repair;
    }
    if (gateSignal.recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.adjustNext) {
      return ReviewRecommendedDispositions.adjustNext;
    }
    if (gateSignal.recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.remind) {
      return ReviewRecommendedDispositions.remind;
    }
    return ReviewRecommendedDispositions.accept;
  }

  String _riskLevel({
    required ExpressionConstraintGateSignal gateSignal,
    required bool evidenceMissing,
    required String disposition,
    required WritingExecutionConstraintBridgeResult bridgeResult,
  }) {
    // 中文注释: 风险等级与共享 disposition 对齐，确保 supervisor 与 repair handoff 读取同一层级。
    if (evidenceMissing) {
      return ReviewRiskLevels.critical;
    }
    if (disposition == ReviewRecommendedDispositions.repair) {
      return bridgeResult.expressionConstraintPolicyMode ==
              ExpressionConstraintExecutionPolicyModes.force
          ? ReviewRiskLevels.critical
          : ReviewRiskLevels.high;
    }
    if (disposition == ReviewRecommendedDispositions.adjustNext) {
      return ReviewRiskLevels.medium;
    }
    if (disposition == ReviewRecommendedDispositions.remind) {
      return gateSignal.repeatedPattern
          ? ReviewRiskLevels.medium
          : ReviewRiskLevels.low;
    }
    return ReviewRiskLevels.none;
  }

  String _findingSeverityForDisposition(String disposition) {
    if (disposition == ReviewRecommendedDispositions.repair) {
      return ReviewFindingSeverities.blocking;
    }
    if (disposition == ReviewRecommendedDispositions.adjustNext) {
      return ReviewFindingSeverities.high;
    }
    if (disposition == ReviewRecommendedDispositions.remind) {
      return ReviewFindingSeverities.medium;
    }
    return ReviewFindingSeverities.info;
  }

  String _suggestedActionForDisposition(String disposition) {
    if (disposition == ReviewRecommendedDispositions.repair) {
      return '根据表达限制复核结论先修订当前章节，再恢复主链。';
    }
    if (disposition == ReviewRecommendedDispositions.adjustNext) {
      return '下一章前收紧表达限制，并优先复查重复风险模式。';
    }
    if (disposition == ReviewRecommendedDispositions.remind) {
      return '记录提醒，继续观察表达限制风险是否扩大。';
    }
    return '记录当前复核结论并继续。';
  }

  String _summaryText({
    required ExpressionConstraintGateSignal gateSignal,
    required ExpressionConstraintReviewProjection review,
    required bool evidenceMissing,
    required String disposition,
  }) {
    if (evidenceMissing) {
      return '表达限制要求复核，但当前缺少复核证据，需先补齐再继续。';
    }
    if (gateSignal.summary.trim().isNotEmpty) {
      return gateSignal.summary.trim();
    }
    if (disposition == ReviewRecommendedDispositions.accept) {
      return review.authenticityPassLevel ==
              ExpressionConstraintReviewProjection.authenticityDisabled
          ? '当前表达限制没有额外处置需求。'
          : '表达限制复核已完成，当前没有额外 gate 动作。';
    }
    return '表达限制复核已生成统一审稿结论。';
  }

  String _repairBrief({
    required ExpressionConstraintGateSignal gateSignal,
    required bool evidenceMissing,
    required String disposition,
  }) {
    if (disposition != ReviewRecommendedDispositions.repair) {
      return '';
    }
    if (evidenceMissing) {
      return '先补齐表达限制复核证据，再判断是否需要正文修订。';
    }
    return gateSignal.summary.trim().isNotEmpty
        ? gateSignal.summary.trim()
        : '先修复表达限制高风险问题，再恢复主链。';
  }

  String _basisSummary({
    required WritingExecutionConstraintBridgeResult bridgeResult,
    required ExpressionConstraintReviewProjection review,
    required bool evidenceMissing,
  }) {
    final profileCount = bridgeResult.expressionConstraintProfiles.length;
    final bindingCount = bridgeResult.projectExpressionConstraintBindings.length;
    final policyMode = bridgeResult.expressionConstraintPolicyMode.trim().isEmpty
        ? ExpressionConstraintExecutionPolicyModes.disabled
        : bridgeResult.expressionConstraintPolicyMode.trim();
    final parts = <String>[
      '基于表达限制执行策略与复核投影生成统一审稿合同。',
      'policy=$policyMode',
      'profiles=$profileCount',
      'bindings=$bindingCount',
    ];
    if (review.authenticityPassLevel.trim().isNotEmpty &&
        review.authenticityPassLevel !=
            ExpressionConstraintReviewProjection.authenticityDisabled) {
      parts.add('authenticity=${review.authenticityPassLevel}');
    }
    if (evidenceMissing) {
      parts.add('review_evidence_missing=true');
    }
    return parts.join(' ');
  }

  List<String> _policyRefs(WritingExecutionConstraintBridgeResult bridgeResult) {
    final refs = <String>[
      'expression_constraint_policy:${bridgeResult.expressionConstraintPolicyMode}',
      'expression_constraint_injection:${bridgeResult.expressionConstraintInjectionStrength}',
      'expression_constraint_review_requirement:${bridgeResult.expressionConstraintReviewRequirement}',
      'expression_constraint_violation:${bridgeResult.expressionConstraintViolationDisposition}',
    ];
    for (final profile in bridgeResult.expressionConstraintProfiles) {
      final clean = profile.id.trim();
      if (clean.isNotEmpty) {
        refs.add('expression_constraint_profile:$clean');
      }
    }
    for (final binding in bridgeResult.projectExpressionConstraintBindings) {
      final clean = binding.id.trim();
      if (clean.isNotEmpty) {
        refs.add('expression_constraint_binding:$clean');
      }
    }
    return _unique(refs);
  }

  List<String> _buildEvidencePaths({
    required String executionId,
    required List<String> sourcePaths,
    required List<String> targetPaths,
    required List<String> evidencePaths,
  }) {
    final merged = _unique(<String>[
      ...targetPaths,
      ...sourcePaths,
      ...evidencePaths,
    ]);
    if (merged.isNotEmpty) {
      return merged;
    }
    return <String>['execution/$executionId'];
  }

  List<String> _unique(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return List<String>.unmodifiable(result);
  }
}
