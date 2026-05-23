import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskBatchOptionService {
  JsonMap batchLimitedOptions(
    JsonMap batchPlan, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 宿主每轮派发前都需要一份被批次边界收紧过的运行参数，这里统一生成。
    final nextOptions = ValueReaders.deepCopyMap(options);
    if (!ValueReaders.boolValue(batchPlan['ok'])) {
      return nextOptions;
    }
    if (ValueReaders.stringValue(batchPlan['action']) != 'dispatch_batch') {
      nextOptions['max_steps'] = 1;
      nextOptions['long_task_batch_action'] = ValueReaders.stringValue(
        batchPlan['action'],
        'wait_user',
      );
      nextOptions['long_task_batch_reason'] = ValueReaders.stringValue(
        batchPlan['reason'],
      );
      return nextOptions;
    }
    nextOptions['max_steps'] = ValueReaders.intValue(
      batchPlan['recommended_max_steps'],
      ValueReaders.intValue(options['max_steps'], 1),
    ).clamp(1, 80);
    nextOptions['max_seconds'] = ValueReaders.intValue(
      batchPlan['max_seconds'],
      ValueReaders.intValue(options['max_seconds'], 7200),
    ).clamp(30, 86400);
    nextOptions['long_task_batch_action'] = 'dispatch_batch';
    nextOptions['long_task_batch_reason'] = ValueReaders.stringValue(
      batchPlan['boundary_reason'],
      'ready_batch',
    );
    return nextOptions;
  }
}
