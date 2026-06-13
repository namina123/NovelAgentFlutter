import '../review/review_basis.dart';
import '../review/review_contract.dart';
import '../review/review_contract_catalog.dart';
import '../review/review_finding_contract.dart';
import '../review/review_reviewer_ref.dart';
import '../review/review_type_constants.dart';
import '../workflow/information_evidence_gate_signal.dart';
import '../workflow/writing_execution_information_summary.dart';

class InformationEvidenceReviewContractMapperService {
  const InformationEvidenceReviewContractMapperService();

  ReviewContract? buildReview({
    required String executionId,
    required WritingExecutionInformationSummary information,
    List<String> sourcePaths = const <String>[],
    List<String> targetPaths = const <String>[],
    List<String> evidencePaths = const <String>[],
    String createdAt = '',
  }) {
    // 中文注释: 这里把 information evidence gate 升格成共享审稿合同，避免继续只停留在 gate/supervisor 旁路层。
    final evidenceGate = information.evidenceGate;
    if (!evidenceGate.present) {
      return null;
    }
    final disposition = _recommendedDisposition(evidenceGate);
    final shouldEmit =
        evidenceGate.waitingUser ||
        evidenceGate.requiresRepair ||
        evidenceGate.manualAttentionRequired ||
        evidenceGate.pendingResearchOnly ||
        evidenceGate.contentEvidenceGap;
    if (!shouldEmit) {
      return null;
    }

    final cleanExecutionId = executionId.trim().isEmpty
        ? 'unknown'
        : executionId.trim();
    final normalizedSourcePaths = _unique(sourcePaths);
    final normalizedTargetPaths = _unique(
      targetPaths.isNotEmpty ? targetPaths : information.changedPaths,
    );
    final normalizedEvidencePaths = _buildEvidencePaths(
      executionId: cleanExecutionId,
      information: information,
      sourcePaths: normalizedSourcePaths,
      targetPaths: normalizedTargetPaths,
      evidencePaths: evidencePaths,
    );
    final findings = _buildFindings(evidenceGate: evidenceGate);
    return ReviewContract(
      reviewId: 'information_evidence_review_$cleanExecutionId',
      reviewType: ReviewTypeConstants.general,
      reviewer: const ReviewReviewerRef(
        reviewerId: 'information_evidence_supervisor',
        reviewerRole: 'information_reviewer',
        label: '信息证据复核',
      ),
      basis: ReviewBasis(
        basisType: 'information_evidence',
        summary: _basisSummary(
          information: information,
          evidenceGate: evidenceGate,
        ),
        sourcePaths: normalizedSourcePaths,
        targetPaths: normalizedTargetPaths,
        policyRefs: _policyRefs(evidenceGate),
      ),
      findings: findings,
      riskLevel: _riskLevel(evidenceGate: evidenceGate),
      recommendedDisposition: disposition,
      repairBrief: disposition == ReviewRecommendedDispositions.repair
          ? _repairBrief(evidenceGate: evidenceGate)
          : '',
      summary: _summaryText(
        information: information,
        evidenceGate: evidenceGate,
        disposition: disposition,
      ),
      evidencePaths: normalizedEvidencePaths,
      createdAt: createdAt.trim(),
      metadata: <String, Object?>{
        'origin': 'information_evidence_review_contract_mapper',
        'execution_id': cleanExecutionId,
        'risk_category': information.riskCategory,
        'evidence_severity': evidenceGate.severity,
        'evidence_reason': evidenceGate.reason,
        'evidence_recommended_disposition':
            evidenceGate.recommendedDisposition,
        'pending_research_count': evidenceGate.pendingResearchCount,
        'awaiting_confirmation_count':
            evidenceGate.awaitingConfirmationCount,
        'gateway_failure_count': evidenceGate.gatewayFailureCount,
        'rigorous_source_insufficient_count':
            evidenceGate.rigorousSourceInsufficientCount,
        'required_information_omitted_count':
            evidenceGate.requiredInformationOmittedCount,
        'external_fact_unverified_count':
            evidenceGate.externalFactUnverifiedCount,
      },
    );
  }

  List<ReviewFindingContract> _buildFindings({
    required InformationEvidenceGateSignal evidenceGate,
  }) {
    // 中文注释: findings 只输出正式 evidence 风险，不把 activation 明细膨胀成第二套解释结构。
    final findings = <ReviewFindingContract>[];
    _appendCountFinding(
      findings,
      count: evidenceGate.pendingResearchCount,
      findingId: 'information_pending_research',
      summary: '存在待执行研究请求。',
      suggestedAction: '继续推进前确认这些研究请求是否需要补执行。',
      severity: ReviewFindingSeverities.low,
    );
    _appendCountFinding(
      findings,
      count: evidenceGate.awaitingConfirmationCount,
      findingId: 'information_awaiting_confirmation',
      summary: '存在等待用户确认的研究请求。',
      suggestedAction: '先完成用户确认，再决定是否继续主链。',
      severity: ReviewFindingSeverities.blocking,
    );
    _appendCountFinding(
      findings,
      count: evidenceGate.gatewayFailureCount,
      findingId: 'information_gateway_failed',
      summary: '资料网关执行失败。',
      suggestedAction: '先修复网关或重试研究链路，再恢复主链。',
      severity: ReviewFindingSeverities.blocking,
    );
    _appendCountFinding(
      findings,
      count: evidenceGate.rigorousSourceInsufficientCount,
      findingId: 'information_rigorous_source_insufficient',
      summary: '当前资料来源未达到严谨来源要求。',
      suggestedAction: '补充权威来源或显式保留不确定性。',
      severity: ReviewFindingSeverities.medium,
    );
    _appendCountFinding(
      findings,
      count: evidenceGate.requiredInformationOmittedCount,
      findingId: 'information_required_omitted',
      summary: 'required information 被省略。',
      suggestedAction: '先补齐必要上下文，再继续主链。',
      severity: ReviewFindingSeverities.blocking,
    );
    _appendCountFinding(
      findings,
      count: evidenceGate.externalFactUnverifiedCount,
      findingId: 'information_external_fact_unverified',
      summary: '存在未核验的外部事实。',
      suggestedAction: '先做交叉核验，再继续主链。',
      severity: ReviewFindingSeverities.blocking,
    );
    return List<ReviewFindingContract>.unmodifiable(findings);
  }

