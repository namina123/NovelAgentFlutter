import '../common/json_types.dart';
import 'long_task_mode_service.dart';

class LongTaskPlanRecordService {
  LongTaskPlanRecordService({required LongTaskModeService modeService})
    : _modeService = modeService;

  final LongTaskModeService _modeService;

  JsonMap planRecord(
    String planId,
    String mode, {
    JsonMap options = const <String, Object?>{},
    List<Object?> createdTasks = const <Object?>[],
    String createdAt = '',
  }) {
    // 中文注释: 长任务计划记录只描述计划与生成出的任务骨架，不承担落盘与索引职责。
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return <String, Object?>{
      'schema_version': 1,
      'id': planId,
      'mode': _modeService.normalizeMode(mode),
      'options': _safePlanOptions(options),
      'created_tasks': createdTasks,
      'created_at': now,
      'updated_at': now,
    };
  }

  JsonMap _safePlanOptions(JsonMap options) {
    // 中文注释: 计划记录里的 options 只保留必要字段，并在需要时截断长文本。
    final result = <String, Object?>{};
    for (final key in const <String>[
      'runtime_baseline_id',
      'outline_path',
      'seed_prompt',
      'chapter_count',
      'checkpoint_interval',
    ]) {
      if (!options.containsKey(key)) {
        continue;
      }
      final value = options[key];
      if (value is String && value.length > 1200) {
        result[key] = '${value.substring(0, 1200)}\n......（已截断）';
      } else {
        result[key] = value;
      }
    }
    return result;
  }
}
