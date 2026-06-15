import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_checkpoint_cadence_policy_service.dart';
import 'long_task_covered_source_task_service.dart';
import 'long_task_controller_profile_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_sample_readiness_service.dart';
import 'long_task_task_summary_service.dart';
import 'long_task_unattended_strategy_service.dart';
import 'task_runtime_constants.dart';
import 'task_selection_service.dart';

class LongTaskNextBatchPlanService {
  LongTaskNextBatchPlanService({
    required LongTaskModeService modeService,
    required LongTaskControllerProfileService profileService,
    required LongTaskUnattendedStrategyService unattendedStrategyService,
    required LongTaskTaskSummaryService taskSummaryService,
    required TaskSelectionService taskSelectionService,
    LongTaskCheckpointCadencePolicyService? checkpointCadencePolicyService,
    LongTaskCoveredSourceTaskService? coveredSourceTaskService,
    LongTaskSampleReadinessService? sampleReadinessService,
  }) : _modeService = modeService,
       _profileService = profileService,
       _unattendedStrategyService = unattendedStrategyService,
       _taskSummaryService = taskSummaryService,
       _taskSelectionService = taskSelectionService,
       _coveredSourceTaskService =
           coveredSourceTaskService ?? const LongTaskCoveredSourceTaskService(),
       _sampleReadinessService =
           sampleReadinessService ?? const LongTaskSampleReadinessService(),
       _checkpointCadencePolicyService =
           checkpointCadencePolicyService ??
           const LongTaskCheckpointCadencePolicyService();

  final LongTaskModeService _modeService;
  final LongTaskControllerProfileService _profileService;
  final LongTaskUnattendedStrategyService _unattendedStrategyService;
  final LongTaskTaskSummaryService _taskSummaryService;
  final TaskSelectionService _taskSelectionService;
  final LongTaskCoveredSourceTaskService _coveredSourceTaskService;
  final LongTaskSampleReadinessService _sampleReadinessService;
  final LongTaskCheckpointCadencePolicyService _checkpointCadencePolicyService;

