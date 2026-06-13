import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/chapter_narrative_submission_validator.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
import 'chapter_delivery_failure.dart';
import 'chapter_length_evaluation.dart';
import 'chapter_delivery_state_request.dart';
import 'chapter_delivery_state_result.dart';
import 'chapter_delivery_state_statuses.dart';

class ChapterDeliveryStateMachine {
  const ChapterDeliveryStateMachine({
    ChapterNarrativeSubmissionValidator? submissionValidator,
  }) : _submissionValidator =
           submissionValidator ?? const ChapterNarrativeSubmissionValidator();

  final ChapterNarrativeSubmissionValidator _submissionValidator;

  ChapterDeliveryStateResult evaluate(ChapterDeliveryStateRequest request) {
    if (!request.writeSucceeded) {
      return _result(
        request: request,
        state: request.retryableFailure
            ? ChapterDeliveryStateStatuses.missingOutputRecoverable
            : ChapterDeliveryStateStatuses.hardFailure,
        recommendedAction: request.retryableFailure
            ? 'request_chapter_repair'
            : 'manual_attention',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.executionFailed,
        reason: request.retryableFailure
            ? 'write_failed_retryable'
            : 'write_failed_hard',
        summary: request.failureReason.trim().isEmpty
            ? '章节交付写入失败。'
            : request.failureReason.trim(),
        blocksProgress: true,
        chapterBodyDelivered: false,
        submissionAccepted: false,
        retryable: request.retryableFailure,
        deliveryFailureCategory: ChapterDeliveryFailureCategories.writeFailed,
      );
    }

    final cleanContent = request.chapterContent.trim();
    if (cleanContent.isEmpty) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.missingOutputRecoverable,
        recommendedAction: 'request_chapter_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
        reason: 'chapter_content_missing',
        summary: '章节正文缺失或为空。',
        blocksProgress: true,
        chapterBodyDelivered: false,
        submissionAccepted: false,
        retryable: true,
        deliveryFailureCategory: ChapterDeliveryFailureCategories.emptyBody,
      );
    }

    if (_isTitleOnly(cleanContent, request.title)) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
        recommendedAction: 'request_chapter_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
        reason: 'title_only_output',
        summary: '章节输出只包含标题或缺少有效正文。',
        blocksProgress: true,
        chapterBodyDelivered: false,
        submissionAccepted: false,
        retryable: false,
        deliveryFailureCategory:
            ChapterDeliveryFailureCategories.titleOnlyOutput,
      );
    }

    final tooShortState = _tooShortBodyState(request, cleanContent);
    if (tooShortState != null) {
      return tooShortState;
    }

    if (_hasPathMismatch(request)) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.pathMismatchRecoverable,
        recommendedAction: 'request_chapter_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.executionFailed,
        reason: 'chapter_path_mismatch',
        summary: '章节写入路径与预期路径不一致。',
        blocksProgress: true,
        chapterBodyDelivered: false,
        submissionAccepted: false,
        retryable: true,
        deliveryFailureCategory: ChapterDeliveryFailureCategories.pathMismatch,
      );
    }

    final submissionState = _submissionState(request);
    if (submissionState != null) {
      return submissionState;
    }

    final qualityState = _qualityState(request);
    if (qualityState != null) {
      return qualityState;
    }

    final gateState = _gateState(request);
    if (gateState != null) {
      return gateState;
    }

    return _result(
      request: request,
      state: ChapterDeliveryStateStatuses.delivered,
      recommendedAction: 'accept',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
      reason: 'delivery_complete',
      summary: '章节正文与 submission 已通过当前交付状态机检查。',
      blocksProgress: false,
      chapterBodyDelivered: true,
      submissionAccepted: true,
      retryable: false,
    );
  }

  ChapterDeliveryStateResult? _submissionState(
    ChapterDeliveryStateRequest request,
  ) {
    final submission = request.submission;
    if (submission == null) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        recommendedAction: 'request_sidecar_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
        reason: 'submission_missing',
        summary: '章节正文已交付，但缺少结构化 submission。',
        blocksProgress: true,
        chapterBodyDelivered: true,
        submissionAccepted: false,
        retryable: true,
        deliveryFailureCategory:
            ChapterDeliveryFailureCategories.sidecarMissing,
      );
    }

    final validationErrors = _submissionValidator.validate(submission);
    if (validationErrors.isEmpty) {
      if (_evidenceMissing(request, submission)) {
        return _result(
          request: request,
          state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
          recommendedAction: 'request_sidecar_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
          reason: 'submission_evidence_missing',
          summary: '章节正文已交付，但缺少最小 evidence 记录。',
          blocksProgress: true,
          chapterBodyDelivered: true,
          submissionAccepted: false,
          retryable: true,
          deliveryFailureCategory:
              ChapterDeliveryFailureCategories.deliveryEvidenceMissing,
        );
      }
      return null;
    }

    return _result(
      request: request,
      state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
      recommendedAction: 'request_sidecar_repair',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
      reason: 'submission_invalid',
      summary: '章节正文已交付，但 submission 结构需要补修。',
      blocksProgress: true,
      chapterBodyDelivered: true,
      submissionAccepted: false,
      retryable: true,
      deliveryFailureCategory: ChapterDeliveryFailureCategories.sidecarInvalid,
      metadata: <String, Object?>{
        'submission_validation_errors': validationErrors,
      },
    );
  }

  ChapterDeliveryStateResult? _tooShortBodyState(
    ChapterDeliveryStateRequest request,
    String chapterContent,
  ) {
    final minimumBodyLength = request.minimumBodyLength;
    if (minimumBodyLength <= 0) {
      return null;
    }
    final effectiveLength = _effectiveBodyLength(request, chapterContent);
    if (effectiveLength >= minimumBodyLength) {
      return null;
    }
    return _result(
      request: request,
      state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
      recommendedAction: 'request_chapter_repair',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      reason: 'chapter_body_too_short',
      summary: '章节正文长度低于当前任务允许的最小正文阈值。',
      blocksProgress: true,
      chapterBodyDelivered: false,
      submissionAccepted: false,
      retryable: false,
      deliveryFailureCategory: ChapterDeliveryFailureCategories.bodyTooShort,
      metadata: <String, Object?>{
        'body_length': effectiveLength,
        'minimum_body_length': minimumBodyLength,
      },
    );
  }

  ChapterDeliveryStateResult? _qualityState(
    ChapterDeliveryStateRequest request,
  ) {
    final chapterLengthEvaluation = request.chapterLengthEvaluation;
    if (_isSeverelyOffLength(chapterLengthEvaluation)) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
        recommendedAction: 'request_chapter_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
        reason: 'chapter_length_severely_off',
        summary: '章节字数严重偏离当前任务目标，要求先返修或重写。',
        blocksProgress: true,
        chapterBodyDelivered: false,
        submissionAccepted: false,
        retryable: false,
        metadata: <String, Object?>{
          'chapter_length_level': chapterLengthEvaluation?.level,
          'chapter_length_recommended_action':
              chapterLengthEvaluation?.recommendedAction,
          'current_length': chapterLengthEvaluation?.currentRecord.length,
          'target_length': chapterLengthEvaluation?.profile.targetLength,
        },
      );
    }

    if (_missingExpressionConstraintReview(request)) {
      return _result(
        request: request,
        state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        recommendedAction: 'request_chapter_repair',
        suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
        reason: 'expression_constraint_review_missing',
        summary: '章节正文已交付，但缺少表达限制复核信号，暂不应视为稳定交付。',
        blocksProgress: true,
        chapterBodyDelivered: true,
        submissionAccepted: true,
        retryable: true,
      );
    }

    return null;
  }

  ChapterDeliveryStateResult? _gateState(ChapterDeliveryStateRequest request) {
    final gateDecision = request.gateDecision;
    if (gateDecision.isEmpty) {
      return null;
    }
    final disposition = ValueReaders.stringValue(
      gateDecision['disposition'],
    ).trim();
    switch (disposition) {
      case 'auto_continue':
        return null;
      case 'auto_create_repair_task':
        return _result(
          request: request,
          state: ChapterDeliveryStateStatuses.deliveredNeedsRepair,
          recommendedAction: 'request_chapter_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
          reason: ValueReaders.stringValue(
            gateDecision['reason'],
            'review_requires_repair',
          ).trim(),
          summary: '章节正文已交付，但 gate 要求先进入 repair。',
          blocksProgress: true,
          chapterBodyDelivered: true,
          submissionAccepted: true,
          retryable: true,
          metadata: gateDecision,
        );
      case 'blocked_wait_user':
        return _result(
          request: request,
          state: ChapterDeliveryStateStatuses.waitingUserChoice,
          recommendedAction: 'checkpoint_user',
          suggestedOutcomeStatus:
              DomainToolOutcomeStatuses.needsUserConfirmation,
          reason: ValueReaders.stringValue(
            gateDecision['reason'],
            'waiting_user_choice',
          ).trim(),
          summary: '章节已交付，但 gate 要求等待用户选择。',
          blocksProgress: true,
          chapterBodyDelivered: true,
          submissionAccepted: true,
          retryable: false,
          metadata: gateDecision,
        );
      case 'manual_attention':
        return _result(
          request: request,
          state: ChapterDeliveryStateStatuses.manualAttentionRequired,
          recommendedAction: 'manual_attention',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.proposed,
          reason: ValueReaders.stringValue(
            gateDecision['reason'],
            'manual_attention_required',
          ).trim(),
          summary: '章节已交付，但 gate 判定需要人工介入。',
          blocksProgress: true,
          chapterBodyDelivered: true,
          submissionAccepted: true,
          retryable: false,
          metadata: gateDecision,
        );
    }

    return _result(
      request: request,
      state: ChapterDeliveryStateStatuses.manualAttentionRequired,
      recommendedAction: 'manual_attention',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.proposed,
      reason: 'unknown_gate_disposition',
      summary: '章节 gate 返回了未知 disposition，进入人工关注。',
      blocksProgress: true,
      chapterBodyDelivered: true,
      submissionAccepted: true,
      retryable: false,
      metadata: gateDecision,
    );
  }

  bool _hasPathMismatch(ChapterDeliveryStateRequest request) {
    final expected = request.chapterPath.trim();
    final actual = request.resolvedChapterPath.trim();
    return expected.isNotEmpty && actual.isNotEmpty && expected != actual;
  }

  bool _evidenceMissing(
    ChapterDeliveryStateRequest request,
    dynamic submission,
  ) {
    return request.requireEvidence && submission.evidenceRefs.isEmpty;
  }

  bool _isSeverelyOffLength(ChapterLengthEvaluation? evaluation) {
    if (evaluation == null) {
      return false;
    }
    return evaluation.level == 'severely_off' ||
        evaluation.recommendedAction == 'review_or_repair';
  }

  bool _missingExpressionConstraintReview(ChapterDeliveryStateRequest request) {
    if (!request.requireExpressionConstraintReview) {
      return false;
    }
    final review =
        request.expressionConstraintReview ??
        const ExpressionConstraintReviewProjection();
    return review.isEmpty;
  }

  bool _isTitleOnly(String chapterContent, String title) {
    final normalizedContent = _normalizeLines(chapterContent);
    final normalizedTitle = title.trim();
    if (normalizedContent.isEmpty) {
      return false;
    }
    final bodyWithoutHeading = _removeLeadingTitleLine(
      normalizedContent,
      normalizedTitle,
    );
    return bodyWithoutHeading.trim().isEmpty;
  }

  String _normalizeLines(String value) {
    return value.replaceAll('\r\n', '\n').trim();
  }

  String _removeLeadingTitleLine(String content, String title) {
    final lines = content.split('\n');
    if (lines.isEmpty) {
      return content;
    }
    final firstLine = lines.first.trim();
    final normalizedTitle = title.trim();
    final markdownHeading = firstLine.startsWith('#')
        ? firstLine.replaceFirst(RegExp(r'^#+\s*'), '').trim()
        : '';
    final matchesTitle =
        normalizedTitle.isNotEmpty &&
        (firstLine == normalizedTitle || markdownHeading == normalizedTitle);
    if (!matchesTitle) {
      return content;
    }
    return lines.skip(1).join('\n');
  }

  int _effectiveBodyLength(
    ChapterDeliveryStateRequest request,
    String chapterContent,
  ) {
    final chapterLengthEvaluation = request.chapterLengthEvaluation;
    if (chapterLengthEvaluation != null &&
        chapterLengthEvaluation.currentRecord.length > 0) {
      return chapterLengthEvaluation.currentRecord.length;
    }
    return chapterContent.trim().length;
  }

  ChapterDeliveryStateResult _result({
    required ChapterDeliveryStateRequest request,
    required String state,
    required String recommendedAction,
    required String suggestedOutcomeStatus,
    required String reason,
    required String summary,
    required bool blocksProgress,
    required bool chapterBodyDelivered,
    required bool submissionAccepted,
    required bool retryable,
    String deliveryFailureCategory = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final resultMetadata = ValueReaders.deepCopyMap(<String, Object?>{
      ...request.metadata,
      ...metadata,
      'chapter_path': request.chapterPath,
      'resolved_chapter_path': request.resolvedChapterPath,
    });
    return ChapterDeliveryStateResult(
      deliveryId: request.deliveryId,
      state: state,
      recommendedAction: recommendedAction,
      suggestedOutcomeStatus: suggestedOutcomeStatus,
      reason: reason,
      summary: summary,
      blocksProgress: blocksProgress,
      chapterBodyDelivered: chapterBodyDelivered,
      submissionAccepted: submissionAccepted,
      retryable: retryable,
      deliveryFailure: deliveryFailureCategory.trim().isEmpty
          ? null
          : ChapterDeliveryFailure(
              category: deliveryFailureCategory.trim(),
              reason: reason,
              summary: summary,
              deliveryState: state,
              chapterPath: request.chapterPath,
              resolvedChapterPath: request.resolvedChapterPath,
              retryable: retryable,
              chapterBodyDelivered: chapterBodyDelivered,
              submissionAccepted: submissionAccepted,
              metadata: resultMetadata,
            ),
      metadata: resultMetadata,
    );
  }
}
