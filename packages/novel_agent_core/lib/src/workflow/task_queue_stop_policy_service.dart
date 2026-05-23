import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_queue_option_service.dart';
import 'task_runtime_constants.dart';

class TaskQueueStopPolicyService {
  TaskQueueStopPolicyService({required TaskQueueOptionService optionService})
    : _optionService = optionService;

  final TaskQueueOptionService _optionService;

  JsonMap stopAfterStep(
    JsonMap result,
    JsonMap taskAfterStep, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 单步停止决策只给宿主一个刹车建议，不在这里修改任务或运行记录。
    final cleanOptions = _optionService.normalizeOptions(options);
    if (!ValueReaders.boolValue(result['ok'])) {
      return <String, Object?>{
        'stop': true,
        'reason': 'step_failed',
        'note': ValueReaders.stringValue(result['error'], '任务单步执行失败。'),
      };
    }
    final response = ValueReaders.mapValue(result['response']);
    if (ValueReaders.boolValue(response['waiting_for_user_choice']) &&
        ValueReaders.boolValue(cleanOptions['stop_on_user_choice'], true)) {
      return <String, Object?>{
        'stop': true,
        'reason': 'waiting_user_choice',
        'note': '模型正在等待用户选择，队列已暂停。',
      };
    }
    final statusAfter = ValueReaders.stringValue(taskAfterStep['status']);
    if (statusAfter == TaskRuntimeConstants.statusWaitingUser &&
        ValueReaders.boolValue(cleanOptions['stop_on_waiting_user'], true)) {
      return <String, Object?>{
        'stop': true,
        'reason': 'waiting_user_checkpoint',
        'note': '任务进入等待用户确认状态，队列已暂停。',
      };
    }
    final outputPaths = ValueReaders.stringList(result['output_paths']);
    if (outputPaths.isEmpty &&
        ValueReaders.boolValue(cleanOptions['stop_on_no_output'], true)) {
      return <String, Object?>{
        'stop': true,
        'reason': 'no_tool_output',
        'note': '本步没有检测到工具写入路径，队列已暂停以等待人工确认。',
      };
    }
    return const <String, Object?>{'stop': false, 'reason': '', 'note': ''};
  }

  String statusForReason(String reason) {
    // 中文注释: 停止原因到运行状态的映射集中在这里，方便后续替换成更细分状态集。
    if (<String>['step_failed', 'run_failed'].contains(reason)) {
      return 'failed';
    }
    if (<String>['max_steps', 'no_runnable_task'].contains(reason)) {
      return 'completed';
    }
    return 'stopped';
  }

  List<String> toolNamesFromResponse(JsonMap response) {
    // 中文注释: 队列记录只需要轻量工具名摘要，不需要保存完整大响应。
    final result = <String>[];
    for (final rawCall in ValueReaders.objectList(response['tool_calls'])) {
      final call = ValueReaders.mapValue(rawCall);
      final name = ValueReaders.stringValue(call['name']).trim();
      if (name.isNotEmpty && !result.contains(name)) {
        result.add(name);
      }
    }
    return result;
  }
}
