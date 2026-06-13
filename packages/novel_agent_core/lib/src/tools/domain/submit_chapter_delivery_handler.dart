import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../project/chapter_output_path_policy_service.dart';
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
    ChapterNarrativeSubmissionContinuityEnricherService?
    submissionContinuityEnricherService,
    ChapterDeliveryStateMachine? deliveryStateMachine,
    ChapterOutputPathPolicyService? chapterOutputPathPolicyService,
  }) : _submissionCodecService =
           submissionCodecService ??
           const ChapterNarrativeSubmissionCodecService(),
       _submissionContinuityEnricherService =
           submissionContinuityEnricherService ??
           const ChapterNarrativeSubmissionContinuityEnricherService(),
       _deliveryStateMachine =
           deliveryStateMachine ?? const ChapterDeliveryStateMachine(),
       _chapterOutputPathPolicyService =
           chapterOutputPathPolicyService ??
           const ChapterOutputPathPolicyService();

  final ChapterNarrativeSubmissionCodecService _submissionCodecService;
  final ChapterNarrativeSubmissionContinuityEnricherService
  _submissionContinuityEnricherService;
  final ChapterDeliveryStateMachine _deliveryStateMachine;
  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;

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
    final requestedChapterPath = ValueReaders.stringValue(
      payload['chapter_path'],
    ).trim();
    final chapterContent = ValueReaders.stringValue(
      payload['chapter_content'],
    ).trimRight();

    if (requestedChapterPath.isEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'submit_chapter_delivery 缺少 chapter_path。',
        errorDetails: const <String, Object?>{'field': 'chapter_path'},
      );
    }

    final submission = _submissionFromPayload(payload);
    final explicitTitle = ValueReaders.stringValue(payload['title']).trim();
    final pathResolution = _chapterOutputPathPolicyService.resolveChapterOutput(
      requestedPath: requestedChapterPath,
      explicitTitle: explicitTitle,
      submissionTitle: submission?.title ?? '',
      chapterContent: chapterContent,
    );
    final effectiveTitle = pathResolution.title.trim();
    final chapterPath = pathResolution.resolvedPath.trim().isEmpty
        ? requestedChapterPath
        : pathResolution.resolvedPath.trim();
    final normalizedSubmission = _normalizedSubmissionForDelivery(
      submission,
      requestedChapterPath: requestedChapterPath,
      chapterPath: chapterPath,
      title: effectiveTitle,
      chapterContent: chapterContent,
    );
    final stateRequest = ChapterDeliveryStateRequest(
      deliveryId: _deliveryIdFor(request, chapterPath, normalizedSubmission),
      chapterPath: chapterPath,
      resolvedChapterPath: chapterPath,
      chapterContent: chapterContent,
      title: effectiveTitle,
      submission: normalizedSubmission,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...ValueReaders.mapValue(payload['metadata']),
        if (requestedChapterPath != chapterPath)
          'requested_chapter_path': requestedChapterPath,
        'path_resolution': pathResolution.toJson(),
      }),
    );
    final stateResult = _deliveryStateMachine.evaluate(stateRequest);
    final result = SubmitChapterDeliveryResult(
      deliveryId: stateResult.deliveryId,
      chapterPath: chapterPath,
      requestedChapterPath: requestedChapterPath,
      resolvedChapterPath: chapterPath,
      title: effectiveTitle,
      deliveryState: stateResult.state,
      chapterBodyState: _chapterBodyStateFor(stateResult),
      sidecarState: _sidecarStateFor(stateResult, normalizedSubmission),
      deliveryEvidenceRefs: _deliveryEvidenceRefs(request, chapterPath),
      stateResult: stateResult,
      pathResolution: pathResolution.toJson(),
      submission: normalizedSubmission?.toJson() ?? const <String, Object?>{},
      constraintCoverage: _constraintCoverageFor(payload, normalizedSubmission),
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        'source': request.source.toJson(),
        if (normalizedSubmission != null)
          'submission_id': normalizedSubmission.submissionId,
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

  ChapterNarrativeSubmission? _normalizedSubmissionForDelivery(
    ChapterNarrativeSubmission? submission, {
    required String requestedChapterPath,
    required String chapterPath,
    required String title,
    required String chapterContent,
  }) {
    if (submission == null) {
      return null;
    }
    final submissionId = _normalizedSubmissionId(
      submission.submissionId,
      requestedChapterPath: requestedChapterPath,
      chapterPath: chapterPath,
    );
    final normalized = submission.copyWith(
      submissionId: submissionId,
      title: title.trim().isEmpty ? submission.title : title.trim(),
      chapterRef: submission.chapterRef.copyWith(
        refId: chapterPath,
        relativePath: chapterPath,
        displayName: title.trim().isEmpty
            ? submission.chapterRef.displayName
            : title.trim(),
      ),
    );
    return _submissionContinuityEnricherService.enrich(
      normalized,
      chapterPath: chapterPath,
      title: title,
      chapterContent: chapterContent,
    );
  }

  String _normalizedSubmissionId(
    String submissionId, {
    required String requestedChapterPath,
    required String chapterPath,
  }) {
    final cleanId = submissionId.trim();
    if (cleanId.isEmpty) {
      return cleanId;
    }
    if (cleanId == 'submission:$requestedChapterPath') {
      return 'submission:$chapterPath';
    }
    return cleanId;
  }

  String _deliveryIdFor(
    DomainToolRequest request,
    String chapterPath,
    ChapterNarrativeSubmission? submission,
  ) {
    final normalizedSubmissionId = submission?.submissionId.trim() ?? '';
    if (normalizedSubmissionId.isNotEmpty) {
      return normalizedSubmissionId;
    }
    final rawSubmission = ValueReaders.mapValue(
      request.requestPayload['submission'],
    );
    final submissionId = ValueReaders.stringValue(
      rawSubmission['submission_id'],
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
