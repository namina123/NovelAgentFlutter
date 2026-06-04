import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../runtime/tool_round_evidence.dart';
import '../../workflow/chapter_delivery_state_machine.dart';
import '../../workflow/chapter_delivery_state_request.dart';
import '../../workflow/chapter_delivery_state_result.dart';
import '../../workflow/chapter_delivery_state_statuses.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_error.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';
import 'submit_chapter_delivery_result.dart';

class SubmitChapterDeliveryHandler implements NarrativeDomainToolHandler {
  SubmitChapterDeliveryHandler({
    ChapterNarrativeSubmissionCodecService? submissionCodecService,
    ChapterDeliveryStateMachine? deliveryStateMachine,
  }) : _submissionCodecService =
           submissionCodecService ??
           const ChapterNarrativeSubmissionCodecService(),
       _deliveryStateMachine =
           deliveryStateMachine ?? const ChapterDeliveryStateMachine();

  final ChapterNarrativeSubmissionCodecService _submissionCodecService;
  final ChapterDeliveryStateMachine _deliveryStateMachine;

  @override
  final NarrativeDomainToolCapability capability =
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        displayName: '提交章节交付',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.writer,
          NarrativeSourceTypes.recovery,
          NarrativeSourceTypes.system,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final payload = request.requestPayload;
    final chapterPath = ValueReaders.stringValue(
      payload['chapter_path'],
    ).trim();
    final chapterContent = ValueReaders.stringValue(
      payload['chapter_content'],
    ).trimRight();

    if (chapterPath.isEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'submit_chapter_delivery 缺少 chapter_path。',
        errorDetails: const <String, Object?>{'field': 'chapter_path'},
      );
    }

    final submission = _submissionFromPayload(payload);
    final stateRequest = ChapterDeliveryStateRequest(
      deliveryId: _deliveryIdFor(request, chapterPath),
      chapterPath: chapterPath,
      resolvedChapterPath: chapterPath,
      chapterContent: chapterContent,
      title: ValueReaders.stringValue(payload['title']).trim(),
      submission: submission,
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(payload['metadata']),
      ),
    );
    final stateResult = _deliveryStateMachine.evaluate(stateRequest);
    final result = SubmitChapterDeliveryResult(
      deliveryId: stateResult.deliveryId,
      chapterPath: chapterPath,
      deliveryState: stateResult.state,
      chapterBodyState: _chapterBodyStateFor(stateResult),
      sidecarState: _sidecarStateFor(stateResult, submission),
      deliveryEvidenceRefs: _deliveryEvidenceRefs(request, chapterPath),
      stateResult: stateResult,
      constraintCoverage: _constraintCoverageFor(payload, submission),
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        'source': request.source.toJson(),
        if (submission != null) 'submission_id': submission.submissionId,
      }),
    );

    return DomainToolOutcome(
      outcomeId: 'submit_chapter_delivery:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: stateResult.suggestedOutcomeStatus,
      permissionDecision: permissionDecision,
      outcomePayload: result.toJson(),
      toolRoundEvidence: _mergedToolRoundEvidence(
        request: request,
        evidenceRefs: result.deliveryEvidenceRefs,
      ),
      schemaVersion: request.schemaVersion,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        'delivery_state': stateResult.state,
        'recommended_action': stateResult.recommendedAction,
      }),
    );
  }

  ChapterNarrativeSubmission? _submissionFromPayload(JsonMap payload) {
    final submissionJson = ValueReaders.mapValue(payload['submission']);
    if (submissionJson.isEmpty) {
      return null;
    }
    return _submissionCodecService.fromJson(submissionJson);
  }

  String _deliveryIdFor(DomainToolRequest request, String chapterPath) {
    final submission = ValueReaders.mapValue(
      request.requestPayload['submission'],
    );
    final submissionId = ValueReaders.stringValue(
      submission['submission_id'],
    ).trim();
    if (submissionId.isNotEmpty) {
      return submissionId;
    }
    return 'delivery:${request.callId}:$chapterPath';
  }

  String _chapterBodyStateFor(ChapterDeliveryStateResult result) {
    if (result.chapterBodyDelivered) {
      return 'delivered';
    }
    if (result.state ==
        ChapterDeliveryStateStatuses.invalidOutputRewriteRequired) {
      return 'rewrite_required';
    }
    if (result.retryable) {
      return 'missing_or_retryable_failure';
    }
    return 'not_delivered';
  }

  String _sidecarStateFor(
    ChapterDeliveryStateResult result,
    ChapterNarrativeSubmission? submission,
  ) {
    if (!result.chapterBodyDelivered) {
      return 'blocked_by_chapter_failure';
    }
    if (submission == null) {
      return 'missing';
    }
    if (result.submissionAccepted) {
      return 'accepted';
    }
    return 'repair_required';
  }

  List<NarrativeEvidenceRef> _deliveryEvidenceRefs(
    DomainToolRequest request,
    String chapterPath,
  ) {
    final evidenceRefs = <NarrativeEvidenceRef>[
      NarrativeEvidenceRef(
        evidenceType: NarrativeEvidenceTypes.toolCall,
        evidenceId: 'submit_chapter_delivery:${request.callId}',
        sourceRef: request.source,
        targetRef: NarrativeRef(
          refType: NarrativeRefTypes.chapter,
          refId: chapterPath,
          relativePath: chapterPath,
        ),
        summary: '章节交付工具调用记录。',
      ),
    ];
    final toolRoundEvidence = request.toolRoundEvidence;
    if (toolRoundEvidence != null) {
      evidenceRefs.addAll(toolRoundEvidence.evidenceRefs);
    }
    return evidenceRefs;
  }

  ToolRoundEvidence? _mergedToolRoundEvidence({
    required DomainToolRequest request,
    required List<NarrativeEvidenceRef> evidenceRefs,
  }) {
    final existing = request.toolRoundEvidence;
    if (existing == null) {
      return null;
    }
    return existing.copyWith(evidenceRefs: evidenceRefs);
  }

  JsonMap _constraintCoverageFor(
    JsonMap payload,
    ChapterNarrativeSubmission? submission,
  ) {
    final directCoverage = ValueReaders.mapValue(
      payload['constraint_coverage'],
    );
    if (directCoverage.isNotEmpty) {
      return ValueReaders.deepCopyMap(directCoverage);
    }
    if (submission == null) {
      return const <String, Object?>{};
    }
    return ValueReaders.deepCopyMap(submission.constraintCoverage);
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId: 'submit_chapter_delivery:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: 'accepted',
      ),
      error: DomainToolError(
        errorCode: 'invalid_submit_chapter_delivery_payload',
        message: message,
        errorDetails: ValueReaders.deepCopyMap(errorDetails),
      ),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }
}
