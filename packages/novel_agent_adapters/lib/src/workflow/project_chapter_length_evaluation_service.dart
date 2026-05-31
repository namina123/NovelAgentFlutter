import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectChapterLengthEvaluationService {
  ProjectChapterLengthEvaluationService({
    required ProjectTaskRepository taskRepository,
    ChapterLengthProfileResolverService? profileResolverService,
    ChapterLengthMeasurementService? measurementService,
    ChapterLengthDistributionService? distributionService,
  }) : _taskRepository = taskRepository,
       _profileResolverService =
           profileResolverService ?? const ChapterLengthProfileResolverService(),
       _measurementService =
           measurementService ?? const ChapterLengthMeasurementService(),
       _distributionService =
           distributionService ?? const ChapterLengthDistributionService();

  final ProjectTaskRepository _taskRepository;
  final ChapterLengthProfileResolverService _profileResolverService;
  final ChapterLengthMeasurementService _measurementService;
  final ChapterLengthDistributionService _distributionService;

  Future<JsonMap> evaluate({
    required ProjectDescriptor project,
    required JsonMap task,
    required DraftGenerationResult result,
  }) async {
    // 中文注释: adapter 负责收集当前章与最近章节样本，真正的分布判断继续交给 core。
    if (ValueReaders.stringValue(task['task_type']) != 'chapter') {
      return const <String, Object?>{};
    }
    final profile = _profileResolverService.resolveFromTask(task);
    if (!profile.isConfigured) {
      return const <String, Object?>{};
    }
    final currentText = await _currentText(project, task, result);
    final currentLength = _measurementService.measureVisibleCharacters(
      currentText,
    );
    if (currentLength <= 0) {
      return const <String, Object?>{};
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    final currentPath = _currentPath(task, result);
    final currentRecord = ChapterLengthRecord(
      length: currentLength,
      sortOrder: ValueReaders.intValue(metadata['sort_order']),
      taskId: ValueReaders.stringValue(task['id']),
      title: ValueReaders.stringValue(task['title']),
      relativePath: currentPath,
    );
    final history = await _historyRecords(
      project,
      task,
      currentTaskId: ValueReaders.stringValue(task['id']),
      currentPath: currentPath,
    );
    final evaluation = _distributionService.evaluate(
      profile: profile,
      policy: _profileResolverService.resolvePolicyFromTask(task),
      currentRecord: currentRecord,
      history: history,
    );
    return evaluation.toJson();
  }

  Future<List<ChapterLengthRecord>> _historyRecords(
    ProjectDescriptor project,
    JsonMap currentTask, {
    required String currentTaskId,
    required String currentPath,
  }) async {
    final tasks = await _taskRepository.listTasks(project);
    final currentOrder = ValueReaders.intValue(
      ValueReaders.mapValue(currentTask['metadata'])['sort_order'],
    );
    final chapterTasks = tasks
        .where((task) => ValueReaders.stringValue(task['task_type']) == 'chapter')
        .where(
          (task) =>
              ValueReaders.intValue(
                ValueReaders.mapValue(task['metadata'])['sort_order'],
              ) < currentOrder,
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ValueReaders.intValue(
          ValueReaders.mapValue(left['metadata'])['sort_order'],
        ).compareTo(
          ValueReaders.intValue(
            ValueReaders.mapValue(right['metadata'])['sort_order'],
          ),
        ),
      );
    final result = <ChapterLengthRecord>[];
    for (final task in chapterTasks) {
      final taskId = ValueReaders.stringValue(task['id']);
      if (taskId == currentTaskId) {
        continue;
      }
      final path = _firstOutputPath(task);
      if (path.isEmpty || path == currentPath) {
        continue;
      }
      final text = (await _taskRepository.readTextFile(project, path) ?? '').trim();
      if (text.isEmpty) {
        continue;
      }
      final length = _measurementService.measureVisibleCharacters(text);
      if (length <= 0) {
        continue;
      }
      result.add(
        ChapterLengthRecord(
          length: length,
          sortOrder: ValueReaders.intValue(
            ValueReaders.mapValue(task['metadata'])['sort_order'],
          ),
          taskId: taskId,
          title: ValueReaders.stringValue(task['title']),
          relativePath: path,
        ),
      );
    }
    return result;
  }

  Future<String> _currentText(
    ProjectDescriptor project,
    JsonMap task,
    DraftGenerationResult result,
  ) async {
    final path = _currentPath(task, result);
    if (path.isNotEmpty) {
      final saved = await _taskRepository.readTextFile(project, path);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved;
      }
    }
    return result.draftMarkdown;
  }

  String _currentPath(JsonMap task, DraftGenerationResult result) {
    for (final path in result.writtenPaths) {
      if (_looksLikeChapterPath(path)) {
        return path;
      }
    }
    final fallback = _firstOutputPath(task);
    if (_looksLikeChapterPath(fallback)) {
      return fallback;
    }
    return '';
  }

  String _firstOutputPath(JsonMap task) {
    for (final path in ValueReaders.stringList(task['output_paths'])) {
      if (path.trim().isNotEmpty) {
        return path;
      }
    }
    return '';
  }

  bool _looksLikeChapterPath(String path) {
    final normalized = path.trim().toLowerCase();
    return normalized.startsWith('chapters/') || normalized.startsWith('scenes/');
  }
}
