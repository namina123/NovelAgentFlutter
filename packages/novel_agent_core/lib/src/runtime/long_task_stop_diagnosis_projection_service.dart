import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../workflow/long_task_recovery_state.dart';
import 'long_task_stop_diagnosis_projection.dart';
import 'long_task_stop_outcome.dart';

class LongTaskStopDiagnosisProjectionService {
  const LongTaskStopDiagnosisProjectionService();

  LongTaskStopDiagnosisProjection project({
    LongTaskStopOutcome stopOutcome = const LongTaskStopOutcome(),
    LongTaskRecoveryState recoveryState = const LongTaskRecoveryState(),
    String legacyReason = '',
    String runStatus = '',
    String note = '',
    String reviewSummary = '',
    String informationSummary = '',
    String detail = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final effectiveOutcome = _effectiveStopOutcome(
      stopOutcome: stopOutcome,
      recoveryState: recoveryState,
    );
    final code = _firstNonBlank(<String>[
      effectiveOutcome.reason,
      effectiveOutcome.legacyStopReason,
      recoveryState.reason,
      legacyReason,
    ]);
    final category = _resolveCategory(
      stopOutcome: effectiveOutcome,
      recoveryState: recoveryState,
      legacyReason: code,
      runStatus: runStatus,
    );
    final label = _labelFor(category, code);
    final summary = _summaryFor(
      category: category,
      code: code,
      stopOutcome: effectiveOutcome,
      recoveryState: recoveryState,
      note: note,
      reviewSummary: reviewSummary,
      informationSummary: informationSummary,
      runStatus: runStatus,
    );
    if (code.isEmpty &&
        category.isEmpty &&
        label.isEmpty &&
        summary.isEmpty &&
        detail.trim().isEmpty) {
      return const LongTaskStopDiagnosisProjection();
    }
    return LongTaskStopDiagnosisProjection(
      present: true,
      code: code,
      category: category,
      label: label,
      summary: summary,
      detail: detail.trim(),
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  LongTaskStopOutcome _effectiveStopOutcome({
    required LongTaskStopOutcome stopOutcome,
    required LongTaskRecoveryState recoveryState,
  }) {
    if (stopOutcome.present) {
      return stopOutcome;
    }
    if (recoveryState.stopOutcome.present) {
      return recoveryState.stopOutcome;
    }
    return const LongTaskStopOutcome();
  }

  String _resolveCategory({
    required LongTaskStopOutcome stopOutcome,
    required LongTaskRecoveryState recoveryState,
    required String legacyReason,
    required String runStatus,
  }) {
    if (stopOutcome.present && stopOutcome.category.trim().isNotEmpty) {
      return stopOutcome.category.trim();
    }
    if (recoveryState.present) {
      if (recoveryState.waitingUser ||
          recoveryState.state == LongTaskRecoveryStates.waitingUser ||
          recoveryState.exhaustedDisposition ==
              LongTaskRecoveryExhaustedDispositions.waitingUser) {
        return LongTaskStopOutcomeCategories.waitingUser;
      }
      if (recoveryState.manualAttentionRequired ||
          recoveryState.state == LongTaskRecoveryStates.manualAttention ||
          recoveryState.exhaustedDisposition ==
              LongTaskRecoveryExhaustedDispositions.manualAttention) {
        return LongTaskStopOutcomeCategories.manualAttention;
      }
      if (recoveryState.requiresRepair ||
          recoveryState.blocksProgress ||
          recoveryState.state == LongTaskRecoveryStates.reviewRequired ||
          recoveryState.state == LongTaskRecoveryStates.repairRequired ||
          recoveryState.state == LongTaskRecoveryStates.pausedFailure) {
        return LongTaskStopOutcomeCategories.constraintGatePause;
      }
      if (recoveryState.exhausted ||
          recoveryState.state == LongTaskRecoveryStates.exhausted) {
        return LongTaskStopOutcomeCategories.recoveryExhausted;
      }
    }
    switch (legacyReason.trim()) {
      case 'completed':
      case 'no_runnable_task':
        return LongTaskStopOutcomeCategories.completedNaturally;
      case 'max_steps':
      case 'max_seconds':
        return LongTaskStopOutcomeCategories.budgetExhausted;
      case 'waiting_user':
      case 'waiting_user_checkpoint':
      case 'waiting_user_choice':
      case 'information_waiting_user':
      case 'delivery_waiting_user_choice':
        return LongTaskStopOutcomeCategories.waitingUser;
      case 'manual_attention':
      case 'failed_manual_attention':
      case 'delivery_manual_attention':
      case 'semantic_review_manual_attention':
      case 'chapter_gate_manual_attention':
      case 'information_manual_attention':
      case 'content_quality_failed':
        return LongTaskStopOutcomeCategories.manualAttention;
      case 'delivery_repair_required':
      case 'information_repair_required':
      case 'waiting_gate':
      case 'blocked_dependencies':
      case 'manual_pause':
      case 'paused':
        return LongTaskStopOutcomeCategories.constraintGatePause;
      case 'write_failed':
      case 'write_failed_retryable':
      case 'write_failed_hard':
      case 'empty_body':
      case 'title_only_output':
      case 'body_too_short':
      case 'chapter_body_too_short':
      case 'path_mismatch':
      case 'chapter_path_mismatch':
      case 'sidecar_missing':
      case 'sidecar_invalid':
      case 'delivery_evidence_missing':
      case 'delivery_failure':
        return LongTaskStopOutcomeCategories.deliveryFailure;
      case 'failed':
      case 'failed_task':
      case 'step_failed':
      case 'record_missing':
      case 'stale_running_task':
        return LongTaskStopOutcomeCategories.technicalFailure;
      default:
        if (runStatus.trim() == 'succeeded') {
          return LongTaskStopOutcomeCategories.completedNaturally;
        }
        return '';
    }
  }

  String _labelFor(String category, String code) {
    switch (category) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return '自然完成';
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return '预算边界已到';
      case LongTaskStopOutcomeCategories.technicalFailure:
        return '技术失败';
      case LongTaskStopOutcomeCategories.deliveryFailure:
        return '交付失败';
      case LongTaskStopOutcomeCategories.constraintGatePause:
        switch (code.trim()) {
          case 'manual_pause':
          case 'paused':
            return '人工暂停';
          case 'delivery_repair_required':
          case 'information_repair_required':
            return '需修补后继续';
          default:
            return '约束暂停';
        }
      case LongTaskStopOutcomeCategories.waitingUser:
        return '等待用户确认';
      case LongTaskStopOutcomeCategories.manualAttention:
        return '需要人工处理';
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return '恢复已耗尽';
      default:
        return code.trim();
    }
  }

  String _summaryFor({
    required String category,
    required String code,
    required LongTaskStopOutcome stopOutcome,
    required LongTaskRecoveryState recoveryState,
    required String note,
    required String reviewSummary,
    required String informationSummary,
    required String runStatus,
  }) {
    final cleanNote = note.trim();
    final cleanReviewSummary = reviewSummary.trim();
    final cleanInformationSummary = informationSummary.trim();
    final cleanOutcomeSummary = stopOutcome.summary.trim();
    final cleanRecoveryNote = recoveryState.note.trim();
    switch (category) {
      case LongTaskStopOutcomeCategories.completedNaturally:
        return _firstNonBlank(<String>[
          cleanOutcomeSummary,
          stopOutcome.completionReason,
          cleanNote,
          '当前运行已经自然收尾，没有新的主链动作需要继续推进。',
        ]);
      case LongTaskStopOutcomeCategories.budgetExhausted:
        return _firstNonBlank(<String>[
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          '当前运行达到预算边界，是否继续推进应由上层显式决定。',
        ]);
      case LongTaskStopOutcomeCategories.technicalFailure:
        return _firstNonBlank(<String>[
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          '当前运行因技术侧失败停止，需要先定位失败链路。',
        ]);
      case LongTaskStopOutcomeCategories.deliveryFailure:
        return _firstNonBlank(<String>[
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          '当前运行未形成有效章节交付，需要先修复交付失败。',
        ]);
      case LongTaskStopOutcomeCategories.constraintGatePause:
        return _firstNonBlank(<String>[
          cleanReviewSummary,
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          cleanInformationSummary,
          code.trim() == 'manual_pause'
              ? '当前运行已由人工暂停。'
              : '当前运行被约束或复核关口暂停，处理完成前不会继续推进。',
        ]);
      case LongTaskStopOutcomeCategories.waitingUser:
        return _firstNonBlank(<String>[
          cleanInformationSummary,
          cleanReviewSummary,
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          '当前运行正在等待用户确认，确认完成前不会继续推进。',
        ]);
      case LongTaskStopOutcomeCategories.manualAttention:
        return _firstNonBlank(<String>[
          cleanReviewSummary,
          cleanInformationSummary,
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
          '当前运行需要人工处理后才能继续推进。',
        ]);
      case LongTaskStopOutcomeCategories.recoveryExhausted:
        return _firstNonBlank(<String>[
          cleanRecoveryNote,
          cleanOutcomeSummary,
          cleanNote,
          '自动恢复预算已经耗尽，需要人工决定下一步。',
        ]);
      default:
        return _firstNonBlank(<String>[
          cleanOutcomeSummary,
          cleanRecoveryNote,
          cleanNote,
        ]);
    }
  }

  String _firstNonBlank(Iterable<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }
}
