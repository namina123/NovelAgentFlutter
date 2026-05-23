import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_controller_profile_service.dart';

class LongTaskLoopGuardService {
  LongTaskLoopGuardService({
    required LongTaskControllerProfileService profileService,
  }) : _profileService = profileService;

  final LongTaskControllerProfileService _profileService;

  JsonMap loopGuard(
    int stepsRun,
    int elapsedMsec, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 循环守卫只做“这一轮是否该停”的判断，不直接修改运行记录。
    final profile = _profileService.controllerProfile(
      ValueReaders.stringValue(options['mode']),
      options: options,
    );
    final maxSteps = ValueReaders.intValue(profile['max_steps'], 1);
    final maxSeconds = ValueReaders.intValue(profile['max_seconds'], 7200);
    if (ValueReaders.boolValue(options['stop_requested'])) {
      return _decision(
        true,
        'manual_stop',
        '用户请求停止长任务。',
        nextStatus: 'cancelled',
      );
    }
    if (ValueReaders.boolValue(options['pause_requested'])) {
      return _decision(
        true,
        'manual_pause',
        '用户请求暂停长任务。',
        nextStatus: 'paused',
      );
    }
    if (stepsRun >= maxSteps) {
      return _decision(
        true,
        'max_steps',
        '已达到本次运行的最大步数，长任务已暂停，可稍后继续。',
        nextStatus: 'paused',
      );
    }
    if (elapsedMsec > maxSeconds * 1000) {
      return _decision(
        true,
        'max_seconds',
        '已达到本次运行的最长时间限制，长任务已暂停，可稍后继续。',
        nextStatus: 'paused',
      );
    }
    return _decision(false, '', '');
  }

  JsonMap _decision(
    bool stop,
    String reason,
    String note, {
    String nextStatus = '',
  }) {
    // 中文注释: 统一守卫输出合同，便于宿主和测试直接消费。
    return <String, Object?>{
      'stop': stop,
      'reason': reason,
      'note': note,
      'long_task_status': nextStatus,
    };
  }
}
