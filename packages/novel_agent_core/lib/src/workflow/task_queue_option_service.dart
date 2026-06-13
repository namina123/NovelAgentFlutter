import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_execution_policy.dart';
import 'task_queue_constants.dart';

class TaskQueueOptionService {
  JsonMap normalizeOptions([JsonMap options = const <String, Object?>{}]) {
    // 中文注释: 队列运行参数在这里统一收敛，先故意保守，避免无人值守时一次跑过多任务。
    final maxSteps = _clampInt(
      ValueReaders.intValue(
        options['max_steps'],
        TaskQueueConstants.defaultMaxSteps,
      ),
      1,
      TaskQueueConstants.maxAllowedSteps,
    );
    final maxSeconds = _clampInt(
      ValueReaders.intValue(
        options['max_seconds'],
        TaskQueueConstants.defaultMaxSeconds,
      ),
      30,
      7200,
    );
    return <String, Object?>{
      'max_steps': maxSteps,
      'max_seconds': maxSeconds,
      'runtime_baseline_id': ValueReaders.stringValue(
        options['runtime_baseline_id'],
      ),
      'runtime_mode': ValueReaders.stringValue(options['runtime_mode']),
      'agent_id': ValueReaders.stringValue(
        options['agent_id'],
        'default_generalist',
      ),
      'auto_start_on_create': _boolOption(
        options,
        'auto_start_on_create',
        false,
      ),
      'unattended': _boolOption(options, 'unattended', false),
      'auto_advance_chapters': _boolOption(
        options,
        'auto_advance_chapters',
        false,
      ),
      'keep_alive_across_project_switch': _boolOption(
        options,
        'keep_alive_across_project_switch',
        false,
      ),
      'stop_on_waiting_user': _boolOption(
        options,
        'stop_on_waiting_user',
        true,
      ),
      'stop_on_user_choice': _boolOption(options, 'stop_on_user_choice', true),
      'stop_on_no_output': _boolOption(options, 'stop_on_no_output', true),
      'allow_independent_tasks_after_checkpoint': _boolOption(
        options,
        'allow_independent_tasks_after_checkpoint',
        false,
      ),
      'expression_constraint_policy_mode':
          _expressionConstraintPolicyMode(options),
    };
  }

  String _expressionConstraintPolicyMode(JsonMap options) {
    final value = ValueReaders.stringValue(
      options['expression_constraint_policy_mode'],
      ValueReaders.stringValue(options['expressionConstraintPolicyMode']),
    ).trim().toLowerCase();
    return ExpressionConstraintExecutionPolicyModes.knownValues.contains(value)
        ? value
        : '';
  }

  bool _boolOption(JsonMap options, String key, bool defaultValue) {
    // 中文注释: 显式 false 必须被保留，不能被默认值重新覆盖。
    if (!options.containsKey(key)) {
      return defaultValue;
    }
    return ValueReaders.boolValue(options[key], defaultValue);
  }

  int _clampInt(int value, int min, int max) {
    // 中文注释: 队列选项边界裁剪放本地实现，保持 pure Dart core 可独立运行。
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
