import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/runtime_baseline_execution_mode_service.dart';
import 'long_task_chapter_output_policy_service.dart';
import 'long_task_chapter_gate_review_task_factory_service.dart';
import 'long_task_mode_context_path_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskTaskFactoryService {
  LongTaskTaskFactoryService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    LongTaskChapterOutputPolicyService? chapterOutputPolicyService,
    LongTaskModeContextPathService? modeContextPathService,
    RuntimeBaselineExecutionModeService? runtimeBaselineExecutionModeService,
    LongTaskChapterGateReviewTaskFactoryService?
    chapterGateReviewTaskFactoryService,
  }) : _pathPolicyService = pathPolicyService,
       _chapterOutputPolicyService =
           chapterOutputPolicyService ??
           LongTaskChapterOutputPolicyService(modeService: modeService),
       _modeContextPathService =
           modeContextPathService ??
           LongTaskModeContextPathService(
             modeService: modeService,
             pathPolicyService: pathPolicyService,
           ),
       _runtimeBaselineExecutionModeService =
           runtimeBaselineExecutionModeService ??
           RuntimeBaselineExecutionModeService(modeService: modeService),
       _chapterGateReviewTaskFactoryService =
           chapterGateReviewTaskFactoryService ??
           LongTaskChapterGateReviewTaskFactoryService();

  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskChapterOutputPolicyService _chapterOutputPolicyService;
  final LongTaskModeContextPathService _modeContextPathService;
  final RuntimeBaselineExecutionModeService
  _runtimeBaselineExecutionModeService;
  final LongTaskChapterGateReviewTaskFactoryService
  _chapterGateReviewTaskFactoryService;

  List<JsonMap> buildTasks(
    String mode,
    String planId, {
    JsonMap options = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 模式任务工厂把长任务模式翻成基础任务骨架，供 GUI 和 CLI 共用。
    final cleanMode = _runtimeBaselineExecutionModeService.resolveRuntimeMode(
      runtimeBaselineId: _runtimeBaselineIdFromOptions(options),
      runtimeMode: mode,
    );
    if (cleanMode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return _seedToFullTasks(planId, options, createdAt: createdAt);
    }
    if (cleanMode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return _singleChapterAtomicTasks(planId, options, createdAt: createdAt);
    }
    if (cleanMode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return _supervisedChapterQueueTasks(
        planId,
        options,
        createdAt: createdAt,
      );
    }
    return _humanOutlineTasks(planId, options, createdAt: createdAt);
  }

  List<JsonMap> _humanOutlineTasks(
    String planId,
    JsonMap options, {
    required String createdAt,
  }) {
    // 中文注释: 用户已确认大纲时，任务队列直接按大纲拆章并插入周期检查点。
    return _outlineDrivenTasks(
      TaskRuntimeConstants.modeHumanOutlineAiDraft,
      planId,
      options,
      defaultChapters: 6,
      defaultCheckpointInterval: 3,
      chapterGoal: '根据用户确认的大纲生成本章正式正文，并保持前后章节、项目规格、设定和风格一致。',
      chapterToolHint:
          '先读取大纲/章纲、相关摘要、设定和风格，再只写入本章正文；不确定剧情方向时调用 present_user_options。',
      createdAt: createdAt,
    );
  }

  List<JsonMap> _supervisedChapterQueueTasks(
    String planId,
    JsonMap options, {
    required String createdAt,
  }) {
    // 中文注释: 监督式队列默认每章后就停一次检查点，强调稳定和人工确认。
    return _outlineDrivenTasks(
      TaskRuntimeConstants.modeSupervisedChapterQueue,
      planId,
      options,
      defaultChapters: 6,
      defaultCheckpointInterval: 1,
      chapterGoal: '在强监督长任务队列中生成本章草稿；每章完成后等待用户检查，优先稳定、可回滚和少量推进。',
      chapterToolHint: '每次只写当前章节；写入 drafts/ 后停在检查点，等待用户确认继续或创建修复任务。',
      createdAt: createdAt,
    );
  }

  List<JsonMap> _singleChapterAtomicTasks(
    String planId,
    JsonMap options, {
    required String createdAt,
  }) {
    // 中文注释: 单章原子模式只生成一个任务，不自动推演后续章节。
    var title = ValueReaders.stringValue(
      options['chapter_title'],
      ValueReaders.stringValue(options['title'], '单章草稿'),
    ).trim();
    if (title.isEmpty) {
      title = '单章草稿';
    }
    final goal = ValueReaders.stringValue(
      options['goal'],
      ValueReaders.stringValue(options['chapter_goal'], '围绕当前目标生成或修订一个独立章节草稿。'),
    ).trim();
    final brief = ValueReaders.stringValue(
      options['brief'],
      ValueReaders.stringValue(
        options['outline_text'],
        ValueReaders.stringValue(options['seed_prompt']),
      ),
    ).trim();
    var outputPath = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(options['output_path']),
    );
    if (outputPath.isEmpty) {
      outputPath = _chapterOutputPolicyService.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSingleChapterAtomic,
        stage: 'atomic',
        fileStem: _chapterFileName(1, title),
      );
    }
    final sourcePaths = _modeContextPathService.mergeTaskSourcePaths(
      TaskRuntimeConstants.modeSingleChapterAtomic,
      options,
      ValueReaders.objectList(
        options['source_paths'] ??
            const <Object?>[
              'specs/project_spec.md',
              'summaries',
              'styles',
              'knowledge',
            ],
      ),
    );
    return <JsonMap>[
      _chapterTask(<String, Object?>{
        'id': '${planId}_single_chapter_001',
        'title': '单章：$title',
        'chapter': ValueReaders.stringValue(options['chapter'], '单章'),
        'goal': goal,
        'brief': brief,
        'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
        'depends_on': <Object?>[],
        'source_paths': sourcePaths,
        'output_paths': <Object?>[outputPath],
        'plan_id': planId,
        'sort_order': 1,
        'stage': 'atomic',
        'tool_hint': '这是单章原子任务，只完成当前章节目标；不要自动生成后续章节任务。',
      }, createdAt: createdAt),
    ];
  }

  List<JsonMap> _seedToFullTasks(
    String planId,
    JsonMap options, {
    required String createdAt,
  }) {
    // 中文注释: 种子到长篇模式先规划，再样章确认，再进入章节队列和关键检查点。
    final persistentPaths = _modeContextPathService.persistentContextPaths(
      TaskRuntimeConstants.modeSeedToFullNovel,
      options,
    );
    final runtimeBaselineId = _runtimeBaselineIdFromOptions(options);
    final chapterCount = ValueReaders.intValue(
      options['chapter_count'],
      8,
    ).clamp(1, 200);
    final checkpointInterval = ValueReaders.intValue(
      options['checkpoint_interval'],
      3,
    ).clamp(0, 30);
    var seedPrompt = ValueReaders.stringValue(
      options['seed_prompt'],
      ValueReaders.stringValue(options['outline_text']),
    ).trim();
    if (seedPrompt.isEmpty) {
      seedPrompt = '用户尚未填写详细种子，请先围绕项目规格、题材、世界观、主角目标和长篇结构提出可选规划。';
    }
    final tasks = <JsonMap>[];
    var sortOrder = 1;
    final planningId = '${planId}_planning';
    tasks.add(
      _planningTask(
        planId,
        planningId,
        seedPrompt,
        sortOrder,
        createdAt,
        persistentPaths,
        runtimeBaselineId: runtimeBaselineId,
      ),
    );
    sortOrder += 1;
    final outlineCheckpointId = '${planId}_checkpoint_outline';
    tasks.add(
      _checkpointTask(
        TaskRuntimeConstants.modeSeedToFullNovel,
        planId,
        outlineCheckpointId,
        '检查点：确认总纲与章节任务',
        planningId,
        <Object?>['specs/project_spec.md', 'outline/总纲.md', ...persistentPaths],
        <Object?>['outline/总纲.md', 'chapter_outlines/章节任务清单.md'],
        sortOrder,
        createdAt,
        persistentPaths,
        runtimeBaselineId: runtimeBaselineId,
      ),
    );
    sortOrder += 1;
    var previousDependency = outlineCheckpointId;
    for (
      var chapterNumber = 1;
      chapterNumber <= chapterCount;
      chapterNumber += 1
    ) {
      final chapterId =
          '${planId}_chapter_${chapterNumber.toString().padLeft(3, '0')}';
      final stage = chapterNumber == 1 ? 'sample' : 'draft';
      final outputPath = _chapterOutputPolicyService.defaultOutputPath(
        mode: TaskRuntimeConstants.modeSeedToFullNovel,
        stage: stage,
        fileStem: _chapterFileName(chapterNumber, 'seed_to_full'),
      );
      var brief = '根据规划任务生成的作品规格、总纲和章纲写作。初始种子：$seedPrompt';
      if (chapterNumber == 1) {
        brief =
            '这是样章任务。请根据已确认总纲写出第一章，让用户能判断叙事口吻、节奏和世界观入口是否成立。\n\n初始种子：$seedPrompt';
      }
      tasks.add(
        _chapterTask(<String, Object?>{
          'id': chapterId,
          'title':
              '${chapterNumber == 1 ? '样章：' : ''}第${chapterNumber.toString().padLeft(2, '0')}章',
          'chapter': '第${chapterNumber.toString().padLeft(2, '0')}章',
          'goal': '按已确认规格、总纲和章纲生成本章正式正文。',
          'brief': brief,
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'depends_on': <Object?>[previousDependency],
          'source_paths': <Object?>[
            'specs/project_spec.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
            ...persistentPaths,
          ],
          'output_paths': <Object?>[outputPath],
          'plan_id': planId,
          'sort_order': sortOrder,
          'stage': stage,
          'runtime_baseline_id': runtimeBaselineId,
          'tool_hint':
              '先读取项目规格、总纲、章纲、摘要和必要设定；如果规划尚未充分，请先调用 present_user_options 或写入大纲，而不是硬写正文。',
          'persistent_context_paths': persistentPaths,
          'chapter_word_constraints': _chapterWordConstraints(
            options,
            stage: stage,
          ),
        }, createdAt: createdAt),
      );
      previousDependency = chapterId;
      sortOrder += 1;
      final shouldCheckpoint =
          chapterNumber == 1 ||
          (checkpointInterval > 0 &&
              chapterNumber % checkpointInterval == 0 &&
              chapterNumber < chapterCount);
      if (shouldCheckpoint) {
        final checkpointId =
            '${planId}_checkpoint_${chapterNumber.toString().padLeft(3, '0')}';
        final checkpointTitle = chapterNumber == 1
            ? '检查点：确认样章'
            : '检查点：第 $chapterNumber 章后确认';
        tasks.add(
          _checkpointTask(
            TaskRuntimeConstants.modeSeedToFullNovel,
            planId,
            checkpointId,
            checkpointTitle,
            previousDependency,
            <Object?>['summaries', outputPath, ...persistentPaths],
            <Object?>[outputPath],
            sortOrder,
            createdAt,
            persistentPaths,
            runtimeBaselineId: runtimeBaselineId,
          ),
        );
        previousDependency = checkpointId;
        sortOrder += 1;
      }
    }
    return tasks;
  }

  List<JsonMap> _outlineDrivenTasks(
    String mode,
    String planId,
    JsonMap options, {
    required int defaultChapters,
    required int defaultCheckpointInterval,
    required String chapterGoal,
    required String chapterToolHint,
    required String createdAt,
  }) {
    // 中文注释: 按大纲拆章的模式共用这套生成逻辑，只在目标、检查点频率和工具提示上有差异。
    final chapterCount = ValueReaders.intValue(
      options['chapter_count'],
      defaultChapters,
    ).clamp(1, 120);
    final runtimeBaselineId = _runtimeBaselineIdFromOptions(options);
    final gateAutorun = runtimeBaselineId == 'chapter_collaboration_autorun';
    final checkpointInterval = ValueReaders.intValue(
      options['checkpoint_interval'],
      gateAutorun ? 0 : defaultCheckpointInterval,
    ).clamp(0, 30);
    final outlinePath = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(options['outline_path']),
    );
    final outlineText = ValueReaders.stringValue(
      options['outline_text'],
    ).trim();
    final items = _outlineItems(outlineText, chapterCount);
    final sourcePaths = <String>[];
    if (outlinePath.isNotEmpty) {
      sourcePaths.add(outlinePath);
    }
    final modeSourcePaths = _modeContextPathService.mergeTaskSourcePaths(
      mode,
      options,
      sourcePaths,
    );
    final persistentPaths = _modeContextPathService.persistentContextPaths(
      mode,
      options,
    );
    final tasks = <JsonMap>[];
    var previousDependency = '';
    var sortOrder = 1;
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final chapterNumber = index + 1;
      final chapterId =
          '${planId}_chapter_${chapterNumber.toString().padLeft(3, '0')}';
      final outputPath = _chapterOutputPolicyService.defaultOutputPath(
        mode: mode,
        stage: 'draft',
        fileStem: _chapterFileName(
          chapterNumber,
          ValueReaders.stringValue(item['title']),
        ),
      );
      final depends = <Object?>[];
      if (previousDependency.isNotEmpty) {
        depends.add(previousDependency);
      }
      tasks.add(
        _chapterTask(<String, Object?>{
          'id': chapterId,
          'title':
              '第${chapterNumber.toString().padLeft(2, '0')}章：${ValueReaders.stringValue(item['title'], '未命名章节')}',
          'chapter': '第${chapterNumber.toString().padLeft(2, '0')}章',
          'goal': chapterGoal,
          'brief': ValueReaders.stringValue(item['brief']),
          'mode': mode,
          'depends_on': depends,
          'source_paths': modeSourcePaths,
          'output_paths': <Object?>[outputPath],
          'plan_id': planId,
          'sort_order': sortOrder,
          'stage': 'draft',
          'runtime_baseline_id': runtimeBaselineId,
          'tool_hint': chapterToolHint,
          'persistent_context_paths': persistentPaths,
          'chapter_word_constraints': _chapterWordConstraints(
            options,
            stage: 'draft',
          ),
        }, createdAt: createdAt),
      );
      previousDependency = chapterId;
      sortOrder += 1;
      final gateReviewTasks = _chapterGateReviewTaskFactoryService
          .buildReviewTasksForChapter(
            tasks.last,
            options: options,
            startingSortOrder: sortOrder,
            createdAt: createdAt,
          );
      if (gateReviewTasks.isNotEmpty) {
        tasks.addAll(gateReviewTasks);
        previousDependency = ValueReaders.stringValue(
          gateReviewTasks.last['id'],
          previousDependency,
        );
        sortOrder += gateReviewTasks.length;
      }
      if (checkpointInterval > 0 &&
          chapterNumber % checkpointInterval == 0 &&
          chapterNumber < items.length) {
        final checkpointId =
            '${planId}_checkpoint_${chapterNumber.toString().padLeft(3, '0')}';
        tasks.add(
          _checkpointTask(
            mode,
            planId,
            checkpointId,
            '检查点：第 $chapterNumber 章后确认',
            previousDependency,
            modeSourcePaths,
            <Object?>[outputPath],
            sortOrder,
            createdAt,
            persistentPaths,
            runtimeBaselineId: runtimeBaselineId,
          ),
        );
        previousDependency = checkpointId;
        sortOrder += 1;
      }
    }
    return tasks;
  }

  JsonMap _planningTask(
    String planId,
    String taskId,
    String seedPrompt,
    int sortOrder,
    String createdAt,
    List<String> persistentPaths, {
    String runtimeBaselineId = '',
  }) {
    // 中文注释: 规划任务是 seed_to_full 模式的入口，不写正文，只产出规格和任务清单。
    return _baseTask(<String, Object?>{
      'id': taskId,
      'title': '规划：扩展作品规格与总纲',
      'task_type': 'planning',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusQueued,
      'goal': '根据用户种子扩展项目规格、创作宪法、总纲、卷纲/章纲，并在必要时创建或修订后续章节任务。',
      'brief': seedPrompt,
      'depends_on': <Object?>[],
      'source_paths': _modeContextPathService.mergeTaskSourcePaths(
        TaskRuntimeConstants.modeSeedToFullNovel,
        <String, Object?>{'persistent_context_paths': persistentPaths},
        <Object?>[
          'specs/project_spec.md',
          'styles',
          'knowledge',
          'inspiration',
        ],
      ),
      'output_paths': <Object?>[
        'specs/project_spec.md',
        'outline/总纲.md',
        'chapter_outlines/章节任务清单.md',
      ],
      'metadata': <String, Object?>{
        'plan_id': planId,
        'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'sort_order': sortOrder,
        'stage': 'planning',
        'seed_prompt': seedPrompt,
        'generated_by': 'LongTaskPlanner',
        'persistent_context_paths': persistentPaths,
        if (runtimeBaselineId.trim().isNotEmpty)
          'runtime_baseline_id': runtimeBaselineId.trim(),
      },
      'tool_hint':
          '不要写正文。优先保存 specs/project_spec.md、outline/总纲.md、chapter_outlines/章节任务清单.md；需要用户确认时调用 present_user_options。',
    }, createdAt);
  }

  JsonMap _chapterTask(JsonMap data, {required String createdAt}) {
    // 中文注释: 章节任务统一在这里补齐元数据和状态历史，保持各模式产物结构一致。
    return _baseTask(<String, Object?>{
      'id': ValueReaders.stringValue(data['id']),
      'title': ValueReaders.stringValue(data['title'], '章节任务'),
      'task_type': 'chapter',
      'mode': ValueReaders.stringValue(
        data['mode'],
        TaskRuntimeConstants.modeSingleChapterAtomic,
      ),
      'status': TaskRuntimeConstants.statusQueued,
      'chapter': ValueReaders.stringValue(data['chapter']),
      'goal': ValueReaders.stringValue(data['goal']),
      'brief': ValueReaders.stringValue(data['brief']),
      'depends_on': _pathPolicyService.stringList(data['depends_on']),
      'source_paths': _pathPolicyService.stringList(data['source_paths']),
      'output_paths': _pathPolicyService.stringList(data['output_paths']),
      'metadata': <String, Object?>{
        'plan_id': ValueReaders.stringValue(data['plan_id']),
        'workflow_mode': ValueReaders.stringValue(data['mode']),
        'sort_order': ValueReaders.intValue(data['sort_order']),
        'stage': ValueReaders.stringValue(data['stage'], 'draft'),
        'generated_by': 'LongTaskPlanner',
        if (ValueReaders.stringValue(
          data['runtime_baseline_id'],
        ).trim().isNotEmpty)
          'runtime_baseline_id': ValueReaders.stringValue(
            data['runtime_baseline_id'],
          ).trim(),
        'persistent_context_paths': _pathPolicyService.stringList(
          data['persistent_context_paths'],
        ),
        ..._chapterWordConstraintMetadata(
          ValueReaders.mapValue(data['chapter_word_constraints']),
        ),
      },
      'tool_hint': ValueReaders.stringValue(data['tool_hint']),
    }, createdAt);
  }

  JsonMap _checkpointTask(
    String mode,
    String planId,
    String taskId,
    String title,
    String dependencyId,
    List<Object?> sourcePaths,
    List<Object?> outputPaths,
    int sortOrder,
    String createdAt,
    List<String> persistentPaths, {
    String runtimeBaselineId = '',
  }) {
    // 中文注释: 检查点任务本身不自动跑模型，只提供用户确认、调整和继续的安全停顿点。
    final dependsOn = <Object?>[];
    if (dependencyId.trim().isNotEmpty) {
      dependsOn.add(dependencyId);
    }
    return _baseTask(<String, Object?>{
      'id': taskId,
      'title': title,
      'task_type': 'checkpoint',
      'mode': mode,
      'status': TaskRuntimeConstants.statusWaitingUser,
      'goal': '等待用户检查前序输出、调整方向或确认继续。确认后把该任务标记完成，后续依赖任务才会继续执行。',
      'brief': '这是长任务流安全检查点，不会自动调用模型。用户可以修改文件、补充要求、创建修复任务，确认后继续。',
      'depends_on': dependsOn,
      'source_paths': _pathPolicyService.stringList(sourcePaths),
      'output_paths': _pathPolicyService.stringList(outputPaths),
      'metadata': <String, Object?>{
        'plan_id': planId,
        'workflow_mode': mode,
        'sort_order': sortOrder,
        'stage': 'checkpoint',
        'generated_by': 'LongTaskPlanner',
        'manual_checkpoint': true,
        'persistent_context_paths': persistentPaths,
        if (runtimeBaselineId.trim().isNotEmpty)
          'runtime_baseline_id': runtimeBaselineId.trim(),
      },
      'tool_hint': '检查点任务只等待用户确认；通常不需要执行模型。',
    }, createdAt);
  }

  JsonMap _baseTask(JsonMap data, String createdAt) {
    // 中文注释: 所有工厂生成的任务都从同一基础结构出发，保证状态历史和时间戳字段齐全。
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return <String, Object?>{
      ...data,
      'schema_version': 1,
      'created_at': now,
      'updated_at': now,
      'chapter': data.containsKey('chapter')
          ? ValueReaders.stringValue(data['chapter'])
          : '',
      'metadata': ValueReaders.mapValue(data['metadata']),
      'history': <Object?>[
        <String, Object?>{
          'status': ValueReaders.stringValue(
            data['status'],
            TaskRuntimeConstants.statusQueued,
          ),
          'note': 'Long task workflow generated.',
          'created_at': now,
        },
      ],
    };
  }

  List<JsonMap> _outlineItems(String outlineText, int chapterCount) {
    // 中文注释: 大纲拆章在 core 中保持轻量文本启发式，足够支撑旧项目的任务生成逻辑。
    final items = <JsonMap>[];
    JsonMap current = <String, Object?>{};
    for (final rawLine in outlineText.split('\n')) {
      final line = _cleanOutlineLine(rawLine);
      if (line.isEmpty) {
        continue;
      }
      final startsNew = current.isEmpty || _looksLikeOutlineHeading(line);
      if (startsNew) {
        if (current.isNotEmpty) {
          items.add(current);
        }
        current = <String, Object?>{'title': _shortTitle(line), 'brief': line};
      } else {
        current['brief'] =
            '${ValueReaders.stringValue(current['brief'])}\n$line';
      }
    }
    if (current.isNotEmpty) {
      items.add(current);
    }
    if (items.isEmpty) {
      for (var index = 0; index < chapterCount; index += 1) {
        items.add(<String, Object?>{
          'title': '未命名章节',
          'brief': '请根据已确认大纲生成第 ${index + 1} 章。',
        });
      }
    }
    while (items.length > chapterCount) {
      items.removeLast();
    }
    while (items.length < chapterCount) {
      items.add(<String, Object?>{
        'title': '续写章节 ${items.length + 1}',
        'brief': '请承接前文和已有大纲继续推进故事。',
      });
    }
    return items;
  }

  String _cleanOutlineLine(String value) {
    // 中文注释: 这里把常见 Markdown/列表符号和序号前缀去掉，便于从大纲文本里提纯章节标题。
    var text = value.trim();
    while (<String>['#', '-', '*', '>'].any(text.startsWith)) {
      text = text.substring(1).trim();
    }
    for (final separator in const <String>['.', '、', ')']) {
      final index = text.indexOf(separator);
      if (index > 0 &&
          index <= 3 &&
          int.tryParse(text.substring(0, index)) != null) {
        return text.substring(index + separator.length).trim();
      }
    }
    return text;
  }

  bool _looksLikeOutlineHeading(String text) {
    // 中文注释: 这是旧项目同等强度的启发式判断，不追求复杂解析器。
    final clean = text.trim();
    if (clean.startsWith('第') &&
        (clean.contains('章') || clean.contains('节') || clean.contains('回'))) {
      return true;
    }
    if (clean.toLowerCase().startsWith('chapter ')) {
      return true;
    }
    for (final separator in const <String>['.', '、', ')']) {
      final index = clean.indexOf(separator);
      if (index > 0 &&
          index <= 3 &&
          int.tryParse(clean.substring(0, index)) != null) {
        return true;
      }
    }
    return false;
  }

  String _shortTitle(String value) {
    // 中文注释: 章节短标题主要用于文件名和任务名，不保留过长说明文本。
    var text = value.trim().replaceAll('：', ':');
    if (text.contains(':')) {
      text = text.split(':').skip(1).join(':').trim();
    }
    if (text.length > 28) {
      text = text.substring(0, 28);
    }
    return text.isEmpty ? '未命名章节' : text;
  }

  String _chapterFileName(int chapterNumber, String title) {
    // 中文注释: 文件名保持“第xx章_标题”风格，便于用户在 drafts/ 中快速人工浏览。
    final prefix = '第${chapterNumber.toString().padLeft(2, '0')}章';
    final safeTitle = _pathPolicyService.safeId(title);
    if (safeTitle.isEmpty || safeTitle == 'seed_to_full') {
      return prefix;
    }
    return '${prefix}_$safeTitle';
  }

  JsonMap _chapterWordConstraints(JsonMap options, {required String stage}) {
    // 中文注释: 字数限制先作为共享任务参数进入计划与提示，不把模式差异散落到 UI 或模型文案里。
    final enabled = options.containsKey('enable_chapter_word_constraints')
        ? ValueReaders.boolValue(options['enable_chapter_word_constraints'])
        : _hasAnyChapterWordConstraint(options);
    if (!enabled) {
      return const <String, Object?>{};
    }
    final cleanStage = stage.trim().toLowerCase();
    final useSampleOverride = cleanStage == 'sample';
    final target = ValueReaders.intValue(
      useSampleOverride
          ? options['sample_chapter_word_target']
          : options['chapter_word_target'],
      ValueReaders.intValue(options['chapter_word_target']),
    );
    final min = ValueReaders.intValue(
      useSampleOverride
          ? options['sample_chapter_word_min']
          : options['chapter_word_min'],
      ValueReaders.intValue(options['chapter_word_min']),
    );
    final max = ValueReaders.intValue(
      useSampleOverride
          ? options['sample_chapter_word_max']
          : options['chapter_word_max'],
      ValueReaders.intValue(options['chapter_word_max']),
    );
    return _chapterWordConstraintMetadata(<String, Object?>{
      if (target > 0) 'chapter_word_target': target,
      if (min > 0) 'chapter_word_min': min,
      if (max > 0) 'chapter_word_max': max,
    });
  }

  bool _hasAnyChapterWordConstraint(JsonMap options) {
    // 中文注释: 兼容旧数据：如果历史记录里直接带了字数值但还没有开关字段，就按“已开启”处理。
    return ValueReaders.intValue(options['chapter_word_target']) > 0 ||
        ValueReaders.intValue(options['chapter_word_min']) > 0 ||
        ValueReaders.intValue(options['chapter_word_max']) > 0 ||
        ValueReaders.intValue(options['sample_chapter_word_target']) > 0 ||
        ValueReaders.intValue(options['sample_chapter_word_min']) > 0 ||
        ValueReaders.intValue(options['sample_chapter_word_max']) > 0;
  }

  JsonMap _chapterWordConstraintMetadata(JsonMap data) {
    // 中文注释: 元数据里只保留有效数字，避免把 0 值噪音带进任务文件和上下文。
    final result = <String, Object?>{};
    final target = ValueReaders.intValue(data['chapter_word_target']);
    final min = ValueReaders.intValue(data['chapter_word_min']);
    final max = ValueReaders.intValue(data['chapter_word_max']);
    if (target > 0) {
      result['chapter_word_target'] = target;
    }
    if (min > 0) {
      result['chapter_word_min'] = min;
    }
    if (max > 0) {
      result['chapter_word_max'] = max;
    }
    return result;
  }

  String _runtimeBaselineIdFromOptions(JsonMap options) {
    return ValueReaders.stringValue(options['runtime_baseline_id']).trim();
  }
}
