import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_delivery_state_statuses.dart';
import 'long_task_writing_execution_signal_service.dart';
import 'task_queue_option_service.dart';
import 'task_runtime_constants.dart';

class TaskQueueStopPolicyService {
  TaskQueueStopPolicyService({
    required TaskQueueOptionService optionService,
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
  }) : _optionService = optionService,
       _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService();

  final TaskQueueOptionService _optionService;
  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;

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
    final writingExecutionSignal = _writingExecutionSignalService
        .signalFromPayload(result: result);
    if (ValueReaders.boolValue(writingExecutionSignal['present']) &&
        ValueReaders.stringValue(writingExecutionSignal['category']) !=
            'success') {
      return <String, Object?>{
        'stop': true,
        'reason': ValueReaders.stringValue(
          writingExecutionSignal['legacy_stop_reason'],
        ),
        'note': ValueReaders.stringValue(
          writingExecutionSignal['note'],
          '共享写作结果要求当前队列暂停。',
        ),
        'writing_execution_category': ValueReaders.stringValue(
          writingExecutionSignal['category'],
        ),
      };
    }
    final deliveryState = ValueReaders.stringValue(
      result['chapter_delivery_state'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(result['execution'])['chapter_delivery_state'],
      ),
    ).trim();
    final deliveryDecision = _deliveryStopDecision(deliveryState);
    if (deliveryDecision.isNotEmpty) {
      return deliveryDecision;
    }
    final informationDecision = _informationStopDecision(result);
    if (informationDecision.isNotEmpty) {
      return informationDecision;
    }
    final outputPaths = ValueReaders.stringList(result['output_paths']);
    if (outputPaths.isEmpty &&
        deliveryState.isEmpty &&
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

  JsonMap _deliveryStopDecision(String deliveryState) {
    switch (deliveryState) {
      case ChapterDeliveryStateStatuses.missingOutputRecoverable:
      case ChapterDeliveryStateStatuses.pathMismatchRecoverable:
      case ChapterDeliveryStateStatuses.deliveredNeedsRepair:
        return const <String, Object?>{
          'stop': true,
          'reason': 'delivery_repair_required',
          'note': '章节交付状态要求先进入 repair/recovery，队列已暂停。',
        };
      case ChapterDeliveryStateStatuses.invalidOutputRewriteRequired:
      case ChapterDeliveryStateStatuses.manualAttentionRequired:
      case ChapterDeliveryStateStatuses.hardFailure:
        return const <String, Object?>{
          'stop': true,
          'reason': 'delivery_manual_attention',
          'note': '章节交付状态要求人工介入，队列已暂停。',
        };
      case ChapterDeliveryStateStatuses.waitingUserChoice:
        return const <String, Object?>{
          'stop': true,
          'reason': 'delivery_waiting_user_choice',
          'note': '章节交付状态正在等待用户确认，队列已暂停。',
        };
    }
    return const <String, Object?>{};
  }

  JsonMap _informationStopDecision(JsonMap result) {
    final checkpointReview = ValueReaders.mapValue(
      ValueReaders.mapValue(result['checkpoint_review'])['review'],
    );
    final informationSignal = ValueReaders.mapValue(
      checkpointReview['information_signal'],
    ).isNotEmpty
        ? ValueReaders.mapValue(checkpointReview['information_signal'])
        : ValueReaders.mapValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                checkpointReview['narrative_supervisor_risk'],
              )['information'],
            ),
          );
    final category = ValueReaders.stringValue(
      informationSignal['category'],
    ).trim();
    switch (category) {
      case 'manual_attention':
        return <String, Object?>{
          'stop': true,
          'reason': 'information_manual_attention',
          'note': ValueReaders.stringValue(
            informationSignal['summary'],
            '信息层信号要求人工介入，队列已暂停。',
          ),
        };
      case 'repair':
        return <String, Object?>{
          'stop': true,
          'reason': 'information_repair_required',
          'note': ValueReaders.stringValue(
            informationSignal['summary'],
            '信息层信号要求先补研究、补上下文或处理设计冲突，队列已暂停。',
          ),
        };
      case 'checkpoint_user':
        return <String, Object?>{
          'stop': true,
          'reason': 'information_waiting_user',
          'note': ValueReaders.stringValue(
            informationSignal['summary'],
            '信息层信号要求先停在用户确认点，队列已暂停。',
          ),
        };
    }
    return const <String, Object?>{};
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
