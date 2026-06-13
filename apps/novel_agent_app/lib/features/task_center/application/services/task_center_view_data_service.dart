import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/runtime_label_service.dart';
import 'task_center_contract_action_view_data_service.dart';
import 'task_center_chapter_length_defaults_service.dart';
import '../../presentation/models/task_center_action_group_view_data.dart';
import '../../presentation/models/task_center_contract_action_view_data.dart';
import '../../presentation/models/task_center_view_data.dart';

class TaskCenterViewDataService {
  const TaskCenterViewDataService({
    TaskCenterContractActionViewDataService? contractActionViewDataService,
    TaskCenterChapterLengthDefaultsService? chapterLengthDefaultsService,
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RuntimeLabelService? runtimeLabelService,
  }) : _contractActionViewDataService =
           contractActionViewDataService ??
           const TaskCenterContractActionViewDataService(),
       _chapterLengthDefaultsService =
           chapterLengthDefaultsService ??
           const TaskCenterChapterLengthDefaultsService(),
       _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService();

  final TaskCenterContractActionViewDataService _contractActionViewDataService;
  final TaskCenterChapterLengthDefaultsService _chapterLengthDefaultsService;
  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RuntimeLabelService _runtimeLabelService;

  TaskCenterViewData build({
    required List<JsonMap> tasks,
    required List<JsonMap> modeDefinitions,
    required String selectedTaskId,
    required String detailBody,
    required String queueSummary,
    required String schedulerSummary,
    required String chainMarkdown,
    required List<JsonMap> longTaskRuns,
    required List<JsonMap> taskQueueRuns,
    required String selectedLongTaskRunPath,
    required String selectedTaskQueueRunPath,
    required String longTaskRunLog,
    required String taskQueueRunLog,
    String resumeBriefBody = '',
    ProjectRuntimeProfile? runtimeProfile,
    ProjectStorageStrategy? projectStorageStrategy,
    JsonMap checkpointActionPackage = const <String, Object?>{},
    JsonMap revisionResolution = const <String, Object?>{},
    String guidanceRevisitBody = '',
    String nextTaskPath = '',
    String nextPostprocessPath = '',
    String status = '',
    List<TaskCenterActionGroupViewData> supplementalActionGroups =
        const <TaskCenterActionGroupViewData>[],
  }) {
    // 中文注释: 任务中心展示映射集中在这里，避免控制器继续堆积状态文案和枚举翻译。
    final selectedLongTaskRun = _runByPath(
      longTaskRuns,
      selectedLongTaskRunPath,
    );
    final resolvedSelectedTaskId = resolveSelectedTaskId(
      tasks: tasks,
      selectedTaskId: selectedTaskId,
      selectedLongTaskRun: selectedLongTaskRun,
    );
    final entries = tasks
        .map(
          (task) => TaskCenterTaskItemViewData(
            id: ValueReaders.stringValue(task['relative_path']),
            title: _taskItemTitle(
              task,
              nextTaskPath: nextTaskPath,
              nextPostprocessPath: nextPostprocessPath,
            ),
            subtitle: _taskSubtitle(task),
            badge: _runtimeLabelService.taskStatusLabel(
              ValueReaders.stringValue(task['status']),
            ),
            relativePath: ValueReaders.stringValue(task['relative_path']),
            isSelected:
                ValueReaders.stringValue(task['relative_path']) ==
                resolvedSelectedTaskId,
          ),
        )
        .toList(growable: false);
    final baseline = runtimeProfile == null
        ? null
        : _runtimeBaselineCatalogService.byId(runtimeProfile.runtimeBaselineId);
    final chapterLengthDefaults = _chapterLengthDefaultsService.resolve(
      runtimeProfile,
    );
    return TaskCenterViewData(
      title: '长篇自动化队列',
      intro:
          '这里不是全局任务箱，而是当前小说项目的可恢复写作队列。适合批量章节、长篇规划、审稿修订和检查点推进；默认只跑小步，遇到需要你确认的地方会停下。',
      help:
          '长篇自动化队列的作用：\n'
          '- 把长篇目标拆成可审计任务，而不是让模型一次性跑飞。\n'
          '- 每个任务都保存在当前项目 tasks/，运行轨迹保存在 tracking/。\n'
          '- “运行下一步”只推进一个可执行任务；“受控连续运行”也会在少量步骤、错误、无输出或等待确认时停下。\n'
          '- 如果你只是想问问题或写一小段，不需要来这里；直接在会话栏和智能体对话即可。',
      status: status,
      runtimeBaselineTitle: baseline?.title ?? '',
      runtimeModeLabel: runtimeProfile == null
          ? ''
          : _runtimeLabelService.runtimeModeLabel(runtimeProfile.runtimeMode),
      runtimePolicyBadges: _runtimePolicyBadges(
        runtimeProfile,
        projectStorageStrategy,
      ),
      tasks: entries,
      selectedTaskId: resolvedSelectedTaskId,
      detailBody: detailBody.trim().isEmpty
          ? '当前项目还没有任务。\n\n可以在这里生成长篇队列，也可以让智能体通过工具创建章节、审稿或修订任务。'
          : detailBody,
      queueSummary: queueSummary,
      schedulerSummary: schedulerSummary,
      chainMarkdown: chainMarkdown,
      longTaskRuns: _runItems(
        longTaskRuns,
        selectedPath: selectedLongTaskRunPath,
        kindLabel: '长任务',
        usesRunCenterContract: true,
      ),
      taskQueueRuns: _runItems(
        taskQueueRuns,
        selectedPath: selectedTaskQueueRunPath,
        kindLabel: '队列',
      ),
      selectedLongTaskRunPath: selectedLongTaskRunPath,
      selectedTaskQueueRunPath: selectedTaskQueueRunPath,
      longTaskRunLog: longTaskRunLog,
      taskQueueRunLog: taskQueueRunLog,
      resumeBriefBody: resumeBriefBody,
      modeOptions: modeDefinitions
          .map(
            (item) => TaskRuntimeModeOptionViewData(
              id: ValueReaders.stringValue(item['id']),
              label: ValueReaders.stringValue(item['name']),
              description: ValueReaders.stringValue(item['description']),
            ),
          )
          .toList(growable: false),
      defaultMode: runtimeProfile?.runtimeMode.trim().isEmpty ?? true
          ? TaskRuntimeConstants.modeHumanOutlineAiDraft
          : runtimeProfile!.runtimeMode.trim(),
      defaultOutlinePath: 'outlines/story/总纲.md',
      defaultSeedPrompt: '',
      defaultChapterCount: 12,
      defaultCheckpointInterval: 3,
      defaultChapterLength: chapterLengthDefaults,
      actionGroups: supplementalActionGroups
          .followedBy(
            _contractActionViewDataService.buildGroups(
              checkpointActionPackage: checkpointActionPackage,
              revisionResolution: revisionResolution,
            ),
          )
          .toList(growable: false),
      guidanceRevisitBody: guidanceRevisitBody,
    );
  }