  JsonMap nextBatchPlan(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 批次规划把长任务从“可表达”推进到“可调度”，但仍只产出纯合同。
    final mode = _modeFromRecordTasksOptions(record, tasks, options);
    final profile = _profileService.controllerProfile(mode, options: options);
    final strategy = _unattendedStrategyService.unattendedStrategy(
      record,
      tasks,
      options: options,
    );
    final cadence = _checkpointCadencePolicyService.policyForRuntime(
      mode,
      record: record,
      options: options,
      controllerProfile: profile,
    );
    final sortedTasks = _taskSelectionService.sortTasks(tasks);
    final base = _baseResult(mode, sortedTasks, profile, strategy, cadence.toJson());

    if (ValueReaders.boolValue(options['stop_requested'])) {
      return <String, Object?>{
        ...base,
        'action': 'stop',
        'reason': 'manual_stop',
        'note': '用户请求停止长任务。',
      };
    }
    if (ValueReaders.boolValue(record['pause_requested']) ||
        ValueReaders.boolValue(options['pause_requested']) ||
        ValueReaders.stringValue(
              record['status'],
              TaskRuntimeConstants.statusRunning,
            ) ==
            TaskRuntimeConstants.statusPaused) {
      return <String, Object?>{
        ...base,
        'action': 'pause',
        'reason': 'manual_pause',
        'note': '长任务已暂停，可稍后从运行记录恢复。',
      };
    }
    if (sortedTasks.isEmpty) {
      return <String, Object?>{
        ...base,
        'action': 'wait_user',
        'reason': 'no_tasks',
        'note': '当前长任务没有任务文件。',
      };
    }

    final failed = _coveredSourceTaskService.firstUncoveredTaskByStatus(
      sortedTasks,
      TaskRuntimeConstants.statusFailed,
    );
    if (failed.isNotEmpty &&
        ValueReaders.boolValue(profile['pause_on_failed_task'], true)) {
      return <String, Object?>{
        ...base,
        'action': 'pause',
        'reason': 'failed_task',
        'note': '检测到失败任务，暂停等待重试、跳过或人工修复。',
        'task': _taskSummaryService.taskSummary(failed),
      };
    }

    final succeeded = _succeededMap(sortedTasks);
    final waiting = _readyWaitingTask(sortedTasks, succeeded);
    if (waiting.isNotEmpty &&
        ValueReaders.boolValue(profile['stop_on_user_checkpoint'], true)) {
      return <String, Object?>{
        ...base,
        'action': 'wait_user',
        'reason': 'waiting_user_checkpoint',
        'note': '长任务到达人工检查点，等待用户确认后继续。',
        'task': _taskSummaryService.taskSummary(waiting),
      };
    }

    final maxSteps = cadence.effectiveBatchSteps.clamp(1, 80);
    final plannedTasks = <JsonMap>[];
    final blockers = <JsonMap>[];
    var boundaryReason = '';
    final optimisticSucceeded = <String, bool>{...succeeded};
    for (final task in sortedTasks) {
      final status = ValueReaders.stringValue(task['status']).trim();
      if (_isReadyCheckpointTask(task, status) &&
          _missingDependencies(task, optimisticSucceeded).isEmpty) {
        if (plannedTasks.isEmpty) {
          return <String, Object?>{
            ...base,
            'action': 'wait_user',
            'reason': 'checkpoint_task',
            'note': '下一任务是人工检查点。',
            'task': _taskSummaryService.taskSummary(task),
          };
        }
        boundaryReason = 'checkpoint_ahead';
        break;
      }
      if (!TaskRuntimeConstants.runnableStatuses.contains(status)) {
        continue;
      }
      if (_sampleReadinessService.isSampleTask(task) &&
          !_sampleReadinessService.hasSatisfiedReadinessCheckpoint(
            task,
            sortedTasks,
          )) {
        blockers.add(<String, Object?>{
          'reason': 'sample_readiness_not_confirmed',
          'note': '样章仍缺少资料收集/风格/大纲确认检查点，当前不能派发。',
          'task': _taskSummaryService.taskSummary(task),
        });
        continue;
      }
      final missing = _missingDependencies(task, optimisticSucceeded);
      if (missing.isNotEmpty) {
        blockers.add(<String, Object?>{
          'reason': 'blocked_dependencies',
          'note': '依赖尚未完成。',
          'task': _taskSummaryService.taskSummary(task),
          'missing_dependencies': missing,
        });
        continue;
      }
      plannedTasks.add(task);
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (taskId.isNotEmpty) {
        optimisticSucceeded[taskId] = true;
      }
      boundaryReason = _boundaryReasonAfterTask(
        mode,
        task,
        plannedTasks.length,
      );
      if (boundaryReason.isNotEmpty || plannedTasks.length >= maxSteps) {
        if (boundaryReason.isEmpty) {
          boundaryReason =
              cadence.tighteningApplied &&
                  cadence.effectiveBatchSteps < cadence.baseBatchSteps
              ? 'risk_tightened_batch'
              : 'max_steps';
        }
        break;
      }
    }

    if (plannedTasks.isEmpty) {
      if (_allTasksTerminal(sortedTasks)) {
        return <String, Object?>{
          ...base,
          'action': 'finish',
          'reason': 'all_tasks_terminal',
          'note': '长任务队列已全部进入终态。',
        };
      }
      final blockerReason = blockers.isEmpty
          ? 'blocked_dependencies'
          : ValueReaders.stringValue(
              blockers.first['reason'],
              'blocked_dependencies',
            );
      final blockerNote = blockers.isEmpty
          ? '当前没有依赖满足的可运行任务。'
          : ValueReaders.stringValue(
              blockers.first['note'],
              '当前没有依赖满足的可运行任务。',
            );
      return <String, Object?>{
        ...base,
        'action': 'wait_user',
        'reason': blockerReason,
        'note': blockerNote,
        'blockers': blockers,
      };
    }

    final summaries = plannedTasks
        .map(_taskSummaryService.taskSummary)
        .toList(growable: false);
    return <String, Object?>{
      ...base,
      'action': 'dispatch_batch',
      'reason': 'ready_batch',
      'note': '已生成下一批可执行任务，宿主应逐步调用模型并每步落盘。',
      'tasks': summaries,
      'task_ids': summaries
          .map((task) => ValueReaders.stringValue(task['id']).trim())
          .where((taskId) => taskId.isNotEmpty)
          .toList(growable: false),
      'task_paths': summaries
          .map((task) => ValueReaders.stringValue(task['relative_path']).trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
      'recommended_max_steps': summaries.length,
      'max_seconds': cadence.effectiveBatchSeconds,
      'optimistic_dependency_simulation': true,
      'boundary_reason': boundaryReason,
      'boundary_note': boundaryReason.isEmpty
          ? '本批次按控制器上限停止。'
          : _boundaryNote(boundaryReason),
      'should_accept_guidance': ValueReaders.boolValue(
        profile['allow_stream_guidance'],
        true,
      ),
      'guidance_delivery':
          ValueReaders.boolValue(profile['allow_stream_guidance'], true)
          ? 'before_next_tool_call'
          : 'disabled',
      'sub_agent_guidance': 'disabled',
    };
  }

  JsonMap _baseResult(
    String mode,
    List<JsonMap> tasks,
    JsonMap profile,
    JsonMap strategy,
    JsonMap checkpointCadence,
  ) {
    // 中文注释: 批次规划返回值的公共骨架集中在这里，确保所有出口字段稳定一致。
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'mode': mode,
      'strategy': strategy,
      'checkpoint_cadence': checkpointCadence,
      'status_counts': _statusCounts(tasks),
      'recommended_max_steps': ValueReaders.intValue(
        checkpointCadence['effective_batch_steps'],
        ValueReaders.intValue(profile['max_steps'], 1),
      ),
      'max_seconds': ValueReaders.intValue(
        checkpointCadence['effective_batch_seconds'],
        ValueReaders.intValue(profile['max_seconds'], 7200),
      ),
      'tasks': <Object?>[],
      'task_ids': <Object?>[],
      'task_paths': <Object?>[],
      'boundary_reason': '',
      'boundary_note': '',
    };
  }

