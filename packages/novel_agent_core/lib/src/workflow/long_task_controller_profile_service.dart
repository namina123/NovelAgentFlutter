import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_chapter_gate_policy_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_mode_strategy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskControllerProfileService {
  LongTaskControllerProfileService({
    required LongTaskModeService modeService,
    required LongTaskModeStrategyService strategyService,
    LongTaskChapterGatePolicyService? chapterGatePolicyService,
  }) : _modeService = modeService,
       _strategyService = strategyService,
       _chapterGatePolicyService =
           chapterGatePolicyService ?? const LongTaskChapterGatePolicyService();

  final LongTaskModeService _modeService;
  final LongTaskModeStrategyService _strategyService;
  final LongTaskChapterGatePolicyService _chapterGatePolicyService;

  JsonMap controllerProfile(
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 控制器画像集中描述各模式的运行边界，供调度、运行中心和宿主合同复用。
    final cleanMode = _modeService.normalizeMode(mode);
    final profile = _profileBase(cleanMode);
    final runtimeBaselineId = _runtimeBaselineId(options);
    profile['agent_id'] = ValueReaders.stringValue(
      options['agent_id'],
      'default_generalist',
    );
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      profile['max_steps'] = 4;
      profile['max_seconds'] = 10800;
      profile['checkpoint_policy'] = 'after_chapter_gate';
      profile['stop_on_waiting_user'] = false;
      profile['stop_on_user_checkpoint'] = false;
      profile['description'] = '逐章协作自动推进基准会在每章后先走共享审稿/返工闸门，通过后再自动解锁下一章。';
    } else if (cleanMode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      profile['max_steps'] = 1;
      profile['max_seconds'] = 1800;
      profile['stop_after_successful_single_step'] = true;
      profile['checkpoint_policy'] = 'after_single_step';
      profile['description'] = '单章原子任务只跑一个模型单步，完成后交给用户确认。';
    } else if (cleanMode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      profile['max_steps'] = 1;
      profile['max_seconds'] = 3600;
      profile['checkpoint_policy'] = 'after_each_chapter';
      profile['description'] = '监督式章节队列每次只推进一章或一个检查点，避免无人值守连写。';
    } else if (cleanMode == TaskRuntimeConstants.modeSeedToFullNovel) {
      profile['max_steps'] = 2;
      profile['max_seconds'] = 7200;
      profile['checkpoint_policy'] = 'planning_outline_sample';
      profile['description'] = '种子长篇先规划与样章确认，确认后再允许章节队列分段推进。';
    } else {
      profile['max_steps'] = 3;
      profile['max_seconds'] = 7200;
      profile['checkpoint_policy'] = 'interval_manual';
      profile['description'] = '人定大纲模式按章纲推进，在间隔检查点和用户选择处停下。';
    }
    return _mergeRuntimeOptions(profile, options);
  }

  JsonMap _profileBase(String mode) {
    // 中文注释: 这里给所有模式提供统一基线，避免各分支重复拼公共字段。
    return <String, Object?>{
      'ok': true,
      'mode': mode,
      'strategy': _strategyService.modeStrategy(mode),
      'max_seconds': 7200,
      'stop_on_waiting_user': true,
      'stop_on_user_choice': true,
      'stop_on_no_output': true,
      'stop_on_user_checkpoint': true,
      'pause_on_failed_task': true,
      'allow_stream_guidance': true,
      'safe_after_crash': true,
      'stop_after_successful_single_step': false,
      'checkpoint_policy': 'manual',
    };
  }

  JsonMap _mergeRuntimeOptions(JsonMap profile, JsonMap options) {
    // 中文注释: 宿主可覆写步数、时长和若干开关，但仍要收敛在安全范围内。
    final result = ValueReaders.deepCopyMap(profile);
    result['max_steps'] = ValueReaders.intValue(
      options['max_steps'],
      ValueReaders.intValue(profile['max_steps'], 1),
    ).clamp(1, 80);
    result['max_seconds'] = ValueReaders.intValue(
      options['max_seconds'],
      ValueReaders.intValue(profile['max_seconds'], 7200),
    ).clamp(30, 86400);
    result['agent_id'] = ValueReaders.stringValue(
      options['agent_id'],
      ValueReaders.stringValue(profile['agent_id'], 'default_generalist'),
    );
    result['runtime_baseline_id'] = _runtimeBaselineId(options);
    result['stop_on_waiting_user'] = ValueReaders.boolValue(
      options['stop_on_waiting_user'],
      ValueReaders.boolValue(profile['stop_on_waiting_user'], true),
    );
    result['stop_on_user_choice'] = ValueReaders.boolValue(
      options['stop_on_user_choice'],
      ValueReaders.boolValue(profile['stop_on_user_choice'], true),
    );
    result['stop_on_no_output'] = ValueReaders.boolValue(
      options['stop_on_no_output'],
      ValueReaders.boolValue(profile['stop_on_no_output'], true),
    );
    result['stop_on_user_checkpoint'] = ValueReaders.boolValue(
      options['stop_on_user_checkpoint'],
      ValueReaders.boolValue(profile['stop_on_user_checkpoint'], true),
    );
    result['pause_on_failed_task'] = ValueReaders.boolValue(
      options['pause_on_failed_task'],
      ValueReaders.boolValue(profile['pause_on_failed_task'], true),
    );
    result['allow_stream_guidance'] = ValueReaders.boolValue(
      options['allow_stream_guidance'],
      ValueReaders.boolValue(profile['allow_stream_guidance'], true),
    );
    result['safe_after_crash'] = ValueReaders.boolValue(
      options['safe_after_crash'],
      ValueReaders.boolValue(profile['safe_after_crash'], true),
    );
    result['stop_after_successful_single_step'] = ValueReaders.boolValue(
      options['stop_after_successful_single_step'],
      ValueReaders.boolValue(
        profile['stop_after_successful_single_step'],
        false,
      ),
    );
    return result;
  }

  String _runtimeBaselineId(JsonMap options) {
    final explicit = ValueReaders.stringValue(
      options['runtime_baseline_id'],
    ).trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return ValueReaders.stringValue(
      _chapterGatePolicyService.chapterGatePolicy(const <String, Object?>{
        'task_type': 'chapter',
      }, options: options)['runtime_baseline_id'],
    ).trim();
  }
}
