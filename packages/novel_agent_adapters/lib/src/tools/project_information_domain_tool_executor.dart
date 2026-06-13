import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_design_element_repository.dart';
import '../storage/local_information_event_repository.dart';
import '../storage/local_information_link_repository.dart';
import '../storage/local_knowledge_card_repository.dart';
import '../storage/local_reference_work_repository.dart';
import '../storage/local_research_note_repository.dart';
import '../storage/open_narrative_state_record_document_service.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_information_projection_writer_service.dart';
import 'project_information_research_coordinator_result.dart';
import 'project_information_research_coordinator_service.dart';
import 'project_information_research_execution_budget.dart';

class ProjectInformationDomainToolExecutor {
  ProjectInformationDomainToolExecutor({
    required ProjectWorkspacePort workspacePort,
    NarrativeDomainToolDispatcher? dispatcher,
    HostInformationPermissionResolverService? hostPermissionResolverService,
    KnowledgeCardRepository? knowledgeCardRepository,
    DesignElementRepository? designElementRepository,
    ResearchNoteRepository? researchNoteRepository,
    ReferenceWorkRepository? referenceWorkRepository,
    InformationLinkRepository? informationLinkRepository,
    InformationEventRepository? informationEventRepository,
    ProjectInformationProjectionWriterService? projectionWriterService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    ProjectInformationPathService? pathService,
    ProjectInformationResearchCoordinatorService? researchCoordinatorService,
    ProjectInformationResearchExecutionBudget researchExecutionBudget =
        const ProjectInformationResearchExecutionBudget(
          allowGatewayExecution: true,
        ),
  }) : _dispatcher =
           dispatcher ??
           NarrativeDomainToolDispatchService(
             handlers: <NarrativeDomainToolHandler>[
               const RequestExternalResearchHandler(),
               const SubmitResearchNoteHandler(),
               const ProposeKnowledgeCardHandler(),
               const ProposeDesignElementHandler(),
               const LinkInformationEvidenceHandler(),
               const ProposeReferenceWorkHandler(),
             ],
           ),
       _hostPermissionResolverService =
           hostPermissionResolverService ??
           const HostInformationPermissionResolverService(),
       _knowledgeCardRepository =
           knowledgeCardRepository ??
           LocalKnowledgeCardRepository(workspacePort: workspacePort),
       _designElementRepository =
           designElementRepository ??
           LocalDesignElementRepository(workspacePort: workspacePort),
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _referenceWorkRepository =
           referenceWorkRepository ??
           LocalReferenceWorkRepository(workspacePort: workspacePort),
       _informationLinkRepository =
           informationLinkRepository ??
           LocalInformationLinkRepository(workspacePort: workspacePort),
       _informationEventRepository =
           informationEventRepository ??
           LocalInformationEventRepository(workspacePort: workspacePort),
       _projectionWriterService =
           projectionWriterService ??
           ProjectInformationProjectionWriterService(
             workspacePort: workspacePort,
             knowledgeCardRepository:
                 knowledgeCardRepository ??
                 LocalKnowledgeCardRepository(workspacePort: workspacePort),
             designElementRepository:
                 designElementRepository ??
                 LocalDesignElementRepository(workspacePort: workspacePort),
             researchNoteRepository:
                 researchNoteRepository ??
                 LocalResearchNoteRepository(workspacePort: workspacePort),
             referenceWorkRepository:
                 referenceWorkRepository ??
                 LocalReferenceWorkRepository(workspacePort: workspacePort),
           ),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _pathService = pathService ?? ProjectInformationPathService(),
       _researchCoordinatorService =
           researchCoordinatorService ??
           ProjectInformationResearchCoordinatorService(
             workspacePort: workspacePort,
           ),
       _researchExecutionBudget = researchExecutionBudget;

  final NarrativeDomainToolDispatcher _dispatcher;
  final HostInformationPermissionResolverService
  _hostPermissionResolverService;
  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ReferenceWorkRepository _referenceWorkRepository;
  final InformationLinkRepository _informationLinkRepository;
  final InformationEventRepository _informationEventRepository;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final ProjectInformationPathService _pathService;
  final ProjectInformationResearchCoordinatorService _researchCoordinatorService;
  final ProjectInformationResearchExecutionBudget _researchExecutionBudget;