  String _modeFromRecordTasksOptions(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
  ) {
    // 中文注释: 批次规划要和无人值守策略使用同一模式解析顺序，避免前后判断打架。
    var mode = ValueReaders.stringValue(options['mode']).trim();
    if (mode.isEmpty) {
      mode = ValueReaders.stringValue(record['mode']).trim();
    }
    if (mode.isEmpty) {
      for (final rawTask in tasks) {
        final task = ValueReaders.mapValue(rawTask);
        mode = ValueReaders.stringValue(task['mode']).trim();
        if (mode.isNotEmpty) {
          break;
        }
      }
    }
    return _modeService.normalizeMode(mode);
  }

  JsonMap _statusCounts(List<JsonMap> tasks) {
    // 中文注释: 这里按批次视角重算状态统计，保证结果反映排序过滤后的有效任务集。
    final counts = <String, Object?>{};
    for (final task in tasks) {
      var status = ValueReaders.stringValue(task['status']).trim();
      if (status.isEmpty) {
        status = 'unknown';
      }
      counts[status] = ValueReaders.intValue(counts[status]) + 1;
    }
    return counts;
  }

  Map<String, bool> _succeededMap(List<JsonMap> tasks) {
    // 中文注释: 批次规划通过乐观成功模拟依赖解锁，这里先收敛出已成功索引。
    final result = <String, bool>{};
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        final taskId = ValueReaders.stringValue(task['id']).trim();
        if (taskId.isNotEmpty) {
          result[taskId] = true;
        }
      }
    }
    return result;
  }

  List<String> _missingDependencies(JsonMap task, Map<String, bool> succeeded) {
    // 中文注释: 缺失依赖保留为字符串列表，便于 GUI/CLI 解释“为什么没有派发”。
    final result = <String>[];
    for (final dependency in ValueReaders.stringList(task['depends_on'])) {
      if (dependency.isNotEmpty && !(succeeded[dependency] ?? false)) {
        result.add(dependency);
      }
    }
    return result;
  }

  JsonMap _readyWaitingTask(List<JsonMap> tasks, Map<String, bool> succeeded) {
    // 中文注释: 只有依赖满足的 waiting_user 任务才算真正轮到用户处理。
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['status']) ==
              TaskRuntimeConstants.statusWaitingUser &&
          _missingDependencies(task, succeeded).isEmpty &&
          !_coveredSourceTaskService.isCoveredBySucceededDependent(
            task,
            tasks,
          )) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  bool _isCheckpointTask(JsonMap task) {
    // 中文注释: 检查点在迁移期可能来自 task_type 或 metadata.stage，两者都兼容。
    return ValueReaders.stringValue(task['task_type']).trim() == 'checkpoint' ||
        ValueReaders.stringValue(
              ValueReaders.mapValue(task['metadata'])['stage'],
            ).trim() ==
            'checkpoint';
  }

  bool _isReadyCheckpointTask(JsonMap task, String status) {
    // 中文注释: 只有仍待处理的 checkpoint 才能阻断批次，历史已成功检查点必须被跳过。
    if (!_isCheckpointTask(task)) {
      return false;
    }
    return status == TaskRuntimeConstants.statusQueued ||
        status == TaskRuntimeConstants.statusWaitingUser;
  }

  bool _allTasksTerminal(List<JsonMap> tasks) {
    // 中文注释: 全终态判断直接服务于 finish 分支，不参与依赖计算。
    if (tasks.isEmpty) {
      return false;
    }
    for (final task in tasks) {
      if (!TaskRuntimeConstants.terminalStatuses.contains(
        ValueReaders.stringValue(task['status']),
      )) {
        return false;
      }
    }
    return true;
  }

  String _boundaryReasonAfterTask(String mode, JsonMap task, int plannedCount) {
    // 中文注释: 安全边界原因按模式和任务阶段决定，是批次截断的核心规则。
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    final stage = ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['stage'],
    ).trim();
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic &&
        plannedCount >= 1) {
      return 'single_step_boundary';
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue &&
        taskType == 'chapter') {
      return 'chapter_review_boundary';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        taskType == 'planning') {
      return 'planning_review_boundary';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel && stage == 'sample') {
      return 'sample_review_boundary';
    }
    return '';
  }

  String _boundaryNote(String reason) {
    // 中文注释: 边界说明是给用户和宿主看的文本，不和状态判断耦在一起。
    switch (reason) {
      case 'single_step_boundary':
        return '单章原子任务每次只执行一个模型单步。';
      case 'chapter_review_boundary':
        return '监督式章节队列每章完成后回到用户确认。';
      case 'planning_review_boundary':
        return '种子长篇完成规划后需要用户确认总纲和任务分解。';
      case 'sample_review_boundary':
        return '样章完成后需要用户确认口吻、节奏和入口。';
      case 'checkpoint_ahead':
        return '下一批前方存在人工检查点，先把当前安全批次跑完。';
      case 'risk_tightened_batch':
        return '最近结构化风险升高，已自动缩短本轮批次并收紧节奏。';
      default:
        return '本批次到达安全边界。';
    }
  }
}
