import '../../information.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class SubmitResearchNoteHandler implements NarrativeDomainToolHandler {
  const SubmitResearchNoteHandler({
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
        toolName: NarrativeDomainToolNames.submitResearchNote,
        displayName: '提交研究笔记',
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
    // 中文注释: 研究笔记允许先作为可审计资料沉淀，但不能在这里直接提升为长期项目规则。
    final note = ResearchNote.fromJson(request.requestPayload);
    final validationErrors = note.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.submitResearchNote,
        errorCode: 'invalid_submit_research_note_payload',
        message: 'submit_research_note 的 research note 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final informationPermissionDecision = _permissionPolicyService
        .decideResearchNote(note);
    final promotionDisposition = ValueReaders.stringValue(
      informationPermissionDecision.metadata['promotion_disposition'],
    ).trim();

    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.submitResearchNote,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_submit_research_note_payload',
      forbiddenMessage: '当前研究笔记包含禁止自动保存的 payload。',
      outcomePayload: <String, Object?>{
        'research_note': note.toJson(),
        'stored_as_research_note': true,
        'promotion_disposition': promotionDisposition,
        'linked_card_count': note.linkedCards.length,
        'usable_fact_count': note.usableFacts.length,
        'creative_suggestion_count': note.creativeSuggestions.length,
      },
      metadata: <String, Object?>{
        'source_kind': note.sourceKind,
        'created_by': note.createdBy,
      },
    );
  }
}
