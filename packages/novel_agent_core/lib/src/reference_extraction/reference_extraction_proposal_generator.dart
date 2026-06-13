import '../output/output_contract_models.dart';
import '../reference_substrate/reference_package_models.dart';
import 'reference_extraction_group_resolution.dart';
import 'reference_extraction_proposal_models.dart';
import 'reference_extraction_reentry_models.dart';
import 'reference_source_batch_models.dart';

class ReferenceExtractionProposalGeneratorRequest {
  const ReferenceExtractionProposalGeneratorRequest({
    required this.runId,
    required this.sourceDocumentTitle,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.seedSnapshot,
    required this.groupResolution,
    required this.batchPlan,
    required this.batchProgress,
    required this.batch,
    this.continuationContext,
  });

  final String runId;
  final String sourceDocumentTitle;
  final String sourceLanguage;
  final String targetLanguage;
  final ReferencePackageSnapshot seedSnapshot;
  final ReferenceExtractionGroupResolution groupResolution;
  final ReferenceSourceBatchPlan batchPlan;
  final ReferenceSourceBatchProgress batchProgress;
  final ReferenceSourceBatch batch;
  final ReferenceExtractionContinuationContext? continuationContext;
}

class ReferenceExtractionProposalGenerationResult {
  const ReferenceExtractionProposalGenerationResult({
    this.proposals = const <ReferenceExtractionProposal>[],
    this.omissionReport,
    this.continuationRequest,
  });

  final List<ReferenceExtractionProposal> proposals;
  final OmissionReport? omissionReport;
  final ContinuationRequest? continuationRequest;
}

abstract class ReferenceExtractionProposalGenerator {
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  );
}
