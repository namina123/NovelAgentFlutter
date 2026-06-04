import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_controller_profile_service.dart';

class LongTaskFinishDispositionService {
  LongTaskFinishDispositionService({
    required LongTaskControllerProfileService profileService,
  }) : _profileService = profileService;

  final LongTaskControllerProfileService _profileService;

  JsonMap finishDisposition(
    String stopReason,
    int stepsRun, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 结束归因只负责给宿主一个终态建议，不直接碰 record 或任务文件。
    var reason = stopReason.trim();
    final profile = _profileService.controllerProfile(
      ValueReaders.stringValue(options['mode']),
      options: options,
    );
    if (reason.isEmpty) {
      reason = stepsRun >= ValueReaders.intValue(profile['max_steps'], 1)
          ? 'max_steps'
          : 'stopped';
    }
    return <String, Object?>{
      'ok': reason != 'step_failed',
      'reason': reason,
      'note': ValueReaders.stringValue(
        options['stop_note'],
        _defaultNoteForReason(reason),
      ),
      'record_action': _reasonShouldPause(reason) ? 'pause' : 'finish',
      'terminal_reason': reason == 'manual_stop'
          ? 'manual_stop'
          : (reason == 'step_failed' ? 'step_failed' : 'completed'),
      'queue_status_reason': reason,
    };
  }

  bool _reasonShouldPause(String reason) {
    // 中文注释: 需要暂停而非彻底收尾的原因集中维护，避免散落硬编码。
    return const <String>{
      'waiting_user',
      'waiting_user_checkpoint',
      'waiting_user_choice',
      'manual_pause',
      'failed_task',
      'blocked_dependencies',
      'checkpoint_reached',
      'no_tool_output',
      'single_step_completed',
      'supervised_chapter_completed',
      'planning_completed',
      'sample_completed',
      'step_failed',
      'delivery_repair_required',
      'delivery_manual_attention',
      'delivery_waiting_user_choice',
      'max_steps',
      'max_seconds',
      'record_missing',
      'stale_running_task',
    }.contains(reason);
  }

  String _defaultNoteForReason(String reason) {
    // 中文注释: 结束说明在 core 内提供默认语义，UI/CLI 可以直接复用或覆盖。
    switch (reason) {
      case 'max_steps':
        return '已达到本次运行的最大步数，长任务已暂停，可稍后继续。';
      case 'max_seconds':
        return '已达到本次运行的最长时间限制，长任务已暂停，可稍后继续。';
      case 'no_runnable_task':
        return '当前没有依赖满足且处于 queued/retrying 的任务。';
      case 'manual_stop':
        return '用户请求停止长任务。';
      case 'step_failed':
        return '任务单步执行失败，长任务已暂停等待重试、跳过或人工修复。';
      case 'delivery_repair_required':
        return '章节交付状态要求先进入 repair/recovery，长任务已暂停。';
      case 'delivery_manual_attention':
        return '章节交付状态要求人工介入，长任务已暂停。';
      case 'delivery_waiting_user_choice':
        return '章节交付状态正在等待用户确认，长任务已暂停。';
      default:
        return '长任务已停止。';
    }
  }
}
