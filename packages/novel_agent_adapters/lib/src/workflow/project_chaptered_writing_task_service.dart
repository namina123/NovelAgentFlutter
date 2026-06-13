import 'project_chapter_label_parser_service.dart';

class ProjectChapteredWritingTaskService {
  const ProjectChapteredWritingTaskService({
    ProjectChapterLabelParserService? parserService,
  }) : _parserService =
           parserService ?? const ProjectChapterLabelParserService();

  final ProjectChapterLabelParserService _parserService;

  bool isChapteredWritingTask({
    required String taskType,
    String chapterLabel = '',
  }) {
    final normalizedTaskType = taskType.trim().toLowerCase();
    if (_isExcludedNonWritingTask(normalizedTaskType)) {
      return false;
    }
    if (_isExplicitChapterWritingTask(normalizedTaskType)) {
      return true;
    }
    if (_hasChapterLabel(chapterLabel) &&
        !_looksLikeNonWritingChapterFollowup(normalizedTaskType)) {
      return true;
    }
    return false;
  }

  bool canApplyContinuity({
    required String taskType,
    required String chapterLabel,
  }) {
    return isChapteredWritingTask(
          taskType: taskType,
          chapterLabel: chapterLabel,
        ) &&
        _hasChapterLabel(chapterLabel);
  }

  bool requiresFormalChapterDelivery({
    required String taskType,
    String chapterLabel = '',
    String outputPath = '',
  }) {
    final normalizedTaskType = taskType.trim().toLowerCase();
    if (_isExcludedNonWritingTask(normalizedTaskType)) {
      return false;
    }
    if (_isChapterOutputPath(outputPath) &&
        !_looksLikeNonWritingChapterFollowup(normalizedTaskType)) {
      return true;
    }
    return isChapteredWritingTask(
      taskType: normalizedTaskType,
      chapterLabel: chapterLabel,
    );
  }

  bool _isExplicitChapterWritingTask(String taskType) {
    if (taskType.isEmpty || taskType == 'chapter' || taskType == 'revision') {
      return true;
    }
    return taskType.contains('chapter') ||
        taskType.contains('continuation') ||
        taskType.contains('continue_write') ||
        taskType.contains('continuation_write') ||
        taskType.contains('followup_write') ||
        taskType.contains('rewrite');
  }

  bool _isExcludedNonWritingTask(String taskType) {
    if (taskType == 'planning' ||
        taskType == 'review' ||
        taskType == 'summary' ||
        taskType == 'checkpoint' ||
        taskType == 'world_update' ||
        taskType == 'research' ||
        taskType == 'path_resolution' ||
        taskType == 'tool' ||
        taskType == 'tool_only') {
      return true;
    }
    return taskType.contains('planning') ||
        taskType.contains('review') ||
        taskType.contains('summary') ||
        taskType.contains('checkpoint') ||
        taskType.contains('world_update') ||
        taskType.contains('research') ||
        taskType.contains('path_resolution');
  }

  bool _looksLikeNonWritingChapterFollowup(String taskType) {
    if (!taskType.contains('deconstruction')) {
      return false;
    }
    return !taskType.contains('continuation') &&
        !taskType.contains('write') &&
        !taskType.contains('rewrite');
  }

  bool _hasChapterLabel(String chapterLabel) {
    return _parserService.hasChapterLabel(chapterLabel);
  }

  bool _isChapterOutputPath(String path) {
    final normalized = path.trim().replaceAll('\\', '/').toLowerCase();
    return normalized.startsWith('chapters/') && normalized.endsWith('.md');
  }
}
