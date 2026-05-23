import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunPlanIdentityService {
  LongTaskRunPlanIdentityService({required LongTaskModeService modeService})
    : _modeService = modeService;

  final LongTaskModeService _modeService;

  JsonMap planFromTasks(
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 运行入口需要先从任务池和显式参数里提炼出最小计划身份，不依赖宿主存储。
    var mode = ValueReaders.stringValue(options['mode']).trim();
    var planId = ValueReaders.stringValue(options['plan_id']).trim();
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (mode.isEmpty) {
        mode = ValueReaders.stringValue(task['mode']).trim();
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (planId.isEmpty) {
        planId = ValueReaders.stringValue(metadata['plan_id']).trim();
      }
      if (mode.isNotEmpty && planId.isNotEmpty) {
        break;
      }
    }
    if (mode.isEmpty) {
      mode = TaskRuntimeConstants.modeSupervisedChapterQueue;
    }
    if (planId.isEmpty) {
      planId = 'loose_long_task';
    }
    return <String, Object?>{
      'id': planId,
      'mode': _modeService.normalizeMode(mode),
    };
  }
}
