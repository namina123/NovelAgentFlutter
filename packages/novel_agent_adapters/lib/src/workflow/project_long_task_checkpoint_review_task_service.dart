import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';

class ProjectLongTaskCheckpointReviewTaskService {
  ProjectLongTaskCheckpointReviewTaskService({
    required ProjectReviewReportService reviewReportService,
    required ProjectTaskRepository taskRepository,
    LongTaskCheckpointReviewTaskSuggestionService? suggestionService,
  }) : _reviewReportService = reviewReportService,
       _taskRepository = taskRepository,
       _suggestionService =
           suggestionService ?? LongTaskCheckpointReviewTaskSuggestionService();

  final ProjectReviewReportService _reviewReportService;
  final ProjectTaskRepository _taskRepository;
  final LongTaskCheckpointReviewTaskSuggestionService _suggestionService;

  Future<JsonMap> createTasks({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
  }) async {
    // 中文注释: adapter 层负责把纯建议转成真实任务文件，并过滤重复或无效来源路径。
    final suggestions = _suggestionService.buildSuggestions(
      task: task,
      checkpointReview: checkpointReview,
    );
    final existingTasks = await _taskRepository.listTasks(project);
    final existingKeys = _existingSuggestionKeys(existingTasks);
    final createdTasks = <JsonMap>[];
    final changedPaths = <String>[];
    final skipped = <JsonMap>[];
    for (final suggestion in suggestions) {
      final sourcePath = ValueReaders.stringValue(
        suggestion['source_path'],
      ).trim();
      if (sourcePath.isEmpty) {
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'missing_source_path',
        });
        continue;
      }
      final content = await _taskRepository.readTextFile(project, sourcePath);
      if (content == null || content.trim().isEmpty) {
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'source_not_ready',
        });
        continue;
      }
      final key = _suggestionKey(suggestion);
      if (existingKeys.contains(key)) {
        skipped.add(<String, Object?>{
          ...suggestion,
          'skip_reason': 'duplicate',
        });
        continue;
      }
      final created = await _reviewReportService.createReviewTask(
        project,
        suggestion,
      );
      final taskMap = ValueReaders.mapValue(created['task']);
      if (taskMap.isNotEmpty) {
        createdTasks.add(taskMap);
        changedPaths.add(ValueReaders.stringValue(taskMap['relative_path']));
        existingKeys.add(key);
      }
    }
    return <String, Object?>{
      'ok': true,
      'suggestions': suggestions,
      'tasks': createdTasks,
      'skipped': skipped,
      'changed_paths': changedPaths,
    };
  }

  Set<String> _existingSuggestionKeys(List<JsonMap> tasks) {
    final result = <String>{};
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'review') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'checkpoint_review_suggestion') {
        continue;
      }
      final sourcePath = ValueReaders.stringValue(
        metadata['source_path'],
      ).trim();
      final reviewType = ValueReaders.stringValue(
        metadata['review_type'],
      ).trim();
      final checkpointReviewId = ValueReaders.stringValue(
        metadata['checkpoint_review_id'],
      ).trim();
      if (sourcePath.isEmpty ||
          reviewType.isEmpty ||
          checkpointReviewId.isEmpty) {
        continue;
      }
      result.add('$checkpointReviewId::$sourcePath::$reviewType');
    }
    return result;
  }

  String _suggestionKey(JsonMap suggestion) {
    final metadata = ValueReaders.mapValue(suggestion['metadata']);
    return '${ValueReaders.stringValue(metadata['checkpoint_review_id'])}'
        '::${ValueReaders.stringValue(suggestion['source_path'])}'
        '::${ValueReaders.stringValue(suggestion['review_type'])}';
  }
}
