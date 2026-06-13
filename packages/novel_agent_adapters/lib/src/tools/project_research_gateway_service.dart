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
    InformationCollectionPolicyService? collectionPolicyService,
    InformationSourceQualityService? sourceQualityService,
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
           const InformationPermissionPolicyService(),
       _collectionPolicyService =
           collectionPolicyService ??
           const InformationCollectionPolicyService(),
       _sourceQualityService =
           sourceQualityService ?? const InformationSourceQualityService();

  final ProjectGatewayToolExecutor _gatewayToolExecutor;
  final ResearchNoteRepository _researchNoteRepository;
  final InformationEventRepository _informationEventRepository;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final ProjectInformationProjectionWriterService _projectionWriterService;
  final ProjectInformationPathService _pathService;
  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;
  final InformationPermissionPolicyService _permissionPolicyService;
  final InformationCollectionPolicyService _collectionPolicyService;
  final InformationSourceQualityService _sourceQualityService;

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
    InformationPermissionDecision? permissionDecisionOverride,
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
    final collectionRequest = _collectionPolicyService.normalize(
      InformationCollectionRequest.fromJson(researchRequest),
    );
    final query = collectionRequest.query;
    final requestedBy = ValueReaders.stringValue(
      researchRequest['requested_by'],
    ).trim();
    final permissionDecision =
        permissionDecisionOverride ??
        _permissionPolicyService.decideExternalResearchRequest(
          query: query,
          requestedBy: requestedBy,
          userGrantedNetworkAccess: collectionRequest.userGrantedNetworkAccess,
          metadata: <String, Object?>{
            ...collectionRequest.metadata,
            'purpose': collectionRequest.purpose,
            'requested_depth': collectionRequest.requestedDepth,
            'reference_relationship': collectionRequest.referenceRelationship,
            'collection_mode': collectionRequest.collectionMode,
            'information_domain': collectionRequest.informationDomain,
            'source_requirements': collectionRequest.sourceRequirements
                .toJson(),
            'extraction_policy': collectionRequest.extractionPolicy.toJson(),
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

    if (!collectionRequest.requiresNetwork) {
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: requestState,
        blockedReason: '当前研究请求是导入收集模式，应由导入收集服务处理，不走联网 gateway。',
        summary: '待研究请求不是联网请求：$requestId',
        gatewaySummary: <String, Object?>{
          'collection_request': collectionRequest.toJson(),
        },
      );
    }

    final effectiveSearchLimit = _clampInt(
      _maxInt(
        searchLimit,
        collectionRequest.extractionPolicy.maxCandidateCount,
      ),
      min: 1,
      max: 24,
    );
    final effectiveFetchLimit = _clampInt(
      collectionRequest.extractionPolicy.maxFetchCount,
      min: 1,
      max: 8,
    );
    final searchResult = await _gatewayToolExecutor
        .execute(project, <String, Object?>{
          'gateway_tool': 'search_internet',
          'query': query,
          'limit': effectiveSearchLimit,
          'max_chars': 12000,
          'preferred_languages':
              collectionRequest.sourceRequirements.preferredLanguages,
          'network_region_hint':
              collectionRequest.sourceRequirements.networkRegionHint,
          'source_requirements': collectionRequest.sourceRequirements.toJson(),
        });
    if (!ValueReaders.boolValue(searchResult['ok'])) {
      final gatewaySummary = <String, Object?>{
        'query': query,
        'requested_by': requestedBy,
        'collection_request': collectionRequest.toJson(),
        'search_result': ValueReaders.deepCopyMap(searchResult),
      };
      final changedPaths = await _markResearchRequestState(
        project,
        requestId: requestId,
        record: record,
        requestState: 'gateway_failed',
        gatewaySummary: gatewaySummary,
      );
      return ProjectResearchGatewayRunResult(
        requestId: requestId,
        executed: false,
        requestState: 'gateway_failed',
        blockedReason: ValueReaders.stringValue(searchResult['error']),
        summary: '待研究请求搜索失败：$requestId',
        changedPaths: changedPaths,
        gatewaySummary: gatewaySummary,
      );
    }

    final results = ValueReaders.mapList(
      searchResult['results'],
    ).take(effectiveSearchLimit).toList(growable: false);
    final searchCandidates = _buildSearchCandidates(results, collectionRequest);
    final fetchedSources = await _fetchCandidateSources(
      project,
      searchCandidates,
      fetchLimit: effectiveFetchLimit,
      fetchMaxChars: fetchMaxChars,
    );
    final fetchSummary = fetchedSources.firstWhere(
      (entry) => ValueReaders.boolValue(entry['ok']),
      orElse: () => const <String, Object?>{},
    );
    final sourceQualitySummary = _sourceQualitySummary(
      searchCandidates,
      collectionRequest,
    );

    final gatewaySummary = <String, Object?>{
      'query': query,
      'requested_by': requestedBy,
      'collection_request': collectionRequest.toJson(),
      'source_quality_summary': sourceQualitySummary,
      'search_results': searchCandidates
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
      'search_candidates': searchCandidates,
      'fetched_sources': fetchedSources,
      if (fetchSummary.isNotEmpty) 'fetched_source': fetchSummary,
      'search_audit': <String, Object?>{
        'effective_search_limit': effectiveSearchLimit,
        'effective_fetch_limit': effectiveFetchLimit,
        'raw_result_count': results.length,
        'search_url': searchResult['search_url'],
        'attempted_search_urls': searchResult['attempted_search_urls'],
      },
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
    final collectionRequest = _collectionPolicyService.normalize(
      InformationCollectionRequest.fromJson(researchRequest),
    );
    final searchCandidates = ValueReaders.mapList(
      gatewaySummary['search_candidates'],
    );
    final firstCandidate = _firstCitationCandidate(searchCandidates);
    final firstTitle = ValueReaders.stringValue(firstCandidate['title']).trim();
    final firstUrl = ValueReaders.stringValue(firstCandidate['url']).trim();
    final firstSnippet = ValueReaders.stringValue(
      firstCandidate['snippet'],
    ).trim();
    final fetchedSources = ValueReaders.mapList(
      gatewaySummary['fetched_sources'],
    );
    final fetchSummary = fetchedSources.firstWhere(
      (entry) => ValueReaders.boolValue(entry['ok']),
      orElse: () => const <String, Object?>{},
    );
    final fetchedExcerpt = ValueReaders.stringValue(
      fetchSummary['content_excerpt'],
    ).trim();
    final sourceQualitySummary = ValueReaders.mapValue(
      gatewaySummary['source_quality_summary'],
    );
    final query = collectionRequest.query;
    final noteId = 'gateway_${requestId}';
    final usableFacts = <Object?>[
      for (final entry in searchCandidates)
        <String, Object?>{
          'kind': 'search_candidate',
          'verification_status': _candidateVerificationStatus(
            entry,
            collectionRequest,
          ),
          'title': ValueReaders.stringValue(entry['title']),
          'url': ValueReaders.stringValue(entry['url']),
          'snippet': ValueReaders.stringValue(entry['snippet']),
          'source_quality': ValueReaders.deepCopyMap(
            ValueReaders.mapValue(entry['source_quality']),
          ),
        },
      for (final entry in fetchedSources)
        if (ValueReaders.boolValue(entry['ok']))
          <String, Object?>{
            'kind': 'source_excerpt',
            'source_url': ValueReaders.stringValue(entry['url']),
            'excerpt': ValueReaders.stringValue(entry['content_excerpt']),
            'source_quality': ValueReaders.deepCopyMap(
              ValueReaders.mapValue(entry['source_quality']),
            ),
          },
    ];
    final summary = [
      if (firstTitle.isNotEmpty) '优先来源：$firstTitle',
      if (firstSnippet.isNotEmpty) '摘要：$firstSnippet',
      if (fetchedExcerpt.isNotEmpty) '抓取补充：$fetchedExcerpt',
      if (sourceQualitySummary.isNotEmpty)
        '来源审计：严谨来源 ${ValueReaders.intValue(sourceQualitySummary['rigorous_source_count'])}/${ValueReaders.intValue(sourceQualitySummary['required_min_source_count'])}',
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
      uncertainty: _researchUncertainty(
        searchCandidates: searchCandidates,
        sourceQualitySummary: sourceQualitySummary,
        collectionRequest: collectionRequest,
      ),
      licenseOrUsageNote: '只作为 research note 保存，未自动提升为 knowledge card。',
      createdBy: 'project_research_gateway_service',
      linkedCards: collectionRequest.targetRefs,
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
        'collection_request': collectionRequest.toJson(),
      },
    );
  }

  List<JsonMap> _buildSearchCandidates(
    List<JsonMap> results,
    InformationCollectionRequest collectionRequest,
  ) {
    final candidates = <JsonMap>[];
    for (var index = 0; index < results.length; index += 1) {
      final entry = results[index];
      final assessment = _sourceQualityService.assessSearchCandidate(
        entry,
        requirements: collectionRequest.sourceRequirements,
        informationDomain: collectionRequest.informationDomain,
      );
      candidates.add(<String, Object?>{
        'rank': index + 1,
        'title': ValueReaders.stringValue(entry['title']),
        'url': ValueReaders.stringValue(entry['url']),
        'snippet': _trimText(ValueReaders.stringValue(entry['snippet']), 360),
        'source_quality': assessment.toJson(),
        'raw_candidate': ValueReaders.deepCopyMap(entry),
      });
    }
    return candidates;
  }

  Future<List<JsonMap>> _fetchCandidateSources(
    ProjectDescriptor project,
    List<JsonMap> candidates, {
    required int fetchLimit,
    required int fetchMaxChars,
  }) async {
    final result = <JsonMap>[];
    for (final candidate in candidates) {
      if (result.length >= fetchLimit) {
        break;
      }
      final url = ValueReaders.stringValue(candidate['url']).trim();
      if (url.isEmpty) {
        continue;
      }
      final fetchResult = await _gatewayToolExecutor.execute(
        project,
        <String, Object?>{
          'gateway_tool': 'fetch_url_content',
          'url': url,
          'max_chars': fetchMaxChars,
        },
      );
      final sourceQuality = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(candidate['source_quality']),
      );
      if (ValueReaders.boolValue(fetchResult['ok'])) {
        final excerpt = ValueReaders.stringValue(fetchResult['content']);
        result.add(<String, Object?>{
          'ok': true,
          'url': url,
          'status_code': fetchResult['status_code'],
          'content_type': fetchResult['content_type'],
          'content_excerpt': _trimText(excerpt, 640),
          'truncated': fetchResult['truncated'],
          'source_quality': sourceQuality,
        });
      } else {
        result.add(<String, Object?>{
          'ok': false,
          'url': url,
          'error': ValueReaders.stringValue(fetchResult['error']),
          'source_quality': sourceQuality,
        });
      }
    }
    return result;
  }

  JsonMap _sourceQualitySummary(
    List<JsonMap> candidates,
    InformationCollectionRequest collectionRequest,
  ) {
    final rigorousCount = candidates
        .where(
          (entry) => ValueReaders.boolValue(
            ValueReaders.mapValue(entry['source_quality'])['is_rigorous'],
          ),
        )
        .length;
    final requiredMin = collectionRequest.sourceRequirements.minSourceCount;
    final requiresRigorous =
        collectionRequest.sourceRequirements.requiresRigorousSources;
    return <String, Object?>{
      'requires_rigorous_sources': requiresRigorous,
      'required_min_source_count': requiredMin,
      'candidate_count': candidates.length,
      'rigorous_source_count': rigorousCount,
      'meets_source_requirement':
          !requiresRigorous || rigorousCount >= requiredMin,
      'information_domain': collectionRequest.informationDomain,
    };
  }

  JsonMap _firstCitationCandidate(List<JsonMap> candidates) {
    for (final candidate in candidates) {
      if (ValueReaders.boolValue(
        ValueReaders.mapValue(candidate['source_quality'])['is_rigorous'],
      )) {
        return candidate;
      }
    }
    return candidates.isEmpty ? const <String, Object?>{} : candidates.first;
  }

  String _candidateVerificationStatus(
    JsonMap candidate,
    InformationCollectionRequest collectionRequest,
  ) {
    final sourceQuality = ValueReaders.mapValue(candidate['source_quality']);
    if (ValueReaders.boolValue(sourceQuality['is_rigorous'])) {
      return 'rigorous_source_candidate';
    }
    if (collectionRequest.sourceRequirements.requiresRigorousSources) {
      return 'reference_only_needs_rigorous_cross_check';
    }
    return 'candidate_needs_extraction';
  }

  String _researchUncertainty({
    required List<JsonMap> searchCandidates,
    required JsonMap sourceQualitySummary,
    required InformationCollectionRequest collectionRequest,
  }) {
    if (searchCandidates.isEmpty) {
      return 'no_results';
    }
    if (collectionRequest.sourceRequirements.requiresRigorousSources &&
        !ValueReaders.boolValue(
          sourceQualitySummary['meets_source_requirement'],
        )) {
      return 'insufficient_rigorous_sources';
    }
    return 'source_candidates_preserved_pending_extraction';
  }

  Future<List<String>> _markResearchRequestState(
    ProjectDescriptor project, {
    required String requestId,
    required JsonMap record,
    required String requestState,
    required JsonMap gatewaySummary,
  }) async {
    final recordPath = _pathService.researchRequestPath(requestId);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: recordPath,
      document: <String, Object?>{
        ...record,
        'request_state': requestState,
        'network_execution_performed': false,
        'gateway_summary': gatewaySummary,
        'updated_at': DateTime.now().toIso8601String(),
      },
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    return <String>[recordPath, _pathService.researchRequestsIndexPath()];
  }

  int _maxInt(int left, int right) {
    return left > right ? left : right;
  }

  int _clampInt(int value, {required int min, required int max}) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
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
