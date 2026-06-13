import '../common/json_types.dart';
import '../ports/reference_evidence_substrate.dart';
import '../output/output_contract_models.dart';
import '../reference_extraction/reference_extraction_agent_group_resolver_service.dart';
import '../reference_extraction/reference_extraction_constants.dart';
import '../reference_extraction/reference_extraction_coverage_merge_service.dart';
import '../reference_extraction/reference_extraction_delivery_decision_service.dart';
import '../reference_extraction/reference_extraction_package_merge_service.dart';
import '../reference_extraction/reference_extraction_proposal_generator.dart';
import '../reference_extraction/reference_extraction_execution_discipline.dart';
import '../reference_extraction/reference_extraction_proposal_models.dart';
import '../reference_extraction/reference_extraction_reentry_decision_service.dart';
import '../reference_extraction/reference_extraction_reentry_models.dart';
import '../reference_extraction/reference_extraction_review_gate_service.dart';
import '../reference_extraction/reference_extraction_run_models.dart';
import '../reference_extraction/reference_extraction_staging_workspace.dart';
import '../reference_extraction/reference_extraction_strategy_profile_resolver_service.dart';
import '../reference_extraction/reference_extraction_workflow_phase_catalog_service.dart';
import '../reference_extraction/reference_ingestion_budget_resolver_service.dart';
import '../reference_extraction/reference_source_batch_models.dart';
import '../reference_extraction/reference_source_batch_planner_service.dart';
import '../reference_extraction/reference_source_batch_progress_service.dart';
import '../reference_substrate/reference_source_document_extraction_service.dart';
import '../reference_substrate/reference_evidence_substrate_state_models.dart';
import '../reference_substrate/reference_source_document_models.dart';
import '../reference_substrate/reference_package_models.dart';
import '../reference_substrate/reference_source_document_structure_service.dart';

class ExecuteReferenceExtractionFromSourceDocumentUseCase {
  ExecuteReferenceExtractionFromSourceDocumentUseCase({
    required ReferenceEvidenceSubstrate substrate,
    required ReferenceExtractionStagingWorkspace stagingWorkspace,
    required ReferenceExtractionProposalGenerator proposalGenerator,
    ReferenceSourceDocumentExtractionService? seedExtractionService,
    ReferenceExtractionAgentGroupResolverService? groupResolverService,
    ReferenceExtractionReviewGateService? reviewGateService,
    ReferenceExtractionDeliveryDecisionService? deliveryDecisionService,
    ReferenceExtractionReentryDecisionService? reentryDecisionService,
    ReferenceExtractionPackageMergeService? packageMergeService,
    ReferenceExtractionWorkflowPhaseCatalogService? phaseCatalogService,
    ReferenceExtractionStrategyProfileResolverService?
    strategyProfileResolverService,
    ReferenceSourceDocumentStructureService? structureService,
    ReferenceIngestionBudgetResolverService? budgetResolverService,
    ReferenceSourceBatchPlannerService? batchPlannerService,
    ReferenceSourceBatchProgressService? batchProgressService,
    ReferenceExtractionCoverageMergeService? coverageMergeService,
  }) : _substrate = substrate,
       _stagingWorkspace = stagingWorkspace,
       _proposalGenerator = proposalGenerator,
       _seedExtractionService =
           seedExtractionService ??
           const ReferenceSourceDocumentExtractionService(),
       _groupResolverService =
           groupResolverService ??
           ReferenceExtractionAgentGroupResolverService(),
       _reviewGateService =
           reviewGateService ?? const ReferenceExtractionReviewGateService(),
       _deliveryDecisionService =
           deliveryDecisionService ??
           const ReferenceExtractionDeliveryDecisionService(),
       _reentryDecisionService =
           reentryDecisionService ??
           const ReferenceExtractionReentryDecisionService(),
       _packageMergeService =
           packageMergeService ??
           const ReferenceExtractionPackageMergeService(),
       _phaseCatalogService =
           phaseCatalogService ??
           const ReferenceExtractionWorkflowPhaseCatalogService(),
       _strategyProfileResolverService =
           strategyProfileResolverService ??
           const ReferenceExtractionStrategyProfileResolverService(),
       _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService(),
       _budgetResolverService =
           budgetResolverService ??
           const ReferenceIngestionBudgetResolverService(),
       _batchPlannerService =
           batchPlannerService ??
           ReferenceSourceBatchPlannerService(
             structureService:
                 structureService ??
                 const ReferenceSourceDocumentStructureService(),
           ),
       _batchProgressService =
           batchProgressService ?? const ReferenceSourceBatchProgressService(),
       _coverageMergeService =
           coverageMergeService ??
           const ReferenceExtractionCoverageMergeService();

