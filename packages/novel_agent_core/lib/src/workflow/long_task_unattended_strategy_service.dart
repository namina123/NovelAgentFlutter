import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_controller_profile_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_mode_strategy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskUnattendedStrategyService {
  LongTaskUnattendedStrategyService({
    required LongTaskModeService modeService,
    required LongTaskModeStrategyService strategyService,
    required LongTaskControllerProfileService profileService,
  }) : _modeService = modeService,
       _strategyService = strategyService,
       _profileService = profileService;

  final LongTaskModeService _modeService;
  final LongTaskModeStrategyService _strategyService;
  final LongTaskControllerProfileService _profileService;

  JsonMap unattendedStrategy(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 无人值守策略描述运行边界与宿主职责，本身不派发任何执行动作。
    final mode = _modeFromRecordTasksOptions(record, tasks, options);
    final profile = _profileService.controllerProfile(mode, options: options);
    final maxSteps = ValueReaders.intValue(
      profile['max_steps'],
      1,
    ).clamp(1, 80);
    final maxSeconds = ValueReaders.intValue(
      profile['max_seconds'],
      7200,
    ).clamp(30, 86400);
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'mode': mode,
      'autonomy_level': _autonomyLevelForMode(mode),
      'mode_strategy': _strategyService.modeStrategy(mode),
      'controller_profile': profile,
      'default_batch_steps': maxSteps,
      'max_seconds': maxSeconds,
      'requires_host_network': true,
      'requires_host_filesystem': true,
      'snapshot_after_each_step': true,
      'resume_after_crash': ValueReaders.boolValue(
        profile['safe_after_crash'],
        true,
      ),
      'main_agent_guidance':
          ValueReaders.boolValue(profile['allow_stream_guidance'], true)
          ? 'before_next_tool_call'
          : 'disabled',
      'sub_agent_midrun_input': 'disabled',
      'tool_execution_boundary': 'host_only',
      'task_count': tasks.length,
      'status_counts': _statusCounts(tasks),
      'host_controls': const <Object?>[
        'pause',
        'stop',
        'resume',
        'retry_failed',
        'skip_failed',
      ],
      'hard_stop_reasons': const <Object?>[
        'manual_pause',
        'manual_stop',
        'waiting_user_checkpoint',
        'waiting_user_choice',
        'step_failed',
        'no_tool_output',
        'max_steps',
        'max_seconds',
      ],
    };
  }

  String _modeFromRecordTasksOptions(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
  ) {
    // 中文注释: 无人值守策略需要在无 record 或无 mode 时仍能从任务列表恢复模式。
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

  JsonMap _statusCounts(List<Object?> tasks) {
    // 中文注释: 状态计数供运行中心、调度摘要和测试共同使用，保持在策略层统一生成。
    final counts = <String, Object?>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      var status = ValueReaders.stringValue(task['status']).trim();
      if (status.isEmpty) {
        status = 'unknown';
      }
      counts[status] = ValueReaders.intValue(counts[status]) + 1;
    }
    return counts;
  }

  String _autonomyLevelForMode(String mode) {
    // 中文注释: 自主级别是宿主 UI/CLI 的解释信息，不影响真实状态机。
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return 'manual_single_step';
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 'supervised_chapter_step';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 'milestone_gated';
    }
    return 'bounded_unattended';
  }
}
