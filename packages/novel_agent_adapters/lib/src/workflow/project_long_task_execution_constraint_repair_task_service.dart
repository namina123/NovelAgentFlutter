import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectLongTaskExecutionConstraintRepairTaskService {
  ProjectLongTaskExecutionConstraintRepairTaskService({
    required ProjectTaskRepository taskRepository,
  }) : _taskRepository = taskRepository;

  final ProjectTaskRepository _taskRepository;

  Future<JsonMap> createTaskIfNeeded({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) async {
    final plan = _repairPlan(
      task: task,
      checkpointReview: checkpointReview,
      checkpointReviewPath: checkpointReviewPath,
    );
    if (!ValueReaders.boolValue(plan['needed'])) {
      return <String, Object?>{
        'ok': true,
        'created': false,
        'reason': ValueReaders.stringValue(plan['reason']),
        'changed_paths': const <Object?>[],
      };
    }
    final sourcePaths = ValueReaders.stringList(plan['source_paths']);
    final outputPaths = ValueReaders.stringList(plan['output_paths']);
    if (outputPaths.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'created': false,
        'error': 'Execution constraint repair output path is missing.',
        'changed_paths': const <Object?>[],
      };
    }
    final existing = await _findExistingRepairTask(
      project,
      checkpointReviewPath,
    );
    if (existing.isNotEmpty) {
      final rewired = await _rewireDependents(
        project,
        predecessorTaskId: ValueReaders.stringValue(task['id']),
        repairTaskId: ValueReaders.stringValue(existing['id']),
      );
      return <String, Object?>{
        'ok': true,
        'created': false,
        'duplicated': true,
        'repair_task': existing,
        'rewired_tasks': rewired,
        'changed_paths': rewired
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((path) => path.trim().isNotEmpty)
            .toList(growable: false),
      };
    }
    final repairTask = await _taskRepository.saveTask(
      project,
      _repairTask(
        sourceTask: task,
        checkpointReview: checkpointReview,
        checkpointReviewPath: checkpointReviewPath,
        sourcePaths: sourcePaths,
        outputPaths: outputPaths,
        plan: plan,
      ),
    );
    final rewired = await _rewireDependents(
      project,
      predecessorTaskId: ValueReaders.stringValue(task['id']),
      repairTaskId: ValueReaders.stringValue(repairTask['id']),
    );
    return <String, Object?>{
      'ok': true,
      'created': true,
      'repair_task': repairTask,
      'rewired_tasks': rewired,
      'changed_paths': <Object?>[
        ValueReaders.stringValue(repairTask['relative_path']),
        ...rewired.map(
          (item) => ValueReaders.stringValue(item['relative_path']),
        ),
      ],
    };
  }

  JsonMap _repairPlan({
    required JsonMap task,
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
  }) {
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    if (!<String>{'chapter', 'revision'}.contains(taskType)) {
      return const <String, Object?>{
        'needed': false,
        'reason': 'task_type_not_repairable',
      };
    }
    if (_autoRepairDepth(task) >= 2) {
      return const <String, Object?>{
        'needed': false,
        'reason': 'execution_constraint_repair_depth_exceeded',
      };
    }
    final expressionSignal = ValueReaders.mapValue(
      checkpointReview['expression_constraint_signal'],
    );
    final expressionReview = ValueReaders.mapValue(
      checkpointReview['expression_constraint_review'],
    );
    final narrativeExpression = ValueReaders.mapValue(
      ValueReaders.mapValue(
        checkpointReview['narrative_supervisor_risk'],
      )['expression_constraints'],
    );
    final gateDisposition = ValueReaders.stringValue(
      expressionSignal['gate_disposition'],
      ValueReaders.stringValue(narrativeExpression['gate_disposition']),
    ).trim();
    final repairRequired =
        ValueReaders.boolValue(expressionSignal['repair_required']) ||
        ValueReaders.boolValue(narrativeExpression['repair_required']) ||
        gateDisposition ==
            ExpressionConstraintGateRecommendedDispositions.repair;
    if (!repairRequired) {
      return const <String, Object?>{
        'needed': false,
        'reason': 'execution_constraint_repair_not_required',
      };
    }
    final deliveredPath = ValueReaders.stringValue(
      ValueReaders.mapValue(
        ValueReaders.mapValue(
          checkpointReview['narrative_supervisor_risk'],
        )['delivery'],
      )['chapter_path'],
    ).trim();
    final outputPaths = _chapterLikePaths(
      deliveredPath.isNotEmpty
          ? <String>[deliveredPath]
          : ValueReaders.stringList(checkpointReview['output_paths']).isEmpty
          ? ValueReaders.stringList(task['output_paths'])
          : ValueReaders.stringList(checkpointReview['output_paths']),
    );
    final sourceOutputPaths = _chapterLikePaths(
      ValueReaders.stringList(checkpointReview['output_paths']).isEmpty
          ? ValueReaders.stringList(task['output_paths'])
          : ValueReaders.stringList(checkpointReview['output_paths']),
    );
    final persistentContextPaths = ValueReaders.stringList(
      ValueReaders.mapValue(task['metadata'])['persistent_context_paths'],
    );
    final checkpointMarkdownPath = ValueReaders.stringValue(
      checkpointReview['markdown_path'],
    );
    return <String, Object?>{
      'needed': true,
      'reason': ValueReaders.stringValue(
        expressionSignal['gate_reason'],
        ValueReaders.stringValue(
          narrativeExpression['gate_reason'],
          'expression_constraint_repair_required',
        ),
      ),
      'summary': ValueReaders.stringValue(
        expressionSignal['summary'],
        ValueReaders.stringValue(
          narrativeExpression['summary'],
          '表达限制要求当前章节先修订再继续。',
        ),
      ),
      'risk_signals':
          ValueReaders.stringList(expressionSignal['risk_signals']).isEmpty
          ? ValueReaders.stringList(narrativeExpression['risk_signals'])
          : ValueReaders.stringList(expressionSignal['risk_signals']),
      'source_paths': _mergePaths(<String>[
        ...sourceOutputPaths,
        ...outputPaths,
        if (checkpointReviewPath.trim().isNotEmpty) checkpointReviewPath,
        if (checkpointMarkdownPath.trim().isNotEmpty) checkpointMarkdownPath,
      ], persistentContextPaths),
      'output_paths': outputPaths,
      'expression_constraint_review': expressionReview,
    };
  }

  JsonMap _repairTask({
    required JsonMap sourceTask,
    required JsonMap checkpointReview,
    required String checkpointReviewPath,
    required List<String> sourcePaths,
    required List<String> outputPaths,
    required JsonMap plan,
  }) {
    final sourceMetadata = ValueReaders.mapValue(sourceTask['metadata']);
    final sourceTaskId = ValueReaders.stringValue(sourceTask['id']);
    final safeId = _safeId(
      '${sourceTaskId}_constraint_repair_${_autoRepairDepth(sourceTask) + 1}',
    );
    final mode = ValueReaders.stringValue(
      sourceTask['mode'],
      ValueReaders.stringValue(sourceMetadata['workflow_mode']),
    );
    final riskSignals = ValueReaders.stringList(plan['risk_signals']);
    final summary = ValueReaders.stringValue(plan['summary']);
    final now = DateTime.now().toIso8601String();
    return <String, Object?>{
      'schema_version': 1,
      'id': safeId,
      'title':
          '修订执行约束：${ValueReaders.stringValue(sourceTask['title'], '当前章节')}',
      'task_type': 'revision',
      'mode': mode,
      'status': TaskRuntimeConstants.statusQueued,
      'chapter': ValueReaders.stringValue(sourceTask['chapter']),
      'goal': _repairGoal(summary: summary, riskSignals: riskSignals),
      'brief': '根据执行约束 gate 修订当前章节，只处理本章表达/字数等执行约束问题，不扩写新章。',
      'depends_on': <Object?>[if (sourceTaskId.trim().isNotEmpty) sourceTaskId],
      'source_paths': sourcePaths,
      'output_paths': outputPaths,
      'metadata': <String, Object?>{
        'origin': 'execution_constraint_gate',
        'repair_kind': 'writing_execution_constraint',
        'auto_repair': true,
        'auto_repair_depth': _autoRepairDepth(sourceTask) + 1,
        'origin_task_id': sourceTaskId,
        'origin_task_path': ValueReaders.stringValue(
          sourceTask['relative_path'],
        ),
        'origin_checkpoint_review_path': checkpointReviewPath,
        'origin_checkpoint_review_id': ValueReaders.stringValue(
          checkpointReview['id'],
        ),
        'workflow_mode': mode,
        'plan_id': ValueReaders.stringValue(sourceMetadata['plan_id']),
        'runtime_baseline_id': ValueReaders.stringValue(
          sourceMetadata['runtime_baseline_id'],
        ),
        'stage': 'revision',
        'sort_order': ValueReaders.intValue(sourceMetadata['sort_order']) + 1,
        'persistent_context_paths': ValueReaders.stringList(
          sourceMetadata['persistent_context_paths'],
        ),
        'repair_reason': ValueReaders.stringValue(plan['reason']),
        'repair_summary': summary,
        'risk_signals': riskSignals,
        'expression_constraint_review': ValueReaders.mapValue(
          plan['expression_constraint_review'],
        ),
      },
      'tool_hint':
          '先读取原章节、checkpoint review 和长期约束；只修订当前章节中命中的执行约束问题。保留人物口吻、时代质感、剧情因果和章节功能。修订后必须覆盖保存原章节路径，并用 submit_chapter_delivery 重新交付同一章节。',
      'created_at': now,
      'updated_at': now,
      'history': <Object?>[
        <String, Object?>{
          'status': TaskRuntimeConstants.statusQueued,
          'note': 'Execution constraint repair task generated.',
          'created_at': now,
        },
      ],
    };
  }

  String _repairGoal({
    required String summary,
    required List<String> riskSignals,
  }) {
    final lines = <String>[
      '修订当前章节，使其通过已启用的执行约束 gate；不得改写成新章节，不得扩大剧情承诺。',
      if (summary.trim().isNotEmpty) 'Gate 摘要：$summary',
      if (riskSignals.isNotEmpty) '命中风险：${riskSignals.take(8).join('；')}',
      '修订时保留原本人物声音、时代感、场景推进和章节完整性；只消解约束命中的表面表达或执行偏差。',
    ];
    return lines.join('\n');
  }

  Future<JsonMap> _findExistingRepairTask(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    if (checkpointReviewPath.trim().isEmpty) {
      return const <String, Object?>{};
    }
    for (final task in await _taskRepository.listTasks(project)) {
      if (ValueReaders.stringValue(task['task_type']) != 'revision') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'execution_constraint_gate') {
        continue;
      }
      if (ValueReaders.stringValue(metadata['origin_checkpoint_review_path']) ==
          checkpointReviewPath) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  Future<List<JsonMap>> _rewireDependents(
    ProjectDescriptor project, {
    required String predecessorTaskId,
    required String repairTaskId,
  }) async {
    if (predecessorTaskId.trim().isEmpty || repairTaskId.trim().isEmpty) {
      return const <JsonMap>[];
    }
    final updated = <JsonMap>[];
    for (final task in await _taskRepository.listTasks(project)) {
      final taskId = ValueReaders.stringValue(task['id']);
      if (taskId == predecessorTaskId || taskId == repairTaskId) {
        continue;
      }
      final dependsOn = ValueReaders.stringList(task['depends_on']);
      if (!dependsOn.contains(predecessorTaskId)) {
        continue;
      }
      final nextDependsOn = <String>[];
      for (final dependency in dependsOn) {
        final next = dependency == predecessorTaskId
            ? repairTaskId
            : dependency;
        if (next.trim().isNotEmpty && !nextDependsOn.contains(next)) {
          nextDependsOn.add(next);
        }
      }
      final saved = await _taskRepository.saveTask(
        project,
        ValueReaders.deepCopyMap(task)..['depends_on'] = nextDependsOn,
      );
      updated.add(saved);
    }
    return List<JsonMap>.unmodifiable(updated);
  }

  int _autoRepairDepth(JsonMap task) {
    return ValueReaders.intValue(
      ValueReaders.mapValue(task['metadata'])['auto_repair_depth'],
    );
  }

  List<String> _chapterLikePaths(List<String> paths) {
    final result = <String>[];
    for (final path in paths) {
      final clean = path.trim().replaceAll('\\', '/');
      if (clean.isEmpty || clean.endsWith('/')) {
        continue;
      }
      if (!clean.toLowerCase().endsWith('.md')) {
        continue;
      }
      if (!clean.startsWith('chapters/') && !clean.startsWith('scenes/')) {
        continue;
      }
      if (!result.contains(clean)) {
        result.add(clean);
      }
    }
    return List<String>.unmodifiable(result);
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      final clean = item.trim().replaceAll('\\', '/');
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return List<String>.unmodifiable(result);
  }

  String _safeId(String value) {
    var result = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_');
    if (result.isEmpty) {
      result = 'execution_constraint_repair';
    }
    if (result.length > 96) {
      result = result.substring(0, 96);
    }
    return result;
  }
}
