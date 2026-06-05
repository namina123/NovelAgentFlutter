import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_run_status.dart';
import 'writing_execution_outcome_statuses.dart';
import 'writing_execution_result.dart';
import 'writing_execution_result_codec_service.dart';

class LongTaskWritingExecutionSignalService {
  const LongTaskWritingExecutionSignalService({
    WritingExecutionResultCodecService? codecService,
  }) : _codecService = codecService ?? const WritingExecutionResultCodecService();

  final WritingExecutionResultCodecService _codecService;

  JsonMap signalFromPayload({
    JsonMap result = const <String, Object?>{},
    JsonMap record = const <String, Object?>{},
    String stopReason = '',
    String fallbackNote = '',
  }) {
    // 中文注释: 该服务只负责把共享写作结果合同翻译成长任务调度可消费的稳定摘要，不读取正文。
    final sharedResult = _sharedResultJson(result: result, record: record);
    if (sharedResult.isNotEmpty) {
      return signalFromWritingExecutionResult(
        _codecService.fromJson(sharedResult),
        stopReason: stopReason,
        fallbackNote: fallbackNote,
      );
    }
    return _budgetSignal(
      stopReason.trim(),
      fallbackNote: fallbackNote,
    );
  }

  JsonMap signalFromWritingExecutionResult(
    WritingExecutionResult executionResult, {
    String stopReason = '',
    String fallbackNote = '',
  }) {
    final category = _categoryFromExecutionResult(
      executionResult,
      stopReason: stopReason,
    );
    if (category.isEmpty) {
      return const <String, Object?>{'present': false};
    }
    final note = _noteForExecutionResult(
      executionResult,
      fallbackNote: fallbackNote,
      category: category,
    );
    return <String, Object?>{
      'present': true,
      'category': category,
      'overall_status': executionResult.overallStatus,
      'summary': executionResult.summary,
      'note': note,
      'next_action': executionResult.nextAction,
      'retryable': executionResult.retryable,
      'blocks_progress': executionResult.blocksProgress,
      'requires_user_action': executionResult.requiresUserAction,
      'recovery_action': _recoveryActionForExecutionResult(
        executionResult,
        category: category,
      ),
      'legacy_stop_reason': _legacyStopReasonForExecutionResult(
        executionResult,
        category: category,
        stopReason: stopReason,
      ),
      'run_status': _runStatusForCategory(category).id,
      'delivery_state': executionResult.delivery.state,
      'information_risk_category': executionResult.information.riskCategory,
      'failed_collaborator_count':
          executionResult.collaboration.failedCollaboratorCount,
      'hard_gate_reasons': executionResult.constraints.hardGateReasons,
      'soft_gate_reasons': executionResult.constraints.softGateReasons,
      'writing_execution_result': executionResult.toJson(),
    };
  }

