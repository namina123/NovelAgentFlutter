import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_constraint_binding_repository.dart';
import '../storage/local_narrative_claim_repository.dart';
import '../storage/local_narrative_ledger_repository.dart';
import '../storage/local_narrative_profile_repository.dart';
import '../storage/local_semantic_review_repository.dart';
import '../storage/open_narrative_state_path_service.dart';
import '../storage/open_narrative_state_projection_writer_service.dart';
import '../storage/open_narrative_state_record_document_service.dart';
import '../storage/project_task_repository.dart';
import 'project_chapter_length_delivery_guard_service.dart';
import 'project_chapter_opening_continuity_guard_service.dart';
import 'project_tool_path_policy.dart';

class ProjectNarrativeDomainToolExecutor {
  ProjectNarrativeDomainToolExecutor({
    required ProjectWorkspacePort workspacePort,
    required ProjectToolHostPort hostPort,
    NarrativeDomainToolDispatcher? dispatcher,
    NarrativeClaimRepository? claimRepository,
    NarrativeProfileRepository? profileRepository,
    SemanticReviewRepository? reviewRepository,
    ConstraintBindingRepository? bindingRepository,
    OpenNarrativeStateProjectionWriterService? projectionWriterService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    OpenNarrativeStatePathService? pathService,
    ProjectToolPathPolicy? pathPolicy,
    ProjectTaskRepository? taskRepository,
    ChapterOutputPathPolicyService? chapterOutputPathPolicyService,
    ProjectChapterLengthDeliveryGuardService? chapterLengthDeliveryGuardService,
    ProjectChapterOpeningContinuityGuardService?
    chapterOpeningContinuityGuardService,
    NarrativeStateClaimCodecService? claimCodecService,
    NarrativeProfileCodecService? profileCodecService,
    NarrativeConstraintBindingCodecService? bindingCodecService,
  }) : _hostPort = hostPort,
       _dispatcher =
           dispatcher ??
           NarrativeDomainToolDispatchService(
             handlers: <NarrativeDomainToolHandler>[
               SubmitChapterDeliveryHandler(),
               const SubmitNarrativeStateClaimsHandler(),
               const ProposeNarrativeProfileUpdateHandler(),
               const SubmitSemanticReviewHandler(),
               const ProposeConstraintBindingHandler(),
               const RequestProfileClarificationHandler(),
             ],
           ),
       _claimRepository =
           claimRepository ??
           LocalNarrativeClaimRepository(workspacePort: workspacePort),
       _reviewRepository =
           reviewRepository ??
           LocalSemanticReviewRepository(workspacePort: workspacePort),
       _bindingRepository =
           bindingRepository ??
           LocalConstraintBindingRepository(workspacePort: workspacePort),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _chapterOutputPathPolicyService =
           chapterOutputPathPolicyService ??
           const ChapterOutputPathPolicyService(),
       _chapterLengthDeliveryGuardService =
           chapterLengthDeliveryGuardService ??
           ProjectChapterLengthDeliveryGuardService(
             taskRepository:
                 taskRepository ??
                 ProjectTaskRepository(workspacePort: workspacePort),
           ),
       _chapterOpeningContinuityGuardService =
           chapterOpeningContinuityGuardService ??
           ProjectChapterOpeningContinuityGuardService(
             workspacePort: workspacePort,
           ),
       _claimCodecService =
           claimCodecService ?? const NarrativeStateClaimCodecService(),
       _profileCodecService =
           profileCodecService ?? const NarrativeProfileCodecService(),
       _bindingCodecService =
           bindingCodecService ??
           const NarrativeConstraintBindingCodecService(),
       _projectionWriterService =
           projectionWriterService ??
           OpenNarrativeStateProjectionWriterService(
             workspacePort: workspacePort,
             profileRepository:
                 profileRepository ??
                 LocalNarrativeProfileRepository(workspacePort: workspacePort),
             claimRepository:
                 claimRepository ??
                 LocalNarrativeClaimRepository(workspacePort: workspacePort),
             ledgerRepository: LocalNarrativeLedgerRepository(
               workspacePort: workspacePort,
             ),
             reviewRepository:
                 reviewRepository ??
                 LocalSemanticReviewRepository(workspacePort: workspacePort),
             bindingRepository:
                 bindingRepository ??
                 LocalConstraintBindingRepository(workspacePort: workspacePort),
           );

  final ProjectToolHostPort _hostPort;
  final NarrativeDomainToolDispatcher _dispatcher;
  final NarrativeClaimRepository _claimRepository;
  final SemanticReviewRepository _reviewRepository;
  final ConstraintBindingRepository _bindingRepository;
  final OpenNarrativeStateProjectionWriterService _projectionWriterService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final ProjectToolPathPolicy _pathPolicy;
  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;
  final ProjectChapterLengthDeliveryGuardService
  _chapterLengthDeliveryGuardService;
  final ProjectChapterOpeningContinuityGuardService
  _chapterOpeningContinuityGuardService;
  final NarrativeStateClaimCodecService _claimCodecService;
  final NarrativeProfileCodecService _profileCodecService;
  final NarrativeConstraintBindingCodecService _bindingCodecService;

