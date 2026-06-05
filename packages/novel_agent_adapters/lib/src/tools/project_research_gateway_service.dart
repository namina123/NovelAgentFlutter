import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_design_element_repository.dart';
import '../storage/local_information_event_repository.dart';
import '../storage/local_knowledge_card_repository.dart';
import '../storage/local_reference_work_repository.dart';
import '../storage/local_research_note_repository.dart';
import '../storage/open_narrative_state_index_document_service.dart';
import '../storage/open_narrative_state_record_document_service.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_information_projection_writer_service.dart';
import '../storage/project_json_document_service.dart';
import 'project_gateway_tool_executor.dart';
import 'project_research_gateway_run_result.dart';

class ProjectResearchGatewayService {
  ProjectResearchGatewayService({
    required ProjectWorkspacePort workspacePort,
    ProjectGatewayToolExecutor? gatewayToolExecutor,
    ResearchNoteRepository? researchNoteRepository,
    InformationEventRepository? informationEventRepository,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    ProjectInformationProjectionWriterService? projectionWriterService,
    ProjectInformationPathService? pathService,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStateIndexDocumentService? indexDocumentService,
    InformationPermissionPolicyService? permissionPolicyService,
  }) : _gatewayToolExecutor =
           gatewayToolExecutor ?? ProjectGatewayToolExecutor(),
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _informationEventRepository =
           informationEventRepository ??
           LocalInformationEventRepository(workspacePort: workspacePort),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _projectionWriterService =
           projectionWriterService ??
           ProjectInformationProjectionWriterService(
             workspacePort: workspacePort,
             knowledgeCardRepository: LocalKnowledgeCardRepository(
               workspacePort: workspacePort,
             ),
             designElementRepository: LocalDesignElementRepository(
               workspacePort: workspacePort,
             ),
             researchNoteRepository:
                 researchNoteRepository ??
                 LocalResearchNoteRepository(workspacePort: workspacePort),
             referenceWorkRepository: LocalReferenceWorkRepository(
               workspacePort: workspacePort,
             ),
           ),
       _pathService = pathService ?? ProjectInformationPathService(),
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _indexDocumentService =
           indexDocumentService ??
           OpenNarrativeStateIndexDocumentService(
             jsonDocumentService:
                 jsonDocumentService ??
                 ProjectJsonDocumentService(workspacePort: workspacePort),
           ),
       _permissionPolicyService =
           permissionPolicyService ??
           const InformationPermissionPolicyService();

  final ProjectGatewayToolExecutor _gatewayToolExecutor;
  final ResearchNoteRepository _researchNoteRepository;
  final InformationEventRepository _informationEventRepository;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final ProjectInformationPathService _pathService;
  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;
  final InformationPermissionPolicyService _permissionPolicyService;

  Future<List<JsonMap>> listPendingResearchRequests(
    ProjectDescriptor project,
  ) async {
    final requestIds = await _indexDocumentService.readIds(
      project.rootPath,
      _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
    );
    final result = <JsonMap>[];
    for (final requestId in requestIds) {
      final record = await _readResearchRequestRecord(project, requestId);
      if (record.isEmpty) {
        continue;
      }
      final state = ValueReaders.stringValue(record['request_state']).trim();
      if (state == 'pending_gateway_execution' ||
          state == 'pending_review' ||
          state == 'awaiting_user_confirmation') {
        result.add(record);
      }
    }
    return result;
  }

  Future<ProjectResearchGatewayRunResult> processPendingRequest(
    ProjectDescriptor project, {
    required String requestId,
    bool allowGatewayExecution = false,
    int searchLimit = 3,
    int fetchMaxChars = 1200,
  }) async {
    final record = await _readResearchRequestRecord(project, requestId);
    if (record.isEmpty) {
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: 'missing',
        blockedReason: 'pending research request 不存在。',
        summary: '未找到待研究请求：$requestId',
      );
    }

    final requestState = ValueReaders.stringValue(
      record['request_state'],
    ).trim();
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    final query = ValueReaders.stringValue(researchRequest['query']).trim();
    final requestedBy = ValueReaders.stringValue(
      researchRequest['requested_by'],
    ).trim();
    final userGrantedNetworkAccess = ValueReaders.boolValue(
      researchRequest['user_granted_network_access'],
    );
    final permissionDecision = _permissionPolicyService
        .decideExternalResearchRequest(
          query: query,
          requestedBy: requestedBy,
          userGrantedNetworkAccess: userGrantedNetworkAccess,
          metadata: <String, Object?>{
            'purpose': researchRequest['purpose'],
            'requested_depth': researchRequest['requested_depth'],
            'reference_relationship': researchRequest['reference_relationship'],
            ...ValueReaders.mapValue(researchRequest['metadata']),
          },
        );