  Future<DomainToolOutcome> execute(
    ProjectDescriptor project,
    DomainToolRequest request,
    {HostInformationPermissionContext? hostPermissionContext}
  ) async {
    final effectiveRequest = _resolveEffectiveRequest(
      request,
      hostPermissionContext: hostPermissionContext,
    );
    final outcome = await _dispatcher.dispatch(request: effectiveRequest);
    if (!_shouldPersistOutcome(outcome)) {
      return outcome;
    }
    final changedPaths = <String>[];
    var persistedOutcome = outcome;
    try {
      switch (effectiveRequest.toolName) {
        case NarrativeDomainToolNames.requestExternalResearch:
          persistedOutcome = await _persistResearchRequest(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
            hostPermissionContext: hostPermissionContext,
          );
          break;
        case NarrativeDomainToolNames.submitResearchNote:
          await _persistResearchNote(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.proposeKnowledgeCard:
          await _persistKnowledgeCard(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.proposeDesignElement:
          await _persistDesignElement(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.linkInformationEvidence:
          await _persistInformationLink(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
          );
          break;
        case NarrativeDomainToolNames.proposeReferenceWork:
          await _persistReferenceWork(
            project,
            effectiveRequest,
            outcome,
            changedPaths,
          );
          break;
      }
      return _withPersistenceMetadata(persistedOutcome, changedPaths);
    } catch (error) {
      return _persistenceFailureOutcome(
        request: effectiveRequest,
        originalOutcome: persistedOutcome,
        error: error,
        changedPaths: changedPaths,
      );
    }
  }

  DomainToolRequest _resolveEffectiveRequest(
    DomainToolRequest request, {
    HostInformationPermissionContext? hostPermissionContext,
  }) {
    if (hostPermissionContext == null ||
        request.toolName != NarrativeDomainToolNames.requestExternalResearch) {
      return request;
    }
    final payload = ValueReaders.deepCopyMap(request.requestPayload);
    if (request.targetRefs.isNotEmpty &&
        ValueReaders.objectList(payload['target_refs']).isEmpty) {
      payload['target_refs'] = request.targetRefs
          .map((entry) => entry.toJson())
          .toList(growable: false);
    }
    final resolution = _hostPermissionResolverService.resolve(
      request: InformationCollectionRequest.fromJson(payload),
      hostContext: hostPermissionContext,
    );
    return request.copyWith(requestPayload: resolution.effectiveRequest.toJson());
  }

  bool _shouldPersistOutcome(DomainToolOutcome outcome) {
    return outcome.outcomeStatus == DomainToolOutcomeStatuses.accepted ||
        outcome.outcomeStatus == DomainToolOutcomeStatuses.proposed ||
        outcome.outcomeStatus ==
            DomainToolOutcomeStatuses.needsUserConfirmation;
  }

  Future<DomainToolOutcome> _persistResearchRequest(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths, {
    HostInformationPermissionContext? hostPermissionContext,
  }
  ) async {
    final researchRequest = ValueReaders.mapValue(
      outcome.outcomePayload['research_request'],
    );
    if (researchRequest.isEmpty) {
      return outcome;
    }
    final requestId = 'research_request_${request.callId}';
    final initialRequestState = _researchRequestState(outcome);
    final recordPath = _pathService.researchRequestPath(requestId);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: recordPath,
      document: <String, Object?>{
        'schema_version': request.schemaVersion,
        'request_id': requestId,
        'tool_name': request.toolName,
        'call_id': request.callId,
        'source': request.source.toJson(),
        'request_payload': ValueReaders.deepCopyMap(request.requestPayload),
        'target_refs': request.targetRefs
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'research_request': ValueReaders.deepCopyMap(researchRequest),
        'outcome_status': outcome.outcomeStatus,
        'permission_decision': outcome.permissionDecision?.toJson(),
        'tool_round_evidence': request.toolRoundEvidence?.toJson(),
        'request_state': initialRequestState,
        'network_execution_performed': false,
        'persisted_at': DateTime.now().toIso8601String(),
      },
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    changedPaths
      ..add(recordPath)
      ..add(_pathService.researchRequestsIndexPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.researchRequest,
        refId: requestId,
      ),
      summary: '已登记待研究请求：${ValueReaders.stringValue(researchRequest['query'])}',
    );
    var persistedOutcome = outcome.copyWith(
      outcomePayload: ValueReaders.deepCopyMap(<String, Object?>{
        ...outcome.outcomePayload,
        'request_id': requestId,
        'request_state': initialRequestState,
        'request_registered': true,
        'network_execution_performed': false,
        'import_execution_performed': false,
        'requires_user_confirmation':
            outcome.outcomeStatus ==
            DomainToolOutcomeStatuses.needsUserConfirmation,
      }),
    );
    if (hostPermissionContext == null) {
      return persistedOutcome;
    }
    final researchExecution = await _researchCoordinatorService.processPendingRequest(
      project,
      requestId: requestId,
      hostPermissionContext: hostPermissionContext,
      budget: _researchExecutionBudget,
    );
    changedPaths.addAll(researchExecution.changedPaths);
    return _withResearchExecutionOutcome(persistedOutcome, researchExecution);
  }

  Future<void> _persistResearchNote(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final noteJson = ValueReaders.mapValue(
      outcome.outcomePayload['research_note'],
    );
    if (noteJson.isEmpty) {
      return;
    }
    final note = ResearchNote.fromJson(noteJson);
    await _researchNoteRepository.appendResearchNote(project, note);
    changedPaths
      ..add(_pathService.researchNotePath(note.researchId))
      ..add(_pathService.researchNotesIndexPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.researchNote,
        refId: note.researchId,
      ),
      summary: '已登记研究笔记：${note.query}',
    );
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistKnowledgeCard(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final cardJson = ValueReaders.mapValue(
      outcome.outcomePayload['knowledge_card'],
    );
    if (cardJson.isEmpty) {
      return;
    }
    final card = ProjectKnowledgeCard.fromJson(
      cardJson,
    ).copyWith(lifecycleStatus: _recordLifecycleStatus(outcome.outcomeStatus));
    await _knowledgeCardRepository.appendKnowledgeCard(project, card);
    changedPaths
      ..add(_pathService.knowledgeCardPath(card.cardId))
      ..add(_pathService.knowledgeCardsIndexPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.knowledgeCard,
        refId: card.cardId,
      ),
      summary: '已登记知识卡：${card.title}',
    );
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistDesignElement(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final cardJson = ValueReaders.mapValue(
      outcome.outcomePayload['design_element'],
    );
    if (cardJson.isEmpty) {
      return;
    }
    final card = DesignElementCard.fromJson(
      cardJson,
    ).copyWith(lifecycleStatus: _recordLifecycleStatus(outcome.outcomeStatus));
    await _designElementRepository.appendDesignElement(project, card);
    changedPaths
      ..add(_pathService.designElementPath(card.designId))
      ..add(_pathService.designElementsIndexPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.designElement,
        refId: card.designId,
      ),
      summary: '已登记设计元素：${card.designLabel}',
    );
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistInformationLink(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final linkJson = ValueReaders.mapValue(
      outcome.outcomePayload['information_link'],
    );
    if (linkJson.isEmpty) {
      return;
    }
    final link = InformationLink.fromJson(linkJson);
    await _informationLinkRepository.appendInformationLink(project, link);
    changedPaths.add(_pathService.informationLinksLogPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: link.targetRef,
      summary: '已登记信息链路：${link.linkType}',
      relatedRefs: <NarrativeRef>[link.sourceRef],
      relatedLinkIds: <String>[link.linkId],
    );
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _persistReferenceWork(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) async {
    final recordJson = ValueReaders.mapValue(
      outcome.outcomePayload['reference_work'],
    );
    if (recordJson.isEmpty) {
      return;
    }
    final record = ReferenceWorkRecord.fromJson(recordJson);
    await _referenceWorkRepository.appendReferenceWork(project, record);
    changedPaths
      ..add(_pathService.referenceWorkPath(record.referenceWorkId))
      ..add(_pathService.referenceWorksIndexPath());
    await _appendInformationEvent(
      project,
      request,
      outcome,
      changedPaths,
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.referenceWork,
        refId: record.referenceWorkId,
      ),
      summary: '已登记引用作品边界：${record.title}',
    );
    await _appendProjectionPaths(project, changedPaths);
  }

  Future<void> _appendInformationEvent(
    ProjectDescriptor project,
    DomainToolRequest request,
    DomainToolOutcome outcome,
    List<String> changedPaths, {
    required NarrativeRef subjectRef,
    required String summary,
    List<NarrativeRef> relatedRefs = const <NarrativeRef>[],
    List<String> relatedLinkIds = const <String>[],
  }) async {
    final actorRef =
        request.toolRoundEvidence?.toolRoundRef ??
        NarrativeRef(
          refType: NarrativeRefTypes.toolRound,
          refId: request.callId,
        );
    final event = InformationEvent(
      eventId: '${request.toolName}:${request.callId}',
      eventType: outcome.outcomeStatus,
      subjectRef: subjectRef,
      lifecycleStatus: _recordLifecycleStatus(outcome.outcomeStatus),
      actorRef: actorRef,
      relatedRefs: <NarrativeRef>[...request.targetRefs, ...relatedRefs],
      relatedLinkIds: relatedLinkIds,
      summary: summary,
      occurredAt: DateTime.now().toIso8601String(),
      metadata: <String, Object?>{
        'tool_name': request.toolName,
        'call_id': request.callId,
        'outcome_status': outcome.outcomeStatus,
        'permission_decision': outcome.permissionDecision?.toJson(),
      },
    );
    await _informationEventRepository.appendInformationEvent(project, event);
    changedPaths.add(_pathService.informationEventsLogPath());
  }

  Future<void> _appendProjectionPaths(
    ProjectDescriptor project,
    List<String> changedPaths,
  ) async {
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((entry) => entry.relativePath));
  }

  String _recordLifecycleStatus(String outcomeStatus) {
    switch (outcomeStatus) {
      case DomainToolOutcomeStatuses.accepted:
        return InformationLifecycleStatuses.accepted;
      case DomainToolOutcomeStatuses.proposed:
      case DomainToolOutcomeStatuses.needsUserConfirmation:
      default:
        return InformationLifecycleStatuses.proposed;
    }
  }

  String _researchRequestState(DomainToolOutcome outcome) {
    final permissionDisposition = ValueReaders.stringValue(
      outcome.permissionDecision?.disposition,
    ).trim();
    if (permissionDisposition == DomainToolPermissionDispositions.accepted) {
      return 'pending_gateway_execution';
    }
    if (permissionDisposition ==
        DomainToolPermissionDispositions.needsUserConfirmation) {
      return 'awaiting_user_confirmation';
    }
    switch (outcome.outcomeStatus) {
      case DomainToolOutcomeStatuses.accepted:
        return 'pending_gateway_execution';
      case DomainToolOutcomeStatuses.proposed:
        return 'pending_review';
      case DomainToolOutcomeStatuses.needsUserConfirmation:
      default:
        return 'awaiting_user_confirmation';
    }
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

  DomainToolOutcome _withResearchExecutionOutcome(
    DomainToolOutcome outcome,
    ProjectInformationResearchCoordinatorResult researchExecution,
  ) {
    return outcome.copyWith(
      outcomePayload: ValueReaders.deepCopyMap(<String, Object?>{
        ...outcome.outcomePayload,
        'request_id': researchExecution.requestId,
        'request_state': researchExecution.requestState,
        'request_registered': true,
        'network_execution_performed': researchExecution.executedNetwork,
        'import_execution_performed': researchExecution.executedImport,
        'requires_user_confirmation': researchExecution.awaitUserConfirmation,
        'research_execution_summary': researchExecution.summary,
        'generated_research_note_ids': researchExecution.generatedResearchNoteIds,
        'research_execution': <String, Object?>{
          'request_id': researchExecution.requestId,
          'request_state': researchExecution.requestState,
          'executed_network': researchExecution.executedNetwork,
          'executed_import': researchExecution.executedImport,
          'await_user_confirmation': researchExecution.awaitUserConfirmation,
          'blocked': researchExecution.blocked,
          'summary': researchExecution.summary,
          'blocked_reason': researchExecution.blockedReason,
          'changed_paths': researchExecution.changedPaths,
          'gateway_summary': researchExecution.gatewaySummary,
          'import_summary': researchExecution.importSummary,
          'execution_decision': researchExecution.executionDecision,
          'generated_research_note_ids':
              researchExecution.generatedResearchNoteIds,
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
        errorCode: 'adapter_information_persistence_failed',
        message: '信息领域工具结果已生成，但本地持久化失败。',
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
}
