import '../../information.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class ProposeKnowledgeCardHandler implements NarrativeDomainToolHandler {
  const ProposeKnowledgeCardHandler({
    InformationPermissionPolicyService? permissionPolicyService,
    InformationDomainToolHandlerSupport? handlerSupport,
  }) : _permissionPolicyService =
           permissionPolicyService ??
           const InformationPermissionPolicyService(),
       _handlerSupport =
           handlerSupport ?? const InformationDomainToolHandlerSupport();

  final InformationPermissionPolicyService _permissionPolicyService;
  final InformationDomainToolHandlerSupport _handlerSupport;

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.proposeKnowledgeCard,
        displayName: '提出知识卡',
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
    // 中文注释: 知识卡 handler 只把 proposal 收口成稳定结果，不在这里直接改写项目事实源或落盘。
    final card = ProjectKnowledgeCard.fromJson(request.requestPayload);
    final validationErrors = card.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.proposeKnowledgeCard,
        errorCode: 'invalid_propose_knowledge_card_payload',
        message: 'propose_knowledge_card 的知识卡存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final informationPermissionDecision = _permissionPolicyService
        .decideKnowledgeCard(card);
    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.proposeKnowledgeCard,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_propose_knowledge_card_payload',
      forbiddenMessage: '当前知识卡 proposal 包含禁止自动应用的 payload。',
      outcomePayload: <String, Object?>{
        'knowledge_card': card.toJson(),
        'requires_user_confirmation':
            informationPermissionDecision.disposition ==
            InformationPermissionDispositions.needsUserConfirmation,
        'activation_policy': card.activationPolicy.toJson(),
        'usage_policy': card.usagePolicy.toJson(),
        'source_refs': card.sourceRefs
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
      metadata: <String, Object?>{
        'card_namespace': card.cardNamespace,
        'card_type': card.cardType,
        'source_authorities': card.sourceRefs
            .map((entry) => entry.sourceAuthority)
            .toSet()
            .toList(growable: false),
      },
    );
  }
}
