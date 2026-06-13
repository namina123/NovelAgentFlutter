import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_agent_group_binding_repository.dart';
import '../storage/reference_bundle_export_service.dart';
import '../storage/reference_source_document_file_reader_service.dart';
import '../storage/sqlite_reference_evidence_substrate.dart';
import '../tools/project_tool_path_policy.dart';
import 'file_reference_extraction_staging_workspace.dart';
import 'llm_reference_extraction_proposal_generator.dart';
import 'project_reference_extraction_agent_context_service.dart';
import 'project_reference_extraction_mount_service.dart';
import 'project_reference_extraction_path_service.dart';
import 'project_reference_extraction_runtime_models.dart';
import 'project_reference_mount_outcome.dart';
import 'project_reference_mount_outcome_resolver_service.dart';
import 'reference_extraction_continuous_task_sync_service.dart';
import 'reference_source_language_hint_service.dart';
import '../workflow/project_reference_continuity_bridge_service.dart';

typedef ReferenceExtractionProposalGeneratorFactory =
    ReferenceExtractionProposalGenerator Function({
      required LlmGateway llmGateway,
      required String modelId,
    });

class ProjectReferenceExtractionRuntimeService {
  ProjectReferenceExtractionRuntimeService({
    required ProjectWorkspacePort workspacePort,
    required Future<List<JsonMap>> Function(ProjectDescriptor project)
    loadAvailableAgents,
    required Future<List<JsonMap>> Function(ProjectDescriptor project)
    loadAvailableGroups,
    required ProjectAgentGroupBindingRepository groupBindingRepository,
    ProjectReferenceExtractionPathService? pathService,
    ProjectToolPathPolicy? toolPathPolicy,
    ReferenceExtractionProposalGeneratorFactory? proposalGeneratorFactory,
    ReferenceSourceDocumentFileReaderService? sourceDocumentFileReaderService,
    ProjectReferenceExtractionMountService? mountService,
    ReferenceSourceLanguageHintService? sourceLanguageHintService,
    ReferenceExtractionContinuousTaskSyncService? continuousTaskSyncService,
    ProjectReferenceContinuityBridgeService? referenceContinuityBridgeService,
    ProjectReferenceMountOutcomeResolverService? mountOutcomeResolverService,
  }) : _pathService = pathService ?? ProjectReferenceExtractionPathService(),
       _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy(),
       _agentContextService = ProjectReferenceExtractionAgentContextService(
         loadAvailableAgents: loadAvailableAgents,
         loadAvailableGroups: loadAvailableGroups,
         groupBindingRepository: groupBindingRepository,
       ),
       _sourceDocumentFileReaderService =
           sourceDocumentFileReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _mountService =
           mountService ??
           ProjectReferenceExtractionMountService(
             workspacePort: workspacePort,
             toolPathPolicy: toolPathPolicy,
             mountOutcomeResolverService: mountOutcomeResolverService,
           ),
       _sourceLanguageHintService =
           sourceLanguageHintService ??
           const ReferenceSourceLanguageHintService(),
       _continuousTaskSyncService = continuousTaskSyncService,
       _referenceContinuityBridgeService =
           referenceContinuityBridgeService ??
           ProjectReferenceContinuityBridgeService(
             pathService:
                 pathService ?? ProjectReferenceExtractionPathService(),
           ),
       _mountOutcomeResolverService =
           mountOutcomeResolverService ??
           const ProjectReferenceMountOutcomeResolverService(),
       _proposalGeneratorFactory =
           proposalGeneratorFactory ?? _defaultProposalGeneratorFactory;

