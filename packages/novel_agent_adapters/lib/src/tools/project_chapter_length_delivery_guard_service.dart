import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectChapterLengthDeliveryGuardService {
  ProjectChapterLengthDeliveryGuardService({
    required ProjectTaskRepository taskRepository,
    ChapterLengthMeasurementService? measurementService,
    ChapterLengthProfileResolverService? profileResolverService,
  }) : _taskRepository = taskRepository,
       _measurementService =
           measurementService ?? const ChapterLengthMeasurementService(),
       _profileResolverService =
           profileResolverService ??
           const ChapterLengthProfileResolverService();

  final ProjectTaskRepository _taskRepository;
  final ChapterLengthMeasurementService _measurementService;
  final ChapterLengthProfileResolverService _profileResolverService;

  Future<ProjectChapterLengthDeliveryGuardResult> evaluate({
    required ProjectDescriptor project,
    required String chapterPath,
    required String chapterContent,
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final cleanPath = chapterPath.trim();
    final cleanContent = chapterContent.trim();
    if (cleanPath.isEmpty || cleanContent.isEmpty) {
      return const ProjectChapterLengthDeliveryGuardResult(blocked: false);
    }
    final directProfile = _profileFromMetadata(metadata);
    if (directProfile.isConfigured) {
      return _evaluateProfile(
        profile: directProfile,
        chapterPath: cleanPath,
        chapterContent: cleanContent,
        source: 'request_metadata',
      );
    }
    final task = await _matchingTask(project, cleanPath);
    if (task.isEmpty) {
      return const ProjectChapterLengthDeliveryGuardResult(blocked: false);
    }
    final executionProfile = await _profileFromAtomicExecution(project, task);
    if (executionProfile.isConfigured) {
      return _evaluateProfile(
        profile: executionProfile,
        chapterPath: cleanPath,
        chapterContent: cleanContent,
        source: 'task_atomic_execution',
        task: task,
      );
    }
    final taskProfile = _profileResolverService.resolveFromTask(task);
    if (!taskProfile.isConfigured) {
      return const ProjectChapterLengthDeliveryGuardResult(blocked: false);
    }
    return _evaluateProfile(
      profile: taskProfile,
      chapterPath: cleanPath,
      chapterContent: cleanContent,
      source: 'task_metadata',
      task: task,
    );
  }

  ChapterLengthProfile _profileFromMetadata(JsonMap metadata) {
    final chapterLengthMetadata = ValueReaders.mapValue(
      metadata['chapter_length_metadata'],
    );
    if (chapterLengthMetadata.isNotEmpty) {
      return _profileResolverService.resolveFromTask(<String, Object?>{
        'metadata': chapterLengthMetadata,
      });
    }
    return _profileResolverService.resolveFromTask(<String, Object?>{
      'metadata': metadata,
    });
  }

  Future<JsonMap> _matchingTask(
    ProjectDescriptor project,
    String chapterPath,
  ) async {
    final tasks = await _taskRepository.listTasks(project);
    final normalizedPath = _normalizedPath(chapterPath);
    final candidates = tasks
        .where((task) {
          for (final path in ValueReaders.stringList(task['output_paths'])) {
            if (_normalizedPath(path) == normalizedPath) {
              return true;
            }
          }
          final proposedChapterPath = _normalizedPath(
            ValueReaders.stringValue(
              ValueReaders.mapValue(task['proposed_output_paths'])['chapter'],
            ),
          );
          return proposedChapterPath == normalizedPath;
        })
        .toList(growable: false);
    if (candidates.isEmpty) {
      return const <String, Object?>{};
    }
    candidates.sort((left, right) {
      final statusCompare = _statusRank(
        ValueReaders.stringValue(left['status']),
      ).compareTo(_statusRank(ValueReaders.stringValue(right['status'])));
      if (statusCompare != 0) {
        return statusCompare;
      }
      return ValueReaders.stringValue(
        right['updated_at'],
      ).compareTo(ValueReaders.stringValue(left['updated_at']));
    });
    return ValueReaders.deepCopyMap(candidates.first);
  }

  Future<ChapterLengthProfile> _profileFromAtomicExecution(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim();
    if (executionPath.isEmpty) {
      return ChapterLengthProfile(
        enabled: false,
        targetLength: 0,
        stage: ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['stage'],
          'draft',
        ),
      );
    }
    final execution = await _taskRepository.loadRecord(project, executionPath);
    if (execution.isEmpty) {
      return ChapterLengthProfile(
        enabled: false,
        targetLength: 0,
        stage: ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['stage'],
          'draft',
        ),
      );
    }
    final chapterLengthMetadata = ValueReaders.mapValue(
      ValueReaders.mapValue(
        execution['execution_constraints'],
      )['chapter_length_metadata'],
    );
    if (chapterLengthMetadata.isEmpty) {
      return ChapterLengthProfile(
        enabled: false,
        targetLength: 0,
        stage: ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['stage'],
          'draft',
        ),
      );
    }
    return _profileResolverService.resolveFromTask(<String, Object?>{
      'metadata': chapterLengthMetadata,
    });
  }

  ProjectChapterLengthDeliveryGuardResult _evaluateProfile({
    required ChapterLengthProfile profile,
    required String chapterPath,
    required String chapterContent,
    required String source,
    JsonMap task = const <String, Object?>{},
  }) {
    final min = profile.preferredMin;
    final max = profile.preferredMax;
    if (min <= 0 && max <= 0) {
      return const ProjectChapterLengthDeliveryGuardResult(blocked: false);
    }
    final measuredLength = _measurementService.measureVisibleCharacters(
      chapterContent,
    );
    if (min > 0 && measuredLength < min) {
      return ProjectChapterLengthDeliveryGuardResult(
        blocked: true,
        reason: 'chapter_length_below_minimum',
        summary:
            '章节字数未通过正式交付 gate：$chapterPath 实际长度 $measuredLength，低于最小要求 $min。',
        measuredLength: measuredLength,
        minimumLength: min,
        maximumLength: max,
        source: source,
        taskId: ValueReaders.stringValue(task['id']),
        taskRelativePath: ValueReaders.stringValue(task['relative_path']),
      );
    }
    if (max > 0 && measuredLength > max) {
      return ProjectChapterLengthDeliveryGuardResult(
        blocked: true,
        reason: 'chapter_length_above_maximum',
        summary:
            '章节字数未通过正式交付 gate：$chapterPath 实际长度 $measuredLength，高于最大要求 $max。',
        measuredLength: measuredLength,
        minimumLength: min,
        maximumLength: max,
        source: source,
        taskId: ValueReaders.stringValue(task['id']),
        taskRelativePath: ValueReaders.stringValue(task['relative_path']),
      );
    }
    return ProjectChapterLengthDeliveryGuardResult(
      blocked: false,
      measuredLength: measuredLength,
      minimumLength: min,
      maximumLength: max,
      source: source,
      taskId: ValueReaders.stringValue(task['id']),
      taskRelativePath: ValueReaders.stringValue(task['relative_path']),
    );
  }

  String _normalizedPath(String path) {
    return path.replaceAll('\\', '/').trim();
  }

  int _statusRank(String status) {
    return switch (status.trim()) {
      TaskRuntimeConstants.statusRunning => 0,
      TaskRuntimeConstants.statusPlanning => 1,
      TaskRuntimeConstants.statusQueued => 2,
      TaskRuntimeConstants.statusRetrying => 3,
      TaskRuntimeConstants.statusWaitingUser => 4,
      TaskRuntimeConstants.statusPaused => 5,
      TaskRuntimeConstants.statusSucceeded => 6,
      TaskRuntimeConstants.statusFailed => 7,
      TaskRuntimeConstants.statusCancelled => 8,
      _ => 9,
    };
  }
}

class ProjectChapterLengthDeliveryGuardResult {
  const ProjectChapterLengthDeliveryGuardResult({
    required this.blocked,
    this.reason = '',
    this.summary = '',
    this.measuredLength = 0,
    this.minimumLength = 0,
    this.maximumLength = 0,
    this.source = '',
    this.taskId = '',
    this.taskRelativePath = '',
  });

  final bool blocked;
  final String reason;
  final String summary;
  final int measuredLength;
  final int minimumLength;
  final int maximumLength;
  final String source;
  final String taskId;
  final String taskRelativePath;

  JsonMap toJson() {
    return <String, Object?>{
      'blocked': blocked,
      'reason': reason,
      'summary': summary,
      'measured_length': measuredLength,
      'minimum_length': minimumLength,
      'maximum_length': maximumLength,
      'source': source,
      'task_id': taskId,
      'task_relative_path': taskRelativePath,
    };
  }
}
