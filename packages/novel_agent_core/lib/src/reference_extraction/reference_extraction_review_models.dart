import 'reference_extraction_constants.dart';
import '../output/output_contract_models.dart';

class ReferenceExtractionReviewDecision {
  const ReferenceExtractionReviewDecision({
    required this.proposalId,
    required this.disposition,
    this.rationale = '',
  });

  final String proposalId;
  final String disposition;
  final String rationale;
}

class ReferenceExtractionReviewOutcome {
  const ReferenceExtractionReviewOutcome({
    this.decisions = const <ReferenceExtractionReviewDecision>[],
    this.omissionReports = const <OmissionReport>[],
    this.continuationRequests = const <ContinuationRequest>[],
    this.coverageLedger,
    this.outputCompressionRisk = const OutputCompressionRisk(),
    this.outputCompletionStatus = OutputCompletionStatuses.completed,
  });

  final List<ReferenceExtractionReviewDecision> decisions;
  final List<OmissionReport> omissionReports;
  final List<ContinuationRequest> continuationRequests;
  final OutputCoverageLedger? coverageLedger;
  final OutputCompressionRisk outputCompressionRisk;
  final String outputCompletionStatus;

  List<String> get acceptedProposalIds => decisions
      .where(
        (decision) =>
            decision.disposition ==
            ReferenceExtractionReviewDispositions.accepted,
      )
      .map((decision) => decision.proposalId)
      .toList(growable: false);

  bool get needsContinuation =>
      outputCompletionStatus ==
      OutputCompletionStatuses.continuationRecommended;
}
