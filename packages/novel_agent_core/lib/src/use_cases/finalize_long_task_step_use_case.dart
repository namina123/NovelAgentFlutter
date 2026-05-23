import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../workflow/long_task_finish_disposition_service.dart';
import '../workflow/long_task_run_lifecycle_service.dart';
import '../workflow/long_task_run_step_recorder_service.dart';
import '../workflow/long_task_stop_after_step_service.dart';

class FinalizeLongTaskStepUseCase {
  FinalizeLongTaskStepUseCase({
    required LongTaskRunStepRecorderService stepRecorderService,
    required LongTaskStopAfterStepService stopAfterStepService,
    required LongTaskFinishDispositionService finishDispositionService,
    required LongTaskRunLifecycleService lifecycleService,
  }) : _stepRecorderService = stepRecorderService,
       _stopAfterStepService = stopAfterStepService,
       _finishDispositionService = finishDispositionService,
       _lifecycleService = lifecycleService;

  final LongTaskRunStepRecorderService _stepRecorderService;
  final LongTaskStopAfterStepService _stopAfterStepService;
  final LongTaskFinishDispositionService _finishDispositionService;
  final LongTaskRunLifecycleService _lifecycleService;

  JsonMap execute(
    JsonMap record,
    JsonMap taskAfterStep,
    JsonMap result, {
    JsonMap options = const <String, Object?>{},
    String phase = 'model_step',
    String createdAt = '',
  }) {
    // 中文注释: 这个用例把单步后的审计、停机判断和 record 收尾动作串成一个纯内存入口。
    var nextRecord = _stepRecorderService.recordStep(
      record,
      taskAfterStep,
      result,
      phase: phase,
      createdAt: createdAt,
    );
    final stopDecision = _stopAfterStepService.stopAfterStep(
      record,
      taskAfterStep,
      result,
      options: options,
    );
    JsonMap disposition = const <String, Object?>{};
    if (ValueReaders.boolValue(stopDecision['stop'])) {
      disposition = _finishDispositionService.finishDisposition(
        ValueReaders.stringValue(stopDecision['reason']),
        ValueReaders.intValue(nextRecord['completed_steps']),
        options: <String, Object?>{
          ...ValueReaders.deepCopyMap(options),
          'stop_note': ValueReaders.stringValue(stopDecision['note']),
        },
      );
      if (ValueReaders.stringValue(disposition['record_action']) == 'pause') {
        nextRecord = _lifecycleService.pauseRecord(
          nextRecord,
          reason: ValueReaders.stringValue(stopDecision['reason']),
          note: ValueReaders.stringValue(stopDecision['note']),
          createdAt: createdAt,
        );
      } else {
        nextRecord = _lifecycleService.finishRecord(
          nextRecord,
          reason: ValueReaders.stringValue(
            disposition['terminal_reason'],
            ValueReaders.stringValue(stopDecision['reason']),
          ),
          note: ValueReaders.stringValue(stopDecision['note']),
          createdAt: createdAt,
        );
      }
    }
    return <String, Object?>{
      'ok': true,
      'record': nextRecord,
      'stop_decision': stopDecision,
      'disposition': disposition,
    };
  }
}