  String resolveSelectedTaskId({
    required List<JsonMap> tasks,
    required String selectedTaskId,
    JsonMap selectedLongTaskRun = const <String, Object?>{},
    JsonMap selectedTaskQueueRun = const <String, Object?>{},
  }) {
    final queuePreferredTask = _preferredTaskFromQueueRun(
      tasks,
      selectedTaskQueueRun,
    );
    if (queuePreferredTask.isNotEmpty) {
      return ValueReaders.stringValue(queuePreferredTask['relative_path']);
    }
    final contract = _runCenterContract(selectedLongTaskRun);
    final preferredTaskId = ValueReaders.stringValue(
      ValueReaders.mapValue(contract['active_task'])['relative_path'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(contract['snapshot'])['active_task'],
        )['relative_path'],
      ),
    ).trim();
    return _resolvedSelectedTaskId(
      selectedTaskId,
      tasks,
      preferredTaskId: preferredTaskId,
    );
  }

  String resolveSelectedTaskQueueRunPath({
    required List<JsonMap> taskQueueRuns,
    required String selectedTaskQueueRunPath,
  }) {
    if (taskQueueRuns.isEmpty) {
      return '';
    }
    final selectedRun = _runByPath(taskQueueRuns, selectedTaskQueueRunPath);
    final newestRun = _newestRun(taskQueueRuns);
    if (selectedRun.isEmpty) {
      return ValueReaders.stringValue(newestRun['relative_path']);
    }
    if (_shouldFollowNewerTaskQueueRun(
      selectedRun: selectedRun,
      newestRun: newestRun,
    )) {
      return ValueReaders.stringValue(newestRun['relative_path']);
    }
    return ValueReaders.stringValue(selectedRun['relative_path']);
  }

  String buildDetailBody(
    JsonMap task, {
    JsonMap execution = const <String, Object?>{},
  }) {
    // 中文注释: 详情区保持轻量可扫读，必要时再附上执行包摘要，不直接把整份 JSON 裸贴给用户。
    if (task.isEmpty) {
      return '';
    }
    final buffer = StringBuffer()
      ..writeln('# ${ValueReaders.stringValue(task['title'], '未命名任务')}')
      ..writeln()
      ..writeln(
        '- 状态：${_runtimeLabelService.taskStatusLabel(ValueReaders.stringValue(task['status']))}',
      )
      ..writeln(
        '- 类型：${ValueReaders.stringValue(task['task_type'], 'chapter')}',
      )
      ..writeln('- 模式：${_modeLabel(ValueReaders.stringValue(task['mode']))}')
      ..writeln(
        '- 路径：${ValueReaders.stringValue(task['relative_path'], '未落盘')}',
      );
    final chapter = ValueReaders.stringValue(task['chapter']).trim();
    if (chapter.isNotEmpty) {
      buffer.writeln('- 章节/范围：$chapter');
    }
    final sourcePaths = ValueReaders.stringList(task['source_paths']);
    if (sourcePaths.isNotEmpty) {
      buffer.writeln('- 来源文件：${sourcePaths.join('、')}');
    }
    final outputPaths = ValueReaders.stringList(task['output_paths']);
    if (outputPaths.isNotEmpty) {
      buffer.writeln('- 输出文件：${outputPaths.join('、')}');
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    final runtimeBaselineId = ValueReaders.stringValue(
      metadata['runtime_baseline_id'],
    ).trim();
    if (runtimeBaselineId.isNotEmpty) {
      final baseline = _runtimeBaselineCatalogService.byId(runtimeBaselineId);
      buffer.writeln('- 运行基准：${baseline?.title ?? runtimeBaselineId}');
    }
    final persistentContextPaths = ValueReaders.stringList(
      metadata['persistent_context_paths'],
    );
    if (persistentContextPaths.isNotEmpty) {
      buffer.writeln('- 持久上下文：${persistentContextPaths.join('、')}');
    }
    final origin = ValueReaders.stringValue(metadata['origin']).trim();
    if (origin == 'chapter_gate_review') {
      buffer.writeln('- 关口类型：章级闸门审稿');
      final gateScope = ValueReaders.stringValue(metadata['gate_scope']).trim();
      if (gateScope.isNotEmpty) {
        buffer.writeln('- 关口范围：$gateScope');
      }
      final gateSourceTaskPath = ValueReaders.stringValue(
        metadata['gate_source_task_path'],
      ).trim();
      if (gateSourceTaskPath.isNotEmpty) {
        buffer.writeln('- 关口来源任务：$gateSourceTaskPath');
      }
    }
    if (origin == 'review_report') {
      final reviewReportPath = ValueReaders.stringValue(
        metadata['review_report_path'],
      ).trim();
      if (reviewReportPath.isNotEmpty) {
        buffer.writeln('- 审稿报告：$reviewReportPath');
      }
    }
    final goal = ValueReaders.stringValue(task['goal']).trim();
    if (goal.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 任务目标')
        ..writeln(goal);
    }
    final brief = ValueReaders.stringValue(task['brief']).trim();
    if (brief.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 简述')
        ..writeln(brief);
    }
    final toolHint = ValueReaders.stringValue(task['tool_hint']).trim();
    if (toolHint.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 工具提示')
        ..writeln(toolHint);
    }
    final history = ValueReaders.objectList(task['history']);
    if (history.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 状态历史');
      for (final rawEntry in history.take(12)) {
        final entry = ValueReaders.mapValue(rawEntry);
        buffer.writeln(
          '- ${_statusLabel(ValueReaders.stringValue(entry['status']))}'
          '｜${ValueReaders.stringValue(entry['created_at'])}'
          '｜${ValueReaders.stringValue(entry['note'])}',
        );
      }
    }
    if (execution.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 执行包')
        ..writeln(
          '- 上下文包：${ValueReaders.stringValue(execution['context_pack_id'], '未记录')}',
        )
        ..writeln(
          '- 输出路径：${ValueReaders.stringList(execution['output_paths']).join('、')}',
        );
      final prompt = ValueReaders.stringValue(
        execution['prompt_preview_markdown'],
      ).trim();
      if (prompt.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('### Prompt 预览')
          ..writeln(prompt);
      }
    }
    return buffer.toString().trim();
  }

  String buildQueueSummary(JsonMap preflight) {
    // 中文注释: 预检摘要压成简洁文案，方便任务中心右栏快速判断“为什么现在不能跑”。
    if (preflight.isEmpty) {
      return '';
    }
    final lines = <String>[
      '可运行：${ValueReaders.boolValue(preflight['runnable']) ? '是' : '否'}',
    ];
    final blocker = ValueReaders.stringValue(preflight['blocker']).trim();
    if (blocker.isNotEmpty) {
      lines.add('阻塞原因：${_runtimeLabelService.blockerLabel(blocker)}');
    }
    final nextTask = ValueReaders.mapValue(preflight['next_task']);
    if (nextTask.isNotEmpty) {
      lines.add('下一任务：${ValueReaders.stringValue(nextTask['title'], '未命名任务')}');
    }
    final warnings = ValueReaders.stringList(preflight['warnings']);
    if (warnings.isNotEmpty) {
      lines.add('提示：${warnings.join('；')}');
    }
    return lines.join('\n');
  }

  String buildSchedulerSummary(JsonMap scheduler) {
    // 中文注释: 调度摘要保留动作、worker 状态和最近运行路径，给 GUI 和 CLI 共用同一口径。
    if (scheduler.isEmpty) {
      return '';
    }
    if (!ValueReaders.boolValue(scheduler['ok'])) {
      final error = ValueReaders.stringValue(scheduler['error']).trim();
      return error.isEmpty ? '' : '调度计划不可用：$error';
    }
    final lines = <String>[
      '调度动作：${_runtimeLabelService.schedulerActionLabel(ValueReaders.stringValue(scheduler['action']))}',
      '执行器状态：${_runtimeLabelService.workerStateLabel(ValueReaders.stringValue(scheduler['worker_state']))}',
    ];
    final runPath = ValueReaders.stringValue(scheduler['relative_path']).trim();
    if (runPath.isNotEmpty) {
      lines.add('运行记录：$runPath');
    }
    final stopReason = ValueReaders.stringValue(
      scheduler['stop_reason'],
    ).trim();
    if (stopReason.isNotEmpty) {
      lines.add('停止原因：${_runtimeLabelService.blockerLabel(stopReason)}');
    }
    final plan = ValueReaders.mapValue(scheduler['next_batch_plan']);
    if (plan.isNotEmpty) {
      lines.add('建议步数：${ValueReaders.objectList(plan['task_paths']).length}');
    }
    return lines.join('\n');
  }

  String buildChainMarkdown(JsonMap chainView) {
    // 中文注释: 任务链详情优先直接拼成 Markdown，页面层只负责展示，不再重写依赖摘要规则。
    final chains = ValueReaders.mapList(chainView['chains']);
    if (chains.isEmpty) {
      return '当前项目还没有任务链路。';
    }
    final lines = <String>[
      '# 任务链路',
      '',
      '- 任务数：${ValueReaders.intValue(chainView['task_count'])}',
      '',
    ];
    for (final chain in chains) {
      lines.add('## ${ValueReaders.stringValue(chain['title'])}');
      lines.add(
        '- 下一可运行：${ValueReaders.stringValue(chain['next_runnable_title'], '无')}',
      );
      final blockers = ValueReaders.stringList(chain['blocking_checkpoints']);
      if (blockers.isNotEmpty) {
        lines.add('- 阻塞检查点：${blockers.join('、')}');
      }
      for (final node in ValueReaders.mapList(chain['nodes'])) {
        lines.add(
          '- ${_chainMarker(node, ValueReaders.stringValue(chain['next_runnable_id']))}'
          '｜${ValueReaders.intValue(node['sort_order']).toString().padLeft(3, '0')}'
          '｜${_runtimeLabelService.taskStatusLabel(ValueReaders.stringValue(node['status']))}'
          '｜${ValueReaders.stringValue(node['task_type'])}'
          '｜${ValueReaders.stringValue(node['title'])}',
        );
      }
      lines.add('');
    }
    return lines.join('\n').trim();
  }

  String buildResumeBriefBody(
    JsonMap longTaskRun, {
    JsonMap checkpointActionPackage = const <String, Object?>{},
    JsonMap revisionResolution = const <String, Object?>{},
    JsonMap selectedTask = const <String, Object?>{},
    JsonMap selectedTaskExecution = const <String, Object?>{},
  }) {
    final contract = _runCenterContract(longTaskRun);
    final brief = ValueReaders.mapValue(contract['resume_brief']);
    if (brief.isEmpty) {
      return '';
    }
    final lines = <String>[
      '## 恢复现场',
      ValueReaders.stringValue(brief['resume_title']).trim(),
    ];
    final resumeSummary = ValueReaders.stringValue(
      brief['resume_summary'],
    ).trim();
    if (resumeSummary.isNotEmpty) {
      lines.add('');
      lines.add(resumeSummary);
    }
    final lastStepSummary = ValueReaders.stringValue(
      brief['last_step_summary'],
    ).trim();
    if (lastStepSummary.isNotEmpty) {
      lines.add('');
      lines.add(lastStepSummary);
    }
    final nextActionSummary = ValueReaders.stringValue(
      brief['next_action_summary'],
    ).trim();
    if (nextActionSummary.isNotEmpty) {
      lines.add('');
      lines.add(nextActionSummary);
    }
    if (ValueReaders.boolValue(brief['action_package_available']) &&
        ValueReaders.boolValue(checkpointActionPackage['ok'])) {
      lines.add('');
      lines.add('当前已有检查点动作包，可直接在右侧上下文动作区处理。');
    }
    if (ValueReaders.boolValue(brief['revision_resolution_available']) &&
        ValueReaders.boolValue(revisionResolution['ok'])) {
      lines.add('');
      lines.add('当前已有修订收口动作，可直接在右侧上下文动作区处理。');
    }
    final pendingOptions = _pendingUserOptions(selectedTaskExecution);
    if (pendingOptions.isNotEmpty) {
      final question = ValueReaders.stringValue(
        pendingOptions.first['source_question'],
      ).trim();
      lines.add('');
      lines.add('当前任务还在等待一个真实用户选择。');
      if (question.isNotEmpty) {
        lines.add('');
        lines.add('问题：$question');
      }
      lines.add('');
      lines.add(
        '可直接在右侧上下文动作区点击以下选项继续：${pendingOptions.map((item) => ValueReaders.stringValue(item["label"], "选项")).where((item) => item.trim().isNotEmpty).join('、')}',
      );
    } else if (ValueReaders.stringValue(selectedTask['status']) ==
        TaskRuntimeConstants.statusWaitingUser) {
      lines.add('');
      lines.add('当前任务处于等待用户确认状态。');
    }
    return lines.join('\n').trim();
  }

  TaskCenterActionGroupViewData? buildUserOptionActionGroup({
    required JsonMap task,
    required JsonMap execution,
  }) {
    if (task.isEmpty ||
        ValueReaders.stringValue(task['status']) !=
            TaskRuntimeConstants.statusWaitingUser) {
      return null;
    }
    final options = _pendingUserOptions(execution);
    if (options.isEmpty) {
      return null;
    }
    final question = ValueReaders.stringValue(
      options.first['source_question'],
    ).trim();
    final ownerTaskPath = ValueReaders.stringValue(task['relative_path']);
    final actions = <TaskCenterContractActionViewData>[];
    for (var index = 0; index < options.length; index += 1) {
      final option = options[index];
      final label = ValueReaders.stringValue(option['label']).trim();
      final prompt = ValueReaders.stringValue(option['prompt'], label).trim();
      if (label.isEmpty || prompt.isEmpty) {
        continue;
      }
      actions.add(
        TaskCenterContractActionViewData(
          id: 'task_user_option_$index',
          label: label,
          note: ValueReaders.stringValue(
            option['description'],
            question.isEmpty ? '将这个方向作为用户确认继续当前任务。' : question,
          ),
          tone: index == 0 ? 'accent' : 'neutral',
          invocationKind: 'task_user_option',
          enabled: ownerTaskPath.trim().isNotEmpty,
          disabledReason: ownerTaskPath.trim().isEmpty
              ? '当前任务路径缺失，暂时不能回写用户选择。'
              : '',
          ownerTaskPath: ownerTaskPath,
          checkpointReviewPath: '',
          isRecommended: index == 0,
          userOptionPrompt: prompt,
          userOptionDescription: ValueReaders.stringValue(
            option['description'],
          ),
          userOptionQuestion: question,
        ),
      );
    }
    if (actions.isEmpty) {
      return null;
    }
    return TaskCenterActionGroupViewData(
      id: 'task_user_options',
      title: '任务选项',
      summary: question.isEmpty ? '当前任务需要用户先选一个方向。' : question,
      actions: actions,
    );
  }

  TaskCenterActionGroupViewData? buildRunControlActionGroup({
    required JsonMap longTaskRun,
    required JsonMap task,
    required String selectedLongTaskRunPath,
  }) {
    if (task.isEmpty) {
      return null;
    }
    final taskPath = ValueReaders.stringValue(task['relative_path']).trim();
    final taskId = ValueReaders.stringValue(task['id']).trim();
    final taskStatus = ValueReaders.stringValue(task['status']).trim();
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    final checkpointAwaitingConfirmation =
        taskType == 'checkpoint' &&
        <String>{
          TaskRuntimeConstants.statusWaitingUser,
          TaskRuntimeConstants.statusPaused,
        }.contains(taskStatus);
    if (taskPath.isEmpty) {
      return null;
    }
    final controls = ValueReaders.mapList(
      _runCenterContract(longTaskRun)['controls'],
    );
    final actions = <TaskCenterContractActionViewData>[];
    for (final control in controls) {
      if (!ValueReaders.boolValue(control['enabled'])) {
        continue;
      }
      final controlId = ValueReaders.stringValue(control['id']).trim();
      final hostCommand = ValueReaders.stringValue(
        control['host_command'],
      ).trim();
      final arguments = ValueReaders.mapValue(control['arguments']);
      switch (controlId) {
        case 'pause':
        case 'resume':
        case 'stop':
          final genericAction = _genericRunControlAction(
            control: control,
            controlId: controlId,
            hostCommand: hostCommand,
            taskPath: taskPath,
            taskId: taskId,
            longTaskRunPath: selectedLongTaskRunPath,
          );
          if (genericAction != null) {
            actions.add(genericAction);
          }
          continue;
        case 'confirm_checkpoint':
          if (hostCommand != 'apply_long_task_revision') {
            continue;
          }
          final revisionCommand = ValueReaders.stringValue(
            arguments['revision_command'],
          ).trim();
          if (revisionCommand.isNotEmpty &&
              revisionCommand != 'confirm_checkpoint') {
            continue;
          }
          final controlTaskPath = ValueReaders.stringValue(
            arguments['relative_path'],
          ).trim();
          final controlTaskId = ValueReaders.stringValue(
            arguments['task_id'],
          ).trim();
          final ownerTaskPath = controlTaskPath.isNotEmpty
              ? controlTaskPath
              : taskPath;
          final ownerTaskId = controlTaskId.isNotEmpty ? controlTaskId : taskId;
          if (ownerTaskPath.isEmpty ||
              (!checkpointAwaitingConfirmation &&
                  controlTaskPath.isEmpty &&
                  controlTaskId.isEmpty)) {
            continue;
          }
          actions.add(
            TaskCenterContractActionViewData(
              id: controlId,
              label: ValueReaders.stringValue(control['label'], '确认检查点'),
              note: '将当前等待确认的检查点标记为已确认，并解锁下一步长任务调度。',
              tone: ValueReaders.stringValue(control['tone'], 'success'),
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: ownerTaskPath,
              checkpointReviewPath: '',
              ownerTaskId: ownerTaskId,
              longTaskRunPath: selectedLongTaskRunPath.trim(),
              isRecommended: true,
            ),
          );
        case 'retry_failed':
          if (hostCommand != 'long_task_failure_action' ||
              ValueReaders.stringValue(task['status']) !=
                  TaskRuntimeConstants.statusFailed ||
              ValueReaders.stringValue(arguments['failure_command']).trim() !=
                  'retry') {
            continue;
          }
          actions.add(
            TaskCenterContractActionViewData(
              id: controlId,
              label: ValueReaders.stringValue(control['label'], '重试失败任务'),
              note: '将当前失败任务重新排队，并恢复长任务运行。',
              tone: ValueReaders.stringValue(control['tone'], 'accent'),
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: taskPath,
              checkpointReviewPath: '',
              ownerTaskId: taskId,
              longTaskRunPath: selectedLongTaskRunPath.trim(),
              isRecommended: true,
            ),
          );
        case 'skip_failed':
          if (hostCommand != 'long_task_failure_action' ||
              ValueReaders.stringValue(task['status']) !=
                  TaskRuntimeConstants.statusFailed ||
              ValueReaders.stringValue(arguments['failure_command']).trim() !=
                  'skip') {
            continue;
          }
          actions.add(
            TaskCenterContractActionViewData(
              id: controlId,
              label: ValueReaders.stringValue(control['label'], '跳过失败任务'),
              note: '将当前失败任务标记为取消，并尝试继续后续长任务链路。',
              tone: ValueReaders.stringValue(control['tone'], 'warm'),
              invocationKind: 'run_center_control',
              enabled: true,
              disabledReason: '',
              ownerTaskPath: taskPath,
              checkpointReviewPath: '',
              ownerTaskId: taskId,
              longTaskRunPath: selectedLongTaskRunPath.trim(),
              isRecommended: false,
            ),
          );
      }
    }
    if (actions.isEmpty) {
      return null;
    }
    final hasCheckpointConfirmAction = actions.any(
      (action) => action.id == 'confirm_checkpoint',
    );
    final hasFailureRecoveryAction = actions.any(
      (action) => action.id == 'retry_failed' || action.id == 'skip_failed',
    );
    final hasResumeAction = actions.any((action) => action.id == 'resume');
    final hasPauseAction = actions.any((action) => action.id == 'pause');
    final hasStopAction = actions.any((action) => action.id == 'stop');
    final summary = hasCheckpointConfirmAction
        ? '当前长任务停在检查点确认处，可直接确认后继续主链。'
        : hasFailureRecoveryAction
        ? '当前任务已失败，可选择重试或跳过后继续恢复长任务。'
        : hasResumeAction && hasStopAction
        ? '当前长任务已暂停，可继续恢复主链推进，或直接停止本轮运行。'
        : hasResumeAction
        ? '当前长任务已暂停，可继续恢复主链推进。'
        : hasPauseAction && hasStopAction
        ? '当前长任务正在运行，可随时暂停或停止本轮运行。'
        : hasPauseAction
        ? '当前长任务正在运行，可随时暂停。'
        : hasStopAction
        ? '当前长任务可直接停止本轮运行。'
        : taskType == 'checkpoint'
        ? '当前任务是显式检查点，可直接确认后继续主链。'
        : '当前运行状态已提供可执行控制。';
    return TaskCenterActionGroupViewData(
      id: 'run_center_control',
      title: '运行控制',
      summary: summary,
      actions: actions,
    );
  }

  TaskCenterContractActionViewData? _genericRunControlAction({
    required JsonMap control,
    required String controlId,
    required String hostCommand,
    required String taskPath,
    required String taskId,
    required String longTaskRunPath,
  }) {
    final note = switch (controlId) {
      'pause' => '暂停当前长任务运行，保留现场，稍后可从当前状态继续。',
      'resume' => '恢复当前长任务运行，从已暂停的主链位置继续推进。',
      'stop' => '停止当前长任务运行，并将本轮连续任务记录收束为已结束。',
      _ => '',
    };
    final expectedHostCommand = switch (controlId) {
      'pause' => 'pause_long_task_run',
      'resume' => 'resume_long_task_run',
      'stop' => 'stop_long_task_run',
      _ => '',
    };
    if (expectedHostCommand.isEmpty || hostCommand != expectedHostCommand) {
      return null;
    }
    return TaskCenterContractActionViewData(
      id: controlId,
      label: ValueReaders.stringValue(control['label'], switch (controlId) {
        'pause' => '暂停',
        'resume' => '继续',
        'stop' => '停止',
        _ => '',
      }),
      note: note,
      tone: ValueReaders.stringValue(control['tone'], switch (controlId) {
        'pause' => 'warm',
        'resume' => 'accent',
        'stop' => 'danger',
        _ => 'neutral',
      }),
      invocationKind: 'run_center_control',
      enabled: true,
      disabledReason: '',
      ownerTaskPath: taskPath,
      checkpointReviewPath: '',
      ownerTaskId: taskId,
      longTaskRunPath: longTaskRunPath.trim(),
      isRecommended: controlId == 'resume',
    );
  }

  List<TaskCenterRunItemViewData> _runItems(
    List<JsonMap> records, {
    required String selectedPath,
    required String kindLabel,
    bool usesRunCenterContract = false,
  }) {
    return records
        .map((record) {
          final contract = usesRunCenterContract
              ? _runCenterContract(record)
              : const <String, Object?>{};
          final statusLabel = _runItemStatusLabel(record, contract);
          final phaseLabel = ValueReaders.stringValue(
            contract['phase_label'],
          ).trim();
          final progressPercent = _runItemProgressPercent(contract);
          final activeTaskTitle = _runItemActiveTaskTitle(contract);
          final updatedAt = _runItemUpdatedAt(record, contract);
          final controlSummary = _runItemControlSummary(contract);
          return TaskCenterRunItemViewData(
            relativePath: ValueReaders.stringValue(record['relative_path']),
            title: '$kindLabel｜$statusLabel',
            subtitle: _runRecordSubtitle(
              record,
              contract: contract,
              phaseLabel: phaseLabel,
              activeTaskTitle: activeTaskTitle,
              progressPercent: progressPercent,
            ),
            statusLabel: statusLabel,
            phaseLabel: phaseLabel,
            progressPercent: progressPercent,
            activeTaskTitle: activeTaskTitle,
            updatedAt: updatedAt,
            isWaitingUser: ValueReaders.boolValue(contract['waiting_user']),
            controlSummary: controlSummary,
            isSelected:
                ValueReaders.stringValue(record['relative_path']) ==
                selectedPath,
          );
        })
        .toList(growable: false);
  }

  String _resolvedSelectedTaskId(
    String selectedTaskId,
    List<JsonMap> tasks, {
    String preferredTaskId = '',
  }) {
    final selectedTask = _taskByPath(tasks, selectedTaskId);
    final preferredTask = _taskByPath(tasks, preferredTaskId);
    final bestTask = _bestSelectionTask(tasks);
    JsonMap resolvedTask = selectedTask;
    for (final candidate in <JsonMap>[preferredTask, bestTask]) {
      if (candidate.isEmpty) {
        continue;
      }
      final candidatePriority = _selectionPriority(candidate);
      final resolvedPriority = _selectionPriority(resolvedTask);
      final prefersCandidateOnTie =
          preferredTaskId.isNotEmpty &&
          ValueReaders.stringValue(candidate['relative_path']) ==
              preferredTaskId &&
          candidatePriority == resolvedPriority;
      if (resolvedTask.isEmpty ||
          candidatePriority > resolvedPriority ||
          prefersCandidateOnTie) {
        resolvedTask = candidate;
      }
    }
    if (resolvedTask.isNotEmpty) {
      return ValueReaders.stringValue(resolvedTask['relative_path']);
    }
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['relative_path']) == selectedTaskId) {
        return selectedTaskId;
      }
    }
    if (tasks.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(tasks.first['relative_path']);
  }

  String _taskItemTitle(
    JsonMap task, {
    required String nextTaskPath,
    required String nextPostprocessPath,
  }) {
    final taskPath = ValueReaders.stringValue(task['relative_path']);
    var prefix = '';
    if (nextTaskPath.isNotEmpty && taskPath == nextTaskPath) {
      prefix = '下一步｜';
    } else if (nextPostprocessPath.isNotEmpty &&
        taskPath == nextPostprocessPath) {
      prefix = '待后处理｜';
    }
    return '$prefix${_statusLabel(ValueReaders.stringValue(task['status']))}'
        '｜${_modeLabel(ValueReaders.stringValue(task['mode']))}'
        '｜${ValueReaders.stringValue(task['title'], '未命名任务')}';
  }

  String _taskSubtitle(JsonMap task) {
    final parts = <String>[
      ValueReaders.stringValue(task['task_type'], 'chapter'),
    ];
    final chapter = ValueReaders.stringValue(task['chapter']).trim();
    if (chapter.isNotEmpty) {
      parts.add(chapter);
    }
    final sourcePath = ValueReaders.stringList(task['source_paths']);
    if (sourcePath.isNotEmpty) {
      parts.add(sourcePath.first);
    }
    return parts.join('｜');
  }

  String _statusLabel(String status) {
    return _runtimeLabelService.taskStatusLabel(status);
  }

  String _modeLabel(String mode) {
    switch (mode.trim()) {
      case TaskRuntimeConstants.modeSingleChapterAtomic:
        return '单章';
      case TaskRuntimeConstants.modeSupervisedChapterQueue:
        return '章节队列';
      case TaskRuntimeConstants.modeHumanOutlineAiDraft:
        return '按大纲';
      case TaskRuntimeConstants.modeSeedToFullNovel:
        return '长任务开局';
      default:
        return mode.trim().isEmpty ? '任务' : mode.trim();
    }
  }

  String _chainMarker(JsonMap node, String nextId) {
    if (nextId.trim().isNotEmpty &&
        ValueReaders.stringValue(node['id']) == nextId.trim()) {
      return '下一步';
    }
    if (ValueReaders.boolValue(node['manual_checkpoint'])) {
      return '检查点';
    }
    switch (ValueReaders.stringValue(node['status'])) {
      case 'succeeded':
        return '完成';
      case 'failed':
        return '失败';
      case 'running':
        return '运行中';
      case 'paused':
        return '暂停';
      case 'waiting_user':
        return '待确认';
      default:
        return '待办';
    }
  }

  List<String> _runtimePolicyBadges(
    ProjectRuntimeProfile? runtimeProfile,
    ProjectStorageStrategy? projectStorageStrategy,
  ) {
    if (runtimeProfile == null) {
      return const <String>[];
    }
    final options = runtimeProfile.initialRunOptions;
    final badges = <String>[];
    if (projectStorageStrategy != null) {
      badges.add(
        _runtimeLabelService.storageStrategyLabel(projectStorageStrategy),
      );
    }
    if (ValueReaders.boolValue(options['unattended'])) {
      badges.add('托管运行');
    }
    if (ValueReaders.boolValue(options['auto_advance_chapters'])) {
      badges.add('自动推进');
    }
    if (ValueReaders.boolValue(options['keep_alive_across_project_switch'])) {
      badges.add('跨项目保活');
    }
    return badges;
  }

  String _runRecordStatusLabel(JsonMap record) {
    final status = ValueReaders.stringValue(record['status']).trim();
    if (status == LongTaskRunStatus.waitingGate.id ||
        status == LongTaskRunStatus.paused.id ||
        status == LongTaskRunStatus.recovering.id ||
        status == LongTaskRunStatus.failedManualAttention.id ||
        status == LongTaskRunStatus.stopped.id ||
        status == LongTaskRunStatus.running.id ||
        status == LongTaskRunStatus.readyToStart.id ||
        status == LongTaskRunStatus.draftingGuidance.id) {
      return _runtimeLabelService.longTaskRunStatusLabelById(status);
    }
    return _runtimeLabelService.taskStatusLabel(status);
  }

  JsonMap _runCenterContract(JsonMap record) {
    final direct = ValueReaders.mapValue(record['run_center_contract']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final schedulerSnapshot = ValueReaders.mapValue(
      record['scheduler_snapshot'],
    );
    final fromSnapshot = ValueReaders.mapValue(
      schedulerSnapshot['run_center_contract'],
    );
    if (fromSnapshot.isNotEmpty) {
      return fromSnapshot;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(
        schedulerSnapshot['scheduler_plan'],
      )['run_center_contract'],
    );
  }

  JsonMap _taskByPath(List<JsonMap> tasks, String taskPath) {
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['relative_path']) == taskPath) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _runByPath(List<JsonMap> runs, String runPath) {
    for (final run in runs) {
      if (ValueReaders.stringValue(run['relative_path']) == runPath) {
        return run;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _newestRun(List<JsonMap> runs) {
    JsonMap newest = const <String, Object?>{};
    var newestTimestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    for (final run in runs) {
      final updatedAt = _runUpdatedAt(run);
      if (newest.isEmpty || updatedAt.isAfter(newestTimestamp)) {
        newest = run;
        newestTimestamp = updatedAt;
      }
    }
    return newest.isEmpty ? runs.first : newest;
  }

  bool _shouldFollowNewerTaskQueueRun({
    required JsonMap selectedRun,
    required JsonMap newestRun,
  }) {
    final selectedPath = ValueReaders.stringValue(
      selectedRun['relative_path'],
    ).trim();
    final newestPath = ValueReaders.stringValue(newestRun['relative_path'])
        .trim();
    if (selectedPath.isEmpty || newestPath.isEmpty || selectedPath == newestPath) {
      return false;
    }
    final selectedUpdatedAt = _runUpdatedAt(selectedRun);
    final newestUpdatedAt = _runUpdatedAt(newestRun);
    if (!newestUpdatedAt.isAfter(selectedUpdatedAt)) {
      return false;
    }
    final selectedStatus = ValueReaders.stringValue(selectedRun['status']).trim();
    if (_isTaskQueueRunActive(selectedStatus)) {
      return false;
    }
    return true;
  }

  bool _isTaskQueueRunActive(String status) {
    return status == TaskRuntimeConstants.statusRunning ||
        status == TaskRuntimeConstants.statusPlanning ||
        status == TaskRuntimeConstants.statusRetrying;
  }

  DateTime _runUpdatedAt(JsonMap run) {
    final updatedAt = DateTime.tryParse(
      ValueReaders.stringValue(run['updated_at']).trim(),
    );
    return updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  JsonMap _bestSelectionTask(List<JsonMap> tasks) {
    JsonMap bestTask = const <String, Object?>{};
    var bestPriority = -1;
    for (final task in tasks) {
      final priority = _selectionPriority(task);
      if (priority > bestPriority) {
        bestTask = task;
        bestPriority = priority;
      }
    }
    return bestTask;
  }

  int _selectionPriority(JsonMap task) {
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    final waitingForUserChoice = ValueReaders.boolValue(
      task['waiting_for_user_choice'],
    );
    switch (ValueReaders.stringValue(task['status']).trim()) {
      case TaskRuntimeConstants.statusFailed:
        return 70;
      case TaskRuntimeConstants.statusWaitingUser:
        if (waitingForUserChoice) {
          return 68;
        }
        if (taskType == 'checkpoint') {
          return 64;
        }
        return 60;
      case TaskRuntimeConstants.statusRunning:
        return 50;
      case TaskRuntimeConstants.statusRetrying:
        return 45;
      case TaskRuntimeConstants.statusPlanning:
        return 40;
      case TaskRuntimeConstants.statusQueued:
        return 35;
      case TaskRuntimeConstants.statusPaused:
        return 30;
      case TaskRuntimeConstants.statusSucceeded:
        return 10;
      case TaskRuntimeConstants.statusCancelled:
        return 0;
      default:
        return 20;
    }
  }

  JsonMap _preferredTaskFromQueueRun(
    List<JsonMap> tasks,
    JsonMap selectedTaskQueueRun,
  ) {
    if (selectedTaskQueueRun.isEmpty) {
      return const <String, Object?>{};
    }
    final stopReason = ValueReaders.stringValue(
      selectedTaskQueueRun['stop_reason'],
    ).trim();
    if (!_queueStopReasonRequiresSourceTaskFocus(stopReason)) {
      return const <String, Object?>{};
    }
    final queueTaskPath = ValueReaders.stringValue(
      selectedTaskQueueRun['last_task_relative_path'],
    ).trim();
    final queueTask = _taskByPath(tasks, queueTaskPath);
    if (queueTask.isEmpty) {
      return const <String, Object?>{};
    }
    if (_taskHasFollowupCheckpoint(queueTask)) {
      return queueTask;
    }
    final status = ValueReaders.stringValue(queueTask['status']).trim();
    if (status == TaskRuntimeConstants.statusWaitingUser ||
        status == TaskRuntimeConstants.statusFailed) {
      return queueTask;
    }
    return const <String, Object?>{};
  }

  bool _queueStopReasonRequiresSourceTaskFocus(String stopReason) {
    return stopReason == 'constraint_gate_pause' ||
        stopReason == 'waiting_user_choice' ||
        stopReason == 'delivery_waiting_user_choice' ||
        stopReason == 'waiting_user';
  }

  bool _taskHasFollowupCheckpoint(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    for (final candidate in <String>[
      ValueReaders.stringValue(task['checkpoint_review_path']),
      ValueReaders.stringValue(task['postprocess_checkpoint_review_path']),
      ValueReaders.stringValue(task['followup_review_checkpoint_review_path']),
      ValueReaders.stringValue(metadata['checkpoint_review_path']),
      ValueReaders.stringValue(
        metadata['followup_review_checkpoint_review_path'],
      ),
      ValueReaders.stringValue(metadata['origin_checkpoint_review_path']),
    ]) {
      if (candidate.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<JsonMap> _pendingUserOptions(JsonMap execution) {
    final stored = ValueReaders.mapList(execution['pending_user_options']);
    if (stored.isNotEmpty) {
      return stored;
    }
    for (final rawTool in ValueReaders.objectList(
      execution['executed_tools'],
    ).reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'present_user_options') {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final question = ValueReaders.stringValue(result['question']);
      return ValueReaders.objectList(result['options'])
          .map(ValueReaders.mapValue)
          .where((entry) => entry.isNotEmpty)
          .map(
            (entry) => <String, Object?>{
              'label': ValueReaders.stringValue(
                entry['label'],
                ValueReaders.stringValue(
                  entry['title'],
                  ValueReaders.stringValue(entry['name'], '选项'),
                ),
              ),
              'description': ValueReaders.stringValue(
                entry['description'],
                ValueReaders.stringValue(
                  entry['detail'],
                  ValueReaders.stringValue(entry['summary']),
                ),
              ),
              'prompt': ValueReaders.stringValue(
                entry['prompt'],
                ValueReaders.stringValue(
                  entry['value'],
                  ValueReaders.stringValue(
                    entry['title'],
                    ValueReaders.stringValue(entry['label']),
                  ),
                ),
              ),
              'source_question': question,
            },
          )
          .toList(growable: false);
    }
    return const <JsonMap>[];
  }

  String _runItemStatusLabel(JsonMap record, JsonMap contract) {
    final statusLabel = ValueReaders.stringValue(
      contract['status_label'],
    ).trim();
    if (statusLabel.isNotEmpty) {
      return statusLabel;
    }
    return _runRecordStatusLabel(record);
  }

  int _runItemProgressPercent(JsonMap contract) {
    final progress = ValueReaders.mapValue(contract['progress']);
    final raw = progress.containsKey('overall_percent')
        ? progress['overall_percent']
        : progress['percent'];
    final percent = ValueReaders.intValue(raw);
    if (percent < 0) {
      return 0;
    }
    if (percent > 100) {
      return 100;
    }
    return percent;
  }

  String _runItemActiveTaskTitle(JsonMap contract) {
    final activeTask = ValueReaders.mapValue(contract['active_task']);
    return ValueReaders.stringValue(
      activeTask['title'],
      ValueReaders.stringValue(contract['active_task_title']),
    ).trim();
  }

  String _runItemUpdatedAt(JsonMap record, JsonMap contract) {
    return ValueReaders.stringValue(
      contract['updated_at'],
      ValueReaders.stringValue(record['updated_at']),
    ).trim();
  }

  String _runItemControlSummary(JsonMap contract) {
    final direct = ValueReaders.stringValue(contract['control_summary']).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final labels = <String>[];
    for (final action in ValueReaders.mapList(contract['controls'])) {
      if (ValueReaders.boolValue(action['enabled'])) {
        final label = ValueReaders.stringValue(action['label']).trim();
        if (label.isNotEmpty) {
          labels.add(label);
        }
      }
    }
    return labels.isEmpty ? '' : '可操作：${labels.join('、')}';
  }

  String _runRecordSubtitle(
    JsonMap record, {
    JsonMap contract = const <String, Object?>{},
    String phaseLabel = '',
    String activeTaskTitle = '',
    int progressPercent = 0,
  }) {
    final parts = <String>[];
    if (phaseLabel.trim().isNotEmpty) {
      parts.add(phaseLabel.trim());
    }
    if (progressPercent > 0) {
      parts.add('$progressPercent%');
    }
    if (activeTaskTitle.trim().isNotEmpty) {
      parts.add(activeTaskTitle.trim());
    }
    if (ValueReaders.boolValue(contract['waiting_user'])) {
      parts.add('等待确认');
    }
    final baselineId = ValueReaders.stringValue(
      record['runtime_baseline_id'],
    ).trim();
    if (baselineId.isNotEmpty) {
      final baseline = _runtimeBaselineCatalogService.byId(baselineId);
      parts.add(baseline?.title ?? baselineId);
    }
    final mode = ValueReaders.stringValue(record['mode']).trim();
    if (mode.isNotEmpty) {
      parts.add(_runtimeLabelService.runtimeModeLabel(mode));
    }
    final stopReason = ValueReaders.stringValue(record['stop_reason']).trim();
    if (stopReason.isNotEmpty) {
      parts.add(_runtimeLabelService.blockerLabel(stopReason));
    }
    final updatedAt = _runItemUpdatedAt(record, contract);
    if (updatedAt.isNotEmpty) {
      parts.add(updatedAt);
    }
    return parts.join('｜');
  }
}
