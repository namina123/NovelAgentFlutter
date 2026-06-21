import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_narrative_artifact_path_policy_service.dart';
import 'task_runtime_constants.dart';

class TaskDefinitionService {
  static const Set<String> _knownTaskTypes = <String>{
    'chapter',
    'summary',
    'revision',
    'review',
    'planning',
    'checkpoint',
    'world_update',
    'agent_task',
  };

  List<JsonMap> modeDefinitions() {
    // 中文注释: 长任务模式定义集中在这里，确保 UI、CLI 和规划逻辑共用同一组枚举说明。
    return const <JsonMap>[
      <String, Object?>{
        'id': TaskRuntimeConstants.modeSingleChapterAtomic,
        'name': '单章原子任务',
        'description': '只执行一个章节或场景任务，是所有长任务流的底座。',
      },
      <String, Object?>{
        'id': TaskRuntimeConstants.modeSupervisedChapterQueue,
        'name': '监督式章节队列',
        'description': '用户周期性确认，AI 按章节队列连续推进。',
      },
      <String, Object?>{
        'id': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'name': '人定大纲 AI 写作',
        'description': '用户确认大纲后，AI 按章纲持续生成正文。',
      },
      <String, Object?>{
        'id': TaskRuntimeConstants.modeSeedToFullNovel,
        'name': '种子到长篇',
        'description': '用户只给少量种子，AI 规划、拆章、写作并在关键节点等待确认。',
      },
    ];
  }

  JsonMap normalizeTask(JsonMap task) {
    // 中文注释: 任务规范化负责补齐核心调度字段，避免旧任务或模型输出脏数据干扰状态机。
    final normalized = ValueReaders.deepCopyMap(task);
    normalized['id'] = ValueReaders.stringValue(
      normalized['id'],
      'task_${DateTime.now().microsecondsSinceEpoch}',
    );
    normalized['title'] = ValueReaders.stringValue(
      normalized['title'],
      '未命名任务',
    );
    final normalizedTaskType = _normalizeTaskType(normalized);
    normalized['task_type'] = normalizedTaskType;
    normalized['mode'] = normalizeMode(
      ValueReaders.stringValue(
        normalized['mode'],
        TaskRuntimeConstants.modeSingleChapterAtomic,
      ),
    );
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalized['metadata']),
    );
    if (normalizedTaskType == 'summary') {
      metadata['stage'] = 'summary';
    }
    normalized['metadata'] = metadata;
    var status = ValueReaders.stringValue(
      normalized['status'],
      TaskRuntimeConstants.statusQueued,
    );
    if (!TaskRuntimeConstants.validStatuses.contains(status)) {
      status = TaskRuntimeConstants.statusQueued;
    }
    normalized['status'] = status;
    if (normalized['depends_on'] is! List) {
      normalized['depends_on'] = <Object?>[];
    }
    if (normalized['output_paths'] is! List) {
      normalized['output_paths'] = <Object?>[];
    }
    if (normalized['history'] is! List) {
      normalized['history'] = <Object?>[];
    }
    return normalized;
  }

  String _normalizeTaskType(JsonMap task) {
    final explicit = ValueReaders.stringValue(task['task_type']).trim();
    if (_shouldTreatAsSummaryTask(task)) {
      return 'summary';
    }
    if (_knownTaskTypes.contains(explicit)) {
      return explicit;
    }
    return explicit.isEmpty ? 'chapter' : explicit;
  }

  bool _shouldTreatAsSummaryTask(JsonMap task) {
    final outputPaths = ValueReaders.stringList(task['output_paths']);
    final sourcePaths = ValueReaders.stringList(task['source_paths']);
    final relativePath = ValueReaders.stringValue(
      task['relative_path'],
    ).trim().toLowerCase();
    final searchText = <String>[
      ValueReaders.stringValue(task['id']),
      ValueReaders.stringValue(task['title']),
      ValueReaders.stringValue(task['goal']),
      ValueReaders.stringValue(task['description']),
      ValueReaders.stringValue(task['brief']),
      ValueReaders.stringValue(task['tool_hint']),
    ].join(' ').toLowerCase();
    final touchesSummaryPath =
        outputPaths.any(_isSummaryPath) || sourcePaths.any(_isSummaryPath);
    final touchesChapterOutputPath = outputPaths.any(_isChapterLikePath);
    final hasSummaryKeyword =
        searchText.contains('save_summary') ||
        searchText.contains('summarize') ||
        searchText.contains('summary') ||
        searchText.contains('摘要') ||
        searchText.contains('总结');
    final summaryRelativePath = relativePath.contains('summary');
    if (touchesSummaryPath && !touchesChapterOutputPath) {
      return true;
    }
    // 中文注释: 关键字或 summary 相对路径命中、且不触碰章节正文时，也按摘要任务识别；
    // 此前这里重复要求 touchesSummaryPath（已被上面 early-return 覆盖），导致关键字启发式永远失效。
    return (summaryRelativePath || hasSummaryKeyword) &&
        !touchesChapterOutputPath;
  }

  bool _isSummaryPath(String path) {
    final clean = path.trim().toLowerCase();
    return clean.startsWith('summaries/');
  }

  bool _isChapterLikePath(String path) {
    return const ProjectNarrativeArtifactPathPolicyService().isChapterLikePath(
      path,
    );
  }

  JsonMap taskSummary(JsonMap task) {
    // 中文注释: 任务摘要只暴露调度和列表展示需要的轻量字段，避免上层到处拆完整 JSON。
    if (task.isEmpty) {
      return <String, Object?>{};
    }
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'mode': ValueReaders.stringValue(task['mode']),
      'status': ValueReaders.stringValue(task['status']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'depends_on': stringList(task['depends_on']),
      'output_paths': stringList(task['output_paths']),
    };
  }

  String normalizeMode(String mode) {
    // 中文注释: 未知模式一律回退到单章原子任务，保证调度器永远有可执行基线。
    for (final item in modeDefinitions()) {
      if (ValueReaders.stringValue(item['id']) == mode) {
        return mode;
      }
    }
    return TaskRuntimeConstants.modeSingleChapterAtomic;
  }

  List<String> stringList(Object? rawValue) {
    // 中文注释: 数组字段统一收敛成字符串列表，供调度、摘要和渲染复用。
    return ValueReaders.stringList(rawValue);
  }
}