  final ProjectReferenceExtractionPathService _pathService;
  final ProjectToolPathPolicy _toolPathPolicy;
  final ProjectReferenceExtractionAgentContextService _agentContextService;
  final ReferenceSourceDocumentFileReaderService
  _sourceDocumentFileReaderService;
  final ProjectReferenceExtractionMountService _mountService;
  final ReferenceSourceLanguageHintService _sourceLanguageHintService;
  final ReferenceExtractionContinuousTaskSyncService?
  _continuousTaskSyncService;
  final ProjectReferenceContinuityBridgeService
  _referenceContinuityBridgeService;
  final ProjectReferenceMountOutcomeResolverService
  _mountOutcomeResolverService;
  final ReferenceExtractionProposalGeneratorFactory _proposalGeneratorFactory;

  Future<ProjectReferenceExtractionResult> execute({
    required ProjectDescriptor project,
    required LlmGateway llmGateway,
    required String modelId,
    required ProjectReferenceExtractionRequest request,
  }) async {
    final now = DateTime.now();
    final runId = request.runId.trim().isEmpty
        ? 'reference_extraction_${now.microsecondsSinceEpoch}'
        : request.runId.trim();
    final stagingWorkspace = FileReferenceExtractionStagingWorkspace(
      stagingRootPath: _pathService.stagingRootPath(project),
    );
    final existingRun = await stagingWorkspace.readRun(runId);
    final sourceDocument = await _sourceDocumentFileReaderService.read(
      sourceFilePath: request.sourceFilePath,
    );
    final sourceTitle = sourceDocument.sourceTitle;
    final sourceLanguage = request.sourceLanguage.trim().isNotEmpty
        ? request.sourceLanguage.trim()
        : _sourceLanguageHintService.infer(
            sourceFilePath: request.sourceFilePath,
            sourceTitle: sourceTitle,
            sourceText: sourceDocument.sourceText,
          );
    final packageId = _resolvePackageId(
      sourceTitle,
      request.packageId,
      now,
      existingRun: existingRun,
    );
    final packageVersionId = _resolvePackageVersionId(
      request.packageVersionId,
      now,
      existingRun: existingRun,
    );
    final versionLabel = request.versionLabel.trim().isEmpty
        ? _resolveVersionLabel(packageVersionId, existingRun: existingRun)
        : request.versionLabel.trim();
    final displayName = request.displayName.trim().isEmpty
        ? _resolveDisplayName(sourceTitle, existingRun: existingRun)
        : request.displayName.trim();
    final createdBy = request.createdBy.trim().isEmpty
        ? _resolveCreatedBy(existingRun: existingRun)
        : request.createdBy.trim();

    await _continuousTaskSyncService?.trackExecutionStart(
      project: project,
      request: request,
      runId: runId,
      displayName: displayName,
      sourceFilePath: sourceDocument.sourceFilePath,
    );

    final substrate = SqliteReferenceEvidenceSubstrate(
      substrateRootPath: _pathService.substrateRootPath(project),
    );
    final proposalGenerator = _proposalGeneratorFactory(
      llmGateway: llmGateway,
      modelId: modelId,
    );
    final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
      substrate: substrate,
      stagingWorkspace: stagingWorkspace,
      proposalGenerator: proposalGenerator,
    );
    final agentContext = await _agentContextService.build(project);
    late final ReferenceExtractionRunResult runResult;
    try {
      runResult = await useCase.execute(
        ReferenceExtractionRunRequest(
          runId: runId,
          sourceDocumentRequest: ReferenceSourceDocumentIngestionRequest(
            sourceText: sourceDocument.sourceText,
            sourceTitle: sourceTitle,
            sourceRef: sourceDocument.sourceFilePath,
            packageId: packageId,
            packageKind: request.packageKind,
            displayName: displayName,
            packageNamespace: request.packageNamespace,
            packageVersionId: packageVersionId,
            versionLabel: versionLabel,
            createdAt: now.toIso8601String(),
            createdBy: createdBy,
            sourceLanguage: sourceLanguage,
            targetLanguage: request.targetLanguage,
            maxChapterEntries: request.maxChapterEntries,
            maxEntityEntries: request.maxEntityEntries,
          ),
          finalizedAt: now.toIso8601String(),
          finalizedBy: createdBy,
          finalizedPackageVersionId: packageVersionId,
          finalizedVersionLabel: versionLabel,
          groupSelections: agentContext.selections,
          groupAssessments: agentContext.groupAssessments,
          agentAssessments: agentContext.agentAssessments,
          strategyProfileId: request.strategyProfileId,
          availableContextChars: request.availableContextChars,
          additionalStrategyProfiles: request.additionalStrategyProfiles,
        ),
      );
    } catch (error) {
      await _continuousTaskSyncService?.syncExecutionFailure(
        project: project,
        request: request,
        runId: runId,
        displayName: displayName,
        sourceFilePath: sourceDocument.sourceFilePath,
        error: error,
      );
      rethrow;
    }
    final deliveryDecision = runResult.deliveryDecision;
    final publishable = deliveryDecision.isPublishable;
    final continuityLedger = await _referenceContinuityBridgeService
        .ensureLedger(
          substrate: substrate,
          packageId: packageId,
          packageVersionId: packageVersionId,
          updatedAt: now.toIso8601String(),
          metadata: <String, Object?>{
            'source': 'project_reference_extraction_runtime',
            'run_id': runId,
          },
        );