  JsonMap _sharedResultJson({
    required JsonMap result,
    required JsonMap record,
  }) {
    final direct = ValueReaders.mapValue(result['writing_execution_result']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final execution = ValueReaders.mapValue(result['execution']);
    final executionShared = ValueReaders.mapValue(
      execution['writing_execution_result'],
    );
    if (executionShared.isNotEmpty) {
      return executionShared;
    }
    final recordShared = ValueReaders.mapValue(record['last_writing_execution_result']);
    if (recordShared.isNotEmpty) {
      return recordShared;
    }
    final lastStep = _lastStep(record);
    return ValueReaders.mapValue(lastStep['writing_execution_result']);
  }

  JsonMap _budgetSignal(String stopReason, {required String fallbackNote}) {
    if (stopReason != 'max_steps' && stopReason != 'max_seconds') {
      return const <String, Object?>{'present': false};
    }
    return <String, Object?>{
      'present': true,
      'category': 'budget_failed',
      'overall_status': '',
      'summary': fallbackNote,
      'note': fallbackNote.isEmpty
          ? (stopReason == 'max_seconds'
                ? '本次运行已达到时长预算边界，可稍后继续调度。'
                : '本次运行已达到步数预算边界，可稍后继续调度。')
          : fallbackNote,
      'next_action': 'resume_dispatch',
      'retryable': true,
      'blocks_progress': false,
      'requires_user_action': false,
      'recovery_action': 'resume_dispatch',
      'legacy_stop_reason': stopReason,
      'run_status': LongTaskRunStatus.paused.id,
      'delivery_state': '',
      'information_risk_category': '',
      'failed_collaborator_count': 0,
      'hard_gate_reasons': const <String>[],
      'soft_gate_reasons': const <String>[],
      'writing_execution_result': const <String, Object?>{},
    };
  }

  String _categoryFromExecutionResult(
    WritingExecutionResult executionResult, {
    required String stopReason,
  }) {
    if (stopReason == 'max_steps' || stopReason == 'max_seconds') {
      return 'budget_failed';
    }
    return switch (executionResult.overallStatus) {
      WritingExecutionOutcomeStatuses.success => 'success',
      WritingExecutionOutcomeStatuses.recoverableFailure => 'recoverable',
      WritingExecutionOutcomeStatuses.userActionRequired => 'waiting_user',
      WritingExecutionOutcomeStatuses.contentQualityIssue =>
        'content_quality_failed',
      WritingExecutionOutcomeStatuses.technicalFailure => 'technical_failed',
      _ => '',
    };
  }

  String _noteForExecutionResult(
    WritingExecutionResult executionResult, {
    required String fallbackNote,
    required String category,
  }) {
    final recoveryNote = executionResult.recovery.note.trim();
    if (recoveryNote.isNotEmpty) {
      return recoveryNote;
    }
    final summary = executionResult.summary.trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    if (fallbackNote.trim().isNotEmpty) {
      return fallbackNote.trim();
    }
    return switch (category) {
      'waiting_user' => '写作结果正在等待用户确认。',
      'recoverable' => '写作结果提示当前节点可恢复，但应先修补后再继续。',
      'content_quality_failed' => '写作结果提示当前节点存在内容质量风险，应先人工复核。',
      'technical_failed' => '写作运行遇到技术失败，长任务应先暂停处理。',
      'budget_failed' => '本次运行已达到预算边界。',
      _ => '写作结果已记录。',
    };
  }

  String _recoveryActionForExecutionResult(
    WritingExecutionResult executionResult, {
    required String category,
  }) {
    final action = executionResult.recovery.recommendedAction.trim();
    if (action.isNotEmpty) {
      return action;
    }
    return switch (category) {
      'waiting_user' => 'resume_when_user_confirms',
      'recoverable' => 'pause_for_repair',
      'content_quality_failed' => 'pause_for_manual_attention',
      'technical_failed' => 'pause_for_failure',
      'budget_failed' => 'resume_dispatch',
      _ => '',
    };
  }

  String _legacyStopReasonForExecutionResult(
    WritingExecutionResult executionResult, {
    required String category,
    required String stopReason,
  }) {
    if (stopReason == 'max_steps' || stopReason == 'max_seconds') {
      return stopReason;
    }
    switch (category) {
      case 'waiting_user':
        return 'waiting_user_checkpoint';
      case 'recoverable':
        if (executionResult.information.requiresRepair) {
          return 'information_repair_required';
        }
        if (executionResult.delivery.present &&
            executionResult.delivery.blocksProgress) {
          return 'delivery_repair_required';
        }
        return 'failed_task';
      case 'content_quality_failed':
        return 'delivery_manual_attention';
      case 'technical_failed':
        return 'step_failed';
      default:
        return '';
    }
  }

  LongTaskRunStatus _runStatusForCategory(String category) {
    return switch (category) {
      'waiting_user' => LongTaskRunStatus.waitingGate,
      'recoverable' => LongTaskRunStatus.recovering,
      'content_quality_failed' => LongTaskRunStatus.failedManualAttention,
      'technical_failed' => LongTaskRunStatus.paused,
      'budget_failed' => LongTaskRunStatus.paused,
      _ => LongTaskRunStatus.running,
    };
  }

  JsonMap _lastStep(JsonMap record) {
    final steps = ValueReaders.mapList(record['steps']);
    if (steps.isEmpty) {
      return const <String, Object?>{};
    }
    return steps.last;
  }
}
