import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_controller_profile_service.dart';
import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';

class LongTaskStopAfterStepService {
  LongTaskStopAfterStepService({
    required LongTaskControllerProfileService profileService,
    required LongTaskModeService modeService,
  }) : _profileService = profileService,
       _modeService = modeService;

  final LongTaskControllerProfileService _profileService;
  final LongTaskModeService _modeService;

  JsonMap stopAfterStep(
    JsonMap record,
    JsonMap taskAfterStep,
    JsonMap result, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 单步后停机规则负责把模型结果和任务状态翻译成下一轮调度边界。
    final mode = _modeForRecordTaskOptions(record, taskAfterStep, options);
    final profile = _profileService.controllerProfile(mode, options: options);
    if (!ValueReaders.boolValue(result['ok'])) {
      return _decision(
        true,
        'step_failed',
        ValueReaders.stringValue(result['error'], '任务单步执行失败，已暂停等待处理。'),
        nextStatus: 'paused',
      );
    }

    final response = ValueReaders.mapValue(result['response']);
    if (ValueReaders.boolValue(response['waiting_for_user_choice']) &&
        ValueReaders.boolValue(profile['stop_on_user_choice'], true)) {
      return _decision(
        true,
        'waiting_user_choice',
        '模型正在等待用户选择，长任务已暂停。',
        nextStatus: 'paused',
      );
    }

    final statusAfter = ValueReaders.stringValue(taskAfterStep['status']);
    final taskType = ValueReaders.stringValue(taskAfterStep['task_type']);
    if (statusAfter == TaskRuntimeConstants.statusWaitingUser &&
        ValueReaders.boolValue(profile['stop_on_waiting_user'], true)) {
      return _decision(
        true,
        'waiting_user_checkpoint',
        '任务进入等待用户确认状态，长任务已暂停。',
        nextStatus: 'paused',
      );
    }
    if (_isCheckpointTask(taskAfterStep)) {
      return _decision(
        true,
        'checkpoint_reached',
        '长任务到达人工检查点，等待用户确认后继续。',
        nextStatus: 'paused',
      );
    }

    final outputPaths = ValueReaders.stringList(result['output_paths']);
    if (outputPaths.isEmpty &&
        ValueReaders.boolValue(profile['stop_on_no_output'], true)) {
      return _decision(
        true,
        'no_tool_output',
        '本步没有检测到工具写入路径，长任务已暂停以等待人工确认。',
        nextStatus: 'paused',
      );
    }

    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic &&
        ValueReaders.boolValue(
          profile['stop_after_successful_single_step'],
          true,
        )) {
      return _decision(
        true,
        'single_step_completed',
        '单章原子任务已完成一个模型单步，等待用户确认后处理或标记完成。',
        nextStatus: 'paused',
      );
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue &&
        taskType == 'chapter') {
      return _decision(
        true,
        'supervised_chapter_completed',
        '监督式队列已完成当前章节单步，等待用户检查后继续。',
        nextStatus: 'paused',
      );
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        (taskType == 'planning' || _taskStage(taskAfterStep) == 'sample')) {
      return _decision(
        true,
        taskType == 'planning' ? 'planning_completed' : 'sample_completed',
        taskType == 'planning'
            ? '规划单步已完成，等待用户确认总纲和章节任务。'
            : '样章单步已完成，等待用户确认口吻、节奏和入口。',
        nextStatus: 'paused',
      );
    }
    return _decision(false, '', '');
  }

  String _modeForRecordTaskOptions(
    JsonMap record,
    JsonMap task,
    JsonMap options,
  ) {
    // 中文注释: 模式来源按 options -> record -> task 回退，保持旧项目兼容逻辑。
    var mode = ValueReaders.stringValue(options['mode']).trim();
    if (mode.isEmpty) {
      mode = ValueReaders.stringValue(record['mode']).trim();
    }
    if (mode.isEmpty) {
      mode = ValueReaders.stringValue(task['mode']).trim();
    }
    return _modeService.normalizeMode(mode);
  }

  String _taskStage(JsonMap task) {
    // 中文注释: stage 在 metadata 中维护，这里单独抽出避免分支里反复拆字典。
    return ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['stage'],
    ).trim();
  }

  bool _isCheckpointTask(JsonMap task) {
    // 中文注释: checkpoint 既可能由 task_type 表达，也可能由 metadata.stage 表达。
    return ValueReaders.stringValue(task['task_type']).trim() == 'checkpoint' ||
        _taskStage(task) == 'checkpoint';
  }

  JsonMap _decision(
    bool stop,
    String reason,
    String note, {
    String nextStatus = '',
  }) {
    // 中文注释: 和 loop guard 共用相同结构，便于宿主统一处理暂停和结束分支。
    return <String, Object?>{
      'stop': stop,
      'reason': reason,
      'note': note,
      'long_task_status': nextStatus,
    };
  }
}
