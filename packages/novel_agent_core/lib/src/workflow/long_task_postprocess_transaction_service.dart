import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'long_task_transaction_context_service.dart';

class LongTaskPostprocessTransactionService {
  LongTaskPostprocessTransactionService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    required LongTaskTransactionContextService contextService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService,
       _contextService = contextService;

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskTransactionContextService _contextService;

  JsonMap buildPostprocessTransaction(
    JsonMap task,
    JsonMap execution,
    List<Object?> draftPaths, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 后处理事务包把正文后处理和修订复核的差异显式写出来，避免宿主层分支过重。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final cleanDraftPaths = _pathPolicyService.stringList(draftPaths);
    final transaction = <String, Object?>{
      'ok': true,
      'transaction_type': 'long_task_postprocess_step',
      'phase': taskType == 'revision'
          ? 'revision_review'
          : 'chapter_postprocess',
      'mode': _modeService.normalizeMode(
        ValueReaders.stringValue(task['mode']),
      ),
      'agent_role': taskType == 'revision'
          ? 'revision_reviewer'
          : 'postprocess_reviewer',
      'task_type': taskType,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title'], '未命名任务'),
      'chapter': ValueReaders.stringValue(task['chapter']),
      'goal': ValueReaders.stringValue(task['goal']),
      'draft_paths': cleanDraftPaths,
      'execution_path': ValueReaders.stringValue(execution['relative_path']),
      'project_templates': ValueReaders.mapValue(options['project_templates']),
    };
    if (taskType == 'revision') {
      final diffPath = _pathPolicyService.safeProjectPath(
        ValueReaders.stringValue(
          task['revision_diff_path'],
          ValueReaders.stringValue(execution['revision_diff_path']),
        ),
      );
      final reviewPath = _contextService.originalReviewPath(task);
      final targets = _contextService.revisionTargets(task, cleanDraftPaths);
      transaction['revision_targets'] = targets;
      transaction['original_review_path'] = reviewPath;
      transaction['revision_diff_path'] = diffPath;
      transaction['related_paths'] = _pathPolicyService.mergePaths(
        reviewPath.isEmpty ? const <Object?>[] : <Object?>[reviewPath],
        diffPath.isEmpty ? const <Object?>[] : <Object?>[diffPath],
      );
    }
    return transaction;
  }
}