    if (!allowGatewayExecution) {
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: requestState,
        blockedReason: '默认不执行真实 gateway 请求，需要显式允许。',
        summary: '待研究请求尚未执行：$requestId',
      );
    }

    if (permissionDecision.disposition !=
        InformationPermissionDispositions.autoAccept) {
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: requestState,
        blockedReason: permissionDecision.reason,
        summary: '待研究请求当前无权联网执行：$requestId',
      );
    }

    final searchResult = await _gatewayToolExecutor
        .execute(project, <String, Object?>{
          'gateway_tool': 'search_internet',
          'query': query,
          'limit': searchLimit,
          'max_chars': 6000,
        });
    if (!ValueReaders.boolValue(searchResult['ok'])) {
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: 'gateway_failed',
        blockedReason: ValueReaders.stringValue(searchResult['error']),
        summary: '待研究请求搜索失败：$requestId',
        gatewaySummary: ValueReaders.deepCopyMap(searchResult),
      );
    }

    final results = ValueReaders.mapList(
      searchResult['results'],
    ).take(searchLimit).toList(growable: false);
    final firstUrl = results.isEmpty
        ? ''
        : ValueReaders.stringValue(results.first['url']).trim();
    JsonMap fetchSummary = const <String, Object?>{};
    if (firstUrl.isNotEmpty) {
      final fetchResult = await _gatewayToolExecutor
          .execute(project, <String, Object?>{
            'gateway_tool': 'fetch_url_content',
            'url': firstUrl,
            'max_chars': fetchMaxChars,
          });
      if (ValueReaders.boolValue(fetchResult['ok'])) {
        final excerpt = ValueReaders.stringValue(fetchResult['content']);
        fetchSummary = <String, Object?>{
          'url': firstUrl,
          'status_code': fetchResult['status_code'],
          'content_type': fetchResult['content_type'],
          'content_excerpt': _trimText(excerpt, 320),
          'truncated': fetchResult['truncated'],
        };
      }
    }

    final gatewaySummary = <String, Object?>{
      'query': query,
      'requested_by': requestedBy,
      'search_results': results
          .map(
            (entry) => <String, Object?>{
              'title': ValueReaders.stringValue(entry['title']),
              'url': ValueReaders.stringValue(entry['url']),
              'snippet': _trimText(
                ValueReaders.stringValue(entry['snippet']),
                180,
              ),
            },
          )
          .toList(growable: false),
      if (fetchSummary.isNotEmpty) 'fetched_source': fetchSummary,
    };
    final note = _buildResearchNote(
      requestId: requestId,
      record: record,
      gatewaySummary: gatewaySummary,
    );

    await _researchNoteRepository.appendResearchNote(project, note);
    final changedPaths = <String>[
      _pathService.researchNotePath(note.researchId),
      _pathService.researchNotesIndexPath(),
    ];
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: _pathService.researchRequestPath(requestId),
      document: <String, Object?>{
        ...record,
        'request_state': 'completed',
        'network_execution_performed': true,
        'generated_research_note_id': note.researchId,
        'gateway_summary': gatewaySummary,
        'completed_at': DateTime.now().toIso8601String(),
      },
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    changedPaths
      ..add(_pathService.researchRequestPath(requestId))
      ..add(_pathService.researchRequestsIndexPath());
    await _appendInformationEvent(
      project,
      requestId: requestId,
      note: note,
      gatewaySummary: gatewaySummary,
    );
    changedPaths.add(_pathService.informationEventsLogPath());
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((entry) => entry.relativePath));

    return ProjectResearchGatewayRunResult(
      requestId: requestId,
      executed: true,
      generatedResearchNote: note,
      requestState: 'completed',
      summary: '已生成 research note：${note.researchId}',
      changedPaths: changedPaths.toSet().toList(growable: false),
      gatewaySummary: gatewaySummary,
    );
  }

  Future<JsonMap> _readResearchRequestRecord(
    ProjectDescriptor project,
    String requestId,
  ) {
    return _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.researchRequestPath(requestId),
    );
  }

  ResearchNote _buildResearchNote({
    required String requestId,
    required JsonMap record,
    required JsonMap gatewaySummary,
  }) {
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    final searchResults = ValueReaders.mapList(
      gatewaySummary['search_results'],
    );
    final firstResult = searchResults.isEmpty
        ? const <String, Object?>{}
        : searchResults.first;
    final firstTitle = ValueReaders.stringValue(firstResult['title']).trim();
    final firstUrl = ValueReaders.stringValue(firstResult['url']).trim();
    final firstSnippet = ValueReaders.stringValue(
      firstResult['snippet'],
    ).trim();
    final fetchSummary = ValueReaders.mapValue(
      gatewaySummary['fetched_source'],
    );
    final fetchedExcerpt = ValueReaders.stringValue(
      fetchSummary['content_excerpt'],
    ).trim();
    final query = ValueReaders.stringValue(researchRequest['query']).trim();
    final linkedCards = ValueReaders.mapList(
      researchRequest['target_refs'],
    ).map(NarrativeRef.fromJson).toList(growable: false);
    final noteId = 'gateway_${requestId}';
    final usableFacts = <Object?>[
      for (final entry in searchResults)
        <String, Object?>{
          'title': ValueReaders.stringValue(entry['title']),
          'url': ValueReaders.stringValue(entry['url']),
          'snippet': ValueReaders.stringValue(entry['snippet']),
        },
      if (fetchSummary.isNotEmpty)
        <String, Object?>{
          'source_url': ValueReaders.stringValue(fetchSummary['url']),
          'excerpt': fetchedExcerpt,
        },
    ];
    final summary = [
      if (firstTitle.isNotEmpty) '首条来源：$firstTitle',
      if (firstSnippet.isNotEmpty) '摘要：$firstSnippet',
      if (fetchedExcerpt.isNotEmpty) '抓取补充：$fetchedExcerpt',
    ].join('；');
    return ResearchNote(
      researchId: noteId,
      query: query,
      sourceKind: 'gateway_search',
      sourceUrlOrRef: firstUrl.isEmpty ? 'gateway_search:$requestId' : firstUrl,
      citation: firstTitle.isEmpty ? 'Gateway search: $query' : firstTitle,
      summary: summary.isEmpty ? '未检索到足够结果，已保留搜索请求审计。' : summary,
      usableFacts: usableFacts,
      creativeSuggestions: const <Object?>[],
      uncertainty: searchResults.isEmpty ? 'no_results' : 'search_summary_only',
      licenseOrUsageNote: '只作为 research note 保存，未自动提升为 knowledge card。',
      createdBy: 'project_research_gateway_service',
      linkedCards: linkedCards,
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.referenceOnly,
        citationRiskLevel: InformationCitationRiskLevels.normal,
        allowsDerivativeUse: true,
      ),
      metadata: <String, Object?>{
        'request_id': requestId,
        'tool_name': record['tool_name'],
        'call_id': record['call_id'],
        'gateway_summary': gatewaySummary,
        'source_request': ValueReaders.deepCopyMap(researchRequest),
      },
    );
  }

  Future<void> _appendInformationEvent(
    ProjectDescriptor project, {
    required String requestId,
    required ResearchNote note,
    required JsonMap gatewaySummary,
  }) {
    final event = InformationEvent(
      eventId: 'gateway_research:$requestId',
      eventType: 'gateway_research_completed',
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.researchNote,
        refId: note.researchId,
      ),
      lifecycleStatus: InformationLifecycleStatuses.accepted,
      actorRef: NarrativeRef(
        refType: NarrativeRefTypes.toolRound,
        refId: requestId,
      ),
      relatedRefs: <NarrativeRef>[
        NarrativeRef(
          refType: InformationLinkedRefTypes.researchRequest,
          refId: requestId,
        ),
      ],
      summary: 'gateway research 已生成 research note：${note.query}',
      occurredAt: DateTime.now().toIso8601String(),
      metadata: <String, Object?>{
        'gateway_summary': gatewaySummary,
        'generated_research_note_id': note.researchId,
      },
    );
    return _informationEventRepository.appendInformationEvent(project, event);
  }

  String _trimText(String value, int maxChars) {
    final normalized = value.trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return normalized.substring(0, maxChars);
  }
}
