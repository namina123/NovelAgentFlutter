import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskRunOptionService {
  JsonMap normalizeOptions(JsonMap options) {
    // 中文注释: 运行选项规范化在 core 里完成，让 GUI 和 CLI 共用一致的步数和时长限制。
    return <String, Object?>{
      'run_id': ValueReaders.stringValue(options['run_id']),
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
      'resume_after_crash': ValueReaders.boolValue(
        options['resume_after_crash'],
        true,
      ),
    };
  }
}
