import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_view_data.dart';

class TaskCenterViewDataService {
  const TaskCenterViewDataService();

  TaskCenterViewData build({
    required List<JsonMap> tasks,
    required List<JsonMap> modeDefinitions,
    required String selectedTaskId,
    required String detailBody,
    required String queueSummary,
    required String schedulerSummary,
    String nextTaskPath = '',
    String nextPostprocessPath = '',
    String status = '',
  }) {
    // 中文注释: 任务中心展示映射集中在这里，避免控制器继续堆积状态文案和枚举翻译。
    final resolvedSelectedTaskId = _resolvedSelectedTaskId(selectedTaskId, tasks);
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
            badge: _statusLabel(ValueReaders.stringValue(task['status'])),
            relativePath: ValueReaders.stringValue(task['relative_path']),
            isSelected:
                ValueReaders.stringValue(task['relative_path']) ==
                resolvedSelectedTaskId,
          ),
        )
        .toList(growable: false);
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
      tasks: entries,
      selectedTaskId: resolvedSelectedTaskId,
      detailBody: detailBody.trim().isEmpty
          ? '当前项目还没有任务。\n\n可以在这里生成长篇队列，也可以让智能体通过工具创建章节、审稿或修订任务。'
          : detailBody,
      queueSummary: queueSummary,
      schedulerSummary: schedulerSummary,
      modeOptions: modeDefinitions
          .map(
            (item) => TaskRuntimeModeOptionViewData(
              id: ValueReaders.stringValue(item['id']),
              label: ValueReaders.stringValue(item['name']),
              description: ValueReaders.stringValue(item['description']),
            ),
          )
          .toList(growable: false),
      defaultMode: TaskRuntimeConstants.modeHumanOutlineAiDraft,
      defaultOutlinePath: 'outline/outline.md',
      defaultSeedPrompt: '',
      defaultChapterCount: 12,
      defaultCheckpointInterval: 3,
    );
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
      ..writeln('- 状态：${_statusLabel(ValueReaders.stringValue(task['status']))}')
      ..writeln('- 类型：${ValueReaders.stringValue(task['task_type'], 'chapter')}')
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
      lines.add('阻塞原因：${_blockerLabel(blocker)}');
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
      '调度动作：${_schedulerActionLabel(ValueReaders.stringValue(scheduler['action']))}',
      '执行器状态：${_workerStateLabel(ValueReaders.stringValue(scheduler['worker_state']))}',
    ];
    final runPath = ValueReaders.stringValue(scheduler['relative_path']).trim();
    if (runPath.isNotEmpty) {
      lines.add('运行记录：$runPath');
    }
    final stopReason = ValueReaders.stringValue(scheduler['stop_reason']).trim();
    if (stopReason.isNotEmpty) {
      lines.add('停止原因：${_blockerLabel(stopReason)}');
    }
    final plan = ValueReaders.mapValue(scheduler['next_batch_plan']);
    if (plan.isNotEmpty) {
      lines.add('建议步数：${ValueReaders.objectList(plan['task_paths']).length}');
    }
    return lines.join('\n');
  }

  String _resolvedSelectedTaskId(String selectedTaskId, List<JsonMap> tasks) {
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
    switch (status.trim()) {
      case 'queued':
        return '排队';
      case 'planning':
        return '规划';
      case 'running':
        return '运行中';
      case 'waiting_user':
        return '等你确认';
      case 'paused':
        return '暂停';
      case 'retrying':
        return '重试';
      case 'succeeded':
        return '完成';
      case 'failed':
        return '失败';
      case 'cancelled':
        return '取消';
      default:
        return status.trim().isEmpty ? '待办' : status.trim();
    }
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

  String _blockerLabel(String reason) {
    switch (reason.trim()) {
      case 'no_tasks':
        return '没有任务';
      case 'waiting_user':
        return '等待用户确认';
      case 'paused':
        return '任务已暂停';
      case 'failed':
        return '存在失败任务';
      case 'blocked_dependencies':
        return '依赖任务尚未完成';
      case 'no_runnable_task':
        return '没有可运行任务';
      default:
        return reason.trim().isEmpty ? '无' : reason.trim();
    }
  }

  String _schedulerActionLabel(String action) {
    switch (action.trim()) {
      case 'dispatch_batch':
        return '可继续运行';
      case 'await_user':
        return '等待你处理';
      case 'await_user_resume':
        return '等待点击继续';
      case 'pause_for_review':
        return '需复核后继续';
      case 'pause_for_failure':
        return '需处理失败任务';
      case 'resume_run':
        return '可恢复运行';
      case 'start_new_run':
        return '可新建运行';
      case 'finish_run':
        return '可收尾';
      case 'stop_run':
        return '将停止';
      case 'read_only':
        return '只读查看';
      case 'disabled':
        return '未启用后台';
      default:
        return action.trim().isEmpty ? '空闲' : action.trim();
    }
  }

  String _workerStateLabel(String state) {
    switch (state.trim()) {
      case 'ready':
        return '可运行';
      case 'blocked':
        return '受阻';
      case 'paused':
        return '已暂停';
      case 'finished':
        return '已结束';
      case 'disabled':
        return '未启用';
      case 'stopped':
        return '已停止';
      default:
        return state.trim().isEmpty ? '空闲' : state.trim();
    }
  }
}