  Future<DomainToolOutcome> execute(
    ProjectDescriptor project,
    DomainToolRequest request,
  ) async {
    var outcome = await _dispatcher.dispatch(request: request);
    outcome = await _applySharedChapterContinuityGuard(
      project: project,
      request: request,
      outcome: outcome,
    );
    outcome = await _applySharedChapterLengthGuard(
      project: project,
      request: request,
      outcome: outcome,
    );
    if (!_shouldPersistOutcome(outcome)) {
      return outcome;
    }
    final changedPaths = <String>[];
    try {
      switch (request.toolName) {
        case NarrativeDomainToolNames.submitChapterDelivery:
          await _persistChapterDelivery(
            project,
            request,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.submitNarrativeStateClaims:
          await _persistClaims(project, outcome, changedPaths);
          break;
        case NarrativeDomainToolNames.proposeNarrativeProfileUpdate:
          await _persistProfileProposal(
            project,
            request,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.submitSemanticReview:
          await _persistSemanticReview(project, outcome, changedPaths);
          break;
        case NarrativeDomainToolNames.proposeConstraintBinding:
          await _persistConstraintBinding(project, outcome, changedPaths);
          break;
        case NarrativeDomainToolNames.requestProfileClarification:
          await _persistClarification(project, request, outcome, changedPaths);
          break;
      }
      return _withPersistenceMetadata(outcome, changedPaths);
    } catch (error) {
      return _persistenceFailureOutcome(
        request: request,
        originalOutcome: outcome,
        error: error,
        changedPaths: changedPaths,
      );
    }
  }

  Future<DomainToolOutcome> _applySharedChapterContinuityGuard({
    required ProjectDescriptor project,
    required DomainToolRequest request,
    required DomainToolOutcome outcome,
  }) async {
    if (request.toolName != NarrativeDomainToolNames.submitChapterDelivery ||
        outcome.outcomeStatus != DomainToolOutcomeStatuses.accepted) {
      return outcome;
    }
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    final stateResult = ValueReaders.mapValue(payload['state_result']);
    if (!ValueReaders.boolValue(stateResult['chapter_body_delivered'])) {
      return outcome;
    }
    final chapterPath = ValueReaders.stringValue(
      payload['chapter_path'],
    ).trim();
    final chapterContent = ValueReaders.stringValue(
      request.requestPayload['chapter_content'],
    );
    if (chapterPath.isEmpty || chapterContent.trim().isEmpty) {
      return outcome;
    }
    final guardResult = await _chapterOpeningContinuityGuardService.evaluate(
      project: project,
      chapterPath: chapterPath,
      chapterContent: chapterContent,
    );
    if (!guardResult.blocked) {
      return outcome;
    }
    return outcome.copyWith(
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      error: DomainToolError(
        errorCode: guardResult.reason,
        message: guardResult.summary,
        retryable: false,
        errorDetails: <String, Object?>{
          'chapter_path': chapterPath,
          'opening_excerpt': guardResult.openingExcerpt,
          'previous_excerpt': guardResult.previousExcerpt,
          'longest_common_span': guardResult.longestCommonSpan,
          'opening_coverage': guardResult.openingCoverage,
          'previous_coverage': guardResult.previousCoverage,
          'replayed_clauses': guardResult.replayedClauses,
          'replayed_action_anchors': guardResult.replayedActionAnchors,
        },
      ),
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...outcome.metadata,
        'continuity_guard': <String, Object?>{
          'blocked': true,
          'reason': guardResult.reason,
          'summary': guardResult.summary,
        },
      }),
    );
  }

