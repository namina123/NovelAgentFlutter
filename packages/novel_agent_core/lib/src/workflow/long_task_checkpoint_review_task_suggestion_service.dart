import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../review/review_type_catalog_service.dart';
import '../review/review_type_constants.dart';
import 'long_task_planning_artifact_path_service.dart';

class LongTaskCheckpointReviewTaskSuggestionService {
  LongTaskCheckpointReviewTaskSuggestionService({
    ReviewTypeCatalogService? reviewTypeCatalogService,
    LongTaskPlanningArtifactPathService? planningArtifactPathService,
  }) : _reviewTypeCatalogService =
           reviewTypeCatalogService ?? ReviewTypeCatalogService(),
       _planningArtifactPathService =
           planningArtifactPathService ??
           const LongTaskPlanningArtifactPathService();

  final ReviewTypeCatalogService _reviewTypeCatalogService;
  final LongTaskPlanningArtifactPathService _planningArtifactPathService;

  List<JsonMap> buildSuggestions({
    required JsonMap task,
    required JsonMap checkpointReview,
  }) {
    // 中文注释: 该服务只负责把检查点复盘转成“可候选的审稿任务建议”，不做宿主去重和落盘。
    final taskId = ValueReaders.stringValue(task['id'], 'task');
    final taskMetadata = ValueReaders.mapValue(task['metadata']);
    final taskType = ValueReaders.stringValue(
      checkpointReview['task_type'],
      ValueReaders.stringValue(task['task_type']),
    );
    final stage = ValueReaders.stringValue(
      checkpointReview['stage'],
      ValueReaders.stringValue(taskMetadata['stage']),
    );
    final workflowMode = ValueReaders.stringValue(
      task['mode'],
      ValueReaders.stringValue(taskMetadata['workflow_mode']),
    );
    final persistentContextPaths = ValueReaders.stringList(
      taskMetadata['persistent_context_paths'],
    );
    final checkpointReviewId = ValueReaders.stringValue(
      checkpointReview['id'],
      'checkpoint_review_$taskId',
    );
    final checkpointReviewPath = ValueReaders.stringValue(
      checkpointReview['relative_path'],
      ValueReaders.stringValue(checkpointReview['json_path']),
    );
    final outputPaths = _reviewCandidatePaths(
      _cleanPaths(
        ValueReaders.stringList(checkpointReview['output_paths']),
        fallback: ValueReaders.stringList(task['output_paths']),
      ),
      taskType: taskType,
    );
    if (_shouldSkipReviewFollowup(
      taskType: taskType,
      outputPaths: outputPaths,
      taskMetadata: taskMetadata,
    )) {
      return const <JsonMap>[];
    }
    final driftWatchItems = ValueReaders.stringList(
      checkpointReview['drift_watch_items'],
    );
    final expressionConstraintReview = ValueReaders.mapValue(
      checkpointReview['expression_constraint_review'],
    );
    final driftProfile = _driftProfile(
      checkpointReview,
      driftWatchItems: driftWatchItems,
      expressionConstraintReview: expressionConstraintReview,
    );
    final result = <JsonMap>[];
    final seenKeys = <String>{};
    for (final sourcePath in outputPaths) {
      for (final reviewType in _reviewTypesForPath(
        sourcePath,
        taskType: taskType,
        stage: stage,
        driftWatchItems: driftWatchItems,
        driftProfile: driftProfile,
      )) {
        final key = '$sourcePath::$reviewType';
        if (!seenKeys.add(key)) {
          continue;
        }
        final priorityScore = _priorityScore(
          reviewType,
          sourcePath: sourcePath,
          taskType: taskType,
          stage: stage,
          driftProfile: driftProfile,
        );
        final priorityReason = _priorityReason(
          reviewType,
          sourcePath: sourcePath,
          taskType: taskType,
          stage: stage,
          driftProfile: driftProfile,
        );
        result.add(<String, Object?>{
          'source_path': sourcePath,
          'review_type': reviewType,
          'mode': workflowMode,
          'priority_score': priorityScore,
          'title':
              '${_reviewTypeCatalogService.reviewTypeLabel(reviewType)}：${_titleBaseFor(sourcePath)}',
          'reason': _reasonFor(
            reviewType,
            taskType: taskType,
            stage: stage,
            priorityReason: priorityReason,
          ),
          'metadata': <String, Object?>{
            'origin': 'checkpoint_review_suggestion',
            'checkpoint_review_path': checkpointReviewPath,
            'checkpoint_review_id': checkpointReviewId,
            'task_id': taskId,
            'task_type': taskType,
            'stage': stage,
            'workflow_mode': workflowMode,
            'persistent_context_paths': persistentContextPaths,
            'plan_id': ValueReaders.stringValue(taskMetadata['plan_id']),
            'source_path': sourcePath,
            'review_type': reviewType,
            'priority_score': priorityScore,
            'priority_reason': priorityReason,
            'drift_focus': _driftFocus(reviewType, driftProfile),
            if (expressionConstraintReview.isNotEmpty)
              'expression_constraint_review': expressionConstraintReview,
            if (ValueReaders.stringList(
              expressionConstraintReview['review_focuses'],
            ).isNotEmpty)
              'review_focuses': ValueReaders.stringList(
                expressionConstraintReview['review_focuses'],
              ),
            if (ValueReaders.stringList(
              expressionConstraintReview['mini_recheck_items'],
            ).isNotEmpty)
              'mini_recheck_items': ValueReaders.stringList(
                expressionConstraintReview['mini_recheck_items'],
              ),
            if (ValueReaders.stringValue(
              expressionConstraintReview['authenticity_pass_level'],
            ).trim().isNotEmpty)
              'authenticity_pass_level': ValueReaders.stringValue(
                expressionConstraintReview['authenticity_pass_level'],
              ),
          },
        });
      }
    }
    result.sort((left, right) {
      final scoreCompare = ValueReaders.intValue(
        right['priority_score'],
      ).compareTo(ValueReaders.intValue(left['priority_score']));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final pathCompare = ValueReaders.stringValue(
        left['source_path'],
      ).compareTo(ValueReaders.stringValue(right['source_path']));
      if (pathCompare != 0) {
        return pathCompare;
      }
      return ValueReaders.stringValue(
        left['review_type'],
      ).compareTo(ValueReaders.stringValue(right['review_type']));
    });
    for (var index = 0; index < result.length; index += 1) {
      result[index]['priority_rank'] = index + 1;
      final metadata = ValueReaders.mapValue(result[index]['metadata']);
      result[index]['metadata'] = <String, Object?>{
        ...metadata,
        'priority_rank': index + 1,
      };
    }
    return result;
  }