    var bundleOutputDirectory = '';
    if (request.exportBundle &&
        publishable &&
        runResult.finalizedSnapshot != null) {
      bundleOutputDirectory = request.bundleOutputDirectory.trim().isEmpty
          ? _pathService.bundleRootPath(
              project,
              packageId: packageId,
              packageVersionId: packageVersionId,
            )
          : request.bundleOutputDirectory.trim();
      final exportService = ReferenceBundleExportService(substrate: substrate);
      await exportService.exportToDirectory(
        bundleOutputDirectory,
        ReferenceBundleExportRequest(
          packageId: packageId,
          packageVersionId: packageVersionId,
          bundleId: '${packageId}_$packageVersionId',
          createdAt: now.toIso8601String(),
          createdBy: createdBy,
        ),
      );
    }

    final mountOutcome = await _resolveMountOutcome(
      project: project,
      packageId: packageId,
      packageVersionId: packageVersionId,
      displayName: displayName,
      attachedAt: now.toIso8601String(),
      request: request,
      substrate: substrate,
      publishedSnapshotAvailable:
          publishable && runResult.finalizedSnapshot != null,
    );
    final acceptedProposalCount =
        runResult.reviewOutcome.acceptedProposalIds.length;
    final persistedBatchState = await substrate.readBatchExecutionState(
      packageId: packageId,
      packageVersionId: packageVersionId,
    );
    final batchState = persistedBatchState;
    final batchPlan = batchState?.batchPlan ?? runResult.stagingRun.batchPlan;
    final batchProgress =
        batchState?.batchProgress ?? runResult.stagingRun.batchProgress;
    final coverageState = batchState?.coverageState;
    final coverageLedger =
        batchState?.coverageLedger ?? runResult.reviewOutcome.coverageLedger;
    final executionDiscipline = runResult.stagingRun.executionDiscipline;
    final stagingRunPath = <String>[
      _pathService.stagingRootPath(project),
      '${_toolPathPolicy.safeFileName(runId, fallback: 'reference_extraction_run', maxLength: 96)}.json',
    ].join(Platform.pathSeparator);
    final result = ProjectReferenceExtractionResult(
      runId: runId,
      packageId: packageId,
      packageVersionId: packageVersionId,
      sourceFilePath: sourceDocument.sourceFilePath,
      sourceDecodeMode: sourceDocument.decodeMode,
      groupResolutionKind: runResult.groupResolution.resolutionKind,
      selectedGroupId: runResult.groupResolution.selectedGroup.id,
      strategyProfileId:
          runResult.groupResolution.executionProfile.strategyProfile.profileId,
      executionConcurrencyMode: executionDiscipline.concurrencyMode,
      executionMaxConcurrentBatches: executionDiscipline.maxConcurrentBatches,
      allowParallelHeavyTextConsumption:
          executionDiscipline.allowParallelHeavyTextConsumption,
      proposalCount: runResult.stagingRun.proposals.length,
      acceptedProposalCount: acceptedProposalCount,
      finalizedEntryCount: runResult.finalizedSnapshot?.entries.length ?? 0,
      batchCount: batchPlan?.batches.length ?? 0,
      batchCoverageRatio: batchProgress?.coverageRatio ?? 0,
      batchPlanningMode:
          batchPlan?.planningMode ??
          ReferenceSourceBatchPlanningModes.structureFirst,
      batchGoalKind:
          batchPlan?.batchGoalKind ??
          ReferenceBatchGoalKinds.semanticExtraction,
      batchStructureMode: batchPlan?.structureMode ?? '',
      batchTargetSourceChars:
          batchPlan?.budgetResolution.targetSourceChars ?? 0,
      batchMaxSourceChars: batchPlan?.budgetResolution.maxSourceChars ?? 0,
      availableContextChars:
          batchPlan?.budgetResolution.availableContextChars ??
          request.availableContextChars,
      completedBatchCount: batchProgress?.completedBatchCount ?? 0,
      failedBatchCount: batchProgress?.failedBatchCount ?? 0,
      pendingBatchCount: batchProgress?.pendingBatchCount ?? 0,
      runStatus: runResult.stagingRun.runStatus,
      continuationRoundCount: runResult.stagingRun.continuationContexts.length,
      deliveryStatus: deliveryDecision.deliveryStatus,
      deliveryRationale: deliveryDecision.rationale,
      outputCompletionStatus: runResult.reviewOutcome.outputCompletionStatus,
      outputCompressionRiskLevel:
          runResult.reviewOutcome.outputCompressionRisk.level,
      needsContinuation: runResult.reviewOutcome.needsContinuation,
      omissionReportCount: runResult.reviewOutcome.omissionReports.length,
      continuationRequestCount:
          runResult.reviewOutcome.continuationRequests.length,
      uncoveredCoverageDimensionIds:
          coverageState?.uncoveredDimensionIds ??
          coverageLedger?.uncoveredDimensionIds ??
          const <String>[],
      coveredCoverageDimensionIds:
          coverageState?.coveredDimensionIds ??
          coverageLedger?.dimensions
              .where(
                (dimension) =>
                    dimension.status == OutputCoverageStatuses.covered,
              )
              .map((dimension) => dimension.dimensionId)
              .toList(growable: false) ??
          const <String>[],
      followupSegmentIds:
          coverageState?.requiresFollowupSegmentIds ?? const <String>[],
      coverageRequiresFollowup: coverageState?.requiresFollowup ?? false,
      conflictClusterCount: continuityLedger.conflictClusters.length,
      canonDecisionCount: continuityLedger.canonDecisions.length,
      reviewAlertCount: continuityLedger.reviewAlerts.length,
      requiresManualContinuityReview: continuityLedger.reviewAlerts.any(
        (alert) => alert.requiresManualReview,
      ),
      unresolvedConflictCount: continuityLedger.conflictClusters
          .where(
            (cluster) =>
                cluster.clusterStatus ==
                NarrativeConflictClusterStatuses.needsDecision,
          )
          .length,
      publishedSnapshotAvailable:
          publishable && runResult.finalizedSnapshot != null,
      attachToProjectRequested: request.attachToProject,
      projectMountedEntriesRequested: request.projectMountedEntries,
      projectMountStatus: mountOutcome.status,
      projectMountWarningCodes: List<String>.from(mountOutcome.warningCodes),
      bundleOutputDirectory: bundleOutputDirectory,
      stagingRunPath: stagingRunPath,
      knowledgeCardIds: mountOutcome.knowledgeCardIds,
      designElementIds: mountOutcome.designElementIds,
      researchNoteIds: mountOutcome.researchNoteIds,
      referenceWorkIds: mountOutcome.referenceWorkIds,
      generatedProjectionPaths: mountOutcome.generatedProjectionPaths,
    );
    await _continuousTaskSyncService?.syncExecutionResult(
      project: project,
      result: result,
    );
    return result;
  }

  Future<ProjectReferenceMountOutcome> _resolveMountOutcome({
    required ProjectDescriptor project,
    required String packageId,
    required String packageVersionId,
    required String displayName,
    required String attachedAt,
    required ProjectReferenceExtractionRequest request,
    required ReferenceEvidenceSubstrate substrate,
    required bool publishedSnapshotAvailable,
  }) async {
    // 中文注释: runtime 只负责决定“本轮是否具备 publishable snapshot”，真正的挂载结果语义统一交给共享 mount outcome 合同解释。
    if (!publishedSnapshotAvailable) {
      return _mountOutcomeResolverService.resolve(
        request: request,
        publishedSnapshotAvailable: false,
      );
    }
    return _mountService.attachAndProjectIfRequested(
      project: project,
      substrate: substrate,
      request: request,
      packageId: packageId,
      packageVersionId: packageVersionId,
      displayName: displayName,
      attachedAt: attachedAt,
    );
  }

  String _resolvePackageId(
    String sourceTitle,
    String explicitValue,
    DateTime now, {
    ReferenceExtractionStagingRun? existingRun,
  }) {
    final trimmed = explicitValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final stagedValue = existingRun?.packageId.trim() ?? '';
    if (stagedValue.isNotEmpty) {
      return stagedValue;
    }
    final dotIndex = sourceTitle.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? sourceTitle.substring(0, dotIndex)
        : sourceTitle;
    final safeBaseName = _toolPathPolicy.safeFileName(
      baseName,
      fallback: 'reference_source',
      maxLength: 48,
    );
    return 'ref_${safeBaseName}_${now.microsecondsSinceEpoch}';
  }

  String _resolvePackageVersionId(
    String explicitValue,
    DateTime now, {
    ReferenceExtractionStagingRun? existingRun,
  }) {
    final trimmed = explicitValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final stagedValue = existingRun?.packageVersionId.trim() ?? '';
    if (stagedValue.isNotEmpty) {
      return stagedValue;
    }
    final compact = now
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
    return 'v_$compact';
  }

  String _resolveVersionLabel(
    String packageVersionId, {
    ReferenceExtractionStagingRun? existingRun,
  }) {
    final stagedValue =
        existingRun?.finalizedSnapshot?.packageVersionRecord.versionLabel
            .trim() ??
        existingRun?.seedSnapshot.packageVersionRecord.versionLabel.trim() ??
        '';
    return stagedValue.isEmpty ? packageVersionId : stagedValue;
  }

  String _resolveDisplayName(
    String sourceTitle, {
    ReferenceExtractionStagingRun? existingRun,
  }) {
    final stagedValue =
        existingRun?.finalizedSnapshot?.packageRecord.displayName.trim() ??
        existingRun?.seedSnapshot.packageRecord.displayName.trim() ??
        '';
    if (stagedValue.isNotEmpty) {
      return stagedValue;
    }
    return '参考资产提取：$sourceTitle';
  }

  String _resolveCreatedBy({ReferenceExtractionStagingRun? existingRun}) {
    final stagedValue =
        existingRun?.finalizedSnapshot?.packageVersionRecord.createdBy.trim() ??
        existingRun?.seedSnapshot.packageVersionRecord.createdBy.trim() ??
        '';
    return stagedValue.isEmpty
        ? 'project_reference_extraction_runtime_service'
        : stagedValue;
  }
}

ReferenceExtractionProposalGenerator _defaultProposalGeneratorFactory({
  required LlmGateway llmGateway,
  required String modelId,
}) {
  return LlmReferenceExtractionProposalGenerator(
    llmGateway: llmGateway,
    modelId: modelId,
  );
}
