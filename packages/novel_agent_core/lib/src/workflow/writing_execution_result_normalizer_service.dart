import '../agents/sub_agent_result_package_service.dart';
import '../agents/child_failure_disposition.dart';
import '../agents/collaboration_arbitration_result.dart';
import '../agents/collaboration_conflict_record.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/context_activation/context_activation_item.dart';
import '../continuity/context_activation/context_activation_report.dart';
import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../review/expression_constraint_review_contract_mapper_service.dart';
import '../review/information_evidence_review_contract_mapper_service.dart';
import '../review/review_summary_builder_service.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
import 'chapter_delivery_failure.dart';
import 'chapter_delivery_state_result.dart';
import 'chapter_delivery_state_statuses.dart';
import 'chapter_length_discipline_summary.dart';
import 'chapter_length_evaluation.dart';
import 'expression_constraint_gate_signal.dart';
import 'expression_constraint_gate_signal_service.dart';
import 'information_evidence_gate_signal.dart';
import 'writing_execution_collaboration_summary.dart';
import 'writing_execution_constraint_bridge_result.dart';
import 'writing_execution_constraint_summary.dart';
import 'writing_execution_delivery_summary.dart';
import 'writing_execution_information_summary.dart';
import 'writing_execution_outcome_statuses.dart';
import 'writing_execution_recovery_summary.dart';
import 'writing_execution_result.dart';

class WritingExecutionResultNormalizerService {
  WritingExecutionResultNormalizerService({
    SubAgentResultPackageService? subAgentResultPackageService,
    ExpressionConstraintGateSignalService?
    expressionConstraintGateSignalService,
    ExpressionConstraintReviewContractMapperService?
    expressionConstraintReviewContractMapperService,
    InformationEvidenceReviewContractMapperService?
    informationEvidenceReviewContractMapperService,
    ReviewSummaryBuilderService? reviewSummaryBuilderService,
  }) : _subAgentResultPackageService =
           subAgentResultPackageService ?? SubAgentResultPackageService(),
       _expressionConstraintGateSignalService =
           expressionConstraintGateSignalService ??
           const ExpressionConstraintGateSignalService(),
       _expressionConstraintReviewContractMapperService =
           expressionConstraintReviewContractMapperService ??
           const ExpressionConstraintReviewContractMapperService(),
       _informationEvidenceReviewContractMapperService =
           informationEvidenceReviewContractMapperService ??
           const InformationEvidenceReviewContractMapperService(),
       _reviewSummaryBuilderService =
           reviewSummaryBuilderService ?? const ReviewSummaryBuilderService();

  final SubAgentResultPackageService _subAgentResultPackageService;
  final ExpressionConstraintGateSignalService
  _expressionConstraintGateSignalService;
  final ExpressionConstraintReviewContractMapperService
  _expressionConstraintReviewContractMapperService;
  final InformationEvidenceReviewContractMapperService
  _informationEvidenceReviewContractMapperService;
  final ReviewSummaryBuilderService _reviewSummaryBuilderService;

