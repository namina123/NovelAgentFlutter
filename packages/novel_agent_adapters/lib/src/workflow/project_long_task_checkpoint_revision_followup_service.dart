import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';
import 'project_long_task_checkpoint_review_task_service.dart';

class ProjectLongTaskCheckpointRevisionFollowupService {
  ProjectLongTaskCheckpointRevisionFollowupService({
    required ProjectTaskRepository taskRepository,
    required ProjectLongTaskCheckpointReviewTaskService
    checkpointReviewTaskService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewTaskService = checkpointReviewTaskService;

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;

  Future<JsonMap> requestFollowup({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) async {
    // 中文注释: 该服务把高风险 checkpoint 的“建议返工”落成可恢复状态，但不直接越级生成 revision。
    final created = await _checkpointReviewTaskService.createTasks(
      project: project,
      task: task,
      checkpointReview: checkpointReview,
    );
    final relatedTasks = await _relatedReviewTasks(
      project,
      checkpointReview: checkpointReview,
      checkpointReviewPath: checkpointReviewPath,
    );
    final updatedTask = await _saveRequestedState(
      project,
      task,
      checkpointReviewPath: checkpointReviewPath,
      relatedTasks: relatedTasks,
    );
    return <String, Object?>{
      'ok': true,
      'checkpoint_review_path': checkpointReviewPath,
      'task': updatedTask,
      'review_tasks': relatedTasks,
      'created_tasks': ValueReaders.mapList(created['tasks']),
      'skipped': ValueReaders.mapList(created['skipped']),
      'suggestions': ValueReaders.mapList(created['suggestions']),
      'changed_paths': _mergePaths(
        ValueReaders.stringList(created['changed_paths']),
        <String>[ValueReaders.stringValue(updatedTask['relative_path'])],
      ),
    };
  }

  Future<List<JsonMap>> _relatedReviewTasks(
    ProjectDescriptor project, {
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) async {
    final checkpointReviewId = ValueReaders.stringValue(
      checkpointReview['id'],
    ).trim();
    final result = <JsonMap>[];
    for (final task in await _taskRepository.listTasks(project)) {
      if (ValueReaders.stringValue(task['task_type']) != 'review') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'checkpoint_review_suggestion') {
        continue;
      }
      final matchedById =
          checkpointReviewId.isNotEmpty &&
          ValueReaders.stringValue(metadata['checkpoint_review_id']) ==
              checkpointReviewId;
      final matchedByPath =
          ValueReaders.stringValue(metadata['checkpoint_review_path']) ==
          checkpointReviewPath;
      if (matchedById || matchedByPath) {
        result.add(task);
      }
    }
    result.sort((left, right) {
      final leftPriority = ValueReaders.intValue(
        ValueReaders.mapValue(left['metadata'])['priority_rank'],
        9999,
      );
      final rightPriority = ValueReaders.intValue(
        ValueReaders.mapValue(right['metadata'])['priority_rank'],
        9999,
      );
      final priorityCompare = leftPriority.compareTo(rightPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return ValueReaders.stringValue(
        left['relative_path'],
      ).compareTo(ValueReaders.stringValue(right['relative_path']));
    });
    return result;
  }

  Future<JsonMap> _saveRequestedState(
    ProjectDescriptor project,
    JsonMap task, {
    required String checkpointReviewPath,
    required List<JsonMap> relatedTasks,
  }) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final requestedAt = DateTime.now().toIso8601String();
    final nextTask = ValueReaders.deepCopyMap(task)
      ..['metadata'] = <String, Object?>{
        ...metadata,
        'followup_request_state': 'requested',
        'followup_request_checkpoint_review_path': checkpointReviewPath,
        'followup_request_task_ids': relatedTasks
            .map((item) => ValueReaders.stringValue(item['id']))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false),
        'followup_request_task_paths': relatedTasks
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false),
        'followup_requested_at': requestedAt,
      }
      ..['followup_request_state'] = 'requested'
      ..['followup_request_checkpoint_review_path'] = checkpointReviewPath
      ..['followup_requested_at'] = requestedAt;
    return _taskRepository.saveTask(project, nextTask);
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      final clean = item.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }
}
