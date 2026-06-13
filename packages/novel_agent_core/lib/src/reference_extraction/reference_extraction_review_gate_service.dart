import '../common/value_readers.dart';
import '../output/output_contract_evaluator_service.dart';
import '../output/output_contract_models.dart';
import 'reference_extraction_constants.dart';
import 'reference_extraction_proposal_models.dart';
import 'reference_extraction_review_models.dart';
import 'reference_extraction_strategy_profile.dart';

class ReferenceExtractionReviewGateService {
  const ReferenceExtractionReviewGateService({
    this.acceptanceThreshold = 0.78,
    this.candidateThreshold = 0.55,
    OutputContractEvaluatorService? outputContractEvaluatorService,
  }) : _outputContractEvaluatorService =
           outputContractEvaluatorService ??
           const OutputContractEvaluatorService();

  final double acceptanceThreshold;
  final double candidateThreshold;
  final OutputContractEvaluatorService _outputContractEvaluatorService;

  ReferenceExtractionReviewOutcome review(
    List<ReferenceExtractionProposal> proposals, {
    ReferenceExtractionReviewPolicy? policy,
    OutputBudgetPolicy? outputBudgetPolicy,
    OutputCoverageContract? coverageContract,
    List<OmissionReport> omissionReports = const <OmissionReport>[],
    List<ContinuationRequest> continuationRequests =
        const <ContinuationRequest>[],
  }) {
    final effectivePolicy =
        policy ??
        ReferenceExtractionReviewPolicy(
          acceptanceThreshold: acceptanceThreshold,
          candidateThreshold: candidateThreshold,
        );
    final decisions = proposals
        .map((proposal) => _reviewProposal(proposal, effectivePolicy))
        .toList(growable: false);
    final acceptedProposalIds = decisions
        .where(
          (decision) =>
              decision.disposition ==
              ReferenceExtractionReviewDispositions.accepted,
        )
        .map((decision) => decision.proposalId)
        .toSet();
    final generatedSignals = _buildCoverageSignals(proposals);
    final acceptedSignals = _buildCoverageSignals(
      proposals
          .where((proposal) {
            return acceptedProposalIds.contains(proposal.proposalId);
          })
          .toList(growable: false),
    );
    final contractEvaluation = _outputContractEvaluatorService.evaluate(
      budgetPolicy: outputBudgetPolicy ?? const OutputBudgetPolicy(),
      coverageContract: coverageContract ?? const OutputCoverageContract(),
      generatedSignals: generatedSignals,
      acceptedSignals: acceptedSignals,
      omissionReports: omissionReports,
      continuationRequests: continuationRequests,
    );
    return ReferenceExtractionReviewOutcome(
      decisions: decisions,
      omissionReports: omissionReports,
      continuationRequests: continuationRequests,
      coverageLedger: contractEvaluation.coverageLedger,
      outputCompressionRisk: contractEvaluation.compressionRisk,
      outputCompletionStatus: contractEvaluation.completionStatus,
    );
  }

  ReferenceExtractionReviewDecision _reviewProposal(
    ReferenceExtractionProposal proposal,
    ReferenceExtractionReviewPolicy policy,
  ) {
    final hasEvidence =
        proposal.sourceRefs.isNotEmpty || proposal.evidenceRefs.isNotEmpty;
    if (policy.requireEvidence && !hasEvidence) {
      return ReferenceExtractionReviewDecision(
        proposalId: proposal.proposalId,
        disposition: ReferenceExtractionReviewDispositions.needsRework,
        rationale: '缺少 source/evidence 引用，不能进入正式包。',
      );
    }
    if (proposal.confidence >= policy.acceptanceThreshold) {
      return ReferenceExtractionReviewDecision(
        proposalId: proposal.proposalId,
        disposition: ReferenceExtractionReviewDispositions.accepted,
        rationale: '证据链和置信度达到定稿门槛。',
      );
    }
    if (proposal.confidence >= policy.candidateThreshold) {
      return ReferenceExtractionReviewDecision(
        proposalId: proposal.proposalId,
        disposition: ReferenceExtractionReviewDispositions.candidateOnly,
        rationale: '证据存在，但置信度不足以进入正式包。',
      );
    }
    return ReferenceExtractionReviewDecision(
      proposalId: proposal.proposalId,
      disposition: ReferenceExtractionReviewDispositions.needsRework,
      rationale: '置信度偏低，需要进一步提取或复核。',
    );
  }

  List<OutputCoverageSignal> _buildCoverageSignals(
    List<ReferenceExtractionProposal> proposals,
  ) {
    final signals = <OutputCoverageSignal>[];
    for (final proposal in proposals) {
      final summaryLength = proposal.summary.trim().length;
      for (final dimensionId in proposal.coverageDimensionIds) {
        final normalizedDimensionId = dimensionId.trim();
        if (normalizedDimensionId.isEmpty) {
          continue;
        }
        signals.add(
          OutputCoverageSignal(
            dimensionId: normalizedDimensionId,
            slotId: proposal.proposalId,
            summaryCharCount: summaryLength,
            metadata: ValueReaders.deepCopyMap(proposal.metadata),
          ),
        );
      }
    }
    return signals;
  }
}
