import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskRunOptionService {
  JsonMap normalizeOptions(JsonMap options) {
    // 中文注释: 运行选项规范化在 core 里完成，让 GUI 和 CLI 共用一致的步数和时长限制。
    return <String, Object?>{
      'run_id': ValueReaders.stringValue(options['run_id']),
      'runtime_baseline_id': ValueReaders.stringValue(
        options['runtime_baseline_id'],
      ),
      'runtime_mode': ValueReaders.stringValue(options['runtime_mode']),
      'agent_id': ValueReaders.stringValue(
        options['agent_id'],
        'default_generalist',
      ),
      'max_steps': ValueReaders.intValue(options['max_steps'], 12).clamp(1, 80),
      'max_seconds': ValueReaders.intValue(
        options['max_seconds'],
        7200,
      ).clamp(30, 86400),
      'stop_on_user_checkpoint': ValueReaders.boolValue(
        options['stop_on_user_checkpoint'],
        true,
      ),
      'stop_on_failed_task': ValueReaders.boolValue(
        options['stop_on_failed_task'],
        true,
      ),
      'allow_stream_guidance': ValueReaders.boolValue(
        options['allow_stream_guidance'],
        true,
      ),
      'safe_after_crash': ValueReaders.boolValue(
        options['safe_after_crash'],
        ValueReaders.boolValue(options['resume_after_crash'], true),
      ),
      'resume_after_crash': ValueReaders.boolValue(
        options['resume_after_crash'],
        true,
      ),
      'auto_retry_failed_task': ValueReaders.boolValue(
        options['auto_retry_failed_task'],
        true,
      ),
      'recovery_retry_budget': ValueReaders.intValue(
        options['recovery_retry_budget'],
        1,
      ).clamp(0, 10),
      'recovery_exhausted_disposition': ValueReaders.stringValue(
        options['recovery_exhausted_disposition'],
        'manual_attention',
      ),
      'auto_start_on_create': ValueReaders.boolValue(
        options['auto_start_on_create'],
        false,
      ),
      'unattended': ValueReaders.boolValue(options['unattended'], false),
      'auto_advance_chapters': ValueReaders.boolValue(
        options['auto_advance_chapters'],
        false,
      ),
      'keep_alive_across_project_switch': ValueReaders.boolValue(
        options['keep_alive_across_project_switch'],
        false,
      ),
    };
  }
}
