import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../runtime/long_task_stop_outcome_resolver_service.dart';
import 'supervisor_decision.dart';
import 'supervisor_decision_action.dart';
import 'supervisor_decision_service.dart';
import 'supervisor_input_bundle.dart';
import 'writing_execution_result.dart';
import 'writing_execution_result_codec_service.dart';

class LongTaskWritingExecutionSignalService {
  const LongTaskWritingExecutionSignalService({
    WritingExecutionResultCodecService? codecService,
    LongTaskStopOutcomeResolverService? stopOutcomeResolverService,
    SupervisorDecisionService? supervisorDecisionService,
  }) : _codecService = codecService ?? const WritingExecutionResultCodecService(),
       _stopOutcomeResolverService =
           stopOutcomeResolverService ??
           const LongTaskStopOutcomeResolverService(),
       _supervisorDecisionService =
           supervisorDecisionService ?? const SupervisorDecisionService();

  final WritingExecutionResultCodecService _codecService;
  final LongTaskStopOutcomeResolverService _stopOutcomeResolverService;
  final SupervisorDecisionService _supervisorDecisionService;

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
    final stopOutcome = _stopOutcomeResolverService.fromWritingExecutionResult(
      executionResult,
      legacyStopReason: stopReason,
    );
    final inputBundle = SupervisorInputBundle.fromWritingExecutionResult(
      executionResult,
      stopOutcome: stopOutcome,
      stopReasonHint: stopReason,
      fallbackNote: fallbackNote,
    );
    final decision = _supervisorDecisionService.decide(inputBundle);
    if (!decision.present) {
      return const <String, Object?>{'present': false};
    }
    return <String, Object?>{
      'present': true,
      'category': _compatibilityCategory(decision),
      'overall_status': executionResult.overallStatus,
      'summary': decision.summary,
      'note': decision.note,
      'next_action': executionResult.nextAction,
      'retryable': decision.retryable,
      'blocks_progress': decision.blocksProgress,
      'requires_user_action': decision.requiresUserAction,
      'recovery_action': decision.recoveryAction,
      'legacy_stop_reason': decision.legacyStopReason,
      'run_status': decision.runStatus,
      'supervisor_action': decision.action,
      'delivery_state': executionResult.delivery.state,
      'information_risk_category': executionResult.information.riskCategory,
      'failed_collaborator_count':
          executionResult.collaboration.failedCollaboratorCount,
      'hard_gate_reasons': executionResult.constraints.hardGateReasons,
      'soft_gate_reasons': executionResult.constraints.softGateReasons,
      'stop_outcome': decision.stopOutcome.toJson(),
      'supervisor_input_bundle': inputBundle.toJson(),
      'supervisor_decision': decision.toJson(),
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
    final decision = _supervisorDecisionService.decisionFromLegacyStopReason(
      stopReason,
      fallbackNote: fallbackNote,
    );
    if (!decision.present) {
      return const <String, Object?>{'present': false};
    }
    return <String, Object?>{
      'present': true,
      'category': _compatibilityCategory(decision),
      'overall_status': '',
      'summary': decision.summary,
      'note': decision.note,
      'next_action': 'resume_dispatch',
      'retryable': decision.retryable,
      'blocks_progress': decision.blocksProgress,
      'requires_user_action': decision.requiresUserAction,
      'recovery_action': decision.recoveryAction,
      'legacy_stop_reason': decision.legacyStopReason,
      'run_status': decision.runStatus,
      'supervisor_action': decision.action,
      'delivery_state': '',
      'information_risk_category': '',
      'failed_collaborator_count': 0,
      'hard_gate_reasons': const <String>[],
      'soft_gate_reasons': const <String>[],
      'stop_outcome': decision.stopOutcome.toJson(),
      'supervisor_decision': decision.toJson(),
      'writing_execution_result': const <String, Object?>{},
    };
  }

  JsonMap _lastStep(JsonMap record) {
    final steps = ValueReaders.mapList(record['steps']);
    if (steps.isEmpty) {
      return const <String, Object?>{};
    }
    return steps.last;
  }

  String _compatibilityCategory(SupervisorDecision decision) {
    // 中文注释: 兼容 category 只服务旧 signal 消费方，真实控制动作已经迁移到统一 supervisor decision 合同。
    switch (decision.action) {
      case SupervisorDecisionActions.continueRun:
      case SupervisorDecisionActions.remind:
      case SupervisorDecisionActions.adjustNext:
        return 'success';
      case SupervisorDecisionActions.repair:
        return 'recoverable';
      case SupervisorDecisionActions.waitingUser:
        return 'waiting_user';
      case SupervisorDecisionActions.manualAttention:
        return 'content_quality_failed';
      case SupervisorDecisionActions.pause:
        return decision.stopOutcome.category ==
                'budget_exhausted'
            ? 'budget_failed'
            : 'technical_failed';
    }
    return '';
  }
}