  void _appendCountFinding(
    List<ReviewFindingContract> findings, {
    required int count,
    required String findingId,
    required String summary,
    required String suggestedAction,
    required String severity,
  }) {
    if (count <= 0) {
      return;
    }
    findings.add(
      ReviewFindingContract(
        findingId: findingId,
        severity: severity,
        summary: count == 1 ? summary : '$summary 当前共 $count 项。',
        suggestedAction: suggestedAction,
      ),
    );
  }

  String _recommendedDisposition(InformationEvidenceGateSignal evidenceGate) {
    if (evidenceGate.manualAttentionRequired ||
        evidenceGate.recommendedDisposition ==
            InformationEvidenceRecommendedDispositions.manualAttention) {
      return ReviewRecommendedDispositions.manualAttention;
    }
    if (evidenceGate.waitingUser ||
        evidenceGate.recommendedDisposition ==
            InformationEvidenceRecommendedDispositions.checkpointUser) {
      return ReviewRecommendedDispositions.checkpointUser;
    }
    if (evidenceGate.requiresRepair ||
        evidenceGate.recommendedDisposition ==
            InformationEvidenceRecommendedDispositions.repair) {
      return ReviewRecommendedDispositions.repair;
    }
    return ReviewRecommendedDispositions.remind;
  }

  String _riskLevel({required InformationEvidenceGateSignal evidenceGate}) {
    // 中文注释: 风险等级与 evidence gate 阻断层级对齐，保证统一 handoff 读取的是同一语义。
    if (evidenceGate.manualAttentionRequired) {
      return ReviewRiskLevels.critical;
    }
    if (evidenceGate.waitingUser ||
        evidenceGate.requiresRepair ||
        evidenceGate.gatewayFailureCount > 0 ||
        evidenceGate.requiredInformationOmittedCount > 0 ||
        evidenceGate.externalFactUnverifiedCount > 0) {
      return ReviewRiskLevels.high;
    }
    if (evidenceGate.contentEvidenceGap) {
      return ReviewRiskLevels.medium;
    }
    return ReviewRiskLevels.low;
  }

  String _summaryText({
    required WritingExecutionInformationSummary information,
    required InformationEvidenceGateSignal evidenceGate,
    required String disposition,
  }) {
    final summary = information.summary.trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    if (evidenceGate.summary.trim().isNotEmpty) {
      return evidenceGate.summary.trim();
    }
    switch (disposition) {
      case ReviewRecommendedDispositions.checkpointUser:
        return '信息证据链当前正在等待用户确认。';
      case ReviewRecommendedDispositions.repair:
        return '信息证据链存在阻断问题，需先修补后再继续。';
      case ReviewRecommendedDispositions.manualAttention:
        return '信息证据链存在需人工决定的高风险事项。';
      default:
        return '信息证据链存在轻量提醒，建议继续观察。';
    }
  }

  String _repairBrief({required InformationEvidenceGateSignal evidenceGate}) {
    if (evidenceGate.gatewayFailureCount > 0) {
      return '先修复资料网关或重试研究链路，再恢复主链。';
    }
    if (evidenceGate.requiredInformationOmittedCount > 0) {
      return '先补齐 required information，再恢复主链。';
    }
    if (evidenceGate.externalFactUnverifiedCount > 0) {
      return '先完成外部事实核验，再恢复主链。';
    }
    if (evidenceGate.rigorousSourceInsufficientCount > 0) {
      return '先补充严谨来源或降低确定性表达，再恢复主链。';
    }
    return '先修复信息证据缺口，再恢复主链。';
  }

  String _basisSummary({
    required WritingExecutionInformationSummary information,
    required InformationEvidenceGateSignal evidenceGate,
  }) {
    final changedPathCount = information.changedPaths.length;
    return '基于 information activation 与 evidence gate 生成统一审稿合同。 changed_paths=$changedPathCount severity=${evidenceGate.severity} disposition=${evidenceGate.recommendedDisposition}';
  }

  List<String> _policyRefs(InformationEvidenceGateSignal evidenceGate) {
    return _unique(<String>[
      'information_evidence_disposition:${evidenceGate.recommendedDisposition}',
      'information_evidence_severity:${evidenceGate.severity}',
      if (evidenceGate.reason.trim().isNotEmpty)
        'information_evidence_reason:${evidenceGate.reason.trim()}',
    ]);
  }

  List<String> _buildEvidencePaths({
    required String executionId,
    required WritingExecutionInformationSummary information,
    required List<String> sourcePaths,
    required List<String> targetPaths,
    required List<String> evidencePaths,
  }) {
    final merged = _unique(<String>[
      ...information.changedPaths,
      ...targetPaths,
      ...sourcePaths,
      ...evidencePaths,
    ]);
    if (merged.isNotEmpty) {
      return merged;
    }
    return <String>['information/$executionId'];
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