  Future<DomainToolOutcome> _applySharedChapterLengthGuard({
    required ProjectDescriptor project,
    required DomainToolRequest request,
    required DomainToolOutcome outcome,
  }) async {
    if (request.toolName != NarrativeDomainToolNames.submitChapterDelivery ||
        outcome.outcomeStatus != DomainToolOutcomeStatuses.accepted) {
      return outcome;
    }
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    final stateResult = ValueReaders.mapValue(payload['state_result']);
    if (!ValueReaders.boolValue(stateResult['chapter_body_delivered'])) {
      return outcome;
    }
    final chapterPath = ValueReaders.stringValue(
      payload['chapter_path'],
    ).trim();
    final chapterContent = ValueReaders.stringValue(
      request.requestPayload['chapter_content'],
    );
    if (chapterPath.isEmpty || chapterContent.trim().isEmpty) {
      return outcome;
    }
    final guardResult = await _chapterLengthDeliveryGuardService.evaluate(
      project: project,
      chapterPath: chapterPath,
      chapterContent: chapterContent,
      metadata: ValueReaders.mapValue(request.requestPayload['metadata']),
    );
    if (!guardResult.blocked) {
      return outcome;
    }
    return outcome.copyWith(
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      error: DomainToolError(
        errorCode: guardResult.reason,
        message: guardResult.summary,
        retryable: false,
        errorDetails: <String, Object?>{
          'chapter_path': chapterPath,
          'measured_length': guardResult.measuredLength,
          'minimum_length': guardResult.minimumLength,
          'maximum_length': guardResult.maximumLength,
          'source': guardResult.source,
          'task_id': guardResult.taskId,
          'task_relative_path': guardResult.taskRelativePath,
        },
      ),
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...outcome.metadata,
        'chapter_length_guard': guardResult.toJson(),
      }),
    );
  }

  bool _shouldPersistOutcome(DomainToolOutcome outcome) {
    return outcome.outcomeStatus == DomainToolOutcomeStatuses.accepted ||
        outcome.outcomeStatus == DomainToolOutcomeStatuses.proposed ||
        outcome.outcomeStatus ==
            DomainToolOutcomeStatuses.needsUserConfirmation;
  }

  Future<void> _persistChapterDelivery(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    final stateResult = ValueReaders.mapValue(payload['state_result']);
    final chapterBodyDelivered = ValueReaders.boolValue(
      stateResult['chapter_body_delivered'],
    );
    if (!chapterBodyDelivered) {
      return;
    }
    final chapterPath = _validatedProjectPath(
      ValueReaders.stringValue(payload['chapter_path']),
      label: 'chapter_path',
    );
    final chapterContent = _chapterOutputPathPolicyService
        .normalizeChapterMarkdownHeading(
          chapterContent: ValueReaders.stringValue(
            request.requestPayload['chapter_content'],
          ),
          title: ValueReaders.stringValue(payload['title']),
        );
    if (chapterContent.trim().isEmpty) {
      throw StateError('章节结果声明已交付，但 chapter_content 为空。');
    }
    final rawChapterContent = ValueReaders.stringValue(
      request.requestPayload['chapter_content'],
    );
    if (rawChapterContent.trim().isEmpty) {
      throw StateError('章节结果声明已交付，但 chapter_content 为空。');
    }
    await _hostPort.writeTextFile(
      project.rootPath,
      chapterPath,
      chapterContent,
    );
    changedPaths.add(chapterPath);

    final submissionJson = ValueReaders.mapValue(payload['submission']);
    if (submissionJson.isEmpty) {
      return;
    }
    final deliveryId = ValueReaders.stringValue(payload['delivery_id']).trim();
    if (deliveryId.isEmpty) {
      throw StateError('submit_chapter_delivery 结果缺少 delivery_id。');
    }
    final recordPath = _pathService.deliveryPath(deliveryId);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: recordPath,
      document: <String, Object?>{
        'schema_version': request.schemaVersion,
        'delivery_id': deliveryId,
        'tool_name': request.toolName,
        'call_id': request.callId,
        'chapter_path': chapterPath,
        'submission': ValueReaders.deepCopyMap(submissionJson),
        'delivery_result': ValueReaders.deepCopyMap(payload),
        'tool_round_evidence': request.toolRoundEvidence?.toJson(),
        'persisted_at': DateTime.now().toIso8601String(),
        'metadata': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(request.requestPayload['metadata']),
        ),
      },
      indexPath: _pathService.deliveriesIndexPath(),
      fieldName: 'delivery_ids',
      recordId: deliveryId,
    );
    changedPaths
      ..add(recordPath)
      ..add(_pathService.deliveriesIndexPath());
    final submissionClaims = ValueReaders.mapList(submissionJson['claims'])
        .map(
          (entry) => _claimCodecService.fromJson(ValueReaders.mapValue(entry)),
        )
        .where((claim) => claim.validateBasics().isEmpty)
        .toList(growable: false);
    if (submissionClaims.isEmpty) {
      return;
    }
    for (final claim in submissionClaims) {
      await _claimRepository.appendClaim(project, claim);
    }
    changedPaths.add(_pathService.claimsLogPath());
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistClaims(
    ProjectDescriptor project,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final claims = ValueReaders.mapList(outcome.outcomePayload['claims'])
        .map(
          (entry) => _claimCodecService.fromJson(ValueReaders.mapValue(entry)),
        )
        .toList(growable: false);
    for (final claim in claims) {
      await _claimRepository.appendClaim(project, claim);
    }
    if (claims.isEmpty) {
      return;
    }
    changedPaths.add(_pathService.claimsLogPath());
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistProfileProposal(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final proposalJson = ValueReaders.mapValue(
      outcome.outcomePayload['proposal'],
    );
    if (proposalJson.isEmpty) {
      return;
    }
    final proposal = _profileCodecService.proposalFromJson(proposalJson);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: _pathService.profileProposalPath(proposal.proposalId),
      document: <String, Object?>{
        'schema_version': request.schemaVersion,
        'proposal': proposal.toJson(),
        'tool_name': request.toolName,
        'call_id': request.callId,
        'outcome_status': outcome.outcomeStatus,
        'permission_decision': outcome.permissionDecision?.toJson(),
        'tool_round_evidence': request.toolRoundEvidence?.toJson(),
        'persisted_at': DateTime.now().toIso8601String(),
      },
      indexPath: _pathService.profileProposalsIndexPath(),
      fieldName: 'proposal_ids',
      recordId: proposal.proposalId,
    );
    changedPaths
      ..add(_pathService.profileProposalPath(proposal.proposalId))
      ..add(_pathService.profileProposalsIndexPath());
  }

  Future<void> _persistSemanticReview(
    ProjectDescriptor project,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final reviewJson = ValueReaders.mapValue(outcome.outcomePayload['review']);
    if (reviewJson.isEmpty) {
      return;
    }
    final review = NarrativeSemanticReview.fromJson(reviewJson);
    await _reviewRepository.appendReview(project, review);
    changedPaths
      ..add(_pathService.reviewPath(review.reviewId))
      ..add(_pathService.reviewsIndexPath());
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistConstraintBinding(
    ProjectDescriptor project,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final bindingJson = ValueReaders.mapValue(
      outcome.outcomePayload['binding_proposal'],
    );
    if (bindingJson.isEmpty) {
      return;
    }
    final binding = _bindingCodecService.proposalFromJson(bindingJson);
    await _bindingRepository.appendBinding(project, binding);
    changedPaths
      ..add(_pathService.bindingPath(binding.bindingId))
      ..add(_pathService.bindingsIndexPath());
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistClarification(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final clarificationJson = ValueReaders.mapValue(
      outcome.outcomePayload['clarification_request'],
    );
    if (clarificationJson.isEmpty) {
      return;
    }
    final clarification = ProfileClarificationRequest.fromJson(
      clarificationJson,
    );
    final requestId = 'clarification_${request.callId}';
    final recordPath = _pathService.clarificationRequestPath(requestId);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: recordPath,
      document: <String, Object?>{
        'schema_version': request.schemaVersion,
        'request_id': requestId,
        'tool_name': request.toolName,
        'call_id': request.callId,
        'clarification_request': clarification.toJson(),
        'outcome_status': outcome.outcomeStatus,
        'permission_decision': outcome.permissionDecision?.toJson(),
        'tool_round_evidence': request.toolRoundEvidence?.toJson(),
        'persisted_at': DateTime.now().toIso8601String(),
      },
      indexPath: _pathService.clarificationRequestsIndexPath(),
      fieldName: 'clarification_request_ids',
      recordId: requestId,
    );
    changedPaths
      ..add(recordPath)
      ..add(_pathService.clarificationRequestsIndexPath());
  }

  Future<void> _appendProjectionPaths(
    ProjectDescriptor project,
    List<String> changedPaths,
  ) async {
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((entry) => entry.relativePath));
  }

  DomainToolOutcome _withPersistenceMetadata(
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) {
    return outcome.copyWith(
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...outcome.metadata,
        'adapter_persistence': <String, Object?>{
          'changed_paths': changedPaths.toSet().toList(growable: false),
        },
      }),
    );
  }

  DomainToolOutcome _persistenceFailureOutcome({
    required DomainToolRequest request,
    required DomainToolOutcome originalOutcome,
    required Object error,
    required List<String> changedPaths,
  }) {
    return originalOutcome.copyWith(
      outcomeId: '${request.toolName}:${request.callId}:persistence_failed',
      outcomeStatus: DomainToolOutcomeStatuses.executionFailed,
      error: DomainToolError(
        errorCode: 'adapter_persistence_failed',
        message: '领域工具结果已生成，但本地持久化失败。',
        errorDetails: <String, Object?>{
          'original_outcome_status': originalOutcome.outcomeStatus,
          'changed_paths': changedPaths,
          'error': error.toString(),
        },
      ),
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...originalOutcome.metadata,
        'adapter_persistence': <String, Object?>{
          'changed_paths': changedPaths.toSet().toList(growable: false),
          'failed': true,
        },
      }),
    );
  }

  String _validatedProjectPath(String rawPath, {required String label}) {
    final cleanPath = _pathPolicy.cleanRelativePath(rawPath);
    if (!_pathPolicy.isSafeFilePath(cleanPath)) {
      throw StateError('$label 不在允许的项目路径范围内: $rawPath');
    }
    return cleanPath;
  }
}