  final ReferenceEvidenceSubstrate _substrate;
  final ReferenceExtractionStagingWorkspace _stagingWorkspace;
  final ReferenceExtractionProposalGenerator _proposalGenerator;
  final ReferenceSourceDocumentExtractionService _seedExtractionService;
  final ReferenceExtractionAgentGroupResolverService _groupResolverService;
  final ReferenceExtractionReviewGateService _reviewGateService;
  final ReferenceExtractionDeliveryDecisionService _deliveryDecisionService;
  final ReferenceExtractionReentryDecisionService _reentryDecisionService;
  final ReferenceExtractionPackageMergeService _packageMergeService;
  final ReferenceExtractionWorkflowPhaseCatalogService _phaseCatalogService;
  final ReferenceExtractionStrategyProfileResolverService
  _strategyProfileResolverService;
  final ReferenceSourceDocumentStructureService _structureService;
  final ReferenceIngestionBudgetResolverService _budgetResolverService;
  final ReferenceSourceBatchPlannerService _batchPlannerService;
  final ReferenceSourceBatchProgressService _batchProgressService;
  final ReferenceExtractionCoverageMergeService _coverageMergeService;

  Future<ReferenceExtractionRunResult> execute(
    ReferenceExtractionRunRequest request,
  ) async {
    var phaseRecords = <ReferenceExtractionPhaseRecord>[];
    final phaseIds = _phaseCatalogService.orderedPhaseIds().toSet();

    final seedResult = _seedExtractionService.extract(
      request.sourceDocumentRequest,
    );
    if (phaseIds.contains(ReferenceExtractionWorkflowPhases.seedExtraction)) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.seedExtraction,
          detail: '生成 ${seedResult.generatedEntryCount} 条 seed entries。',
        ),
      );
    }

    final groupResolution = _groupResolverService.resolve(
      groupSelections: request.groupSelections,
      groupAssessments: request.groupAssessments,
      agentBindings: request.agentBindings,
      agentAssessments: request.agentAssessments,
    );
    final resolvedStrategyProfile = _strategyProfileResolverService.resolve(
      executionProfile: groupResolution.executionProfile,
      overrideProfileId: request.strategyProfileId,
      additionalProfiles: request.additionalStrategyProfiles,
    );
    final effectiveGroupResolution = groupResolution.copyWith(
      executionProfile: groupResolution.executionProfile.copyWith(
        strategyProfile: resolvedStrategyProfile,
      ),
    );
    final executionDiscipline = _normalizeExecutionDiscipline(
      resolvedStrategyProfile.executionDiscipline,
    );
    if (phaseIds.contains(ReferenceExtractionWorkflowPhases.groupResolution)) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.groupResolution,
          detail:
              '${effectiveGroupResolution.resolutionKind}:${resolvedStrategyProfile.profileId}',
        ),
      );
    }

    final structure = _structureService.analyze(
      request.sourceDocumentRequest.sourceText,
    );
    final budgetResolution = _budgetResolverService.resolve(
      policy: resolvedStrategyProfile.ingestionBudgetPolicy,
      availableContextChars: request.availableContextChars > 0
          ? request.availableContextChars
          : null,
    );
    final batchPlan = _batchPlannerService.plan(
      planId: '${request.runId}_plan',
      structure: structure,
      budgetResolution: budgetResolution,
      budgetPolicy: resolvedStrategyProfile.ingestionBudgetPolicy,
    );
    var batchProgress = _batchProgressService.initialize(batchPlan);
    final existingRun = await _stagingWorkspace.readRun(request.runId);
    final resumableRun = _isResumableRun(
      existingRun,
      request,
      seedResult,
      batchPlan,
    );
    final reentryDecision = _reentryDecisionService.decide(
      existingRun: resumableRun ? existingRun : null,
      batchPlan: batchPlan,
    );
    final resumableExistingRun = resumableRun ? existingRun : null;
    if (resumableRun && reentryDecision.shouldShortCircuit) {
      final resumableExistingRun = existingRun!;
      return ReferenceExtractionRunResult(
        groupResolution: effectiveGroupResolution,
        seedResult: seedResult,
        reviewOutcome: resumableExistingRun.reviewOutcome!,
        stagingRun: resumableExistingRun,
        deliveryDecision: resumableExistingRun.deliveryDecision,
        finalizedSnapshot: resumableExistingRun.finalizedSnapshot,
      );
    }
    if (resumableRun) {
      final resumableExistingRun = existingRun!;
      phaseRecords = resumableExistingRun.phaseRecords.isEmpty
          ? phaseRecords
          : List<ReferenceExtractionPhaseRecord>.from(
              resumableExistingRun.phaseRecords,
            );
      batchProgress = resumableExistingRun.batchProgress ?? batchProgress;
      if (reentryDecision.isTechnicalResume &&
          phaseIds.contains(ReferenceExtractionWorkflowPhases.batchExecution)) {
        phaseRecords = <ReferenceExtractionPhaseRecord>[
          ...phaseRecords,
          ReferenceExtractionPhaseRecord(
            phaseId: ReferenceExtractionWorkflowPhases.batchExecution,
            detail:
                'resume:${batchProgress.completedBatchCount}/${batchProgress.totalBatches}',
          ),
        ];
      }
      if (reentryDecision.isSemanticContinuation) {
        phaseRecords = <ReferenceExtractionPhaseRecord>[
          ...phaseRecords,
          ReferenceExtractionPhaseRecord(
            phaseId: ReferenceExtractionWorkflowPhases.proposalGeneration,
            detail:
                'semantic_continuation:round=${reentryDecision.continuationContext!.roundIndex}:batches=${reentryDecision.targetBatchIds.join(",")}',
          ),
        ];
      }
    }
    if (phaseIds.contains(ReferenceExtractionWorkflowPhases.batchPlanning)) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.batchPlanning,
          detail:
              'batches=${batchPlan.batches.length};structure=${batchPlan.structureMode};target=${budgetResolution.targetSourceChars};max=${budgetResolution.maxSourceChars};context=${budgetResolution.availableContextChars}',
        ),
      );
    }

    var stagingRun = resumableRun
        ? resumableExistingRun!.copyWith(
            batchPlan: batchPlan,
            batchProgress: batchProgress,
            executionDiscipline: executionDiscipline,
            runStatus: reentryDecision.nextRunStatus,
            continuationContexts: reentryDecision.isSemanticContinuation
                ? <ReferenceExtractionContinuationContext>[
                    ...resumableExistingRun.continuationContexts,
                    reentryDecision.continuationContext!,
                  ]
                : resumableExistingRun.continuationContexts,
            omissionReports: reentryDecision.isSemanticContinuation
                ? const <OmissionReport>[]
                : resumableExistingRun.omissionReports,
            continuationRequests: reentryDecision.isSemanticContinuation
                ? const <ContinuationRequest>[]
                : resumableExistingRun.continuationRequests,
            phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
              phaseRecords,
            ),
          )
        : ReferenceExtractionStagingRun(
            runId: request.runId,
            packageId: seedResult.packageId,
            packageVersionId: seedResult.packageVersionId,
            sourceDocumentTitle: request.sourceDocumentRequest.sourceTitle,
            sourceLanguage: seedResult.sourceLanguage,
            targetLanguage: seedResult.targetLanguage,
            groupResolution: effectiveGroupResolution,
            seedSnapshot: seedResult.snapshot,
            batchPlan: batchPlan,
            batchProgress: batchProgress,
            executionDiscipline: executionDiscipline,
            runStatus: reentryDecision.nextRunStatus,
            phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
              phaseRecords,
            ),
          );
    await _stagingWorkspace.upsertRun(stagingRun);
    await _persistBatchExecutionState(
      packageId: seedResult.packageId,
      packageVersionId: seedResult.packageVersionId,
      batchPlan: batchPlan,
      batchProgress: batchProgress,
      proposals: stagingRun.proposals,
      omissionReports: stagingRun.omissionReports,
      continuationRequests: stagingRun.continuationRequests,
      coverageLedger: stagingRun.coverageLedger,
      metadata: <String, Object?>{
        'run_id': stagingRun.runId,
        'run_status': stagingRun.runStatus,
      },
    );

    final proposals = List<ReferenceExtractionProposal>.from(
      stagingRun.proposals,
    );
    final omissionReports = List<OmissionReport>.from(
      stagingRun.omissionReports,
    );
    final continuationRequests = List<ContinuationRequest>.from(
      stagingRun.continuationRequests,
    );
    final targetBatchIds = reentryDecision.targetBatchIds.toSet();
    final batchesToExecute = reentryDecision.isSemanticContinuation
        ? batchPlan.batches.where(
            (batch) => targetBatchIds.contains(batch.batchId),
          )
        : batchPlan.batches;
    for (final batch in batchesToExecute) {
      if (!reentryDecision.isSemanticContinuation &&
          _isCompletedBatch(batchProgress, batch.batchId)) {
        continue;
      }
      late final ReferenceExtractionProposalGenerationResult batchResult;
      try {
        batchResult = await _proposalGenerator.generateProposals(
          ReferenceExtractionProposalGeneratorRequest(
            runId: request.runId,
            sourceDocumentTitle: request.sourceDocumentRequest.sourceTitle,
            sourceLanguage: seedResult.sourceLanguage,
            targetLanguage: seedResult.targetLanguage,
            seedSnapshot: seedResult.snapshot,
            groupResolution: effectiveGroupResolution,
            batchPlan: batchPlan,
            batchProgress: batchProgress,
            batch: batch,
            continuationContext: reentryDecision.continuationContext,
          ),
        );
      } catch (error) {
        batchProgress = _batchProgressService.markFailed(
          progress: batchProgress,
          batch: batch,
          failureReason: error.toString(),
        );
        stagingRun = stagingRun.copyWith(
          runStatus: ReferenceExtractionRunStatuses.technicalResumable,
          batchProgress: batchProgress,
          phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
            phaseRecords,
          ),
        );
        await _stagingWorkspace.upsertRun(stagingRun);
        await _persistBatchExecutionState(
          packageId: seedResult.packageId,
          packageVersionId: seedResult.packageVersionId,
          batchPlan: batchPlan,
          batchProgress: batchProgress,
          proposals: stagingRun.proposals,
          omissionReports: stagingRun.omissionReports,
          continuationRequests: stagingRun.continuationRequests,
          coverageLedger: stagingRun.coverageLedger,
          metadata: <String, Object?>{
            'run_id': stagingRun.runId,
            'run_status': stagingRun.runStatus,
            'failure_reason': error.toString(),
          },
        );
        rethrow;
      }
      final batchProposals = batchResult.proposals;
      proposals.addAll(
        batchProposals.map(
          (proposal) => proposal.copyWith(
            metadata: <String, Object?>{
              ...proposal.metadata,
              'batch_id': batch.batchId,
              'batch_index': batch.batchIndex,
              'execution_concurrency_mode': executionDiscipline.concurrencyMode,
            },
          ),
        ),
      );
      final actionableOmissionReport = batchResult.omissionReport;
      if (actionableOmissionReport != null &&
          actionableOmissionReport.isActionable) {
        omissionReports.add(actionableOmissionReport);
      }
      final actionableContinuationRequest = batchResult.continuationRequest;
      if (actionableContinuationRequest != null &&
          actionableContinuationRequest.isActionable) {
        continuationRequests.add(actionableContinuationRequest);
      }
      batchProgress = _batchProgressService.markCompleted(
        progress: batchProgress,
        batch: batch,
        proposalCount: batchProposals.length,
        completedAt: request.finalizedAt,
      );
      if (phaseIds.contains(ReferenceExtractionWorkflowPhases.batchExecution)) {
        phaseRecords.add(
          ReferenceExtractionPhaseRecord(
            phaseId: ReferenceExtractionWorkflowPhases.batchExecution,
            detail:
                '${batch.batchId}:${batch.charCount}:${batchProposals.length}:omissions=${batchResult.omissionReport == null ? 0 : 1}:continuation=${batchResult.continuationRequest == null ? 0 : 1}',
          ),
        );
      }
      stagingRun = stagingRun.copyWith(
        proposals: List<ReferenceExtractionProposal>.unmodifiable(proposals),
        omissionReports: List<OmissionReport>.unmodifiable(omissionReports),
        continuationRequests: List<ContinuationRequest>.unmodifiable(
          continuationRequests,
        ),
        batchProgress: batchProgress,
        phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
          phaseRecords,
        ),
      );
      await _stagingWorkspace.upsertRun(stagingRun);
      await _persistBatchExecutionState(
        packageId: seedResult.packageId,
        packageVersionId: seedResult.packageVersionId,
        batchPlan: batchPlan,
        batchProgress: batchProgress,
        proposals: stagingRun.proposals,
        omissionReports: stagingRun.omissionReports,
        continuationRequests: stagingRun.continuationRequests,
        coverageLedger: stagingRun.coverageLedger,
        metadata: <String, Object?>{
          'run_id': stagingRun.runId,
          'run_status': stagingRun.runStatus,
          'last_completed_batch_id': batch.batchId,
        },
      );
    }
    if (phaseIds.contains(
      ReferenceExtractionWorkflowPhases.proposalGeneration,
    )) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.proposalGeneration,
          detail:
              '生成 ${proposals.length} 条候选提案；batch_coverage=${batchProgress.coverageRatio.toStringAsFixed(2)}；omissions=${omissionReports.length}；continuations=${continuationRequests.length}',
        ),
      );
    }
    stagingRun = stagingRun.copyWith(
      proposals: List<ReferenceExtractionProposal>.unmodifiable(proposals),
      omissionReports: List<OmissionReport>.unmodifiable(omissionReports),
      continuationRequests: List<ContinuationRequest>.unmodifiable(
        continuationRequests,
      ),
      batchProgress: batchProgress,
      phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
        phaseRecords,
      ),
    );
    await _stagingWorkspace.upsertRun(stagingRun);
    await _persistBatchExecutionState(
      packageId: seedResult.packageId,
      packageVersionId: seedResult.packageVersionId,
      batchPlan: batchPlan,
      batchProgress: batchProgress,
      proposals: stagingRun.proposals,
      omissionReports: stagingRun.omissionReports,
      continuationRequests: stagingRun.continuationRequests,
      coverageLedger: stagingRun.coverageLedger,
      metadata: <String, Object?>{
        'run_id': stagingRun.runId,
        'run_status': stagingRun.runStatus,
      },
    );

    final reviewOutcome = _reviewGateService.review(
      proposals,
      policy: effectiveGroupResolution
          .executionProfile
          .strategyProfile
          .reviewPolicy,
      outputBudgetPolicy: effectiveGroupResolution
          .executionProfile
          .strategyProfile
          .outputBudgetPolicy,
      coverageContract: effectiveGroupResolution
          .executionProfile
          .strategyProfile
          .outputCoverageContract,
      omissionReports: omissionReports,
      continuationRequests: continuationRequests,
    );
    final deliveryDecision = _deliveryDecisionService.resolve(reviewOutcome);
    if (phaseIds.contains(ReferenceExtractionWorkflowPhases.reviewGate)) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.reviewGate,
          detail:
              'accepted=${reviewOutcome.acceptedProposalIds.length};output_status=${reviewOutcome.outputCompletionStatus};delivery=${deliveryDecision.deliveryStatus};compression=${reviewOutcome.outputCompressionRisk.level}',
        ),
      );
    }
    stagingRun = stagingRun.copyWith(
      reviewOutcome: reviewOutcome,
      runStatus: _reentryDecisionService.resolvePostRunStatus(
        deliveryDecision: deliveryDecision,
      ),
      deliveryDecision: deliveryDecision,
      coverageLedger: reviewOutcome.coverageLedger,
      outputCompressionRisk: reviewOutcome.outputCompressionRisk,
      outputCompletionStatus: reviewOutcome.outputCompletionStatus,
      phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
        phaseRecords,
      ),
    );
    await _stagingWorkspace.upsertRun(stagingRun);
    await _persistBatchExecutionState(
      packageId: seedResult.packageId,
      packageVersionId: seedResult.packageVersionId,
      batchPlan: batchPlan,
      batchProgress: batchProgress,
      proposals: stagingRun.proposals,
      omissionReports: stagingRun.omissionReports,
      continuationRequests: stagingRun.continuationRequests,
      coverageLedger: stagingRun.coverageLedger,
      metadata: <String, Object?>{
        'run_id': stagingRun.runId,
        'run_status': stagingRun.runStatus,
        'delivery_status': deliveryDecision.deliveryStatus,
      },
    );

    ReferencePackageSnapshot? finalizedSnapshot;
    if (deliveryDecision.isPublishable) {
      finalizedSnapshot = _packageMergeService.merge(
        seedSnapshot: seedResult.snapshot,
        proposals: proposals,
        reviewOutcome: reviewOutcome,
        finalizedAt: request.finalizedAt,
        finalizedBy: request.finalizedBy,
        finalizedPackageVersionId: request.finalizedPackageVersionId,
        finalizedVersionLabel: request.finalizedVersionLabel,
      );
      await _substrate.upsertPackageSnapshot(finalizedSnapshot);
    }
    if (phaseIds.contains(ReferenceExtractionWorkflowPhases.packageFinalize)) {
      phaseRecords.add(
        ReferenceExtractionPhaseRecord(
          phaseId: ReferenceExtractionWorkflowPhases.packageFinalize,
          detail: deliveryDecision.isPublishable
              ? finalizedSnapshot!.packageVersionRecord.packageVersionId
              : 'skipped:${deliveryDecision.deliveryStatus}:${deliveryDecision.outputCompletionStatus}',
        ),
      );
    }
    stagingRun = stagingRun.copyWith(
      finalizedSnapshot: finalizedSnapshot,
      phaseRecords: List<ReferenceExtractionPhaseRecord>.unmodifiable(
        phaseRecords,
      ),
    );
    await _stagingWorkspace.upsertRun(stagingRun);

    return ReferenceExtractionRunResult(
      groupResolution: effectiveGroupResolution,
      seedResult: seedResult,
      reviewOutcome: reviewOutcome,
      stagingRun: stagingRun,
      deliveryDecision: deliveryDecision,
      finalizedSnapshot: finalizedSnapshot,
    );
  }

  ReferenceExtractionExecutionDiscipline _normalizeExecutionDiscipline(
    ReferenceExtractionExecutionDiscipline discipline,
  ) {
    return ReferenceExtractionExecutionDiscipline(
      concurrencyMode: ReferenceExtractionConcurrencyModes.single,
      maxConcurrentBatches: 1,
      allowParallelHeavyTextConsumption: false,
      metadata: <String, Object?>{
        ...discipline.metadata,
        'normalized': true,
        'requested_concurrency_mode': discipline.concurrencyMode,
        'requested_max_concurrent_batches': discipline.maxConcurrentBatches,
      },
    );
  }

  bool _isCompletedBatch(
    ReferenceSourceBatchProgress progress,
    String batchId,
  ) {
    return progress.items.any(
      (item) =>
          item.batchId == batchId &&
          item.status == ReferenceSourceBatchStatuses.completed,
    );
  }

  bool _isResumableRun(
    ReferenceExtractionStagingRun? existingRun,
    ReferenceExtractionRunRequest request,
    ReferenceSourceDocumentIngestionResult seedResult,
    ReferenceSourceBatchPlan batchPlan,
  ) {
    if (existingRun == null) {
      return false;
    }
    if (existingRun.runId != request.runId ||
        existingRun.packageId != seedResult.packageId ||
        existingRun.packageVersionId != seedResult.packageVersionId ||
        existingRun.sourceDocumentTitle !=
            request.sourceDocumentRequest.sourceTitle) {
      return false;
    }
    final existingPlan = existingRun.batchPlan;
    if (existingPlan == null ||
        existingPlan.structureMode != batchPlan.structureMode ||
        existingPlan.batches.length != batchPlan.batches.length) {
      return false;
    }
    for (var index = 0; index < existingPlan.batches.length; index += 1) {
      if (existingPlan.batches[index].batchId !=
          batchPlan.batches[index].batchId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _persistBatchExecutionState({
    required String packageId,
    required String packageVersionId,
    required ReferenceSourceBatchPlan batchPlan,
    required ReferenceSourceBatchProgress batchProgress,
    required List<ReferenceExtractionProposal> proposals,
    required List<OmissionReport> omissionReports,
    required List<ContinuationRequest> continuationRequests,
    required OutputCoverageLedger? coverageLedger,
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final coverageState = _coverageMergeService.merge(
      batchPlan: batchPlan,
      batchProgress: batchProgress,
      proposals: proposals,
      coverageLedger: coverageLedger,
      omissionReports: omissionReports,
      continuationRequests: continuationRequests,
    );
    await _substrate.upsertBatchExecutionState(
      ReferenceEvidenceBatchExecutionState(
        packageId: packageId,
        packageVersionId: packageVersionId,
        batchPlan: batchPlan,
        batchProgress: batchProgress,
        coverageState: coverageState,
        coverageLedger: coverageLedger,
        metadata: metadata,
      ),
    );
  }
}
