import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_context_path_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskDynamicTaskFactoryService {
  LongTaskDynamicTaskFactoryService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    LongTaskModeContextPathService? modeContextPathService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService,
       _modeContextPathService =
           modeContextPathService ??
           LongTaskModeContextPathService(
             modeService: modeService,
             pathPolicyService: pathPolicyService,
           );

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskModeContextPathService _modeContextPathService;

  JsonMap buildCheckpointTask(
    JsonMap record,
    List<Object?> tasks,
    JsonMap arguments, {
    String createdAt = '',
  }) {
    // 中文注释: 动态检查点只用于在运行中插入人工确认节点，不重用整套初始计划工厂。
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    final planId = ValueReaders.stringValue(
      record['plan_id'],
      ValueReaders.stringValue(arguments['plan_id'], 'long_task'),
    );
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        record['mode'],
        ValueReaders.stringValue(arguments['mode']),
      ),
    );
    final afterTaskId = ValueReaders.stringValue(
      arguments['after_task_id'],
      ValueReaders.stringValue(record['last_task_id']),
    ).trim();
    final afterTask = _taskAt(tasks, _indexById(tasks, afterTaskId));
    final checkpointId = _pathPolicyService.safeId(
      ValueReaders.stringValue(
        arguments['id'],
        '${planId}_checkpoint_manual_${_maxSortOrder(tasks) + 1}',
      ),
      fallbackPrefix: 'checkpoint',
    );
    final dependsOn = <Object?>[];
    if (afterTaskId.isNotEmpty) {
      dependsOn.add(afterTaskId);
    }
    final inheritedPersistentPaths = _persistentContextPaths(
      arguments,
      afterTask,
    );
    return <String, Object?>{
      'schema_version': 1,
      'id': checkpointId,
      'title': ValueReaders.stringValue(arguments['title'], '检查点：人工确认'),
      'task_type': 'checkpoint',
      'mode': mode,
      'status': TaskRuntimeConstants.statusWaitingUser,
      'chapter': '',
      'goal': ValueReaders.stringValue(
        arguments['goal'],
        '等待用户检查当前产物、调整方向或确认继续。',
      ),
      'brief': ValueReaders.stringValue(arguments['brief'], '这是动态插入的长任务检查点。'),
      'depends_on': dependsOn,
      'source_paths': _modeContextPathService.mergeTaskSourcePaths(
        mode,
        <String, Object?>{'persistent_context_paths': inheritedPersistentPaths},
        ValueReaders.objectList(
          arguments['source_paths'] ?? afterTask['output_paths'],
        ),
      ),
      'output_paths': _pathPolicyService.stringList(
        arguments['output_paths'] ?? afterTask['output_paths'],
      ),
      'metadata': <String, Object?>{
        'plan_id': planId,
        'workflow_mode': mode,
        'sort_order': _maxSortOrder(tasks) + 1,
        'stage': 'checkpoint',
        'manual_checkpoint': true,
        'generated_by': 'LongTaskRevision',
        'persistent_context_paths': inheritedPersistentPaths,
      },
      'tool_hint': '检查点任务只等待用户确认；通常不需要执行模型。',
      'created_at': now,
      'updated_at': now,
      'history': <Object?>[
        <String, Object?>{
          'status': TaskRuntimeConstants.statusWaitingUser,
          'note': 'Long task revision inserted checkpoint.',
          'created_at': now,
        },
      ],
    };
  }

  JsonMap buildChapterTask(
    JsonMap record,
    List<Object?> tasks,
    JsonMap arguments, {
    String createdAt = '',
  }) {
    // 中文注释: 追加章节任务用于运行中延展队列，不去修改已有初始任务顺序。
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    final planId = ValueReaders.stringValue(
      record['plan_id'],
      ValueReaders.stringValue(arguments['plan_id'], 'long_task'),
    );
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        record['mode'],
        ValueReaders.stringValue(arguments['mode']),
      ),
    );
    final chapterNumber = ValueReaders.intValue(
      arguments['chapter_number'],
      _chapterNumberHint(tasks),
    );
    final title = ValueReaders.stringValue(
      arguments['title'],
      '续写章节 $chapterNumber',
    ).trim();
    final afterTaskId = ValueReaders.stringValue(
      arguments['after_task_id'],
      ValueReaders.stringValue(record['last_task_id']),
    ).trim();
    final dependsOn = <Object?>[];
    if (afterTaskId.isNotEmpty) {
      dependsOn.add(afterTaskId);
    }
    var outputPath = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(arguments['output_path']),
    );
    if (outputPath.isEmpty) {
      outputPath =
          'drafts/第${chapterNumber.toString().padLeft(2, '0')}章_${_safeFilePart(title, 'chapter')}.md';
    }
    final inheritedPersistentPaths = _persistentContextPaths(
      arguments,
      _taskAt(tasks, _indexById(tasks, afterTaskId)),
    );
    return <String, Object?>{
      'schema_version': 1,
      'id': _pathPolicyService.safeId(
        ValueReaders.stringValue(
          arguments['id'],
          '${planId}_chapter_${chapterNumber.toString().padLeft(3, '0')}',
        ),
        fallbackPrefix: 'chapter',
      ),
      'title': ValueReaders.stringValue(
        arguments['task_title'],
        '第${chapterNumber.toString().padLeft(2, '0')}章：$title',
      ),
      'task_type': 'chapter',
      'mode': mode,
      'status': TaskRuntimeConstants.statusQueued,
      'chapter': ValueReaders.stringValue(
        arguments['chapter'],
        '第${chapterNumber.toString().padLeft(2, '0')}章',
      ),
      'goal': ValueReaders.stringValue(
        arguments['goal'],
        '根据已确认规划、前文摘要和当前方向续写本章。',
      ),
      'brief': ValueReaders.stringValue(arguments['brief']),
      'depends_on': dependsOn,
      'source_paths': _modeContextPathService.mergeTaskSourcePaths(
        mode,
        <String, Object?>{'persistent_context_paths': inheritedPersistentPaths},
        ValueReaders.objectList(
          arguments['source_paths'] ??
              const <Object?>[
                'specs/project_spec.md',
                'outline/总纲.md',
                'summaries',
              ],
        ),
      ),
      'output_paths': <Object?>[outputPath],
      'metadata': <String, Object?>{
        'plan_id': planId,
        'workflow_mode': mode,
        'sort_order': _maxSortOrder(tasks) + 1,
        'stage': ValueReaders.stringValue(arguments['stage'], 'draft'),
        'generated_by': 'LongTaskRevision',
        'persistent_context_paths': inheritedPersistentPaths,
      },
      'tool_hint': ValueReaders.stringValue(
        arguments['tool_hint'],
        '先读取规划、前文摘要、设定和风格，再只写入本章正文。',
      ),
      'created_at': now,
      'updated_at': now,
      'history': <Object?>[
        <String, Object?>{
          'status': TaskRuntimeConstants.statusQueued,
          'note': 'Long task revision appended chapter.',
          'created_at': now,
        },
      ],
    };
  }

  JsonMap _taskAt(List<Object?> tasks, int index) {
    // 中文注释: revision 场景只需要按索引读取已存在任务，失败时回空字典即可。
    if (index < 0 || index >= tasks.length) {
      return <String, Object?>{};
    }
    return ValueReaders.mapValue(tasks[index]);
  }

  int _indexById(List<Object?> tasks, String taskId) {
    // 中文注释: 这里维持线性扫描即可，当前任务规模远小于需要额外索引结构的程度。
    for (var index = 0; index < tasks.length; index += 1) {
      final task = ValueReaders.mapValue(tasks[index]);
      if (task.isNotEmpty && ValueReaders.stringValue(task['id']) == taskId) {
        return index;
      }
    }
    return -1;
  }

  int _maxSortOrder(List<Object?> tasks) {
    // 中文注释: 动态插入任务总是接在当前最大 sort_order 之后，避免破坏已有顺序。
    var result = 0;
    for (var index = 0; index < tasks.length; index += 1) {
      final task = ValueReaders.mapValue(tasks[index]);
      final metadata = ValueReaders.mapValue(task['metadata']);
      final sortOrder = ValueReaders.intValue(
        metadata['sort_order'],
        index + 1,
      );
      if (sortOrder > result) {
        result = sortOrder;
      }
    }
    return result;
  }

  int _chapterNumberHint(List<Object?> tasks) {
    // 中文注释: 没有显式章节号时，用现有 chapter 数量推一个可读的默认序号。
    var count = 0;
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['task_type']) == 'chapter') {
        count += 1;
      }
    }
    return count + 1;
  }

  String _safeFilePart(String value, String fallback) {
    // 中文注释: 文件名片段沿用核心路径策略，避免动态章节生成出脏路径。
    final result = _pathPolicyService.safeId(value, fallbackPrefix: fallback);
    return result.isEmpty ? fallback : result;
  }

  List<String> _persistentContextPaths(JsonMap arguments, JsonMap afterTask) {
    // 中文注释: 动态任务默认继承前序任务的长期约束路径；调用方显式传入时，以显式值为准。
    final explicit = _pathPolicyService.stringList(
      arguments['persistent_context_paths'],
    );
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final metadata = ValueReaders.mapValue(afterTask['metadata']);
    return _pathPolicyService.stringList(metadata['persistent_context_paths']);
  }
}
