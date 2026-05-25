import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_runtime_constants.dart';

class LongTaskRevisionResolutionService {
  JsonMap buildResolution(JsonMap task) {
    // 中文注释: 该服务只根据 revision 任务当前状态和已知产物生成“收口动作合同”，不触碰存储。
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return <String, Object?>{
        'ok': false,
        'error': 'Only revision tasks can build revision resolution.',
        'actions': const <Object?>[],
      };
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    final revisionDiffPath = ValueReaders.stringValue(
      task['revision_diff_path'],
    ).trim();
    final reviewReportPath = ValueReaders.stringValue(
      metadata['review_report_path'],
    ).trim();
    final postprocessReviewReportPath = ValueReaders.stringValue(
      task['postprocess_review_report_path'],
    ).trim();
    final postprocessReviewReportJsonPath = ValueReaders.stringValue(
      task['postprocess_review_report_json_path'],
    ).trim();
    final checkpointResolution = _resolveCheckpoint(task, metadata);
    final status = ValueReaders.stringValue(
      task['status'],
      TaskRuntimeConstants.statusQueued,
    );
    final stage = _resolutionStage(
      status: status,
      postprocessReviewReportPath: postprocessReviewReportPath,
      checkpointReviewPath: checkpointResolution.path,
    );
    final actions = _actionsFor(
      task,
      status: status,
      revisionDiffPath: revisionDiffPath,
      checkpointReviewPath: checkpointResolution.path,
      checkpointSource: checkpointResolution.source,
    );
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'task': _taskSummary(task),
      'status': status,
      'stage': stage,
      'stage_label': _stageLabel(stage),
      'note': _noteFor(
        stage: stage,
        checkpointReviewPath: checkpointResolution.path,
      ),
      'evidence': <String, Object?>{
        'review_report_path': reviewReportPath,
        'revision_diff_path': revisionDiffPath,
        'postprocess_review_report_path': postprocessReviewReportPath,
        'postprocess_review_report_json_path': postprocessReviewReportJsonPath,
        'postprocess_checkpoint_review_path': ValueReaders.stringValue(
          task['postprocess_checkpoint_review_path'],
        ),
        'origin_checkpoint_review_path': ValueReaders.stringValue(
          metadata['origin_checkpoint_review_path'],
        ),
      },
      'checkpoint_review_path': checkpointResolution.path,
      'checkpoint_review_source': checkpointResolution.source,
      'actions': actions,
      'action_summary': _actionSummary(actions),
    };
  }

  String _resolutionStage({
    required String status,
    required String postprocessReviewReportPath,
    required String checkpointReviewPath,
  }) {
    // 中文注释: 阶段标签用于给 GUI/CLI 统一解释当前修订处在哪个收口节点。
    if (status == TaskRuntimeConstants.statusSucceeded) {
      return 'accepted';
    }
    if (status == TaskRuntimeConstants.statusCancelled) {
      return 'rolled_back';
    }
    if (status == TaskRuntimeConstants.statusFailed) {
      return 'failed';
    }
    if (status == TaskRuntimeConstants.statusWaitingUser &&
        (postprocessReviewReportPath.isNotEmpty ||
            checkpointReviewPath.isNotEmpty)) {
      return 'awaiting_resolution';
    }
    if (status == TaskRuntimeConstants.statusRunning) {
      return 'running';
    }
    if (TaskRuntimeConstants.runnableStatuses.contains(status)) {
      return 'queued';
    }
    return 'drafting';
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'accepted':
        return '已接受';
      case 'rolled_back':
        return '已回滚';
      case 'failed':
        return '修订失败';
      case 'awaiting_resolution':
        return '等待收口';
      case 'running':
        return '执行中';
      case 'queued':
        return '等待执行';
      default:
        return '处理中';
    }
  }

  String _noteFor({
    required String stage,
    required String checkpointReviewPath,
  }) {
    // 中文注释: 说明文案也固定在 core，避免后面 GUI/CLI 再各自猜测修订收口含义。
    switch (stage) {
      case 'accepted':
        return '当前修订任务已经被接受，可以回到上游长任务继续推进。';
      case 'rolled_back':
        return '当前修订任务已经回滚，正文应恢复到备份版本。';
      case 'failed':
        return '修订执行失败，通常应先决定重试、回滚或转回上游检查点。';
      case 'awaiting_resolution':
        return checkpointReviewPath.isEmpty
            ? '后处理已完成，等待决定是否接受、继续返工或回滚。'
            : '后处理已完成，可以继续返工，也可以基于检查点结果回到长任务。';
      case 'running':
        return '修订或后处理仍在运行中，暂不应执行收口动作。';
      case 'queued':
        return '修订任务尚未执行，当前还没有可供收口的结果。';
      default:
        return '当前修订任务还在处理中。';
    }
  }

  List<JsonMap> _actionsFor(
    JsonMap task, {
    required String status,
    required String revisionDiffPath,
    required String checkpointReviewPath,
    required String checkpointSource,
  }) {
    // 中文注释: 动作规则集中在这里，保证 GUI/CLI 都共享同一套可用性判断。
    final terminal = TaskRuntimeConstants.terminalStatuses.contains(status);
    final awaitingResolution =
        status == TaskRuntimeConstants.statusWaitingUser ||
        status == TaskRuntimeConstants.statusFailed ||
        status == TaskRuntimeConstants.statusPaused;
    final baseArguments = <String, Object?>{
      ..._taskSelector(task),
      'checkpoint_review_path': checkpointReviewPath,
    };
    return <JsonMap>[
      _action(
        'accept_revision',
        '接受修复',
        enabled: !terminal && status == TaskRuntimeConstants.statusWaitingUser,
        tone: 'success',
        note: '确认本轮修订结果可接受，并把任务标记为完成。',
        disabledReason: terminal ? '当前修订任务已经处于终态。' : '只有等待确认的修订任务可以直接接受。',
        arguments: baseArguments,
      ),
      _action(
        'retry_revision',
        '继续返工',
        enabled: !terminal && awaitingResolution,
        tone: 'accent',
        note: '把当前修订重新排队，继续沿用同一份长期约束和审稿上下文返工。',
        disabledReason: terminal ? '当前修订任务已经处于终态。' : '当前修订任务还没有进入可返工状态。',
        arguments: baseArguments,
      ),
      _action(
        'rollback_revision',
        '回滚修复',
        enabled: !terminal && revisionDiffPath.isNotEmpty,
        tone: 'danger',
        note: '根据 revision diff 里的备份配对恢复被改写的目标文件。',
        disabledReason: terminal ? '当前修订任务已经处于终态。' : '当前没有可回滚的 revision diff。',
        arguments: baseArguments,
      ),
      _action(
        'return_to_checkpoint',
        '回到检查点',
        enabled: !terminal && checkpointReviewPath.isNotEmpty,
        tone: 'warm',
        note: checkpointSource == 'postprocess'
            ? '结束当前返工轮次，并回到修订后检查点继续决策后续动作。'
            : '结束当前返工轮次，并回到来源长任务检查点继续决策后续动作。',
        disabledReason: terminal ? '当前修订任务已经处于终态。' : '当前没有可回到的检查点。',
        arguments: baseArguments,
      ),
      _action(
        'create_followup_review_tasks',
        '生成后续审稿',
        enabled: checkpointReviewPath.isNotEmpty,
        tone: 'muted',
        note: '根据当前检查点复盘继续物化新的审稿任务，进入下一轮细化判断。',
        disabledReason: '当前没有检查点复盘可用于生成后续审稿任务。',
        arguments: baseArguments,
      ),
    ];
  }

  JsonMap _action(
    String id,
    String label, {
    required bool enabled,
    required String tone,
    required String note,
    required String disabledReason,
    JsonMap arguments = const <String, Object?>{},
  }) {
    // 中文注释: 动作合同统一成一套结构，宿主层只负责映射按钮或命令。
    return <String, Object?>{
      'id': id,
      'label': label,
      'enabled': enabled,
      'host_command': 'apply_revision_resolution_action',
      'tone': tone,
      'note': note,
      'disabled_reason': enabled ? '' : disabledReason,
      'arguments': <String, Object?>{...arguments, 'resolution_command': id},
    };
  }

  JsonMap _taskSummary(JsonMap task) {
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'status': ValueReaders.stringValue(task['status']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
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

  _CheckpointResolution _resolveCheckpoint(JsonMap task, JsonMap metadata) {
    // 中文注释: 检查点优先使用修订后新生成的复盘，其次再回退到来源长任务检查点。
    final postprocess = ValueReaders.stringValue(
      task['postprocess_checkpoint_review_path'],
    ).trim();
    if (postprocess.isNotEmpty) {
      return _CheckpointResolution(path: postprocess, source: 'postprocess');
    }
    final origin = ValueReaders.stringValue(
      metadata['origin_checkpoint_review_path'],
      ValueReaders.stringValue(metadata['checkpoint_review_path']),
    ).trim();
    if (origin.isNotEmpty) {
      return _CheckpointResolution(path: origin, source: 'origin');
    }
    final taskCheckpoint = ValueReaders.stringValue(
      task['checkpoint_review_path'],
    ).trim();
    if (taskCheckpoint.isNotEmpty) {
      return _CheckpointResolution(path: taskCheckpoint, source: 'task');
    }
    return const _CheckpointResolution(path: '', source: '');
  }

  String _actionSummary(List<JsonMap> actions) {
    final enabled = <String>[];
    for (final action in actions) {
      if (ValueReaders.boolValue(action['enabled'])) {
        enabled.add(ValueReaders.stringValue(action['label']));
      }
    }
    return enabled.isEmpty ? '暂无可用收口动作。' : '可用收口动作：${enabled.join('、')}';
  }
}

class _CheckpointResolution {
  const _CheckpointResolution({required this.path, required this.source});

  final String path;
  final String source;
}
