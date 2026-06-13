import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskCheckpointDispositionService {
  JsonMap resolve(JsonMap review) {
    // 中文注释: 该服务只把 checkpoint review 翻译成放行语义，不直接生成动作、不直接改任务状态。
    final severity = ValueReaders.stringValue(
      review['severity'],
      'low',
    ).trim().toLowerCase();
    final taskType = ValueReaders.stringValue(review['task_type']).trim();
    final resultOk = ValueReaders.boolValue(review['result_ok']);
    final error = ValueReaders.stringValue(review['error']).trim();
    final outputPaths = ValueReaders.stringList(review['output_paths']);
    final persistentContextPaths = ValueReaders.stringList(
      review['persistent_context_paths'],
    );
    final narrativeRisk = ValueReaders.mapValue(
      review['narrative_supervisor_risk'],
    );
    final overallRisk = ValueReaders.mapValue(narrativeRisk['overall']);
    final collaborationSignal = ValueReaders.mapValue(
      review['collaboration_signal'],
    );
    final overallCategory = ValueReaders.stringValue(
      overallRisk['category'],
    ).trim();
    final overallSummary = ValueReaders.stringValue(
      overallRisk['summary'],
    ).trim();
    final overallReason = ValueReaders.stringValue(
      overallRisk['reason'],
    ).trim();
    final collaborationCategory = ValueReaders.stringValue(
      collaborationSignal['category'],
    ).trim();
    final collaborationSummary = ValueReaders.stringValue(
      collaborationSignal['summary'],
    ).trim();
    final mode = ValueReaders.stringValue(review['mode']).trim();
    final informationSignal = ValueReaders.mapValue(
      review['information_signal'],
    );
    final informationCategory = ValueReaders.stringValue(
      informationSignal['category'],
    ).trim();
    final expressionConstraintSignal = ValueReaders.mapValue(
      review['expression_constraint_signal'],
    );
    final expressionConstraintCategory = ValueReaders.stringValue(
      expressionConstraintSignal['category'],
    ).trim();

    if (collaborationCategory == 'checkpoint_user') {
      return _result(
        disposition: 'blocked_wait_user',
        reason: 'collaboration_conflict_requires_user_confirmation',
        summary: collaborationSummary.isEmpty
            ? '当前存在高风险协作冲突，需要用户确认采纳方向后再继续。'
            : collaborationSummary,
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: false,
        recommendedActionId: '',
      );
    }

    if (collaborationCategory == 'repair') {
      return _result(
        disposition: 'blocked_wait_user',
        reason: 'collaboration_conflict_requires_repair',
        summary: collaborationSummary.isEmpty
            ? '当前存在中风险协作冲突，建议先修订再决定是否继续。'
            : collaborationSummary,
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: true,
        revisitModeGuidance: false,
        recommendedActionId: 'request_revision_followup',
      );
    }

    if (overallCategory == 'manual_attention') {
      return _result(
        disposition: 'manual_attention',
        reason: overallReason.isEmpty
            ? 'narrative_manual_attention'
            : overallReason,
        summary: overallSummary.isEmpty
            ? '当前节点已经进入人工处理范围，不应继续按普通 waiting_user 或自动放行处理。'
            : overallSummary,
        blocksAutoContinue: true,
        manualAttentionRequired: true,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: persistentContextPaths.isNotEmpty,
        recommendedActionId: persistentContextPaths.isNotEmpty
            ? 'revisit_mode_guidance'
            : '',
      );
    }

    if (overallCategory == 'repair') {
      return _result(
        disposition: 'blocked_wait_user',
        reason: overallReason.isEmpty
            ? 'narrative_repair_required'
            : overallReason,
        summary: overallSummary.isEmpty
            ? '当前节点已经有明确返工信号，建议先走 repair / revision，再决定是否继续主链。'
            : overallSummary,
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: true,
        revisitModeGuidance: false,
        recommendedActionId: 'request_revision_followup',
      );
    }

    if (overallCategory == 'checkpoint_user') {
      final waitingFromPermission = overallReason == 'permission_waiting_user';
      final canDeferPermissionAndContinue =
          waitingFromPermission &&
          resultOk &&
          error.isEmpty &&
          outputPaths.isNotEmpty;
      return _result(
        disposition: 'blocked_wait_user',
        reason: overallReason.isEmpty
            ? 'narrative_checkpoint_user'
            : overallReason,
        summary: overallSummary.isEmpty
            ? '当前节点停在真实用户确认点，应该等待用户处理而不是被别的技术缺口挤占。'
            : (canDeferPermissionAndContinue
                  ? '当前节点存在待确认的权限提案，但已有稳定产物；可先保留提案待处理，并由用户确认继续主链。'
                  : overallSummary),
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: canDeferPermissionAndContinue,
        allowConfirmCheckpoint:
            !waitingFromPermission && taskType == 'checkpoint',
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: false,
        recommendedActionId: canDeferPermissionAndContinue
            ? 'continue_long_task'
            : (!waitingFromPermission && taskType == 'checkpoint'
                  ? 'confirm_checkpoint_continue'
                  : ''),
      );
    }

    if (!resultOk || error.isNotEmpty) {
      return _result(
        disposition: 'manual_attention',
        reason: 'task_failed',
        summary: '当前单步并未稳定完成，应先人工处理错误或决定是否重试。',
        blocksAutoContinue: true,
        manualAttentionRequired: true,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: persistentContextPaths.isNotEmpty,
        recommendedActionId: persistentContextPaths.isNotEmpty
            ? 'revisit_mode_guidance'
            : '',
      );
    }

    if (_shouldAutoContinueContinuousAgentTask(
      taskType: taskType,
      mode: mode,
      overallCategory: overallCategory,
      collaborationCategory: collaborationCategory,
      informationCategory: informationCategory,
      expressionConstraintCategory: expressionConstraintCategory,
    )) {
      return _result(
        disposition: 'auto_continue',
        reason: 'continuous_agent_task_advisory_only',
        summary: '连续自治内部 agent task 已稳定完成，提醒信号保留给后续章节观察即可，不应把主链停在这里。',
        blocksAutoContinue: false,
        manualAttentionRequired: false,
        allowContinue: true,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: false,
        recommendedActionId: 'continue_long_task',
      );
    }

    if (taskType == 'review') {
      if (severity == 'critical') {
        return _result(
          disposition: 'manual_attention',
          reason: 'critical_review_risk',
          summary: '当前审稿结果风险已到关键级，建议先人工处理或明确返工策略。',
          blocksAutoContinue: true,
          manualAttentionRequired: true,
          allowContinue: false,
          allowConfirmCheckpoint: false,
          createFollowupReviewTasks: false,
          requestRevisionFollowup: false,
          revisitModeGuidance: persistentContextPaths.isNotEmpty,
          recommendedActionId: persistentContextPaths.isNotEmpty
              ? 'revisit_mode_guidance'
              : '',
        );
      }
      if (severity == 'high') {
        return _result(
          disposition: 'blocked_wait_user',
          reason: 'high_review_risk_needs_revision',
          summary: '当前审稿已经明确给出较高风险，建议先派生返工再恢复主链。',
          blocksAutoContinue: true,
          manualAttentionRequired: false,
          allowContinue: false,
          allowConfirmCheckpoint: false,
          createFollowupReviewTasks: false,
          requestRevisionFollowup: true,
          revisitModeGuidance: false,
          recommendedActionId: 'request_revision_followup',
        );
      }
      return _result(
        disposition: 'auto_continue',
        reason: 'review_result_ready',
        summary: '当前审稿结果已形成，可继续主链；若后续需要修复，应派生返工而不是继续卡在 review 自身。',
        blocksAutoContinue: false,
        manualAttentionRequired: false,
        allowContinue: true,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: false,
        recommendedActionId: 'continue_long_task',
      );
    }

    if (outputPaths.isEmpty &&
        <String>{'planning', 'chapter'}.contains(taskType)) {
      return _result(
        disposition: 'manual_attention',
        reason: 'missing_output_paths',
        summary: '当前没有稳定产物文件，不适合直接继续主链。',
        blocksAutoContinue: true,
        manualAttentionRequired: true,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: false,
        revisitModeGuidance: persistentContextPaths.isNotEmpty,
        recommendedActionId: persistentContextPaths.isNotEmpty
            ? 'revisit_mode_guidance'
            : '',
      );
    }

    if (severity == 'critical') {
      final requestRevisionFollowup = <String>{
        'planning',
        'chapter',
        'checkpoint',
      }.contains(taskType);
      final revisitModeGuidance = persistentContextPaths.isNotEmpty;
      return _result(
        disposition: 'manual_attention',
        reason: 'critical_risk',
        summary: '当前节点风险已到关键级，默认不应直接放行主链。',
        blocksAutoContinue: true,
        manualAttentionRequired: true,
        allowContinue: false,
        allowConfirmCheckpoint: false,
        createFollowupReviewTasks: false,
        requestRevisionFollowup: requestRevisionFollowup,
        revisitModeGuidance: revisitModeGuidance,
        recommendedActionId: requestRevisionFollowup
            ? 'request_revision_followup'
            : (revisitModeGuidance ? 'revisit_mode_guidance' : ''),
      );
    }

    if (severity == 'high') {
      final requestRevisionFollowup = <String>{
        'planning',
        'chapter',
        'checkpoint',
      }.contains(taskType);
      return _result(
        disposition: 'blocked_wait_user',
        reason: 'high_risk_needs_gate',
        summary: '当前节点风险较高，建议先补返工或复核，再决定是否继续。',
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: true,
        allowConfirmCheckpoint: taskType == 'checkpoint',
        createFollowupReviewTasks: !requestRevisionFollowup,
        requestRevisionFollowup: requestRevisionFollowup,
        revisitModeGuidance: persistentContextPaths.isNotEmpty,
        recommendedActionId: requestRevisionFollowup
            ? 'request_revision_followup'
            : 'create_followup_review_tasks',
      );
    }

    if (severity == 'medium') {
      return _result(
        disposition: 'blocked_wait_user',
        reason: 'medium_risk_needs_review',
        summary: '当前节点建议先过一轮补充审视，再决定是否继续推进。',
        blocksAutoContinue: true,
        manualAttentionRequired: false,
        allowContinue: true,
        allowConfirmCheckpoint: taskType == 'checkpoint',
        createFollowupReviewTasks: true,
        requestRevisionFollowup: false,
        revisitModeGuidance: false,
        recommendedActionId: 'create_followup_review_tasks',
      );
    }

    return _result(
      disposition: 'auto_continue',
      reason: taskType == 'checkpoint'
          ? 'checkpoint_ready_to_confirm'
          : 'risk_is_low',
      summary: taskType == 'checkpoint'
          ? '当前检查点风险较低，可确认后继续调度。'
          : '当前节点风险较低，可在确认产物后继续主链。',
      blocksAutoContinue: false,
      manualAttentionRequired: false,
      allowContinue: true,
      allowConfirmCheckpoint: taskType == 'checkpoint',
      createFollowupReviewTasks: false,
      requestRevisionFollowup: false,
      revisitModeGuidance: false,
      recommendedActionId: taskType == 'checkpoint'
          ? 'confirm_checkpoint_continue'
          : 'continue_long_task',
    );
  }

  JsonMap _result({
    required String disposition,
    required String reason,
    required String summary,
    required bool blocksAutoContinue,
    required bool manualAttentionRequired,
    required bool allowContinue,
    required bool allowConfirmCheckpoint,
    required bool createFollowupReviewTasks,
    required bool requestRevisionFollowup,
    required bool revisitModeGuidance,
    required String recommendedActionId,
  }) {
    return <String, Object?>{
      'disposition': disposition,
      'reason': reason,
      'summary': summary,
      'blocks_auto_continue': blocksAutoContinue,
      'manual_attention_required': manualAttentionRequired,
      'allow_continue': allowContinue,
      'allow_confirm_checkpoint': allowConfirmCheckpoint,
      'create_followup_review_tasks': createFollowupReviewTasks,
      'request_revision_followup': requestRevisionFollowup,
      'revisit_mode_guidance': revisitModeGuidance,
      'recommended_action_id': recommendedActionId,
    };
  }

  bool _shouldAutoContinueContinuousAgentTask({
    required String taskType,
    required String mode,
    required String overallCategory,
    required String collaborationCategory,
    required String informationCategory,
    required String expressionConstraintCategory,
  }) {
    if (taskType != 'agent_task' || !_isContinuousLongTaskMode(mode)) {
      return false;
    }
    if (!_isAdvisoryOnlyCategory(overallCategory) ||
        !_isAdvisoryOnlyCategory(collaborationCategory) ||
        !_isAdvisoryOnlyCategory(informationCategory) ||
        !_isAdvisoryExpressionCategory(expressionConstraintCategory)) {
      return false;
    }
    return true;
  }

  bool _isContinuousLongTaskMode(String mode) {
    return mode == 'human_outline_ai_draft' || mode == 'seed_to_full_novel';
  }

  bool _isAdvisoryOnlyCategory(String category) {
    return category.isEmpty || category == 'accept';
  }

  bool _isAdvisoryExpressionCategory(String category) {
    return category.isEmpty ||
        category == 'accept' ||
        category == 'suggest_strengthen' ||
        category == 'policy_disabled' ||
        category == 'applied' ||
        category == 'skipped' ||
        category == 'inactive';
  }
}
