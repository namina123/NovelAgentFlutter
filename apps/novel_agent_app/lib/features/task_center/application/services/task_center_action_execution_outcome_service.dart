import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/task_center_action_execution_outcome.dart';
import '../../presentation/models/task_center_contract_action_view_data.dart';

class TaskCenterActionExecutionOutcomeService {
  const TaskCenterActionExecutionOutcomeService();

  TaskCenterActionExecutionOutcome resolve({
    required TaskCenterContractActionViewData action,
    required JsonMap result,
    required String defaultSuccessMessage,
    required String currentSelectedTaskId,
  }) {
    // 中文注释: 动作结果的选中跳转与状态文案统一收束在这里，避免控制器继续理解各种 runtime 返回结构。
    final success = ValueReaders.boolValue(result['ok']);
    final nextSelectedTaskId = _resolveNextSelectedTaskId(
      action: action,
      result: result,
      currentSelectedTaskId: currentSelectedTaskId,
    );
    return TaskCenterActionExecutionOutcome(
      statusMessage: success
          ? _successMessage(
              action: action,
              result: result,
              fallback: defaultSuccessMessage,
            )
          : _errorMessage(result),
      nextSelectedTaskId: nextSelectedTaskId,
    );
  }

  String _resolveNextSelectedTaskId({
    required TaskCenterContractActionViewData action,
    required JsonMap result,
    required String currentSelectedTaskId,
  }) {
    for (final candidate in <String>[
      _firstTaskPath(result['created_tasks']),
      _firstTaskPath(result['tasks']),
      _firstTaskPath(result['review_tasks']),
      ValueReaders.stringValue(
        ValueReaders.mapValue(result['task'])['relative_path'],
      ),
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(result['transition'])['task'],
        )['relative_path'],
      ),
      ValueReaders.stringValue(
        ValueReaders.mapValue(result['transition'])['relative_path'],
      ),
      ValueReaders.stringValue(result['relative_path']),
      action.ownerTaskPath,
      currentSelectedTaskId,
    ]) {
      final clean = candidate.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }

  String _successMessage({
    required TaskCenterContractActionViewData action,
    required JsonMap result,
    required String fallback,
  }) {
    final warning = ValueReaders.stringValue(result['warning']).trim();
    final message = switch (action.id) {
      'create_followup_review_tasks' => _followupReviewMessage(
        result,
        fallback: fallback,
      ),
      'request_revision_followup' => _revisionFollowupMessage(
        result,
        fallback: fallback,
      ),
      'continue_long_task' => '已确认当前检查点可继续主链。',
      'confirm_checkpoint' => '已确认检查点，长任务可继续推进。',
      'confirm_checkpoint_continue' => '已确认检查点，长任务可继续推进。',
      'retry_failed' => '已将失败任务重新排队，长任务可继续推进。',
      'skip_failed' => '已跳过失败任务，长任务可尝试继续推进。',
      'revisit_mode_guidance' => '已载入长期约束回看。',
      'accept_revision' => '已接受修复结果。',
      'retry_revision' => '已将修订任务重新加入队列。',
      'return_to_checkpoint' => '已结束当前返工轮次并返回检查点。',
      'rollback_revision' => _rollbackMessage(result, fallback: fallback),
      _ => fallback,
    };
    if (warning.isEmpty) {
      return message;
    }
    if (message.contains(warning)) {
      return message;
    }
    return '$message $warning';
  }

  String _followupReviewMessage(JsonMap result, {required String fallback}) {
    final createdCount = _taskCount(result['tasks']);
    if (createdCount <= 0) {
      return fallback;
    }
    return '已生成后续审稿任务 $createdCount 项。';
  }

  String _revisionFollowupMessage(JsonMap result, {required String fallback}) {
    final createdCount = _taskCount(result['created_tasks']);
    final relatedCount = _taskCount(result['review_tasks']);
    if (createdCount > 0 && relatedCount > 0) {
      return '已请求返工，并关联 $relatedCount 个审稿任务（新建 $createdCount 项）。';
    }
    if (createdCount > 0) {
      return '已请求返工，并新建审稿任务 $createdCount 项。';
    }
    if (relatedCount > 0) {
      return '已请求返工，并关联审稿任务 $relatedCount 项。';
    }
    return fallback;
  }

  String _rollbackMessage(JsonMap result, {required String fallback}) {
    final rollback = ValueReaders.mapValue(result['rollback']);
    final restoredCount = ValueReaders.stringList(
      rollback['restored_paths'],
    ).length;
    if (restoredCount <= 0) {
      return fallback;
    }
    return '已回滚修复，并恢复 $restoredCount 个文件。';
  }

  String _errorMessage(JsonMap result) {
    final error = ValueReaders.stringValue(result['error']).trim();
    return error.isEmpty ? '操作失败。' : '操作失败：$error';
  }

  String _firstTaskPath(Object? value) {
    final tasks = ValueReaders.mapList(value);
    if (tasks.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(tasks.first['relative_path']);
  }

  int _taskCount(Object? value) => ValueReaders.mapList(value).length;
}
