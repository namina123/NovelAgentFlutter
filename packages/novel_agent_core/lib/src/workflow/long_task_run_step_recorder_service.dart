import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_task_summary_service.dart';
import 'long_task_writing_execution_signal_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunStepRecorderService {
  LongTaskRunStepRecorderService({
    required LongTaskTaskSummaryService taskSummaryService,
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
  }) : _taskSummaryService = taskSummaryService,
       _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService();

  final LongTaskTaskSummaryService _taskSummaryService;
  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;

  JsonMap recordStep(
    JsonMap record,
    JsonMap task,
    JsonMap result, {
    String phase = 'model_step',
    String createdAt = '',
  }) {
    // 中文注释: 运行步骤记录只记审计所需摘要，不把完整 response 和任务正文塞进 record。
    final next = ValueReaders.deepCopyMap(record);
    final steps = ValueReaders.objectList(next['steps']);
    final response = ValueReaders.mapValue(result['response']);
    final checkpointReviewEnvelope = ValueReaders.mapValue(
      result['checkpoint_review'],
    );
    final checkpointReview = ValueReaders.mapValue(
      checkpointReviewEnvelope['review'],
    );
    final informationSignal = ValueReaders.mapValue(
      checkpointReview['information_signal'],
    ).isNotEmpty
        ? ValueReaders.mapValue(checkpointReview['information_signal'])
        : ValueReaders.mapValue(
            ValueReaders.mapValue(
              checkpointReview['narrative_supervisor_risk'],
            )['information'],
          );
    final execution = ValueReaders.mapValue(result['execution']);
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    final informationChangedPaths = ValueReaders.stringList(
      informationSignal['changed_paths'],
    );
    final informationSummary = ValueReaders.stringValue(
      informationSignal['summary'],
    );
    final informationRiskCategory = ValueReaders.stringValue(
      informationSignal['category'],
    );
    final writingExecutionSignal = _writingExecutionSignalService.signalFromPayload(
      result: result,
    );
    final writingExecutionResult = ValueReaders.mapValue(
      writingExecutionSignal['writing_execution_result'],
    );
    final toolNames = <String>[];
    for (final rawCall in ValueReaders.objectList(response['tool_calls'])) {
      final call = ValueReaders.mapValue(rawCall);
      final name = ValueReaders.stringValue(call['name']).trim();
      if (name.isNotEmpty && !toolNames.contains(name)) {
        toolNames.add(name);
      }
    }
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    steps.add(<String, Object?>{
      'index': steps.length + 1,
      'phase': phase,
      'task': _taskSummaryService.taskSummary(task),
      'ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'output_paths': ValueReaders.stringList(result['output_paths']),
      'changed_paths': changedPaths,
      'tool_names': toolNames,
      'activation_report_path': ValueReaders.stringValue(
        result['activation_report_path'],
        ValueReaders.stringValue(execution['activation_report_path']),
      ),
      'activation_report_summary': ValueReaders.stringValue(
        result['activation_report_summary'],
        ValueReaders.stringValue(execution['activation_report_summary']),
      ),
      'chapter_delivery_state': ValueReaders.stringValue(
        result['chapter_delivery_state'],
        ValueReaders.stringValue(execution['chapter_delivery_state']),
      ),
      'chapter_delivery_path': ValueReaders.stringValue(
        result['chapter_delivery_path'],
        ValueReaders.stringValue(execution['chapter_delivery_path']),
      ),
      'checkpoint_review_path': ValueReaders.stringValue(
        checkpointReviewEnvelope['relative_path'],
      ),
      'checkpoint_review_summary': ValueReaders.stringValue(
        checkpointReview['summary'],
      ),
      'checkpoint_review_severity': ValueReaders.stringValue(
        checkpointReview['severity'],
      ),
      'checkpoint_review_action_summary': ValueReaders.stringValue(
        checkpointReview['action_summary'],
      ),
      'information_changed_paths': informationChangedPaths,
      'information_summary': informationSummary,
      'information_risk_category': informationRiskCategory,
      'writing_execution_result': writingExecutionResult,
      'writing_execution_category': ValueReaders.stringValue(
        writingExecutionSignal['category'],
      ),
      'writing_execution_status': ValueReaders.stringValue(
        writingExecutionSignal['overall_status'],
      ),
      'writing_execution_summary': ValueReaders.stringValue(
        writingExecutionSignal['summary'],
      ),
      'writing_execution_next_action': ValueReaders.stringValue(
        writingExecutionSignal['next_action'],
      ),
      'created_at': now,
    });
    next['steps'] = steps;
    next['completed_steps'] = steps.length;
    next['last_task_id'] = ValueReaders.stringValue(task['id']);
    next['last_task_title'] = ValueReaders.stringValue(task['title']);
    next['last_output_paths'] = ValueReaders.stringList(result['output_paths']);
    next['last_changed_paths'] = changedPaths;
    next['last_activation_report_path'] = ValueReaders.stringValue(
      result['activation_report_path'],
      ValueReaders.stringValue(execution['activation_report_path']),
    );
    next['last_chapter_delivery_state'] = ValueReaders.stringValue(
      result['chapter_delivery_state'],
      ValueReaders.stringValue(execution['chapter_delivery_state']),
    );
    next['last_chapter_delivery_path'] = ValueReaders.stringValue(
      result['chapter_delivery_path'],
      ValueReaders.stringValue(execution['chapter_delivery_path']),
    );
    next['last_checkpoint_review_path'] = ValueReaders.stringValue(
      checkpointReviewEnvelope['relative_path'],
    );
    next['last_checkpoint_review_severity'] = ValueReaders.stringValue(
      checkpointReview['severity'],
    );
    next['last_information_changed_paths'] = informationChangedPaths;
    next['last_information_summary'] = informationSummary;
    next['last_information_risk_category'] = informationRiskCategory;
    next['last_writing_execution_result'] = writingExecutionResult;
    next['last_writing_execution_category'] = ValueReaders.stringValue(
      writingExecutionSignal['category'],
    );
    next['last_writing_execution_status'] = ValueReaders.stringValue(
      writingExecutionSignal['overall_status'],
    );
    next['last_writing_execution_summary'] = ValueReaders.stringValue(
      writingExecutionSignal['summary'],
    );
    next['last_writing_execution_next_action'] = ValueReaders.stringValue(
      writingExecutionSignal['next_action'],
    );
    next['updated_at'] = now;
    if (!ValueReaders.boolValue(result['ok'])) {
      next['failed_steps'] = ValueReaders.intValue(next['failed_steps']) + 1;
      next['status'] = TaskRuntimeConstants.statusPaused;
      next['stop_reason'] = 'step_failed';
      next['stop_note'] = ValueReaders.stringValue(
        result['error'],
        '任务单步失败，已暂停等待处理。',
      );
    }
    return next;
  }
}
