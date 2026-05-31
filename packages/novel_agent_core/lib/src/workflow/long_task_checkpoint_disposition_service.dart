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

    if (outputPaths.isEmpty &&
        <String>{'planning', 'chapter', 'checkpoint'}.contains(taskType)) {
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
}
