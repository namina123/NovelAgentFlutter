import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';
import 'project_long_task_checkpoint_review_task_service.dart';

class ProjectLongTaskRevisionResolutionService {
  ProjectLongTaskRevisionResolutionService({
    required ProjectTaskRepository taskRepository,
    required ProjectLongTaskCheckpointReviewTaskService
    checkpointReviewTaskService,
    LongTaskRevisionResolutionService? resolutionService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewTaskService = checkpointReviewTaskService,
       _resolutionService =
           resolutionService ?? LongTaskRevisionResolutionService();

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;
  final LongTaskRevisionResolutionService _resolutionService;

  Future<JsonMap> buildResolution({
    required ProjectDescriptor project,
    required JsonMap selector,
  }) async {
    // 中文注释: 项目态服务负责补齐 task 读取与 checkpoint 详情加载，纯规则仍留在 core。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'actions': const <Object?>[],
      };
    }
    final resolution = _resolutionService.buildResolution(task);
    if (!ValueReaders.boolValue(resolution['ok'])) {
      return resolution;
    }
    final checkpointReviewPath = ValueReaders.stringValue(
      resolution['checkpoint_review_path'],
    ).trim();
    JsonMap checkpointReview = const <String, Object?>{};
    if (checkpointReviewPath.isNotEmpty) {
      checkpointReview = await _taskRepository.loadRecord(
        project,
        checkpointReviewPath,
      );
    }
    return <String, Object?>{
      ...resolution,
      'task_record': task,
      'checkpoint_review': checkpointReview,
    };
  }

  Future<JsonMap> applyAction({
    required ProjectDescriptor project,
    required JsonMap selector,
    required String command,
  }) async {
    // 中文注释: 这里把修订收口动作映射到真实项目写入，保持宿主和核心规则之间只有一层薄适配。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'Task not found.'};
    }
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return <String, Object?>{
        'ok': false,
        'error': 'Only revision tasks support revision resolution actions.',
      };
    }
    final cleanCommand = command.trim().toLowerCase();
    switch (cleanCommand) {
      case 'accept_revision':
        return _acceptRevision(project, selector, task);
      case 'retry_revision':
        return _retryRevision(project, selector, task);
      case 'rollback_revision':
        return _rollbackRevision(project, selector, task);
      case 'return_to_checkpoint':
        return _returnToCheckpoint(project, selector, task);
      case 'create_followup_review_tasks':
        return _createFollowupReviewTasks(project, task);
      default:
        return <String, Object?>{
          'ok': false,
          'error': 'Unknown revision resolution command.',
        };
    }
  }

  Future<JsonMap> _acceptRevision(
    ProjectDescriptor project,
    JsonMap selector,
    JsonMap task,
  ) {
    return _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: '用户接受修复结果。',
      extra: <String, Object?>{
        'accepted_revision_diff_path': ValueReaders.stringValue(
          task['revision_diff_path'],
        ),
        'accepted_checkpoint_review_path': _resolvedCheckpointReviewPath(task),
      },
    );
  }

  Future<JsonMap> _retryRevision(
    ProjectDescriptor project,
    JsonMap selector,
    JsonMap task,
  ) {
    return _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusQueued,
      note: '用户要求继续返工，本轮修订重新进入队列。',
      extra: <String, Object?>{
        'retry_from_checkpoint_review_path': _resolvedCheckpointReviewPath(
          task,
        ),
        'retry_from_postprocess_review_report_path': ValueReaders.stringValue(
          task['postprocess_review_report_path'],
        ),
      },
    );
  }

  Future<JsonMap> _returnToCheckpoint(
    ProjectDescriptor project,
    JsonMap selector,
    JsonMap task,
  ) async {
    final checkpointReviewPath = _resolvedCheckpointReviewPath(task);
    final transitioned = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: '用户结束当前返工轮次并返回长任务检查点。',
      extra: <String, Object?>{
        'returned_checkpoint_review_path': checkpointReviewPath,
      },
    );
    return <String, Object?>{
      ...transitioned,
      'checkpoint_review_path': checkpointReviewPath,
    };
  }

  Future<JsonMap> _createFollowupReviewTasks(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    final checkpointReviewPath = _resolvedCheckpointReviewPath(task);
    if (checkpointReviewPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review path is missing.',
        'tasks': const <Object?>[],
        'changed_paths': const <Object?>[],
      };
    }
    final checkpointReview = await _taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    if (checkpointReview.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review not found.',
        'tasks': const <Object?>[],
        'changed_paths': const <Object?>[],
      };
    }
    final created = await _checkpointReviewTaskService.createTasks(
      project: project,
      task: task,
      checkpointReview: checkpointReview,
    );
    return <String, Object?>{
      ...created,
      'checkpoint_review_path': checkpointReviewPath,
    };
  }

  Future<JsonMap> _rollbackRevision(
    ProjectDescriptor project,
    JsonMap selector,
    JsonMap task,
  ) async {
    // 中文注释: 回滚需要读取 revision diff 里的 backup 对，真正文件恢复保持只在 adapter 执行。
    final diffPath = ValueReaders.stringValue(
      task['revision_diff_path'],
    ).trim();
    if (diffPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Revision diff path is missing.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final report = await _taskRepository.loadRecord(
      project,
      diffPath.replaceAll(RegExp(r'\.md$'), '.json'),
    );
    if (report.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Revision diff not found.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final restored = <String>[];
    final failed = <JsonMap>[];
    for (final pair in ValueReaders.mapList(report['pairs'])) {
      final backupPath = ValueReaders.stringValue(pair['backup_path']).trim();
      final targetPath = ValueReaders.stringValue(pair['target_path']).trim();
      if (backupPath.isEmpty || targetPath.isEmpty) {
        failed.add(<String, Object?>{
          'target_path': targetPath,
          'backup_path': backupPath,
          'error': 'Missing backup or target path.',
        });
        continue;
      }
      final backupContent =
          await _taskRepository.readTextFile(project, backupPath) ?? '';
      if (backupContent.isEmpty) {
        failed.add(<String, Object?>{
          'target_path': targetPath,
          'backup_path': backupPath,
          'error': 'Backup file not found.',
        });
        continue;
      }
      await _taskRepository.writeTextFile(project, targetPath, backupContent);
      restored.add(targetPath);
    }
    final transition = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusCancelled,
      note: '用户根据修复 Diff 回滚修复。',
      extra: <String, Object?>{
        'rollback_result': <String, Object?>{
          'ok': failed.isEmpty && restored.isNotEmpty,
          'restored_paths': restored,
          'failed': failed,
        },
        'rolled_back_revision_diff_path': diffPath,
      },
    );
    return <String, Object?>{
      'ok': failed.isEmpty && restored.isNotEmpty,
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'rollback': <String, Object?>{
        'ok': failed.isEmpty && restored.isNotEmpty,
        'restored_paths': restored,
        'failed': failed,
      },
      'transition': transition,
      'warning': failed.isEmpty ? '' : '部分或全部目标回滚失败。',
    };
  }

  String _resolvedCheckpointReviewPath(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    for (final candidate in <String>[
      ValueReaders.stringValue(task['postprocess_checkpoint_review_path']),
      ValueReaders.stringValue(metadata['origin_checkpoint_review_path']),
      ValueReaders.stringValue(metadata['checkpoint_review_path']),
      ValueReaders.stringValue(task['checkpoint_review_path']),
    ]) {
      final clean = candidate.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }
}