  WritingExecutionResult normalize({
    required String executionId,
    required String workflowKind,
    ChapterDeliveryStateResult? deliveryState,
    WritingExecutionConstraintBridgeResult? constraintBridgeResult,
    ChapterLengthEvaluation? chapterLengthEvaluation,
    ExpressionConstraintReviewProjection? expressionConstraintReview,
    ContextActivationReport? activationReport,
    JsonMap informationSignal = const <String, Object?>{},
    List<Object?> collaborationResults = const <Object?>[],
    JsonMap recoveryPlan = const <String, Object?>{},
    bool transportFailed = false,
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: normalizer 只负责把现有散落信号归并成共享结果合同，不修改任何既有 runtime 或 tool 返回值。
    final delivery = _deliverySummary(deliveryState);
    final constraints = _constraintSummary(
      executionId: executionId,
      bridgeResult: constraintBridgeResult,
      chapterLengthEvaluation: chapterLengthEvaluation,
      expressionConstraintReview: expressionConstraintReview,
      deliveryState: deliveryState,
    );
    final information = _informationSummary(
      executionId: executionId,
      activationReport: activationReport,
      informationSignal: informationSignal,
      deliveryState: deliveryState,
    );
    final collaboration = _collaborationSummary(
      collaborationResults,
      metadata: metadata,
    );
    final recovery = _recoverySummary(recoveryPlan);
    final overallStatus = _overallStatus(
      transportFailed: transportFailed,
      delivery: delivery,
      constraints: constraints,
      information: information,
      collaboration: collaboration,
      recovery: recovery,
    );
    final requiresUserAction =
        recovery.waitingUser ||
        recovery.manualAttentionRequired ||
        information.waitingUser ||
        information.manualAttentionRequired ||
        collaboration.userConfirmationConflictCount > 0 ||
        delivery.state == ChapterDeliveryStateStatuses.waitingUserChoice;
    final retryable =
        delivery.retryable ||
        recovery.retryable ||
        overallStatus == WritingExecutionOutcomeStatuses.recoverableFailure;
    final blocksProgress =
        delivery.blocksProgress ||
        constraints.repairRequired ||
        constraints.contentQualityRisk ||
        information.requiresRepair ||
        information.waitingUser ||
        information.manualAttentionRequired ||
        collaboration.blockingFailureCount > 0 ||
        collaboration.repairRequiredConflictCount > 0 ||
        collaboration.userConfirmationConflictCount > 0 ||
        recovery.present;
    return WritingExecutionResult(
      executionId: executionId.trim(),
      workflowKind: workflowKind.trim(),
      overallStatus: overallStatus,
      summary: _summaryForStatus(
        overallStatus,
        delivery: delivery,
        constraints: constraints,
        information: information,
        collaboration: collaboration,
        recovery: recovery,
      ),
      delivery: delivery,
      constraints: constraints,
      information: information,
      collaboration: collaboration,
      recovery: recovery,
      nextAction: _nextAction(
        delivery: delivery,
        constraints: constraints,
        collaboration: collaboration,
        recovery: recovery,
      ),
      blocksProgress: blocksProgress,
      retryable: retryable,
      requiresUserAction: requiresUserAction,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  WritingExecutionDeliverySummary _deliverySummary(
    ChapterDeliveryStateResult? deliveryState,
  ) {
    // 中文注释: delivery 归并保持最小映射，只把状态机稳定字段搬进共享合同，不再额外推断正文内容。
    if (deliveryState == null) {
      return const WritingExecutionDeliverySummary();
    }
    final metadata = deliveryState.metadata;
    final deliveryFailure =
        deliveryState.deliveryFailure ?? _legacyDeliveryFailure(deliveryState);
    return WritingExecutionDeliverySummary(
      present: true,
      deliveryId: deliveryState.deliveryId,
      state: deliveryState.state,
      recommendedAction: deliveryState.recommendedAction,
      suggestedOutcomeStatus: deliveryState.suggestedOutcomeStatus,
      reason: deliveryState.reason,
      summary: deliveryState.summary,
      chapterPath: ValueReaders.stringValue(metadata['chapter_path']).trim(),
      resolvedChapterPath: ValueReaders.stringValue(
        metadata['resolved_chapter_path'],
      ).trim(),
      blocksProgress: deliveryState.blocksProgress,
      chapterBodyDelivered: deliveryState.chapterBodyDelivered,
      submissionAccepted: deliveryState.submissionAccepted,
      retryable: deliveryState.retryable,
      deliveryFailure: deliveryFailure,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  ChapterDeliveryFailure? _legacyDeliveryFailure(
    ChapterDeliveryStateResult deliveryState,
  ) {
    final category = _legacyDeliveryFailureCategory(deliveryState.reason);
    if (category.isEmpty) {
      return null;
    }
    return ChapterDeliveryFailure(
      category: category,
      reason: deliveryState.reason,
      summary: deliveryState.summary,
      deliveryState: deliveryState.state,
      chapterPath: ValueReaders.stringValue(
        deliveryState.metadata['chapter_path'],
      ).trim(),
      resolvedChapterPath: ValueReaders.stringValue(
        deliveryState.metadata['resolved_chapter_path'],
      ).trim(),
      retryable: deliveryState.retryable,
      chapterBodyDelivered: deliveryState.chapterBodyDelivered,
      submissionAccepted: deliveryState.submissionAccepted,
      metadata: ValueReaders.deepCopyMap(deliveryState.metadata),
    );
  }

  String _legacyDeliveryFailureCategory(String reason) {
    switch (reason.trim()) {
      case 'write_failed_retryable':
      case 'write_failed_hard':
        return ChapterDeliveryFailureCategories.writeFailed;
      case 'chapter_content_missing':
        return ChapterDeliveryFailureCategories.emptyBody;
      case 'title_only_output':
        return ChapterDeliveryFailureCategories.titleOnlyOutput;
      case 'chapter_body_too_short':
        return ChapterDeliveryFailureCategories.bodyTooShort;
      case 'chapter_path_mismatch':
        return ChapterDeliveryFailureCategories.pathMismatch;
      case 'submission_missing':
        return ChapterDeliveryFailureCategories.sidecarMissing;
      case 'submission_invalid':
        return ChapterDeliveryFailureCategories.sidecarInvalid;
      case 'submission_evidence_missing':
        return ChapterDeliveryFailureCategories.deliveryEvidenceMissing;
    }
    return '';
  }

  WritingExecutionConstraintSummary _constraintSummary({
    required String executionId,
    required WritingExecutionConstraintBridgeResult? bridgeResult,
    required ChapterLengthEvaluation? chapterLengthEvaluation,
    required ExpressionConstraintReviewProjection? expressionConstraintReview,
    required ChapterDeliveryStateResult? deliveryState,
  }) {
    // 中文注释: 约束摘要把字数评估、表达限制与 review projection 对齐到同一结果对象，不改现有 bridge 逻辑。
    final review =
        expressionConstraintReview ??
        const ExpressionConstraintReviewProjection();
    final bridge =
        bridgeResult ?? const WritingExecutionConstraintBridgeResult();
    final chapterLengthMetadata = bridge.chapterLengthMetadata;
    final chapterLengthConfigured = chapterLengthEvaluation != null
        ? chapterLengthEvaluation.profile.isConfigured
        : chapterLengthMetadata.isNotEmpty;
    final chapterLengthLevel = chapterLengthEvaluation?.level.trim() ?? '';
    final chapterLengthRecommendedAction =
        chapterLengthEvaluation?.recommendedAction.trim() ?? '';
    final expressionConstraintActive =
        bridge.projectExpressionConstraintBindings.isNotEmpty;
    final expressionConstraintPolicyMode =
        bridge.expressionConstraintPolicyMode.trim().isEmpty
        ? ExpressionConstraintExecutionPolicyModes.disabled
        : bridge.expressionConstraintPolicyMode.trim();
    final expressionConstraintDisabled =
        expressionConstraintPolicyMode ==
        ExpressionConstraintExecutionPolicyModes.disabled;
    final expressionConstraintApplied =
        expressionConstraintActive && bridge.expressionConstraintApplied;
    final expressionConstraintSkipped =
        expressionConstraintActive &&
        !expressionConstraintDisabled &&
        !expressionConstraintApplied &&
        (bridge.expressionConstraintSkippedReasons.isNotEmpty ||
            bridge.expressionConstraintTechnicalTurnExcluded);
    final expressionConstraintInjectionStrength =
        bridge.expressionConstraintInjectionStrength.trim().isEmpty
        ? ExpressionConstraintInjectionStrengths.none
        : bridge.expressionConstraintInjectionStrength.trim();
    final expressionConstraintReviewRequirement =
        bridge.expressionConstraintReviewRequirement.trim().isEmpty
        ? ExpressionConstraintReviewRequirements.none
        : bridge.expressionConstraintReviewRequirement.trim();
    final expressionConstraintViolationDisposition =
        bridge.expressionConstraintViolationDisposition.trim().isEmpty
        ? ExpressionConstraintViolationDispositions.remind
        : bridge.expressionConstraintViolationDisposition.trim();
    final expressionConstraintReviewProvided = !review.isEmpty;
    final expressionConstraintReviewRequired =
        expressionConstraintApplied &&
        expressionConstraintReviewRequirement !=
            ExpressionConstraintReviewRequirements.none;
    final expressionConstraintEvidenceMissing =
        expressionConstraintReviewRequired &&
        !expressionConstraintReviewProvided;
    final expressionConstraintGate = _expressionConstraintGateSignalService
        .build(bridgeResult: bridge, review: review);
    final expressionConstraintReviewContract =
        _expressionConstraintReviewContractMapperService.buildReview(
          executionId: executionId,
          bridgeResult: bridge,
          review: review,
          gateSignal: expressionConstraintGate,
          sourcePaths: _constraintSourcePaths(deliveryState),
          targetPaths: _constraintTargetPaths(deliveryState),
          evidencePaths: _constraintEvidencePaths(deliveryState),
        );
    final expressionConstraintReviewSummary =
        expressionConstraintReviewContract == null
        ? null
        : _reviewSummaryBuilderService.buildSummary(
            expressionConstraintReviewContract,
          );
    final expressionConstraintViolationRecorded =
        expressionConstraintGate.riskSignals.isNotEmpty;
    final hardGateReasons = _constraintHardGateReasons(
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
      expressionConstraintGate: expressionConstraintGate,
    );
    final softGateReasons = _constraintSoftGateReasons(
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      expressionConstraintApplied: expressionConstraintApplied,
      expressionConstraintSkipped: expressionConstraintSkipped,
      expressionConstraintReviewProvided: expressionConstraintReviewProvided,
      expressionConstraintGate: expressionConstraintGate,
    );
    final hardConstraintTriggered = hardGateReasons.isNotEmpty;
    final repairRequired =
        hardConstraintTriggered || expressionConstraintGate.repairRequired;
    final reviewSuggested =
        hardConstraintTriggered || softGateReasons.isNotEmpty;
    final reminderOnly =
        reviewSuggested &&
        !repairRequired &&
        !expressionConstraintGate.adjustNextChapter;
    final contentQualityRisk = hardConstraintTriggered;
    final chapterLengthHardGateTriggered =
        chapterLengthLevel == 'severely_off' ||
        chapterLengthRecommendedAction == 'review_or_repair';
    final chapterLengthReviewSuggested =
        chapterLengthHardGateTriggered ||
        chapterLengthLevel == 'needs_rebalance' ||
        chapterLengthRecommendedAction == 'adjust_next_chapter' ||
        chapterLengthRecommendedAction == 'remind';
    final chapterLengthReminderOnly =
        chapterLengthReviewSuggested &&
        !chapterLengthHardGateTriggered &&
        chapterLengthRecommendedAction == 'remind';
    final chapterLengthDiscipline = _chapterLengthDisciplineSummary(
      chapterLengthEvaluation: chapterLengthEvaluation,
      hardGateTriggered: chapterLengthHardGateTriggered,
      reviewSuggested: chapterLengthReviewSuggested,
      reminderOnly: chapterLengthReminderOnly,
      repairRequired: chapterLengthHardGateTriggered,
    );
    final notes = <String>[
      if (chapterLengthEvaluation != null) ...chapterLengthEvaluation.notes,
      ...review.voiceProtectionNotes,
    ];
    final summary = _constraintSummaryText(
      chapterLengthConfigured: chapterLengthConfigured,
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      profileCount: bridge.expressionConstraintProfiles.length,
      bindingCount: bridge.projectExpressionConstraintBindings.length,
      expressionConstraintPolicyMode: expressionConstraintPolicyMode,
      expressionConstraintApplied: expressionConstraintApplied,
      expressionConstraintSkipped: expressionConstraintSkipped,
      expressionConstraintInjectionMode:
          bridge.expressionConstraintInjectionMode,
      expressionConstraintInjectionStrength:
          expressionConstraintInjectionStrength,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
      expressionConstraintReviewProvided: expressionConstraintReviewProvided,
      expressionConstraintViolationRecorded:
          expressionConstraintViolationRecorded,
      skippedReasons: bridge.expressionConstraintSkippedReasons,
      expressionConstraintGate: expressionConstraintGate,
      review: review,
    );
    return WritingExecutionConstraintSummary(
      present:
          chapterLengthConfigured ||
          bridge.hasExpressionConstraintRuntime ||
          !review.isEmpty,
      chapterLengthConfigured: chapterLengthConfigured,
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      chapterLengthCurrent: chapterLengthEvaluation?.currentRecord.length ?? 0,
      chapterLengthTarget:
          chapterLengthEvaluation?.profile.targetLength ??
          ValueReaders.intValue(chapterLengthMetadata['chapter_word_target']),
      expressionConstraintProfileCount:
          bridge.expressionConstraintProfiles.length,
      expressionConstraintBindingCount:
          bridge.projectExpressionConstraintBindings.length,
      authenticityPassLevel: review.authenticityPassLevel,
      reviewFocuses: List<String>.unmodifiable(review.reviewFocuses),
      continuityWatchItems: List<String>.unmodifiable(
        review.continuityWatchItems,
      ),
      miniRecheckItems: List<String>.unmodifiable(review.miniRecheckItems),
      voiceProtectionNotes: List<String>.unmodifiable(
        review.voiceProtectionNotes,
      ),
      notes: List<String>.unmodifiable(notes),
      hardConstraintTriggered: hardConstraintTriggered,
      reviewSuggested: reviewSuggested,
      contentQualityRisk: contentQualityRisk,
      repairRequired: repairRequired,
      reminderOnly: reminderOnly,
      expressionConstraintActive: expressionConstraintActive,
      expressionConstraintPolicyMode: expressionConstraintPolicyMode,
      expressionConstraintInjectionStrength:
          expressionConstraintInjectionStrength,
      expressionConstraintReviewRequirement:
          expressionConstraintReviewRequirement,
      expressionConstraintViolationDisposition:
          expressionConstraintViolationDisposition,
      expressionConstraintApplied: expressionConstraintApplied,
      expressionConstraintDisabled: expressionConstraintDisabled,
      expressionConstraintSkipped: expressionConstraintSkipped,
      expressionConstraintRuntimeEscalated:
          bridge.expressionConstraintRuntimeEscalated,
      expressionConstraintTechnicalTurnExcluded:
          bridge.expressionConstraintTechnicalTurnExcluded,
      expressionConstraintInjectionMode:
          bridge.expressionConstraintInjectionMode,
      expressionConstraintReviewRequired: expressionConstraintReviewRequired,
      expressionConstraintReviewProvided: expressionConstraintReviewProvided,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
      expressionConstraintViolationRecorded:
          expressionConstraintViolationRecorded,
      expressionConstraintAppliedReasons: List<String>.unmodifiable(
        bridge.expressionConstraintAppliedReasons,
      ),
      expressionConstraintSkippedReasons: List<String>.unmodifiable(
        bridge.expressionConstraintSkippedReasons,
      ),
      expressionConstraintGate: expressionConstraintGate,
      expressionConstraintReviewContract: expressionConstraintReviewContract,
      expressionConstraintReviewSummary: expressionConstraintReviewSummary,
      hardGateReasons: List<String>.unmodifiable(hardGateReasons),
      softGateReasons: List<String>.unmodifiable(softGateReasons),
      summary: summary,
      chapterLengthDiscipline: chapterLengthDiscipline,
      chapterLengthMetadata: ValueReaders.deepCopyMap(chapterLengthMetadata),
      runtimeReport: ValueReaders.deepCopyMap(bridge.runtimeReport),
      metadata: <String, Object?>{
        'has_bridge_runtime': bridge.runtimeReport.isNotEmpty,
        'expression_constraint_policy_mode': expressionConstraintPolicyMode,
        if (expressionConstraintReviewContract != null)
          'expression_constraint_review_id':
              expressionConstraintReviewContract.reviewId,
      },
    );
  }

  List<String> _constraintSourcePaths(ChapterDeliveryStateResult? deliveryState) {
    // 中文注释: 表达限制统一审稿合同优先复用真实章节路径，避免 handoff 只能拿到抽象 execution id。
    if (deliveryState == null) {
      return const <String>[];
    }
    return _nonEmptyPaths(<String>[
      ValueReaders.stringValue(deliveryState.metadata['resolved_chapter_path']),
      ValueReaders.stringValue(deliveryState.metadata['chapter_path']),
    ]);
  }

  List<String> _constraintTargetPaths(ChapterDeliveryStateResult? deliveryState) {
    // 中文注释: target path 与 source path 共用 delivery 真相，确保 repair lane 能直接定位当前正文文件。
    if (deliveryState == null) {
      return const <String>[];
    }
    return _nonEmptyPaths(<String>[
      ValueReaders.stringValue(deliveryState.metadata['chapter_path']),
      ValueReaders.stringValue(deliveryState.metadata['resolved_chapter_path']),
    ]);
  }

  List<String> _constraintEvidencePaths(
    ChapterDeliveryStateResult? deliveryState,
  ) {
    // 中文注释: 当前阶段没有独立 reviews/ 落盘时，先把真实交付路径作为统一审稿证据锚点。
    if (deliveryState == null) {
      return const <String>[];
    }
    final failure = deliveryState.deliveryFailure;
    return _nonEmptyPaths(<String>[
      ValueReaders.stringValue(deliveryState.metadata['chapter_path']),
      ValueReaders.stringValue(deliveryState.metadata['resolved_chapter_path']),
      failure?.chapterPath ?? '',
      failure?.resolvedChapterPath ?? '',
    ]);
  }

  List<String> _nonEmptyPaths(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return List<String>.unmodifiable(result);
  }

  ChapterLengthDisciplineSummary _chapterLengthDisciplineSummary({
    required ChapterLengthEvaluation? chapterLengthEvaluation,
    required bool hardGateTriggered,
    required bool reviewSuggested,
    required bool reminderOnly,
    required bool repairRequired,
  }) {
    // 中文注释: 这里把字数评估正式投影成统一纪律摘要，供 supervisor/runtime 直接消费阈值与处置层级。
    if (chapterLengthEvaluation == null) {
      return const ChapterLengthDisciplineSummary();
    }
    return ChapterLengthDisciplineSummary(
      present: true,
      configured: chapterLengthEvaluation.profile.isConfigured,
      currentLength: chapterLengthEvaluation.currentRecord.length,
      targetLength: chapterLengthEvaluation.profile.targetLength,
      preferredMinLength: chapterLengthEvaluation.profile.preferredMin,
      preferredMaxLength: chapterLengthEvaluation.profile.preferredMax,
      mildDeviationRatioThreshold:
          chapterLengthEvaluation.policy.mildDeviationRatio,
      severeDeviationRatioThreshold:
          chapterLengthEvaluation.policy.severeDeviationRatio,
      mildAdjacentDeltaRatioThreshold:
          chapterLengthEvaluation.policy.mildAdjacentDeltaRatio,
      severeAdjacentDeltaRatioThreshold:
          chapterLengthEvaluation.policy.severeAdjacentDeltaRatio,
      targetDeviationRatio: chapterLengthEvaluation.targetDeviationRatio,
      adjacentDeltaRatio: chapterLengthEvaluation.adjacentDeltaRatio,
      level: chapterLengthEvaluation.level,
      recommendedAction: chapterLengthEvaluation.recommendedAction,
      hardGateTriggered: hardGateTriggered,
      reviewSuggested: reviewSuggested,
      reminderOnly: reminderOnly,
      repairRequired: repairRequired,
      notes: List<String>.unmodifiable(chapterLengthEvaluation.notes),
      metadata: <String, Object?>{
        'rolling_average_length': chapterLengthEvaluation.rollingAverageLength,
        'previous_length': chapterLengthEvaluation.previousLength,
        'adjacent_delta': chapterLengthEvaluation.adjacentDelta,
        'target_deviation': chapterLengthEvaluation.targetDeviation,
        'history_samples_used': chapterLengthEvaluation.historySamplesUsed,
        'metric_unit': chapterLengthEvaluation.profile.metricUnit,
      },
    );
  }

  String _constraintSummaryText({
    required bool chapterLengthConfigured,
    required String chapterLengthLevel,
    required String chapterLengthRecommendedAction,
    required int profileCount,
    required int bindingCount,
    required String expressionConstraintPolicyMode,
    required bool expressionConstraintApplied,
    required bool expressionConstraintSkipped,
    required String expressionConstraintInjectionMode,
    required String expressionConstraintInjectionStrength,
    required bool expressionConstraintEvidenceMissing,
    required bool expressionConstraintReviewProvided,
    required bool expressionConstraintViolationRecorded,
    required List<String> skippedReasons,
    required ExpressionConstraintGateSignal expressionConstraintGate,
    required ExpressionConstraintReviewProjection review,
  }) {
    // 中文注释: 约束摘要文案保持人话优先，便于后续 session 直接投影给 GUI/CLI 而不翻译内部字段。
    final parts = <String>[];
    if (chapterLengthConfigured) {
      parts.add(
        chapterLengthLevel.isEmpty ? '已启用字数策略' : '字数分布：$chapterLengthLevel',
      );
      if (chapterLengthRecommendedAction == 'adjust_next_chapter') {
        parts.add('建议后续章节回调字数分布');
      } else if (chapterLengthRecommendedAction == 'remind') {
        parts.add('当前只需记录字数提醒');
      } else if (chapterLengthRecommendedAction == 'review_or_repair') {
        parts.add('当前字数偏离已进入返修门槛');
      }
    }
    if (bindingCount > 0) {
      if (expressionConstraintPolicyMode ==
          ExpressionConstraintExecutionPolicyModes.disabled) {
        parts.add('表达限制：当前策略已关闭');
      } else if (expressionConstraintApplied) {
        parts.add(
          '表达限制：$profileCount 条 profile，$bindingCount 条绑定，按 $expressionConstraintInjectionStrength 强度应用，注入模式 $expressionConstraintInjectionMode',
        );
      } else if (expressionConstraintSkipped) {
        final skippedReason = skippedReasons.isEmpty
            ? ''
            : skippedReasons.first;
        parts.add(
          skippedReason.isEmpty
              ? '表达限制：当前轮次未应用'
              : '表达限制：当前轮次未应用（$skippedReason）',
        );
      } else {
        parts.add('表达限制：当前存在绑定，但本轮没有形成应用信号');
      }
    } else if (profileCount > 0) {
      parts.add('表达限制库：$profileCount 条 profile 可用，但当前项目没有启用 binding');
    }
    if (expressionConstraintEvidenceMissing) {
      parts.add('缺少表达限制复核证据');
    } else if (expressionConstraintReviewProvided) {
      parts.add('已记录表达限制复核证据');
    }
    if (expressionConstraintViolationRecorded) {
      parts.add('已记录表达限制风险信号');
    }
    if (expressionConstraintGate.summary.trim().isNotEmpty &&
        !parts.contains(expressionConstraintGate.summary.trim())) {
      parts.add(expressionConstraintGate.summary.trim());
    }
    if (!review.isEmpty) {
      parts.add('复核强度：${review.authenticityPassLevel}');
    }
    if (parts.isEmpty) {
      return '当前没有额外的字数或表达限制信号。';
    }
    return parts.join('，');
  }

  List<String> _constraintHardGateReasons({
    required String chapterLengthLevel,
    required String chapterLengthRecommendedAction,
    required bool expressionConstraintEvidenceMissing,
    required ExpressionConstraintGateSignal expressionConstraintGate,
  }) {
    // 中文注释: 硬 gate 原因只保留会触发返修/阻断的稳定原因码，避免宿主再各自判断严重程度。
    final reasons = <String>[];
    if (chapterLengthLevel == 'severely_off' ||
        chapterLengthRecommendedAction == 'review_or_repair') {
      reasons.add('chapter_length_severely_off');
    }
    if (expressionConstraintEvidenceMissing) {
      reasons.add('expression_constraint_review_missing');
    }
    if (expressionConstraintGate.repairRequired) {
      reasons.add(
        expressionConstraintGate.reason.trim().isEmpty
            ? 'expression_constraint_gate_repair_required'
            : expressionConstraintGate.reason.trim(),
      );
    }
    return reasons;
  }

  List<String> _constraintSoftGateReasons({
    required String chapterLengthLevel,
    required String chapterLengthRecommendedAction,
    required bool expressionConstraintApplied,
    required bool expressionConstraintSkipped,
    required bool expressionConstraintReviewProvided,
    required ExpressionConstraintGateSignal expressionConstraintGate,
  }) {
    // 中文注释: 软 gate 原因只表达提醒或后续回调，不把它们升级成必须返修的阻断信号。
    final reasons = <String>[];
    if (chapterLengthLevel == 'needs_rebalance' ||
        chapterLengthRecommendedAction == 'adjust_next_chapter') {
      reasons.add('chapter_length_needs_rebalance');
    } else if (chapterLengthLevel == 'slightly_off' ||
        chapterLengthRecommendedAction == 'remind') {
      reasons.add('chapter_length_slightly_off');
    }
    if (expressionConstraintApplied && expressionConstraintReviewProvided) {
      reasons.add('expression_constraint_review_recorded');
    }
    if (expressionConstraintSkipped) {
      reasons.add('expression_constraint_skipped');
    }
    if (expressionConstraintGate.adjustNextChapter) {
      reasons.add('expression_constraint_adjust_next_chapter');
    } else if (expressionConstraintGate.recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.remind) {
      reasons.add('expression_constraint_remind');
    }
    if (expressionConstraintGate.riskSignals.isNotEmpty) {
      reasons.add('expression_constraint_violation_recorded');
    }
    return reasons;
  }

  WritingExecutionInformationSummary _informationSummary({
    required String executionId,
    required ContextActivationReport? activationReport,
    required JsonMap informationSignal,
    required ChapterDeliveryStateResult? deliveryState,
  }) {
    // 中文注释: information 摘要把 activation 报告与风险信号合并成共享视图，避免宿主继续自己统计数量。
    final report = activationReport;
    final items = report?.items ?? const [];
    final selectedCount =
        report?.selectedItemIds.length ??
        items.where((item) => item.selected).length;
    final omittedCount =
        report?.omittedItemIds.length ??
        items.where((item) => item.omitted).length;
    final truncatedCount =
        report?.truncatedItemIds.length ??
        items.where((item) => item.truncated).length;
    final requiredOmittedCount = items.where((item) {
      if (!item.omitted) {
        return false;
      }
      return ValueReaders.boolValue(item.metadata['required']);
    }).length;
    final changedPaths = ValueReaders.stringList(
      informationSignal['changed_paths'],
    );
    final riskCategory = ValueReaders.stringValue(
      informationSignal['category'],
      changedPaths.isNotEmpty ? 'accept' : '',
    ).trim();
    final requiredOmittedSignalCount = ValueReaders.intValue(
      informationSignal['required_information_omitted_count'],
      ValueReaders.intValue(informationSignal['required_omitted_count']),
    );
    final evidenceGate =
        InformationEvidenceGateSignal.fromJson(<String, Object?>{
          ...informationSignal,
          'present': report != null || informationSignal.isNotEmpty,
          'category': riskCategory,
          'changed_paths': changedPaths,
          'required_information_omitted_count': requiredOmittedSignalCount > 0
              ? requiredOmittedSignalCount
              : requiredOmittedCount,
        });
    final summary = evidenceGate.summary.isNotEmpty
        ? evidenceGate.summary
        : _informationEvidenceSummary(
            evidenceGate: evidenceGate,
            informationSignal: informationSignal,
            changedPaths: changedPaths,
            fallbackSummary: ValueReaders.stringValue(
              informationSignal['summary'],
              report?.summary ?? '',
            ).trim(),
          );
    final informationSummary = WritingExecutionInformationSummary(
      present: report != null || informationSignal.isNotEmpty,
      activationReportId: report?.reportId ?? '',
      activationPlanId: report?.planId ?? '',
      activationSource: report?.source ?? '',
      activationSummary: report?.summary ?? '',
      budgetChars: report?.budgetChars ?? 0,
      usedChars: report?.usedChars ?? 0,
      selectedItemCount: selectedCount,
      omittedItemCount: omittedCount,
      requiredOmittedItemCount: requiredOmittedCount,
      truncatedItemCount: truncatedCount,
      changedPathCount: changedPaths.length,
      riskCategory: evidenceGate.recommendedDisposition.isNotEmpty
          ? evidenceGate.recommendedDisposition
          : riskCategory,
      reason: evidenceGate.reason,
      summary: summary.isEmpty
          ? (changedPaths.isEmpty
                ? '当前没有新的 information 激活或风险信号。'
                : '当前已有 information 改动，建议在后续 checkpoint 中复核。')
          : summary,
      changedPaths: List<String>.unmodifiable(changedPaths),
      waitingUser: evidenceGate.waitingUser,
      requiresRepair: evidenceGate.requiresRepair,
      manualAttentionRequired: evidenceGate.manualAttentionRequired,
      evidenceGate: evidenceGate,
    );
    final informationEvidenceReviewContract =
        _informationEvidenceReviewContractMapperService.buildReview(
          executionId: executionId,
          information: informationSummary,
          sourcePaths: _informationSourcePaths(deliveryState),
          targetPaths: _informationTargetPaths(deliveryState, changedPaths),
          evidencePaths: changedPaths,
        );
    final informationEvidenceReviewSummary =
        informationEvidenceReviewContract == null
        ? null
        : _reviewSummaryBuilderService.buildSummary(
            informationEvidenceReviewContract,
          );
    return WritingExecutionInformationSummary(
      present: informationSummary.present,
      activationReportId: informationSummary.activationReportId,
      activationPlanId: informationSummary.activationPlanId,
      activationSource: informationSummary.activationSource,
      activationSummary: informationSummary.activationSummary,
      budgetChars: informationSummary.budgetChars,
      usedChars: informationSummary.usedChars,
      selectedItemCount: informationSummary.selectedItemCount,
      omittedItemCount: informationSummary.omittedItemCount,
      requiredOmittedItemCount: informationSummary.requiredOmittedItemCount,
      truncatedItemCount: informationSummary.truncatedItemCount,
      changedPathCount: informationSummary.changedPathCount,
      riskCategory: informationSummary.riskCategory,
      reason: informationSummary.reason,
      summary: informationSummary.summary,
      changedPaths: informationSummary.changedPaths,
      waitingUser: informationSummary.waitingUser,
      requiresRepair: informationSummary.requiresRepair,
      manualAttentionRequired: informationSummary.manualAttentionRequired,
      evidenceGate: informationSummary.evidenceGate,
      informationEvidenceReviewContract: informationEvidenceReviewContract,
      informationEvidenceReviewSummary: informationEvidenceReviewSummary,
      metadata: <String, Object?>{
        'evidence_gate': evidenceGate.toJson(),
        'evidence_severity': evidenceGate.severity,
        'evidence_recommended_disposition': evidenceGate.recommendedDisposition,
        'pending_research_count': ValueReaders.intValue(
          evidenceGate.pendingResearchCount,
        ),
        'awaiting_confirmation_count': evidenceGate.awaitingConfirmationCount,
        'gateway_failure_count': evidenceGate.gatewayFailureCount,
        'rigorous_source_insufficient_count':
            evidenceGate.rigorousSourceInsufficientCount,
        'required_information_omitted_count':
            evidenceGate.requiredInformationOmittedCount,
        'external_fact_unverified_count':
            evidenceGate.externalFactUnverifiedCount,
        'high_risk_reference_count': ValueReaders.intValue(
          informationSignal['high_risk_reference_count'],
        ),
        'design_conflict_count': ValueReaders.intValue(
          informationSignal['design_conflict_count'],
        ),
        if (report != null) ...<String, Object?>{
          'selected_item_ids': report.selectedItemIds,
          'omitted_item_ids': report.omittedItemIds,
          'truncated_item_ids': report.truncatedItemIds,
          'selected_source_kind_counts': _sourceKindCounts(
            _activationItemsByIds(
              report,
              report.selectedItemIds,
              fallback: (item) => item.selected,
            ),
          ),
          'omitted_source_kind_counts': _sourceKindCounts(
            _activationItemsByIds(
              report,
              report.omittedItemIds,
              fallback: (item) => item.omitted,
            ),
          ),
          'truncated_source_kind_counts': _sourceKindCounts(
            _activationItemsByIds(
              report,
              report.truncatedItemIds,
              fallback: (item) => item.truncated,
            ),
          ),
          'selected_item_paths':
              _activationItemsByIds(
                    report,
                    report.selectedItemIds,
                    fallback: (item) => item.selected,
                  )
                  .map((item) => item.targetPath)
                  .where((path) => path.isNotEmpty)
                  .toList(growable: false),
          'omitted_item_paths':
              _activationItemsByIds(
                    report,
                    report.omittedItemIds,
                    fallback: (item) => item.omitted,
                  )
                  .map((item) => item.targetPath)
                  .where((path) => path.isNotEmpty)
                  .toList(growable: false),
          'truncated_item_paths':
              _activationItemsByIds(
                    report,
                    report.truncatedItemIds,
                    fallback: (item) => item.truncated,
                  )
                  .map((item) => item.targetPath)
                  .where((path) => path.isNotEmpty)
                  .toList(growable: false),
          'selected_source_refs': _activationSourceRefs(
            _activationItemsByIds(
              report,
              report.selectedItemIds,
              fallback: (item) => item.selected,
            ),
          ),
          'omitted_source_refs': _activationSourceRefs(
            _activationItemsByIds(
              report,
              report.omittedItemIds,
              fallback: (item) => item.omitted,
            ),
          ),
          'truncated_source_refs': _activationSourceRefs(
            _activationItemsByIds(
              report,
              report.truncatedItemIds,
              fallback: (item) => item.truncated,
            ),
          ),
        },
        if (informationEvidenceReviewContract != null)
          'information_evidence_review_id':
              informationEvidenceReviewContract.reviewId,
      },
    );
  }

  List<String> _informationSourcePaths(ChapterDeliveryStateResult? deliveryState) {
    // 中文注释: information shared review 优先带上当前章节锚点，方便 repair/waiting 结论回到同一主链上下文。
    if (deliveryState == null) {
      return const <String>[];
    }
    return _nonEmptyPaths(<String>[
      ValueReaders.stringValue(deliveryState.metadata['resolved_chapter_path']),
      ValueReaders.stringValue(deliveryState.metadata['chapter_path']),
    ]);
  }

  List<String> _informationTargetPaths(
    ChapterDeliveryStateResult? deliveryState,
    List<String> changedPaths,
  ) {
    // 中文注释: target paths 优先使用 information changed paths，缺失时再回落到当前章节路径，保证统一 handoff 有定位锚点。
    return _nonEmptyPaths(<String>[
      ...changedPaths,
      if (deliveryState != null)
        ValueReaders.stringValue(deliveryState.metadata['chapter_path']),
      if (deliveryState != null)
        ValueReaders.stringValue(
          deliveryState.metadata['resolved_chapter_path'],
        ),
    ]);
  }

  String _informationEvidenceSummary({
    required InformationEvidenceGateSignal evidenceGate,
    required JsonMap informationSignal,
    required List<String> changedPaths,
    required String fallbackSummary,
  }) {
    if (fallbackSummary.isNotEmpty) {
      return fallbackSummary;
    }
    final parts = <String>[
      if (evidenceGate.pendingResearchCount > 0)
        '待研究 ${evidenceGate.pendingResearchCount} 项',
      if (evidenceGate.awaitingConfirmationCount > 0)
        '待确认研究 ${evidenceGate.awaitingConfirmationCount} 项',
      if (evidenceGate.gatewayFailureCount > 0)
        '研究网关失败 ${evidenceGate.gatewayFailureCount} 项',
      if (evidenceGate.rigorousSourceInsufficientCount > 0)
        '严谨来源不足 ${evidenceGate.rigorousSourceInsufficientCount} 项',
      if (evidenceGate.requiredInformationOmittedCount > 0)
        'required 信息省略 ${evidenceGate.requiredInformationOmittedCount} 项',
      if (evidenceGate.externalFactUnverifiedCount > 0)
        '外部事实未核验 ${evidenceGate.externalFactUnverifiedCount} 项',
    ];
    final highRiskReferenceCount = ValueReaders.intValue(
      informationSignal['high_risk_reference_count'],
    );
    if (highRiskReferenceCount > 0) {
      parts.add('高风险引用 $highRiskReferenceCount 项');
    }
    final designConflictCount = ValueReaders.intValue(
      informationSignal['design_conflict_count'],
    );
    if (designConflictCount > 0) {
      parts.add('设计冲突 $designConflictCount 项');
    }
    if (changedPaths.isNotEmpty) {
      parts.add('information 改动 ${changedPaths.length} 项');
    }
    if (parts.isNotEmpty) {
      return parts.join('，');
    }
    return changedPaths.isEmpty
        ? '当前没有新的 information 激活或风险信号。'
        : '当前已有 information 改动，建议在后续 checkpoint 中复核。';
  }

  List<ContextActivationItem> _activationItemsByIds(
    ContextActivationReport report,
    List<String> itemIds, {
    required bool Function(ContextActivationItem item) fallback,
  }) {
    final idSet = itemIds.where((itemId) => itemId.trim().isNotEmpty).toSet();
    if (idSet.isNotEmpty) {
      return report.items
          .where((item) => idSet.contains(item.itemId))
          .toList(growable: false);
    }
    return report.items.where(fallback).toList(growable: false);
  }

  JsonMap _sourceKindCounts(List<ContextActivationItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final sourceKind = ValueReaders.stringValue(
        item.metadata['source_kind'],
        item.source,
      ).trim();
      if (sourceKind.isEmpty) {
        continue;
      }
      counts[sourceKind] = (counts[sourceKind] ?? 0) + 1;
    }
    return counts;
  }

  List<JsonMap> _activationSourceRefs(List<ContextActivationItem> items) {
    final result = <JsonMap>[];
    for (final item in items) {
      final structuredSourceRefs = ValueReaders.mapList(
        item.metadata['source_refs'],
      ).map(ValueReaders.deepCopyMap).toList(growable: false);
      if (structuredSourceRefs.isNotEmpty) {
        result.add(<String, Object?>{
          'item_id': item.itemId,
          'source': item.source,
          'target_path': item.targetPath,
          'source_refs': structuredSourceRefs,
        });
        continue;
      }
      if (item.source == 'project_research_note') {
        result.add(<String, Object?>{
          'item_id': item.itemId,
          'source': item.source,
          'target_path': item.targetPath,
          'source_refs': <Object?>[
            <String, Object?>{
              'source_kind': ValueReaders.stringValue(
                item.metadata['research_source_kind'],
              ),
              'source_url_or_ref': ValueReaders.stringValue(
                item.metadata['source_url_or_ref'],
              ),
              'citation': ValueReaders.stringValue(item.metadata['citation']),
            },
          ],
        });
      }
    }
    return result;
  }

  WritingExecutionCollaborationSummary _collaborationSummary(
    List<Object?> collaborationResults, {
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 协作摘要只消费已经稳定的 sub-agent result package，不读取主会话 transcript 或 provider 私有字段。
    final results = collaborationResults
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (results.isEmpty) {
      return const WritingExecutionCollaborationSummary();
    }
    final collaborators = <WritingExecutionCollaboratorSummary>[];
    final agentNames = <String>[];
    final failedAgentNames = <String>[];
    final executionPackageIds = <String>[];
    final childRunPackageIds = <String>[];
    final failureSummaryParts = <String>[];
    final conflicts = <CollaborationConflictRecord>[];
    var successCount = 0;
    var failedCount = 0;
    var blockingFailureCount = 0;
    var cancelledCount = 0;
    var retryableFailures = 0;
    var retryChildCount = 0;
    var skipChildCount = 0;
    var fallbackSingleMainCount = 0;
    var requireUserCount = 0;
    for (final result in results) {
      final ok = ValueReaders.boolValue(result['ok']);
      final cancelled = ValueReaders.boolValue(result['cancelled']);
      if (ok) {
        successCount += 1;
      } else if (cancelled) {
        cancelledCount += 1;
      } else {
        failedCount += 1;
      }
      final retryable = ValueReaders.boolValue(result['retryable']);
      final collaborationResultPackage = ValueReaders.mapValue(
        result['collaboration_result_package'],
      );
      final collaborationMetadata = ValueReaders.mapValue(
        collaborationResultPackage['metadata'],
      );
      final mergeContract = ValueReaders.mapValue(
        collaborationResultPackage['merge_contract'],
      );
      final executionPackageId = ValueReaders.stringValue(
        collaborationResultPackage['execution_package_id'],
      ).trim();
      final childRunPackageId = ValueReaders.stringValue(
        collaborationResultPackage['child_run_package_id'],
      ).trim();
      if (!ok && retryable) {
        retryableFailures += 1;
      }
      final failureDisposition = ValueReaders.stringValue(
        result['failure_disposition'],
        ValueReaders.stringValue(collaborationMetadata['failure_disposition']),
      ).trim();
      if (!ok) {
        switch (failureDisposition) {
          case ChildFailureDispositions.retryChild:
            retryChildCount += 1;
          case ChildFailureDispositions.skipChild:
            skipChildCount += 1;
          case ChildFailureDispositions.fallbackSingleMain:
            fallbackSingleMainCount += 1;
          case ChildFailureDispositions.requireUser:
            requireUserCount += 1;
        }
        if (ChildFailureDispositions.blocksProgress(failureDisposition)) {
          blockingFailureCount += 1;
        }
        final failureSummary = ValueReaders.stringValue(
          collaborationMetadata['collaboration_failure_summary'],
          ValueReaders.stringValue(result['summary']),
        ).trim();
        if (failureSummary.isNotEmpty &&
            !failureSummaryParts.contains(failureSummary)) {
          failureSummaryParts.add(failureSummary);
        }
      }
      final agentName = ValueReaders.stringValue(
        result['agent_name'],
        ValueReaders.stringValue(result['agent_id']),
      ).trim();
      if (agentName.isNotEmpty && !agentNames.contains(agentName)) {
        agentNames.add(agentName);
      }
      if (!ok &&
          agentName.isNotEmpty &&
          !failedAgentNames.contains(agentName)) {
        failedAgentNames.add(agentName);
      }
      if (executionPackageId.isNotEmpty &&
          !executionPackageIds.contains(executionPackageId)) {
        executionPackageIds.add(executionPackageId);
      }
      if (childRunPackageId.isNotEmpty &&
          !childRunPackageIds.contains(childRunPackageId)) {
        childRunPackageIds.add(childRunPackageId);
      }
      conflicts.addAll(
        _collectCollaborationConflicts(
          result,
          collaborationResultPackage: collaborationResultPackage,
          fallbackAgentId: ValueReaders.stringValue(result['agent_id']).trim(),
          fallbackAgentName: agentName,
          fallbackTask: ValueReaders.stringValue(result['task']).trim(),
        ),
      );
      collaborators.add(
        WritingExecutionCollaboratorSummary(
          agentId: ValueReaders.stringValue(result['agent_id']).trim(),
          agentName: agentName,
          status: ok
              ? 'success'
              : cancelled
              ? 'cancelled'
              : 'failed',
          task: ValueReaders.stringValue(result['task']).trim(),
          retryable: retryable,
          usedToolCount: ValueReaders.objectList(result['tool_calls']).length,
          resultSummary: _collaboratorResultSummary(result),
          metadata: <String, Object?>{
            'sub_session_id': ValueReaders.stringValue(
              result['sub_session_id'],
            ),
            'continue_session_id': ValueReaders.stringValue(
              result['continue_session_id'],
            ),
            'execution_package_id': executionPackageId,
            'child_run_package_id': childRunPackageId,
            'merge_mode': ValueReaders.stringValue(mergeContract['merge_mode']),
            'allows_direct_delivery': ValueReaders.boolValue(
              mergeContract['allows_direct_delivery'],
            ),
            'failure_disposition': failureDisposition,
          },
        ),
      );
    }
    final arbitrationResults = _arbitrationResultsForConflicts(conflicts);
    final autoResolvedConflictCount = arbitrationResults
        .where(
          (entry) =>
              entry.status == CollaborationArbitrationStatuses.autoResolved,
        )
        .length;
    final repairRequiredConflictCount = arbitrationResults
        .where(
          (entry) =>
              entry.status == CollaborationArbitrationStatuses.needsRepair,
        )
        .length;
    final userConfirmationConflictCount = arbitrationResults
        .where(
          (entry) =>
              entry.status ==
              CollaborationArbitrationStatuses.needsUserConfirmation,
        )
        .length;
    final downgradedRetryChildFailure =
        _shouldDowngradeRetryChildCollaborationFailure(
          metadata: metadata,
          retryChildCount: retryChildCount,
          blockingFailureCount: blockingFailureCount,
          requireUserCount: requireUserCount,
          repairRequiredConflictCount: repairRequiredConflictCount,
          userConfirmationConflictCount: userConfirmationConflictCount,
        );
    final effectiveBlockingFailureCount = downgradedRetryChildFailure
        ? 0
        : blockingFailureCount;
    final highestConflictRisk = _highestConflictRisk(conflicts);
    final degraded =
        fallbackSingleMainCount > 0 ||
        skipChildCount > 0 ||
        (failedCount > 0 && successCount > 0) ||
        downgradedRetryChildFailure;
    return WritingExecutionCollaborationSummary(
      present: true,
      strategy: ValueReaders.stringValue(results.first['strategy']).trim(),
      totalCollaboratorCount: results.length,
      successfulCollaboratorCount: successCount,
      failedCollaboratorCount: failedCount,
      blockingFailureCount: effectiveBlockingFailureCount,
      cancelledCollaboratorCount: cancelledCount,
      retryableFailureCount: retryableFailures,
      retryChildCount: retryChildCount,
      skipChildCount: skipChildCount,
      fallbackSingleMainCount: fallbackSingleMainCount,
      requireUserCount: requireUserCount,
      totalConflictCount: conflicts.length,
      autoResolvedConflictCount: autoResolvedConflictCount,
      repairRequiredConflictCount: repairRequiredConflictCount,
      userConfirmationConflictCount: userConfirmationConflictCount,
      degraded: degraded,
      highestConflictRisk: highestConflictRisk,
      summary: _collaborationSummaryText(
        successCount: successCount,
        failedCount: failedCount,
        cancelledCount: cancelledCount,
        totalConflictCount: conflicts.length,
      ),
      failureSummary: failureSummaryParts.join('；'),
      conflictSummary: _collaborationConflictSummary(arbitrationResults),
      agentNames: List<String>.unmodifiable(agentNames),
      failedAgentNames: List<String>.unmodifiable(failedAgentNames),
      collaborators: List<WritingExecutionCollaboratorSummary>.unmodifiable(
        collaborators,
      ),
      conflicts: List<CollaborationConflictRecord>.unmodifiable(conflicts),
      arbitrationResults: List<CollaborationArbitrationResult>.unmodifiable(
        arbitrationResults,
      ),
      metadata: <String, Object?>{
        'final_content_fallback': _subAgentResultPackageService
            .subAgentFinalContent('', stoppedByToolError: failedCount > 0),
        'execution_package_ids': executionPackageIds,
        'child_run_package_ids': childRunPackageIds,
        'result_package_relation': 'derived_from_collaboration_result_package',
        'arbitration_statuses': arbitrationResults
            .map((entry) => entry.status)
            .where((entry) => entry.trim().isNotEmpty)
            .toList(growable: false),
        'formal_review_retry_child_downgraded': downgradedRetryChildFailure,
      },
    );
  }

  bool _shouldDowngradeRetryChildCollaborationFailure({
    required JsonMap metadata,
    required int retryChildCount,
    required int blockingFailureCount,
    required int requireUserCount,
    required int repairRequiredConflictCount,
    required int userConfirmationConflictCount,
  }) {
    if (!ValueReaders.boolValue(metadata['formal_review_completed'])) {
      return false;
    }
    if (retryChildCount <= 0 || blockingFailureCount != retryChildCount) {
      return false;
    }
    if (requireUserCount > 0 ||
        repairRequiredConflictCount > 0 ||
        userConfirmationConflictCount > 0) {
      return false;
    }
    return true;
  }

  List<CollaborationConflictRecord> _collectCollaborationConflicts(
    JsonMap result, {
    required JsonMap collaborationResultPackage,
    required String fallbackAgentId,
    required String fallbackAgentName,
    required String fallbackTask,
  }) {
    final rawConflicts =
        ValueReaders.mapList(collaborationResultPackage['conflicts']).isNotEmpty
        ? ValueReaders.mapList(collaborationResultPackage['conflicts'])
        : ValueReaders.mapList(result['collaboration_conflicts']);
    final conflicts = <CollaborationConflictRecord>[];
    for (var index = 0; index < rawConflicts.length; index += 1) {
      final conflict = CollaborationConflictRecord.fromJson(
        rawConflicts[index],
      );
      conflicts.add(
        CollaborationConflictRecord(
          conflictId: conflict.conflictId.isEmpty
              ? 'collaboration_conflict_${fallbackAgentId}_${index + 1}'
              : conflict.conflictId,
          groupKey: conflict.groupKey,
          subject: conflict.subject.isEmpty ? fallbackTask : conflict.subject,
          target: conflict.target,
          agentId: conflict.agentId.isEmpty
              ? fallbackAgentId
              : conflict.agentId,
          agentName: conflict.agentName.isEmpty
              ? fallbackAgentName
              : conflict.agentName,
          task: conflict.task.isEmpty ? fallbackTask : conflict.task,
          risk: conflict.risk,
          suggestion: conflict.suggestion,
          adoptionHint: conflict.adoptionHint,
          confidence: conflict.confidence,
          evidence: conflict.evidence,
          metadata: ValueReaders.deepCopyMap(conflict.metadata),
        ),
      );
    }
    return conflicts;
  }

  List<CollaborationArbitrationResult> _arbitrationResultsForConflicts(
    List<CollaborationConflictRecord> conflicts,
  ) {
    if (conflicts.isEmpty) {
      return const <CollaborationArbitrationResult>[];
    }
    final grouped = <String, List<CollaborationConflictRecord>>{};
    for (final conflict in conflicts) {
      final key = _conflictGroupKey(conflict);
      grouped
          .putIfAbsent(key, () => <CollaborationConflictRecord>[])
          .add(conflict);
    }
    return grouped.entries
        .map((entry) => _arbitrateConflictGroup(entry.key, entry.value))
        .toList(growable: false);
  }

  String _conflictGroupKey(CollaborationConflictRecord conflict) {
    final subject = conflict.subject.trim();
    final target = conflict.target.trim();
    if (conflict.groupKey.trim().isNotEmpty) {
      return conflict.groupKey.trim();
    }
    if (subject.isNotEmpty && target.isNotEmpty) {
      return '$subject::$target';
    }
    if (subject.isNotEmpty) {
      return subject;
    }
    return conflict.conflictId;
  }

  CollaborationArbitrationResult _arbitrateConflictGroup(
    String groupKey,
    List<CollaborationConflictRecord> conflicts,
  ) {
    final selected = conflicts.reduce((best, current) {
      final currentRiskRank = CollaborationConflictRisks.rank(current.risk);
      final bestRiskRank = CollaborationConflictRisks.rank(best.risk);
      if (currentRiskRank > bestRiskRank) {
        return current;
      }
      if (currentRiskRank < bestRiskRank) {
        return best;
      }
      if (current.confidence > best.confidence) {
        return current;
      }
      return best;
    });
    final highestRisk = _highestConflictRisk(conflicts);
    final requiresUserConfirmation =
        highestRisk == CollaborationConflictRisks.high ||
        conflicts.any(
          (entry) => ValueReaders.boolValue(
            entry.metadata['requires_user_confirmation'],
          ),
        );
    final requiresRepair =
        !requiresUserConfirmation &&
        highestRisk == CollaborationConflictRisks.medium;
    final status = requiresUserConfirmation
        ? CollaborationArbitrationStatuses.needsUserConfirmation
        : requiresRepair
        ? CollaborationArbitrationStatuses.needsRepair
        : CollaborationArbitrationStatuses.autoResolved;
    final conflictIds = conflicts
        .map((entry) => entry.conflictId)
        .where((entry) => entry.trim().isNotEmpty)
        .toList(growable: false);
    final rejectedConflictIds = conflicts
        .where((entry) => entry.conflictId != selected.conflictId)
        .map((entry) => entry.conflictId)
        .where((entry) => entry.trim().isNotEmpty)
        .toList(growable: false);
    return CollaborationArbitrationResult(
      arbitrationId: 'arbitration_$groupKey',
      groupKey: groupKey,
      status: status,
      highestRisk: highestRisk,
      selectedConflictId: selected.conflictId,
      summary: _arbitrationSummaryText(
        status: status,
        subject: selected.subject,
        agentName: selected.agentName,
        groupSize: conflicts.length,
      ),
      reason: status == CollaborationArbitrationStatuses.needsUserConfirmation
          ? 'collaboration_conflict_needs_user_confirmation'
          : status == CollaborationArbitrationStatuses.needsRepair
          ? 'collaboration_conflict_needs_repair'
          : 'collaboration_conflict_auto_resolved',
      autoResolved: status == CollaborationArbitrationStatuses.autoResolved,
      requiresRepair: requiresRepair,
      requiresUserConfirmation: requiresUserConfirmation,
      acceptedConflictIds: selected.conflictId.isEmpty
          ? const <String>[]
          : <String>[selected.conflictId],
      rejectedConflictIds: rejectedConflictIds,
      pendingConflictIds:
          status == CollaborationArbitrationStatuses.autoResolved
          ? const <String>[]
          : conflictIds,
      metadata: <String, Object?>{
        'agent_names': conflicts
            .map((entry) => entry.agentName)
            .where((entry) => entry.trim().isNotEmpty)
            .toSet()
            .toList(growable: false),
        'selected_adoption_hint': selected.adoptionHint,
        'selected_suggestion': selected.suggestion,
        'selected_confidence': selected.confidence,
        'conflict_count': conflicts.length,
      },
    );
  }

  String _highestConflictRisk(List<CollaborationConflictRecord> conflicts) {
    var highest = '';
    for (final conflict in conflicts) {
      if (highest.isEmpty ||
          CollaborationConflictRisks.rank(conflict.risk) >
              CollaborationConflictRisks.rank(highest)) {
        highest = conflict.risk;
      }
    }
    return highest;
  }

  String _collaboratorResultSummary(JsonMap result) {
    // 中文注释: 协作者结果摘要优先使用结构化 summary，再退回 error 或正文摘要，避免暴露整段 markdown。
    final summary = ValueReaders.stringValue(result['summary']).trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    final error = ValueReaders.stringValue(result['error']).trim();
    if (error.isNotEmpty) {
      return error;
    }
    return ValueReaders.stringValue(result['result_markdown']).trim();
  }

  String _collaborationSummaryText({
    required int successCount,
    required int failedCount,
    required int cancelledCount,
    required int totalConflictCount,
  }) {
    // 中文注释: 协作摘要文案只解释成功/失败/取消数量，给后续 GUI 展示留出稳定中文口径。
    if (failedCount == 0 && cancelledCount == 0 && totalConflictCount == 0) {
      return '协作者结果已全部返回。';
    }
    final parts = <String>[
      if (successCount > 0) '成功 $successCount 项',
      if (failedCount > 0) '失败 $failedCount 项',
      if (cancelledCount > 0) '取消 $cancelledCount 项',
      if (totalConflictCount > 0) '冲突 $totalConflictCount 项',
    ];
    return parts.isEmpty ? '当前没有协作结果。' : '协作结果：${parts.join('，')}';
  }

  String _collaborationConflictSummary(
    List<CollaborationArbitrationResult> arbitrationResults,
  ) {
    if (arbitrationResults.isEmpty) {
      return '';
    }
    final autoResolved = arbitrationResults
        .where(
          (entry) =>
              entry.status == CollaborationArbitrationStatuses.autoResolved,
        )
        .length;
    final repairRequired = arbitrationResults
        .where(
          (entry) =>
              entry.status == CollaborationArbitrationStatuses.needsRepair,
        )
        .length;
    final userConfirmation = arbitrationResults
        .where(
          (entry) =>
              entry.status ==
              CollaborationArbitrationStatuses.needsUserConfirmation,
        )
        .length;
    final parts = <String>[
      if (autoResolved > 0) '低风险自动归并 $autoResolved 项',
      if (repairRequired > 0) '待修订 $repairRequired 项',
      if (userConfirmation > 0) '待用户确认 $userConfirmation 项',
    ];
    return parts.isEmpty ? '' : '协作冲突：${parts.join('，')}';
  }

  String _arbitrationSummaryText({
    required String status,
    required String subject,
    required String agentName,
    required int groupSize,
  }) {
    final cleanSubject = subject.trim().isEmpty ? '当前协作议题' : subject.trim();
    final cleanAgentName = agentName.trim();
    final who = cleanAgentName.isEmpty ? '' : '$cleanAgentName 提出的';
    if (status == CollaborationArbitrationStatuses.autoResolved) {
      return groupSize > 1
          ? '低风险协作冲突已自动归并：$cleanSubject。'
          : '低风险协作冲突已记录并可自动采用：$who$cleanSubject。';
    }
    if (status == CollaborationArbitrationStatuses.needsRepair) {
      return '协作冲突需要先修订再继续：$cleanSubject。';
    }
    return '协作冲突需要用户确认：$cleanSubject。';
  }

  WritingExecutionRecoverySummary _recoverySummary(JsonMap recoveryPlan) {
    // 中文注释: recovery 归并只消费恢复计划壳层字段，方便后续 supervisor 与 GUI 共享同一建议来源。
    if (recoveryPlan.isEmpty) {
      return const WritingExecutionRecoverySummary();
    }
    final action = ValueReaders.stringValue(recoveryPlan['action']).trim();
    final reason = ValueReaders.stringValue(recoveryPlan['reason']).trim();
    final task = ValueReaders.mapValue(recoveryPlan['task']);
    final waitingUser = action == 'resume_when_user_confirms';
    final requiresRepair = action == 'pause_for_repair';
    final manualAttentionRequired = action == 'pause_for_manual_attention';
    final resumeAllowed =
        action == 'resume_dispatch' ||
        action == 'resume_when_user_confirms' ||
        action == 'run_scheduled_repair';
    final retryable =
        requiresRepair ||
        action == 'pause_for_failure' ||
        action == 'pause_for_review' ||
        action == 'resume_dispatch' ||
        action == 'run_scheduled_repair';
    return WritingExecutionRecoverySummary(
      present: true,
      recommendedAction: action,
      reason: reason,
      note: ValueReaders.stringValue(recoveryPlan['note']).trim(),
      safeAfterCrash: ValueReaders.boolValue(
        recoveryPlan['safe_after_crash'],
        true,
      ),
      waitingUser: waitingUser,
      requiresRepair: requiresRepair,
      manualAttentionRequired: manualAttentionRequired,
      resumeAllowed: resumeAllowed,
      retryable: retryable,
      taskId: ValueReaders.stringValue(task['id']).trim(),
      taskTitle: ValueReaders.stringValue(task['title']).trim(),
      taskPath: ValueReaders.stringValue(task['relative_path']).trim(),
      metadata: <String, Object?>{
        'record_id': ValueReaders.stringValue(recoveryPlan['record_id']),
        'status': ValueReaders.stringValue(recoveryPlan['status']),
      },
    );
  }

  String _overallStatus({
    required bool transportFailed,
    required WritingExecutionDeliverySummary delivery,
    required WritingExecutionConstraintSummary constraints,
    required WritingExecutionInformationSummary information,
    required WritingExecutionCollaborationSummary collaboration,
    required WritingExecutionRecoverySummary recovery,
  }) {
    // 中文注释: 顶层状态优先表达“现在为什么不能继续”，让后续 session 能围绕统一分类继续收口。
    if (transportFailed ||
        delivery.suggestedOutcomeStatus ==
                DomainToolOutcomeStatuses.executionFailed &&
            !delivery.retryable ||
        recovery.reason == 'failed_task' ||
        recovery.recommendedAction == 'start_new') {
      return WritingExecutionOutcomeStatuses.technicalFailure;
    }
    if (recovery.waitingUser ||
        recovery.manualAttentionRequired ||
        information.waitingUser ||
        information.manualAttentionRequired ||
        collaboration.requireUserCount > 0 ||
        collaboration.userConfirmationConflictCount > 0 ||
        delivery.state == ChapterDeliveryStateStatuses.waitingUserChoice) {
      return WritingExecutionOutcomeStatuses.userActionRequired;
    }
    if (delivery.state ==
            ChapterDeliveryStateStatuses.invalidOutputRewriteRequired ||
        delivery.state ==
            ChapterDeliveryStateStatuses.manualAttentionRequired ||
        constraints.contentQualityRisk) {
      return WritingExecutionOutcomeStatuses.contentQualityIssue;
    }
    if (delivery.blocksProgress ||
        information.requiresRepair ||
        collaboration.blockingFailureCount > 0 ||
        collaboration.repairRequiredConflictCount > 0 ||
        recovery.requiresRepair) {
      return WritingExecutionOutcomeStatuses.recoverableFailure;
    }
    return WritingExecutionOutcomeStatuses.success;
  }

  String _summaryForStatus(
    String overallStatus, {
    required WritingExecutionDeliverySummary delivery,
    required WritingExecutionConstraintSummary constraints,
    required WritingExecutionInformationSummary information,
    required WritingExecutionCollaborationSummary collaboration,
    required WritingExecutionRecoverySummary recovery,
  }) {
    // 中文注释: 聚合摘要优先复用已有子摘要，避免不同宿主各自再把同一状态翻译一遍。
    late final String primarySummary;
    switch (overallStatus) {
      case WritingExecutionOutcomeStatuses.technicalFailure:
        primarySummary = delivery.summary.isNotEmpty
            ? delivery.summary
            : (recovery.note.isNotEmpty ? recovery.note : '写作运行遇到技术失败。');
      case WritingExecutionOutcomeStatuses.userActionRequired:
        primarySummary = recovery.note.isNotEmpty
            ? recovery.note
            : (collaboration.conflictSummary.isNotEmpty
                  ? collaboration.conflictSummary
                  : (collaboration.failureSummary.isNotEmpty
                        ? collaboration.failureSummary
                        : (information.summary.isNotEmpty
                              ? information.summary
                              : '写作运行需要用户或人工介入后再继续。')));
      case WritingExecutionOutcomeStatuses.contentQualityIssue:
        primarySummary = delivery.summary.isNotEmpty
            ? delivery.summary
            : (constraints.summary.isNotEmpty
                  ? constraints.summary
                  : '写作运行暴露出内容质量问题，需要先修订。');
      case WritingExecutionOutcomeStatuses.recoverableFailure:
        primarySummary = recovery.note.isNotEmpty
            ? recovery.note
            : (collaboration.conflictSummary.isNotEmpty &&
                      collaboration.repairRequiredConflictCount > 0
                  ? collaboration.conflictSummary
                  : (collaboration.failureSummary.isNotEmpty
                        ? collaboration.failureSummary
                        : (delivery.summary.isNotEmpty
                              ? delivery.summary
                              : (collaboration.summary.isNotEmpty
                                    ? collaboration.summary
                                    : '写作运行出现可恢复失败，可通过修复或重试继续。'))));
      default:
        primarySummary = delivery.summary.isNotEmpty
            ? delivery.summary
            : (constraints.summary.isNotEmpty
                  ? constraints.summary
                  : (collaboration.conflictSummary.isNotEmpty
                        ? collaboration.conflictSummary
                        : (collaboration.summary.isNotEmpty
                              ? collaboration.summary
                              : '写作运行结果稳定，可继续推进。')));
    }
    return _mergeInformationEvidenceSummary(
      primarySummary,
      information: information,
    );
  }

  String _mergeInformationEvidenceSummary(
    String primarySummary, {
    required WritingExecutionInformationSummary information,
  }) {
    final base = primarySummary.trim();
    final informationSummary = information.summary.trim();
    final evidenceGateSummary = information.evidenceGate.summary.trim();
    final preferredInformationSummary = informationSummary.isNotEmpty
        ? informationSummary
        : evidenceGateSummary;
    if (!_shouldAppendInformationEvidence(
      information: information,
      summary: preferredInformationSummary,
    )) {
      return base;
    }
    if (base.isEmpty) {
      return preferredInformationSummary;
    }
    if (_containsEvidenceSummary(base, preferredInformationSummary)) {
      return base;
    }
    return '$base Information：$preferredInformationSummary';
  }

  bool _shouldAppendInformationEvidence({
    required WritingExecutionInformationSummary information,
    required String summary,
  }) {
    if (summary.isEmpty) {
      return false;
    }
    final evidenceGate = information.evidenceGate;
    return evidenceGate.present ||
        information.activationReportId.isNotEmpty ||
        information.changedPathCount > 0 ||
        information.selectedItemCount > 0 ||
        information.omittedItemCount > 0 ||
        information.truncatedItemCount > 0;
  }

  bool _containsEvidenceSummary(String base, String evidenceSummary) {
    if (evidenceSummary.isEmpty) {
      return false;
    }
    if (base.contains(evidenceSummary)) {
      return true;
    }
    final compactEvidence = evidenceSummary.replaceAll('。', '').trim();
    return compactEvidence.isNotEmpty && base.contains(compactEvidence);
  }

  String _nextAction({
    required WritingExecutionDeliverySummary delivery,
    required WritingExecutionConstraintSummary constraints,
    required WritingExecutionCollaborationSummary collaboration,
    required WritingExecutionRecoverySummary recovery,
  }) {
    // 中文注释: 下一步动作优先采用恢复计划，其次复用交付、冲突仲裁和约束层已经给出的动作建议。
    if (recovery.recommendedAction.trim().isNotEmpty) {
      return recovery.recommendedAction;
    }
    if (delivery.recommendedAction.trim().isNotEmpty) {
      return delivery.recommendedAction;
    }
    if (collaboration.userConfirmationConflictCount > 0) {
      return 'confirm_collaboration_conflict';
    }
    if (collaboration.repairRequiredConflictCount > 0) {
      return 'repair_collaboration_conflict';
    }
    if (constraints.expressionConstraintGate.repairRequired) {
      return 'repair_expression_constraint';
    }
    if (constraints.expressionConstraintGate.adjustNextChapter) {
      return 'adjust_expression_constraint_next_chapter';
    }
    if (constraints.expressionConstraintGate.recommendedDisposition ==
        ExpressionConstraintGateRecommendedDispositions.remind) {
      return 'review_expression_constraint_notes';
    }
    return constraints.chapterLengthRecommendedAction;
  }
}
