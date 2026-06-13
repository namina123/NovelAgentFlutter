import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';

class ProjectLongTaskReviewRepairTaskService {
  ProjectLongTaskReviewRepairTaskService({
    required ProjectReviewReportService reviewReportService,
    required ProjectTaskRepository taskRepository,
    ReviewPathPolicyService? reviewPathPolicyService,
  }) : _reviewReportService = reviewReportService,
       _taskRepository = taskRepository,
       _reviewPathPolicyService =
           reviewPathPolicyService ?? ReviewPathPolicyService();

  final ProjectReviewReportService _reviewReportService;
  final ProjectTaskRepository _taskRepository;
  final ReviewPathPolicyService _reviewPathPolicyService;

  Future<JsonMap> createTask({
    required ProjectDescriptor project,
    required JsonMap task,
    String reviewReportPath = '',
  }) async {
    // 中文注释: 该服务只负责把 review 任务产出的报告再转成修复任务，并在项目内做重复保护。
    final resolvedReportPath = _resolveReviewReportPath(
      task,
      explicitPath: reviewReportPath,
    );
    if (resolvedReportPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Review report path is missing.',
        'changed_paths': const <Object?>[],
      };
    }
    final existing = await _findExistingRevisionTask(
      project,
      resolvedReportPath,
    );
    if (existing.isNotEmpty) {
      final enrichedExisting = await _enrichCreatedTask(
        project,
        existing,
        sourceTask: task,
        reviewReportPath: resolvedReportPath,
      );
      return <String, Object?>{
        'ok': true,
        'duplicated': true,
        'review_report_path': resolvedReportPath,
        'task': enrichedExisting,
        'changed_paths': const <Object?>[],
      };
    }
    final created = await _reviewReportService.createReviewRepairTask(
      project,
      resolvedReportPath,
      sourceTask: task,
    );
    var createdTask = ValueReaders.mapValue(created['task']);
    if (createdTask.isNotEmpty) {
      createdTask = await _enrichCreatedTask(
        project,
        createdTask,
        sourceTask: task,
        reviewReportPath: resolvedReportPath,
      );
    }
    return <String, Object?>{
      'ok': ValueReaders.boolValue(created['ok']),
      'duplicated': false,
      'review_report_path': ValueReaders.stringValue(
        created['review_report_path'],
        resolvedReportPath,
      ),
      'task': createdTask,
      'changed_paths': <Object?>[
        ValueReaders.stringValue(createdTask['relative_path']),
      ],
    };
  }

  String _resolveReviewReportPath(JsonMap task, {String explicitPath = ''}) {
    final direct = _normalizeReportPath(explicitPath);
    if (direct.isNotEmpty) {
      return direct;
    }
    final metadataPath = _normalizeReportPath(
      ValueReaders.stringValue(
        ValueReaders.mapValue(task['metadata'])['review_report_path'],
      ),
    );
    if (metadataPath.isNotEmpty) {
      return metadataPath;
    }
    for (final path in ValueReaders.stringList(task['output_paths'])) {
      final normalized = _normalizeReportPath(path);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    for (final path in ValueReaders.stringList(task['source_paths'])) {
      final normalized = _normalizeReportPath(path);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  String _normalizeReportPath(String path) {
    final clean = path.trim().replaceAll('\\', '/');
    if (!clean.startsWith('reviews/')) {
      return '';
    }
    return _reviewPathPolicyService.reviewMarkdownPath(clean);
  }

  Future<JsonMap> _findExistingRevisionTask(
    ProjectDescriptor project,
    String reviewReportPath,
  ) async {
    final tasks = await _taskRepository.listTasks(project);
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'revision') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (!<String>{
        'review_report',
        'review_repair_handoff',
      }.contains(ValueReaders.stringValue(metadata['origin']))) {
        continue;
      }
      if (ValueReaders.stringValue(metadata['review_report_path']) ==
          reviewReportPath) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  Future<JsonMap> _enrichCreatedTask(
    ProjectDescriptor project,
    JsonMap createdTask, {
    required JsonMap sourceTask,
    required String reviewReportPath,
  }) async {
    // 中文注释: review -> repair 派生出的 revision 任务需要继承长期约束，否则 mode 1 会在返工时丢失风格/世界锚点。
    final sourceMetadata = ValueReaders.mapValue(sourceTask['metadata']);
    final createdMetadata = ValueReaders.mapValue(createdTask['metadata']);
    final workflowMode = ValueReaders.stringValue(
      sourceTask['mode'],
      ValueReaders.stringValue(sourceMetadata['workflow_mode']),
    );
    final runtimeBaselineId = ValueReaders.stringValue(
      sourceMetadata['runtime_baseline_id'],
    ).trim();
    final persistentContextPaths = ValueReaders.stringList(
      sourceMetadata['persistent_context_paths'],
    );
    final dependsOn = _mergePaths(
      ValueReaders.stringList(createdTask['depends_on']),
      <String>[ValueReaders.stringValue(sourceTask['id'])],
    );
    final nextMetadata = <String, Object?>{
      ...createdMetadata,
      if (workflowMode.trim().isNotEmpty) 'workflow_mode': workflowMode,
      if (runtimeBaselineId.isNotEmpty)
        'runtime_baseline_id': runtimeBaselineId,
      if (persistentContextPaths.isNotEmpty)
        'persistent_context_paths': persistentContextPaths,
      'origin_review_task_id': ValueReaders.stringValue(sourceTask['id']),
      'origin_review_task_path': ValueReaders.stringValue(
        sourceTask['relative_path'],
      ),
      'review_report_path': reviewReportPath,
      'origin_checkpoint_review_path': ValueReaders.stringValue(
        sourceMetadata['checkpoint_review_path'],
      ),
      'origin_checkpoint_review_id': ValueReaders.stringValue(
        sourceMetadata['checkpoint_review_id'],
      ),
    };
    final nextTask = ValueReaders.deepCopyMap(createdTask)
      ..['mode'] = workflowMode.trim().isEmpty
          ? ValueReaders.stringValue(createdTask['mode'])
          : workflowMode
      ..['depends_on'] = dependsOn
      ..['metadata'] = nextMetadata
      ..['source_paths'] = _mergePaths(
        ValueReaders.stringList(createdTask['source_paths']),
        persistentContextPaths,
      );
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
