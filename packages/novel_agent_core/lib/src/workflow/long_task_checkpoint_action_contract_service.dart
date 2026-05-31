import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_checkpoint_disposition_service.dart';

class LongTaskCheckpointActionContractService {
  LongTaskCheckpointActionContractService({
    LongTaskCheckpointDispositionService? dispositionService,
  }) : _dispositionService =
           dispositionService ?? LongTaskCheckpointDispositionService();

  final LongTaskCheckpointDispositionService _dispositionService;

  JsonMap buildPackage(JsonMap review, {String checkpointReviewPath = ''}) {
    // 中文注释: 动作合同只描述“此刻适合做什么”，不在这里执行任何宿主操作。
    final severity = ValueReaders.stringValue(review['severity'], 'low').trim();
    final task = ValueReaders.mapValue(review['task']);
    final actionPath = checkpointReviewPath.trim().isEmpty
        ? ValueReaders.stringValue(review['json_path']).trim()
        : checkpointReviewPath.trim();
    final disposition = _dispositionService.resolve(review);
    final actions = <JsonMap>[
      _action(
        'create_followup_review_tasks',
        '生成后续审稿',
        enabled: ValueReaders.boolValue(
          disposition['create_followup_review_tasks'],
        ),
        tone:
            ValueReaders.stringValue(disposition['disposition']) ==
                'blocked_wait_user'
            ? 'accent'
            : 'muted',
        note: '把当前检查点复盘继续物化成 review 任务，进入下一轮精细判断。',
        disabledReason: '当前没有稳定产物可用于生成后续审稿任务。',
        hostCommand: 'apply_checkpoint_review_action',
        arguments: <String, Object?>{
          ..._taskSelector(task),
          'checkpoint_review_path': actionPath,
          'checkpoint_action': 'create_followup_review_tasks',
        },
      ),
      _action(
        'continue_long_task',
        '继续主链',
        enabled: ValueReaders.boolValue(disposition['allow_continue']),
        tone: _continueTone(severity),
        note: _continueNote(review, disposition),
        disabledReason: '当前没有稳定产物可供确认后继续主链。',
        hostCommand: 'apply_checkpoint_review_action',
        arguments: <String, Object?>{
          ..._taskSelector(task),
          'checkpoint_review_path': actionPath,
        },
      ),
      _action(
        'request_revision_followup',
        '建议返工',
        enabled: ValueReaders.boolValue(
          disposition['request_revision_followup'],
        ),
        tone: 'warm',
        note: '当前节点风险较高，建议先插入返工或复核动作，再决定是否继续主链。',
        disabledReason: '当前节点还不需要优先走返工分支。',
        hostCommand: 'apply_checkpoint_review_action',
        arguments: <String, Object?>{
          ..._taskSelector(task),
          'checkpoint_review_path': actionPath,
          'checkpoint_action': 'request_revision_followup',
        },
      ),
      _action(
        'confirm_checkpoint_continue',
        '确认检查点',
        enabled: ValueReaders.boolValue(
          disposition['allow_confirm_checkpoint'],
        ),
        tone: 'success',
        note: '将当前 checkpoint 任务标记为已确认，允许长任务继续调度。',
        disabledReason: '当前复盘对应的不是显式 checkpoint 任务。',
        hostCommand: 'apply_checkpoint_review_action',
        arguments: <String, Object?>{
          ..._taskSelector(task),
          'checkpoint_review_path': actionPath,
          'revision_command': 'confirm_checkpoint',
        },
      ),
      _action(
        'revisit_mode_guidance',
        '回看长期约束',
        enabled: ValueReaders.boolValue(disposition['revisit_mode_guidance']),
        tone: 'danger',
        note: '当前节点可能已经接近长期约束边界，建议回看模式摘要、风格和世界锚点。',
        disabledReason: '当前没有额外长期约束需要强制回看。',
        hostCommand: 'apply_checkpoint_review_action',
        arguments: <String, Object?>{
          ..._taskSelector(task),
          'checkpoint_review_path': actionPath,
        },
      ),
    ];
    return <String, Object?>{
      'disposition': disposition,
      'actions': actions,
      'action_summary': _actionSummary(actions),
      'recommended_action_id': _recommendedActionId(
        actions,
        severity,
        ValueReaders.stringValue(disposition['recommended_action_id']),
      ),
    };
  }

  JsonMap _action(
    String id,
    String label, {
    required bool enabled,
    required String tone,
    required String note,
    required String disabledReason,
    required String hostCommand,
    JsonMap arguments = const <String, Object?>{},
  }) {
    return <String, Object?>{
      'id': id,
      'label': label,
      'enabled': enabled,
      'tone': tone,
      'note': note,
      'host_command': hostCommand,
      'disabled_reason': enabled ? '' : disabledReason,
      'arguments': arguments,
    };
  }

  JsonMap _taskSelector(JsonMap task) {
    final result = <String, Object?>{};
    final relativePath = ValueReaders.stringValue(task['relative_path']).trim();
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (relativePath.isNotEmpty) {
      result['relative_path'] = relativePath;
    }
    if (taskId.isNotEmpty) {
      result['task_id'] = taskId;
    }
    return result;
  }

  String _actionSummary(List<JsonMap> actions) {
    final enabled = <String>[];
    for (final action in actions) {
      if (ValueReaders.boolValue(action['enabled'])) {
        enabled.add(ValueReaders.stringValue(action['label']));
      }
    }
    return enabled.isEmpty ? '当前暂无可执行动作。' : '建议动作：${enabled.join('、')}';
  }

  String _recommendedActionId(
    List<JsonMap> actions,
    String severity,
    String dispositionRecommendedActionId,
  ) {
    if (dispositionRecommendedActionId.trim().isNotEmpty) {
      for (final action in actions) {
        if (ValueReaders.boolValue(action['enabled']) &&
            ValueReaders.stringValue(action['id']) ==
                dispositionRecommendedActionId) {
          return dispositionRecommendedActionId;
        }
      }
    }
    final priority = <String>[
      if (severity == 'critical') 'revisit_mode_guidance',
      if (severity == 'high') 'request_revision_followup',
      if (severity == 'medium') 'create_followup_review_tasks',
      'continue_long_task',
      'confirm_checkpoint_continue',
    ];
    for (final id in priority) {
      for (final action in actions) {
        if (ValueReaders.boolValue(action['enabled']) &&
            ValueReaders.stringValue(action['id']) == id) {
          return id;
        }
      }
    }
    return '';
  }

  String _continueTone(String severity) {
    if (severity == 'critical') {
      return 'danger';
    }
    if (severity == 'high') {
      return 'warm';
    }
    return 'success';
  }

  String _continueNoteBySeverity(String severity) {
    if (severity == 'critical' || severity == 'high') {
      return '当前存在较高风险；只有在你确认接受现状时，才建议继续主链推进。';
    }
    return '当前风险可控，确认产物后可以继续主链推进。';
  }

  String _continueNote(JsonMap review, JsonMap disposition) {
    final summary = ValueReaders.stringValue(disposition['summary']).trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    return _continueNoteBySeverity(
      ValueReaders.stringValue(review['severity']),
    );
  }
}
