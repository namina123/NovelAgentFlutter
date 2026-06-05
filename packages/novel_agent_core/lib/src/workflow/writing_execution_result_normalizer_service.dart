import '../agents/sub_agent_result_package_service.dart';
import '../agents/child_failure_disposition.dart';
import '../agents/collaboration_arbitration_result.dart';
import '../agents/collaboration_conflict_record.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/context_activation/context_activation_item.dart';
import '../continuity/context_activation/context_activation_report.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../tools/domain/domain_tool_outcome_statuses.dart';
import 'chapter_delivery_state_result.dart';
import 'chapter_delivery_state_statuses.dart';
import 'chapter_length_evaluation.dart';
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
  }) : _subAgentResultPackageService =
           subAgentResultPackageService ?? SubAgentResultPackageService();

  final SubAgentResultPackageService _subAgentResultPackageService;

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
      bridgeResult: constraintBridgeResult,
      chapterLengthEvaluation: chapterLengthEvaluation,
      expressionConstraintReview: expressionConstraintReview,
    );
    final information = _informationSummary(
      activationReport: activationReport,
      informationSignal: informationSignal,
    );
    final collaboration = _collaborationSummary(collaborationResults);
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
        information.requiresRepair ||
        information.waitingUser ||
        information.manualAttentionRequired ||
        collaboration.failedCollaboratorCount > 0 ||
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
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  WritingExecutionConstraintSummary _constraintSummary({
    required WritingExecutionConstraintBridgeResult? bridgeResult,
    required ChapterLengthEvaluation? chapterLengthEvaluation,
    required ExpressionConstraintReviewProjection? expressionConstraintReview,
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
        bridge.projectExpressionConstraintBindings.isNotEmpty ||
        bridge.expressionConstraintProfiles.isNotEmpty;
    final expressionConstraintReviewProvided = !review.isEmpty;
    final expressionConstraintReviewRequired =
        bridge.expressionConstraintReviewRequired ||
        (expressionConstraintActive &&
            bridge.expressionConstraintInjectionMode != 'disabled');
    final expressionConstraintEvidenceMissing =
        expressionConstraintReviewRequired &&
        !expressionConstraintReviewProvided;
    final hardGateReasons = _constraintHardGateReasons(
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
    );
    final softGateReasons = _constraintSoftGateReasons(
      chapterLengthLevel: chapterLengthLevel,
      chapterLengthRecommendedAction: chapterLengthRecommendedAction,
      expressionConstraintActive: expressionConstraintActive,
      expressionConstraintReviewProvided: expressionConstraintReviewProvided,
      review: review,
    );
    final hardConstraintTriggered = hardGateReasons.isNotEmpty;
    final repairRequired = hardConstraintTriggered;
    final reviewSuggested =
        hardConstraintTriggered || softGateReasons.isNotEmpty;
    final reminderOnly = reviewSuggested && !repairRequired;
    final contentQualityRisk = hardConstraintTriggered;
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
      expressionConstraintInjectionMode:
          bridge.expressionConstraintInjectionMode,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
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
      expressionConstraintInjectionMode:
          bridge.expressionConstraintInjectionMode,
      expressionConstraintReviewRequired: expressionConstraintReviewRequired,
      expressionConstraintReviewProvided: expressionConstraintReviewProvided,
      expressionConstraintEvidenceMissing: expressionConstraintEvidenceMissing,
      hardGateReasons: List<String>.unmodifiable(hardGateReasons),
      softGateReasons: List<String>.unmodifiable(softGateReasons),
      summary: summary,
      chapterLengthMetadata: ValueReaders.deepCopyMap(chapterLengthMetadata),
      runtimeReport: ValueReaders.deepCopyMap(bridge.runtimeReport),
      metadata: <String, Object?>{
        'has_bridge_runtime': bridge.runtimeReport.isNotEmpty,
      },
    );
  }

  String _constraintSummaryText({
    required bool chapterLengthConfigured,
    required String chapterLengthLevel,
    required String chapterLengthRecommendedAction,
    required int profileCount,
    required int bindingCount,
    required String expressionConstraintInjectionMode,
    required bool expressionConstraintEvidenceMissing,
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
    if (profileCount > 0 || bindingCount > 0) {
      parts.add(
        '表达限制：$profileCount 条 profile，$bindingCount 条绑定，注入模式 $expressionConstraintInjectionMode',
      );
    }
    if (expressionConstraintEvidenceMissing) {
      parts.add('缺少表达限制复核证据');
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
    return reasons;
  }

  List<String> _constraintSoftGateReasons({
    required String chapterLengthLevel,
    required String chapterLengthRecommendedAction,
    required bool expressionConstraintActive,
    required bool expressionConstraintReviewProvided,
    required ExpressionConstraintReviewProjection review,
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
    if (expressionConstraintActive && expressionConstraintReviewProvided) {
      reasons.add('expression_constraint_review_recorded');
    } else if (expressionConstraintActive &&
        (review.reviewFocuses.isNotEmpty ||
            review.miniRecheckItems.isNotEmpty ||
            review.continuityWatchItems.isNotEmpty ||
            review.voiceProtectionNotes.isNotEmpty)) {
      reasons.add('expression_constraint_review_recommended');
    }
    return reasons;
  }

  WritingExecutionInformationSummary _informationSummary({
    required ContextActivationReport? activationReport,
    required JsonMap informationSignal,
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
    final summary = ValueReaders.stringValue(
      informationSignal['summary'],
      report?.summary ?? '',
    ).trim();
    final waitingUser = ValueReaders.boolValue(
      informationSignal['waiting_user'],
    );
    final requiresRepair = ValueReaders.boolValue(
      informationSignal['requires_repair'],
    );
    final manualAttentionRequired = ValueReaders.boolValue(
      informationSignal['manual_attention_required'],
    );
    return WritingExecutionInformationSummary(
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
      riskCategory: riskCategory,
      reason: ValueReaders.stringValue(informationSignal['reason']).trim(),
      summary: summary.isEmpty
          ? (changedPaths.isEmpty
                ? '当前没有新的 information 激活或风险信号。'
                : '当前已有 information 改动，建议在后续 checkpoint 中复核。')
          : summary,
      changedPaths: List<String>.unmodifiable(changedPaths),
      waitingUser: waitingUser,
      requiresRepair: requiresRepair,
      manualAttentionRequired: manualAttentionRequired,
      metadata: <String, Object?>{
        'pending_research_count': ValueReaders.intValue(
          informationSignal['pending_research_count'],
        ),
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
      },
    );
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
    List<Object?> collaborationResults,
  ) {
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
    final highestConflictRisk = _highestConflictRisk(conflicts);
    final degraded =
        fallbackSingleMainCount > 0 ||
        skipChildCount > 0 ||
        (failedCount > 0 && successCount > 0);
    return WritingExecutionCollaborationSummary(
      present: true,
      strategy: ValueReaders.stringValue(results.first['strategy']).trim(),
      totalCollaboratorCount: results.length,
      successfulCollaboratorCount: successCount,
      failedCollaboratorCount: failedCount,
      blockingFailureCount: blockingFailureCount,
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
      },
    );
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
        action == 'resume_dispatch' || action == 'resume_when_user_confirms';
    final retryable =
        requiresRepair ||
        action == 'pause_for_failure' ||
        action == 'pause_for_review' ||
        action == 'resume_dispatch';
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
    switch (overallStatus) {
      case WritingExecutionOutcomeStatuses.technicalFailure:
        return delivery.summary.isNotEmpty
            ? delivery.summary
            : (recovery.note.isNotEmpty ? recovery.note : '写作运行遇到技术失败。');
      case WritingExecutionOutcomeStatuses.userActionRequired:
        return recovery.note.isNotEmpty
            ? recovery.note
            : (collaboration.conflictSummary.isNotEmpty
                  ? collaboration.conflictSummary
                  : (collaboration.failureSummary.isNotEmpty
                        ? collaboration.failureSummary
                        : (information.summary.isNotEmpty
                              ? information.summary
                              : '写作运行需要用户或人工介入后再继续。')));
      case WritingExecutionOutcomeStatuses.contentQualityIssue:
        return delivery.summary.isNotEmpty
            ? delivery.summary
            : (constraints.summary.isNotEmpty
                  ? constraints.summary
                  : '写作运行暴露出内容质量问题，需要先修订。');
      case WritingExecutionOutcomeStatuses.recoverableFailure:
        return recovery.note.isNotEmpty
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
        return delivery.summary.isNotEmpty
            ? delivery.summary
            : (constraints.summary.isNotEmpty
                  ? constraints.summary
                  : (collaboration.conflictSummary.isNotEmpty
                        ? collaboration.conflictSummary
                        : (collaboration.summary.isNotEmpty
                              ? collaboration.summary
                              : '写作运行结果稳定，可继续推进。')));
    }
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
    return constraints.chapterLengthRecommendedAction;
  }
}