  bool _shouldSkipReviewFollowup({
    required String taskType,
    required List<String> outputPaths,
    required JsonMap taskMetadata,
  }) {
    // 中文注释: review 任务的产物不再继续派生“审稿的审稿”，否则会在 checkpoint followup 上递归膨胀并卡住主链。
    if (taskType == 'review') {
      return true;
    }
    if (ValueReaders.stringValue(taskMetadata['origin']) ==
        'checkpoint_review_suggestion') {
      return true;
    }
    if (outputPaths.isEmpty) {
      return false;
    }
    return outputPaths.every(
      (path) => path.toLowerCase().startsWith('reviews/'),
    );
  }

  List<String> _cleanPaths(
    List<String> paths, {
    List<String> fallback = const <String>[],
  }) {
    final candidates = paths.isEmpty ? fallback : paths;
    final result = <String>[];
    for (final rawPath in candidates) {
      final clean = rawPath.trim().replaceAll('\\', '/');
      if (clean.isEmpty || clean.endsWith('/')) {
        continue;
      }
      if (!result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  List<String> _reviewCandidatePaths(
    List<String> outputPaths, {
    required String taskType,
  }) {
    final filtered = outputPaths
        .where(_isReviewableOutputPath)
        .toList(growable: false);
    if (taskType != 'planning') {
      return filtered;
    }
    return filtered
        .where(_isPlanningReviewCandidatePath)
        .toList(growable: false);
  }

  bool _isReviewableOutputPath(String path) {
    final lowerPath = path.trim().replaceAll('\\', '/').toLowerCase();
    if (lowerPath.isEmpty) {
      return false;
    }
    return !_startsWithAny(lowerPath, const <String>[
      'tasks/',
      'tracking/',
      '.novel_agent/',
      'runs/',
      'sessions/',
      'exports/',
      'backups/',
      'reviews/',
    ]);
  }

  bool _isPlanningReviewCandidatePath(String path) {
    final lowerPath = path.trim().replaceAll('\\', '/').toLowerCase();
    if (lowerPath ==
        LongTaskPlanningArtifactPathService.projectSpecPath.toLowerCase()) {
      return true;
    }
    return _startsWithAny(lowerPath, <String>[
      '${_planningArtifactPathService.storyOutlinePath().toLowerCase().split('/').first}/',
      '${_planningArtifactPathService.chapterPlanPath().toLowerCase().split('/').first}/',
      'outlines/story/',
      'outlines/chapters/',
      'outlines/volumes/',
      'outline/',
      'chapter_outlines/',
      'volume_outlines/',
    ]);
  }

  List<String> _reviewTypesForPath(
    String sourcePath, {
    required String taskType,
    required String stage,
    required List<String> driftWatchItems,
    required _CheckpointDriftProfile driftProfile,
  }) {
    final lowerPath = sourcePath.toLowerCase();
    final types = <String>[];
    if (_startsWithAny(lowerPath, const <String>[
      'chapters/',
      'scenes/',
      'chapter_outlines/',
    ])) {
      _addType(types, ReviewTypeConstants.continuity);
      _addType(types, ReviewTypeConstants.plot);
      if (stage == 'sample' ||
          _mentionsStyleRisk(driftWatchItems) ||
          driftProfile.styleSeverity > 0 ||
          driftProfile.authenticitySeverity > 0) {
        _addType(types, ReviewTypeConstants.style);
      }
      return types;
    }
    if (_startsWithAny(lowerPath, const <String>[
      'outline/',
      'volume_outlines/',
    ])) {
      _addType(types, ReviewTypeConstants.plot);
      if (driftProfile.continuityPressure > 1) {
        _addType(types, ReviewTypeConstants.continuity);
      }
      return types;
    }
    if (lowerPath.startsWith('specs/')) {
      _addType(types, ReviewTypeConstants.plot);
      _addType(types, ReviewTypeConstants.continuity);
      return types;
    }
    if (_startsWithAny(lowerPath, const <String>[
      'assets/styles/',
      'styles/',
    ])) {
      _addType(types, ReviewTypeConstants.style);
      return types;
    }
    if (_startsWithAny(lowerPath, const <String>[
      'assets/world/',
      'assets/characters/',
      'assets/foreshadows/',
      'assets/timeline/',
      'assets/relationships/',
      'world/',
      'characters/',
      'knowledge/',
    ])) {
      _addType(types, ReviewTypeConstants.continuity);
      return types;
    }
    if (taskType == 'planning') {
      _addType(types, ReviewTypeConstants.plot);
    } else if (taskType == 'chapter') {
      _addType(types, ReviewTypeConstants.continuity);
    } else {
      _addType(types, ReviewTypeConstants.general);
    }
    return types;
  }

  int _priorityScore(
    String reviewType, {
    required String sourcePath,
    required String taskType,
    required String stage,
    required _CheckpointDriftProfile driftProfile,
  }) {
    final lowerPath = sourcePath.toLowerCase();
    if (reviewType == ReviewTypeConstants.style) {
      return 60 +
          driftProfile.styleSeverity * 20 +
          driftProfile.authenticitySeverity * 12 +
          (stage == 'sample' ? 12 : 0) +
          (_startsWithAny(lowerPath, const <String>[
                'assets/styles/',
                'styles/',
              ])
              ? 8
              : 0);
    }
    if (reviewType == ReviewTypeConstants.continuity) {
      return 58 +
          driftProfile.continuityPressure * 20 +
          (_startsWithAny(lowerPath, const <String>[
                'assets/world/',
                'assets/characters/',
                'assets/foreshadows/',
                'assets/timeline/',
                'assets/relationships/',
                'world/',
                'characters/',
                'knowledge/',
                'specs/',
              ])
              ? 8
              : 0);
    }
    if (reviewType == ReviewTypeConstants.plot) {
      return 56 +
          (taskType == 'planning' ? 14 : 0) +
          (lowerPath.startsWith('outline/') ||
                  lowerPath.startsWith('volume_outlines/')
              ? 10
              : 0) +
          driftProfile.overallSeverity * 3;
    }
    return 30 + driftProfile.overallSeverity * 2;
  }

  String _priorityReason(
    String reviewType, {
    required String sourcePath,
    required String taskType,
    required String stage,
    required _CheckpointDriftProfile driftProfile,
  }) {
    if (reviewType == ReviewTypeConstants.style &&
        driftProfile.styleSeverity >= 1) {
      return '检查点已出现文风漂移信号，文风审稿应前置。';
    }
    if (reviewType == ReviewTypeConstants.style &&
        driftProfile.authenticitySeverity >= 1) {
      return '当前表达限制要求额外做真实性 / 去模板复核，文风审稿应前置。';
    }
    if (reviewType == ReviewTypeConstants.continuity &&
        driftProfile.continuityPressure >= 2) {
      return '检查点已出现世界规则或角色状态漂移信号，连续性审稿应前置。';
    }
    if (reviewType == ReviewTypeConstants.plot && taskType == 'planning') {
      return '当前规划产物更需要优先确认剧情承诺和结构链路。';
    }
    if (reviewType == ReviewTypeConstants.style && stage == 'sample') {
      return '样章阶段适合尽早验证文风、节奏和入口质感。';
    }
    if (reviewType == ReviewTypeConstants.continuity &&
        _startsWithAny(sourcePath.toLowerCase(), const <String>[
          'assets/world/',
          'assets/characters/',
          'assets/foreshadows/',
          'assets/timeline/',
          'assets/relationships/',
          'world/',
          'characters/',
          'knowledge/',
        ])) {
      return '当前产物直接关联世界观或角色信息，适合优先做连续性核查。';
    }
    return '';
  }

  List<String> _driftFocus(
    String reviewType,
    _CheckpointDriftProfile driftProfile,
  ) {
    if (reviewType == ReviewTypeConstants.style) {
      if (driftProfile.styleSeverity > 0) {
        return <String>[
          'style',
          if (driftProfile.authenticitySeverity > 0) 'authenticity',
        ];
      }
      if (driftProfile.authenticitySeverity > 0) {
        return const <String>['authenticity'];
      }
      return const <String>[];
    }
    if (reviewType == ReviewTypeConstants.continuity) {
      final result = <String>[];
      if (driftProfile.worldSeverity > 0) {
        result.add('world');
      }
      if (driftProfile.entitySeverity > 0) {
        result.add('entity');
      }
      if (driftProfile.narrativeSeverity > 0) {
        result.add('narrative');
      }
      return result;
    }
    return const <String>[];
  }

  bool _startsWithAny(String value, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  void _addType(List<String> types, String reviewType) {
    final normalized = _reviewTypeCatalogService.normalizeReviewType(
      reviewType,
    );
    if (!types.contains(normalized)) {
      types.add(normalized);
    }
  }

  bool _mentionsStyleRisk(List<String> driftWatchItems) {
    final text = driftWatchItems.join(' ');
    return text.contains('文风') || text.contains('风格') || text.contains('语言');
  }

  String _titleBaseFor(String sourcePath) {
    final fileName = sourcePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  String _reasonFor(
    String reviewType, {
    required String taskType,
    required String stage,
    required String priorityReason,
  }) {
    if (reviewType == ReviewTypeConstants.style) {
      final base = stage == 'sample'
          ? '样章阶段需要尽早验证文风、节奏和入口质感。'
          : '当前产物涉及正文或风格文件，适合补一轮文风审稿。';
      return _mergeReason(base, priorityReason);
    }
    if (reviewType == ReviewTypeConstants.plot) {
      final base = taskType == 'planning'
          ? '规划产物需要确认剧情承诺、章法和因果链是否成立。'
          : '当前产物涉及正文或大纲，需要确认剧情推进与章节功能。';
      return _mergeReason(base, priorityReason);
    }
    if (reviewType == ReviewTypeConstants.continuity) {
      return _mergeReason('当前产物需要确认世界规则、角色状态和前后文连续性。', priorityReason);
    }
    return _mergeReason('当前检查点建议补一轮综合审视。', priorityReason);
  }

  String _mergeReason(String base, String extra) {
    final cleanExtra = extra.trim();
    if (cleanExtra.isEmpty) {
      return base;
    }
    return '$base $cleanExtra';
  }

  _CheckpointDriftProfile _driftProfile(
    JsonMap checkpointReview, {
    required List<String> driftWatchItems,
    required JsonMap expressionConstraintReview,
  }) {
    var styleSeverity = _mentionsStyleRisk(driftWatchItems) ? 1 : 0;
    var worldSeverity = 0;
    var entitySeverity = 0;
    var narrativeSeverity = 0;
    final authenticitySeverity = _authenticitySeverity(
      expressionConstraintReview,
    );
    if (ValueReaders.stringList(
          expressionConstraintReview['continuity_watch_items'],
        ).isNotEmpty &&
        narrativeSeverity < 2) {
      narrativeSeverity = 2;
    }
    for (final rawSignal in ValueReaders.mapList(
      checkpointReview['drift_signals'],
    )) {
      final domain = ValueReaders.stringValue(rawSignal['domain']).trim();
      final severity = _severityScore(
        ValueReaders.stringValue(rawSignal['severity']),
      );
      switch (domain) {
        case 'style':
          if (severity > styleSeverity) {
            styleSeverity = severity;
          }
          break;
        case 'world':
          if (severity > worldSeverity) {
            worldSeverity = severity;
          }
          break;
        case 'entity':
          if (severity > entitySeverity) {
            entitySeverity = severity;
          }
          break;
        case 'narrative':
          if (severity > narrativeSeverity) {
            narrativeSeverity = severity;
          }
          break;
      }
    }
    return _CheckpointDriftProfile(
      styleSeverity: styleSeverity,
      worldSeverity: worldSeverity,
      entitySeverity: entitySeverity,
      narrativeSeverity: narrativeSeverity,
      authenticitySeverity: authenticitySeverity,
    );
  }

  int _authenticitySeverity(JsonMap expressionConstraintReview) {
    switch (ValueReaders.stringValue(
      expressionConstraintReview['authenticity_pass_level'],
    ).trim()) {
      case ExpressionConstraintReviewProjection.authenticityAggressive:
        return 3;
      case ExpressionConstraintReviewProjection.authenticityMedium:
        return 2;
      case ExpressionConstraintReviewProjection.authenticityLight:
        return 1;
      default:
        return 0;
    }
  }

  int _severityScore(String severity) {
    switch (severity.trim()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}

class _CheckpointDriftProfile {
  const _CheckpointDriftProfile({
    required this.styleSeverity,
    required this.worldSeverity,
    required this.entitySeverity,
    required this.narrativeSeverity,
    required this.authenticitySeverity,
  });

  final int styleSeverity;
  final int worldSeverity;
  final int entitySeverity;
  final int narrativeSeverity;
  final int authenticitySeverity;

  int get continuityPressure {
    var result = worldSeverity > entitySeverity
        ? worldSeverity
        : entitySeverity;
    if (narrativeSeverity > result) {
      result = narrativeSeverity;
    }
    return result;
  }

  int get overallSeverity {
    var result = styleSeverity > authenticitySeverity
        ? styleSeverity
        : authenticitySeverity;
    if (worldSeverity > result) {
      result = worldSeverity;
    }
    if (entitySeverity > result) {
      result = entitySeverity;
    }
    if (narrativeSeverity > result) {
      result = narrativeSeverity;
    }
    return result;
  }
}
