import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../information.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class RequestExternalResearchHandler implements NarrativeDomainToolHandler {
  const RequestExternalResearchHandler({
    InformationPermissionPolicyService? permissionPolicyService,
    InformationCollectionPolicyService? collectionPolicyService,
    InformationDomainToolHandlerSupport? handlerSupport,
  }) : _permissionPolicyService =
           permissionPolicyService ??
           const InformationPermissionPolicyService(),
       _collectionPolicyService =
           collectionPolicyService ??
           const InformationCollectionPolicyService(),
       _handlerSupport =
           handlerSupport ?? const InformationDomainToolHandlerSupport();

  final InformationPermissionPolicyService _permissionPolicyService;
  final InformationCollectionPolicyService _collectionPolicyService;
  final InformationDomainToolHandlerSupport _handlerSupport;

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.requestExternalResearch,
        displayName: '请求外部研究',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.writer,
          NarrativeSourceTypes.reviewer,
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.explainerInterpreted,
          NarrativeSourceTypes.user,
          NarrativeSourceTypes.system,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    // 中文注释: 这里明确只收口受控研究请求，不执行联网，让 runtime 后续能看到清晰的待研究状态。
    final query = ValueReaders.stringValue(
      request.requestPayload['query'],
    ).trim();
    if (query.isEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.requestExternalResearch,
        errorCode: 'invalid_request_external_research_payload',
        message: 'request_external_research 的 query 不能为空。',
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final rawTargetRefs = request.requestPayload['target_refs'];
    if (rawTargetRefs != null && rawTargetRefs is! List) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.requestExternalResearch,
        errorCode: 'invalid_request_external_research_payload',
        message: 'request_external_research 的 target_refs 必须是对象数组。',
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final targetRefs = ValueReaders.mapList(
      rawTargetRefs,
    ).map(NarrativeRef.fromJson).toList(growable: false);
    final targetRefErrors = targetRefs
        .where(
          (entry) => entry.refType.trim().isEmpty || entry.refId.trim().isEmpty,
        )
        .map((_) => 'target_ref 缺少 ref_type 或 ref_id。')
        .toList(growable: false);
    if (targetRefErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.requestExternalResearch,
        errorCode: 'invalid_request_external_research_payload',
        message: 'request_external_research 的 target_refs 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': targetRefErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final requestMetadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(request.requestPayload['metadata']),
    );
    final collectionRequest = _collectionPolicyService.normalize(
      InformationCollectionRequest.fromJson(<String, Object?>{
        ...request.requestPayload,
        'target_refs': targetRefs
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'metadata': requestMetadata,
      }),
    );
    final informationPermissionDecision = _permissionPolicyService
        .decideExternalResearchRequest(
          query: query,
          requestedBy: request.source.sourceType,
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

    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.requestExternalResearch,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_request_external_research_payload',
      forbiddenMessage: '当前外部研究请求包含禁止自动执行的 payload。',
      outcomePayload: <String, Object?>{
        'research_request': <String, Object?>{
          ...collectionRequest.toJson(),
          'requested_by': request.source.sourceType,
        },
        'request_registered': true,
        'network_execution_performed': false,
        'requires_user_confirmation':
            informationPermissionDecision.disposition ==
            InformationPermissionDispositions.needsUserConfirmation,
      },
      metadata: <String, Object?>{
        'request_source_type': request.source.sourceType,
        'target_ref_count': targetRefs.length,
        'collection_mode': collectionRequest.collectionMode,
        'information_domain': collectionRequest.informationDomain,
      },
    );
  }
}
