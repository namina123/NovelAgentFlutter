import 'reference_extraction_group_resolution.dart';
import 'reference_extraction_execution_discipline.dart';
import 'reference_extraction_delivery_decision.dart';
import 'reference_extraction_proposal_models.dart';
import 'reference_extraction_reentry_models.dart';
import 'reference_extraction_review_models.dart';
import '../output/output_contract_models.dart';
import '../agents/agent_availability_assessment.dart';
import '../agents/agent_group_availability_assessment.dart';
import '../agents/project_agent_binding.dart';
import '../agents/project_agent_group_selection.dart';
import '../reference_substrate/reference_package_models.dart';
import '../reference_substrate/reference_source_document_models.dart';
import 'reference_source_batch_models.dart';
import 'reference_extraction_strategy_profile.dart';

class ReferenceExtractionPhaseRecord {
  const ReferenceExtractionPhaseRecord({
    required this.phaseId,
    this.detail = '',
  });

  final String phaseId;
  final String detail;
}

class ReferenceExtractionRunRequest {
  const ReferenceExtractionRunRequest({
    required this.runId,
    required this.sourceDocumentRequest,
    required this.finalizedAt,
    this.finalizedBy = '',
    this.finalizedPackageVersionId = '',
    this.finalizedVersionLabel = '',
    this.groupSelections = const <ProjectAgentGroupSelection>[],
    this.groupAssessments = const <AgentGroupAvailabilityAssessment>[],
    this.agentBindings = const <ProjectAgentBinding>[],
    this.agentAssessments = const <AgentAvailabilityAssessment>[],
    this.strategyProfileId = '',
    this.availableContextChars = 0,
    this.additionalStrategyProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  });

  final String runId;
  final ReferenceSourceDocumentIngestionRequest sourceDocumentRequest;
  final String finalizedAt;
  final String finalizedBy;
  final String finalizedPackageVersionId;
  final String finalizedVersionLabel;
  final List<ProjectAgentGroupSelection> groupSelections;
  final List<AgentGroupAvailabilityAssessment> groupAssessments;
  final List<ProjectAgentBinding> agentBindings;
  final List<AgentAvailabilityAssessment> agentAssessments;
  final String strategyProfileId;
  final int availableContextChars;
  final List<ReferenceExtractionStrategyProfile> additionalStrategyProfiles;
}

class ReferenceExtractionStagingRun {
  const ReferenceExtractionStagingRun({
    required this.runId,
    required this.packageId,
    required this.packageVersionId,
    required this.sourceDocumentTitle,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.groupResolution,
    required this.seedSnapshot,
    this.proposals = const <ReferenceExtractionProposal>[],
    this.reviewOutcome,
    this.finalizedSnapshot,
    this.batchPlan,
    this.batchProgress,
    this.executionDiscipline = const ReferenceExtractionExecutionDiscipline(),
    this.runStatus = ReferenceExtractionRunStatuses.active,
    this.deliveryDecision = const ReferenceExtractionDeliveryDecision(),
    this.continuationContexts =
        const <ReferenceExtractionContinuationContext>[],
    this.omissionReports = const <OmissionReport>[],
    this.continuationRequests = const <ContinuationRequest>[],
    this.coverageLedger,
    this.outputCompressionRisk = const OutputCompressionRisk(),
    this.outputCompletionStatus = OutputCompletionStatuses.completed,
    this.phaseRecords = const <ReferenceExtractionPhaseRecord>[],
  });

  final String runId;
  final String packageId;
  final String packageVersionId;
  final String sourceDocumentTitle;
  final String sourceLanguage;
  final String targetLanguage;
  final ReferenceExtractionGroupResolution groupResolution;
  final ReferencePackageSnapshot seedSnapshot;
  final List<ReferenceExtractionProposal> proposals;
  final ReferenceExtractionReviewOutcome? reviewOutcome;
  final ReferencePackageSnapshot? finalizedSnapshot;
  final ReferenceSourceBatchPlan? batchPlan;
  final ReferenceSourceBatchProgress? batchProgress;
  final ReferenceExtractionExecutionDiscipline executionDiscipline;
  final String runStatus;
  final ReferenceExtractionDeliveryDecision deliveryDecision;
  final List<ReferenceExtractionContinuationContext> continuationContexts;
  final List<OmissionReport> omissionReports;
  final List<ContinuationRequest> continuationRequests;
  final OutputCoverageLedger? coverageLedger;
  final OutputCompressionRisk outputCompressionRisk;
  final String outputCompletionStatus;
  final List<ReferenceExtractionPhaseRecord> phaseRecords;

  ReferenceExtractionStagingRun copyWith({
    List<ReferenceExtractionProposal>? proposals,
    ReferenceExtractionReviewOutcome? reviewOutcome,
    ReferencePackageSnapshot? finalizedSnapshot,
    ReferenceSourceBatchPlan? batchPlan,
    ReferenceSourceBatchProgress? batchProgress,
    ReferenceExtractionExecutionDiscipline? executionDiscipline,
    String? runStatus,
    ReferenceExtractionDeliveryDecision? deliveryDecision,
    List<ReferenceExtractionContinuationContext>? continuationContexts,
    List<OmissionReport>? omissionReports,
    List<ContinuationRequest>? continuationRequests,
    OutputCoverageLedger? coverageLedger,
    OutputCompressionRisk? outputCompressionRisk,
    String? outputCompletionStatus,
    List<ReferenceExtractionPhaseRecord>? phaseRecords,
  }) {
    return ReferenceExtractionStagingRun(
      runId: runId,
      packageId: packageId,
      packageVersionId: packageVersionId,
      sourceDocumentTitle: sourceDocumentTitle,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      groupResolution: groupResolution,
      seedSnapshot: seedSnapshot,
      proposals: proposals ?? this.proposals,
      reviewOutcome: reviewOutcome ?? this.reviewOutcome,
      finalizedSnapshot: finalizedSnapshot ?? this.finalizedSnapshot,
      batchPlan: batchPlan ?? this.batchPlan,
      batchProgress: batchProgress ?? this.batchProgress,
      executionDiscipline: executionDiscipline ?? this.executionDiscipline,
      runStatus: runStatus ?? this.runStatus,
      deliveryDecision: deliveryDecision ?? this.deliveryDecision,
      continuationContexts: continuationContexts ?? this.continuationContexts,
      omissionReports: omissionReports ?? this.omissionReports,
      continuationRequests: continuationRequests ?? this.continuationRequests,
      coverageLedger: coverageLedger ?? this.coverageLedger,
      outputCompressionRisk:
          outputCompressionRisk ?? this.outputCompressionRisk,
      outputCompletionStatus:
          outputCompletionStatus ?? this.outputCompletionStatus,
      phaseRecords: phaseRecords ?? this.phaseRecords,
    );
  }
}

class ReferenceExtractionRunResult {
  const ReferenceExtractionRunResult({
    required this.groupResolution,
    required this.seedResult,
    required this.reviewOutcome,
    required this.stagingRun,
    required this.deliveryDecision,
    this.finalizedSnapshot,
  });

  final ReferenceExtractionGroupResolution groupResolution;
  final ReferenceSourceDocumentIngestionResult seedResult;
  final ReferenceExtractionReviewOutcome reviewOutcome;
  final ReferenceExtractionStagingRun stagingRun;
  final ReferenceExtractionDeliveryDecision deliveryDecision;
  final ReferencePackageSnapshot? finalizedSnapshot;
}
