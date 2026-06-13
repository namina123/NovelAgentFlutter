import '../runtime/long_task_run_status.dart';
import '../runtime/long_task_stop_outcome.dart';
import '../runtime/long_task_stop_outcome_resolver_service.dart';
import 'chapter_delivery_state_statuses.dart';
import 'expression_constraint_gate_signal.dart';
import 'information_evidence_gate_signal.dart';
import 'supervisor_decision.dart';
import 'supervisor_decision_action.dart';
import 'supervisor_input_bundle.dart';
import 'writing_execution_outcome_statuses.dart';

class SupervisorDecisionService {
  const SupervisorDecisionService({
    LongTaskStopOutcomeResolverService? stopOutcomeResolverService,
  }) : _stopOutcomeResolverService =
           stopOutcomeResolverService ??
           const LongTaskStopOutcomeResolverService();

  final LongTaskStopOutcomeResolverService _stopOutcomeResolverService;

  SupervisorDecision decide(SupervisorInputBundle bundle) {
    // 中文注释: supervisor 决策只消费结构化输入包并产出统一控制动作，不再让子链直接编写 stop reason 语义。
    if (!bundle.present) {
      return const SupervisorDecision();
    }
    final action = _actionForBundle(bundle);
    final legacyStopReason = _legacyStopReasonForAction(bundle, action);
    final stopOutcome = _stopOutcomeForAction(
      bundle,
      action,
      legacyStopReason: legacyStopReason,
    );
    final summary = _summaryForAction(bundle, action);
    return SupervisorDecision(
      present: true,
      action: action,
      reason: _reasonForAction(bundle, action),
      summary: summary,
      note: _noteForAction(bundle, action, summary),
      runStatus: _runStatusForAction(action).id,
      recoveryAction: _recoveryActionForAction(bundle, action),
      blocksProgress: _blocksProgressForAction(bundle, action),
      retryable: _retryableForAction(bundle, action),
      requiresUserAction: action == SupervisorDecisionActions.waitingUser,
      legacyStopReason: legacyStopReason,
      stopOutcome: stopOutcome,
      metadata: <String, Object?>{
        'overall_status': bundle.overallStatus,
        'next_action': bundle.nextAction,
        'delivery_state': bundle.delivery.state,
        'information_risk_category': bundle.information.riskCategory,
        'failed_collaborator_count': bundle.collaboration.failedCollaboratorCount,
        'hard_gate_reasons': bundle.constraints.hardGateReasons,
        'soft_gate_reasons': bundle.constraints.softGateReasons,
      },
    );
  }

  SupervisorDecision decisionFromLegacyStopReason(
    String legacyStopReason, {
    String fallbackNote = '',
  }) {
    // 中文注释: 预算边界等没有共享写作结果的场景，仍通过统一决策合同收口，而不是继续临时拼 budget signal。
    final cleanReason = legacyStopReason.trim();
    if (cleanReason.isEmpty) {
      return const SupervisorDecision();
    }
    final stopOutcome = _stopOutcomeResolverService.fromLegacyStopReason(
      cleanReason,
      summary: fallbackNote,
      metadata: const <String, Object?>{
        'source': 'legacy_stop_reason',
      },
    );
    final isBudget = cleanReason == 'max_steps' || cleanReason == 'max_seconds';
    final summary = fallbackNote.trim().isNotEmpty
        ? fallbackNote.trim()
        : (cleanReason == 'max_seconds'
              ? '本次运行已达到时长预算边界，可稍后继续调度。'
              : cleanReason == 'max_steps'
              ? '本次运行已达到步数预算边界，可稍后继续调度。'
              : '当前长任务已进入暂停处理阶段。');
    return SupervisorDecision(
      present: true,
      action: SupervisorDecisionActions.pause,
      reason: isBudget ? 'budget_exhausted' : cleanReason,
      summary: summary,
      note: summary,
      runStatus: LongTaskRunStatus.paused.id,
      recoveryAction: isBudget ? 'resume_dispatch' : 'pause_for_failure',
      blocksProgress: !isBudget,
      retryable: isBudget,
      legacyStopReason: cleanReason,
      stopOutcome: stopOutcome,
      metadata: const <String, Object?>{
        'source': 'legacy_stop_reason',
      },
    );
  }

  String _actionForBundle(SupervisorInputBundle bundle) {
    // 中文注释: 动作优先级先处理必须停下的等待/暂停/人工，再处理 repair，最后才允许继续或轻提醒。
    if (_isBudgetStop(bundle.stopReasonHint)) {
      return SupervisorDecisionActions.pause;
    }
    if (_requiresWaitingUser(bundle)) {
      return SupervisorDecisionActions.waitingUser;
    }
    if (_requiresPause(bundle)) {
      return SupervisorDecisionActions.pause;
    }
    if (_requiresManualAttention(bundle)) {
      return SupervisorDecisionActions.manualAttention;
    }
    if (_requiresRepair(bundle)) {
      return SupervisorDecisionActions.repair;
    }
    if (_requiresAdjustNext(bundle)) {
      return SupervisorDecisionActions.adjustNext;
    }
    if (_requiresRemind(bundle)) {
      return SupervisorDecisionActions.remind;
    }
    return SupervisorDecisionActions.continueRun;
  }

  bool _requiresWaitingUser(SupervisorInputBundle bundle) {
    // 中文注释: waiting_user 统一覆盖共享结果、信息层、协作层和恢复层的真实等待确认点。
    return bundle.requiresUserAction ||
        bundle.information.waitingUser ||
        bundle.recovery.waitingUser ||
        bundle.collaboration.requireUserCount > 0 ||
        bundle.collaboration.userConfirmationConflictCount > 0 ||
        bundle.stopOutcome.category == LongTaskStopOutcomeCategories.waitingUser;
  }

  bool _requiresPause(SupervisorInputBundle bundle) {
    // 中文注释: pause 只表达预算、技术失败或恢复耗尽等控制面应暂停的情况，不吞掉 repair 与 waiting_user。
    return _isBudgetStop(bundle.stopReasonHint) ||
        bundle.overallStatus == WritingExecutionOutcomeStatuses.technicalFailure ||
        bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.technicalFailure ||
        bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.recoveryExhausted;
  }

  bool _requiresManualAttention(SupervisorInputBundle bundle) {
    // 中文注释: manual attention 只在当前节点不适合自动 repair 时触发，避免把严重内容失败伪装成普通返工。
    return bundle.information.manualAttentionRequired ||
        bundle.recovery.manualAttentionRequired ||
        _isManualDeliveryState(bundle.delivery.state) ||
        bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.manualAttention ||
        (bundle.overallStatus ==
                WritingExecutionOutcomeStatuses.contentQualityIssue &&
            !_requiresConstraintRepair(bundle));
  }

  bool _requiresRepair(SupervisorInputBundle bundle) {
    // 中文注释: repair 统一承接交付、约束、信息与协作层的可恢复阻塞，而不是继续散成多种 stop reason 方言。
    return _isRepairDeliveryState(bundle.delivery.state) ||
        bundle.delivery.blocksProgress ||
        bundle.information.requiresRepair ||
        bundle.recovery.requiresRepair ||
        _requiresConstraintRepair(bundle) ||
        bundle.collaboration.blockingFailureCount > 0 ||
        bundle.collaboration.repairRequiredConflictCount > 0;
  }

  bool _requiresConstraintRepair(SupervisorInputBundle bundle) {
    // 中文注释: 共享约束 repair 用统一 helper 收口，避免表达限制、字数与其他 gate 各自改写 supervisor 结论。
    return bundle.constraints.hardConstraintTriggered ||
        bundle.constraints.repairRequired ||
        bundle.constraints.chapterLengthDiscipline.repairRequired ||
        bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.constraintGatePause ||
        bundle.constraints.expressionConstraintGate.repairRequired ||
        bundle.constraints.expressionConstraintGate.recommendedDisposition ==
            ExpressionConstraintGateRecommendedDispositions.repair;
  }

  bool _requiresAdjustNext(SupervisorInputBundle bundle) {
    // 中文注释: adjust_next 只处理不阻塞当前推进、但要求下一步收紧的共享约束信号。
    return bundle.constraints.chapterLengthDiscipline.recommendedAction ==
            'adjust_next_chapter' ||
        bundle.constraints.expressionConstraintGate.adjustNextChapter ||
        bundle.constraints.expressionConstraintGate.recommendedDisposition ==
            ExpressionConstraintGateRecommendedDispositions.adjustNext ||
        bundle.nextAction.trim() == 'adjust_next_chapter';
  }

  bool _requiresRemind(SupervisorInputBundle bundle) {
    // 中文注释: remind 表示当前可以继续，但 supervisor 应保留明确提示，避免轻风险彻底静默扩散。
    return bundle.constraints.chapterLengthDiscipline.reminderOnly ||
        bundle.constraints.reminderOnly ||
        bundle.constraints.softGateReasons.isNotEmpty ||
        (_isInformationWarning(bundle) && !_requiresAdjustNext(bundle)) ||
        (bundle.collaboration.degraded &&
            bundle.collaboration.blockingFailureCount == 0 &&
            bundle.collaboration.repairRequiredConflictCount == 0);
  }

  bool _isInformationWarning(SupervisorInputBundle bundle) {
    // 中文注释: information 轻风险只在证据门控仍为 warning 且没有升级成 repair/wait/manual 时视作 remind。
    return bundle.information.evidenceGate.severity ==
            InformationEvidenceGateSeverities.warning &&
        !bundle.information.waitingUser &&
        !bundle.information.requiresRepair &&
        !bundle.information.manualAttentionRequired;
  }

  String _reasonForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: reason 只记录中央决策为何选了这个动作，不再直接复用子链的 stop reason 作为最终真相。
    switch (action) {
      case SupervisorDecisionActions.pause:
        if (_isBudgetStop(bundle.stopReasonHint)) {
          return 'budget_exhausted';
        }
        if (bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.recoveryExhausted) {
          return 'recovery_exhausted';
        }
        return _firstNonEmpty(
          <String>[
            bundle.recovery.reason,
            bundle.stopOutcome.reason,
            'technical_failure',
          ],
        );
      case SupervisorDecisionActions.waitingUser:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.reason,
            bundle.information.reason,
            'waiting_user',
          ],
        );
      case SupervisorDecisionActions.manualAttention:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.reason,
            bundle.information.reason,
            bundle.delivery.reason,
            'manual_attention',
          ],
        );
      case SupervisorDecisionActions.repair:
        if (_isRepairDeliveryState(bundle.delivery.state) ||
            bundle.delivery.blocksProgress) {
          return _firstNonEmpty(
            <String>[bundle.delivery.reason, 'delivery_repair_required'],
          );
        }
        if (_requiresConstraintRepair(bundle)) {
          return _firstNonEmpty(
            <String>[
              bundle.constraints.hardGateReasons.isEmpty
                  ? ''
                  : bundle.constraints.hardGateReasons.first,
              bundle.recovery.reason,
              'constraint_gate_pause',
            ],
          );
        }
        if (bundle.information.requiresRepair) {
          return _firstNonEmpty(
            <String>[bundle.information.reason, 'information_repair_required'],
          );
        }
        return _firstNonEmpty(
          <String>[bundle.recovery.reason, 'repair_required'],
        );
      case SupervisorDecisionActions.adjustNext:
        return _firstNonEmpty(
          <String>[
            bundle.constraints.expressionConstraintGate.reason,
            bundle.nextAction,
            'adjust_next',
          ],
        );
      case SupervisorDecisionActions.remind:
        return _firstNonEmpty(
          <String>[
            bundle.information.reason,
            bundle.constraints.softGateReasons.isEmpty
                ? ''
                : bundle.constraints.softGateReasons.first,
            'remind',
          ],
        );
      case SupervisorDecisionActions.continueRun:
        return _firstNonEmpty(
          <String>[bundle.stopOutcome.reason, 'completed_naturally'],
        );
    }
    return '';
  }

  String _summaryForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: summary 优先复用共享结果已有摘要，只有在缺失时才补统一默认文案，避免宿主再猜解释文本。
    switch (action) {
      case SupervisorDecisionActions.pause:
        if (_isBudgetStop(bundle.stopReasonHint)) {
          return bundle.fallbackNote.isNotEmpty
              ? bundle.fallbackNote
              : (bundle.stopReasonHint == 'max_seconds'
                    ? '本次运行已达到时长预算边界，可稍后继续调度。'
                    : '本次运行已达到步数预算边界，可稍后继续调度。');
        }
        return _firstNonEmpty(
          <String>[
            bundle.recovery.note,
            bundle.summary,
            '写作运行遇到技术失败，长任务应先暂停处理。',
          ],
        );
      case SupervisorDecisionActions.waitingUser:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.note,
            bundle.information.summary,
            bundle.summary,
            '写作结果正在等待用户确认。',
          ],
        );
      case SupervisorDecisionActions.manualAttention:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.note,
            bundle.delivery.summary,
            bundle.summary,
            '当前节点存在内容质量或人工处理风险，应先人工复核。',
          ],
        );
      case SupervisorDecisionActions.repair:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.note,
            bundle.delivery.summary,
            bundle.information.summary,
            bundle.constraints.summary,
            bundle.collaboration.failureSummary,
            bundle.summary,
            '当前节点存在可恢复阻塞，应先修补后再继续。',
          ],
        );
      case SupervisorDecisionActions.adjustNext:
        return _firstNonEmpty(
          <String>[
            bundle.constraints.summary,
            bundle.summary,
            '共享执行约束建议下一步收紧或回调。',
          ],
        );
      case SupervisorDecisionActions.remind:
        return _firstNonEmpty(
          <String>[
            bundle.constraints.summary,
            bundle.information.summary,
            bundle.collaboration.summary,
            bundle.summary,
            '当前节点存在轻量风险提示，可以继续但应保留提醒。',
          ],
        );
      case SupervisorDecisionActions.continueRun:
        return _firstNonEmpty(
          <String>[bundle.summary, '当前共享写作结果允许继续推进。'],
        );
    }
    return '';
  }

  String _noteForAction(
    SupervisorInputBundle bundle,
    String action,
    String summary,
  ) {
    // 中文注释: note 优先沿用恢复备注与外部 fallback，确保 station/probe 能看到最贴近现场的解释句子。
    return _firstNonEmpty(
      <String>[
        bundle.recovery.note,
        bundle.fallbackNote,
        summary,
      ],
    );
  }

  String _recoveryActionForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: recovery action 只给宿主下一步最小动作建议，不在决策合同里扩展成新的运行编排中心。
    switch (action) {
      case SupervisorDecisionActions.pause:
        if (_isBudgetStop(bundle.stopReasonHint)) {
          return 'resume_dispatch';
        }
        return _firstNonEmpty(
          <String>[bundle.recovery.recommendedAction, 'pause_for_failure'],
        );
      case SupervisorDecisionActions.waitingUser:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.recommendedAction,
            'resume_when_user_confirms',
          ],
        );
      case SupervisorDecisionActions.manualAttention:
        return _firstNonEmpty(
          <String>[
            bundle.recovery.recommendedAction,
            'pause_for_manual_attention',
          ],
        );
      case SupervisorDecisionActions.repair:
        return _firstNonEmpty(
          <String>[bundle.recovery.recommendedAction, 'pause_for_repair'],
        );
      case SupervisorDecisionActions.adjustNext:
        return _firstNonEmpty(
          <String>[bundle.nextAction, 'adjust_next_chapter'],
        );
      case SupervisorDecisionActions.remind:
        return _firstNonEmpty(
          <String>[bundle.nextAction, 'continue_with_reminder'],
        );
      case SupervisorDecisionActions.continueRun:
        return bundle.nextAction.trim();
    }
    return '';
  }

  bool _blocksProgressForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: blocks_progress 统一由中央动作语义兜底，防止各子链对“是否阻塞”给出互相冲突的答案。
    switch (action) {
      case SupervisorDecisionActions.continueRun:
      case SupervisorDecisionActions.remind:
      case SupervisorDecisionActions.adjustNext:
        return false;
      case SupervisorDecisionActions.pause:
        return !_isBudgetStop(bundle.stopReasonHint);
      case SupervisorDecisionActions.repair:
      case SupervisorDecisionActions.waitingUser:
      case SupervisorDecisionActions.manualAttention:
        return true;
    }
    return bundle.blocksProgress;
  }

  bool _retryableForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: retryable 优先沿用共享结果已有事实，再由动作语义给预算与 repair 这类典型情况补最小默认值。
    if (_isBudgetStop(bundle.stopReasonHint)) {
      return true;
    }
    if (bundle.retryable || bundle.delivery.retryable || bundle.recovery.retryable) {
      return true;
    }
    return action == SupervisorDecisionActions.repair;
  }

  String _legacyStopReasonForAction(SupervisorInputBundle bundle, String action) {
    // 中文注释: legacy stop reason 只在这里集中派生，后续兼容层统一消费这个结果，不再接受子链直接改写最终停机语义。
    switch (action) {
      case SupervisorDecisionActions.pause:
        if (_isBudgetStop(bundle.stopReasonHint)) {
          return bundle.stopReasonHint.trim();
        }
        if (bundle.stopOutcome.category ==
            LongTaskStopOutcomeCategories.recoveryExhausted) {
          return 'recovery_exhausted';
        }
        return 'step_failed';
      case SupervisorDecisionActions.waitingUser:
        return 'waiting_user_checkpoint';
      case SupervisorDecisionActions.manualAttention:
        if (bundle.information.manualAttentionRequired) {
          return 'information_manual_attention';
        }
        if (_isManualDeliveryState(bundle.delivery.state) ||
            bundle.overallStatus ==
                WritingExecutionOutcomeStatuses.contentQualityIssue) {
          return 'delivery_manual_attention';
        }
        return 'manual_attention';
      case SupervisorDecisionActions.repair:
        if (_isRepairDeliveryState(bundle.delivery.state) ||
            bundle.delivery.blocksProgress) {
          return 'delivery_repair_required';
        }
        if (bundle.information.requiresRepair) {
          return 'information_repair_required';
        }
        return 'constraint_gate_pause';
      case SupervisorDecisionActions.remind:
      case SupervisorDecisionActions.adjustNext:
      case SupervisorDecisionActions.continueRun:
        return '';
    }
    return '';
  }

  LongTaskStopOutcome _stopOutcomeForAction(
    SupervisorInputBundle bundle,
    String action, {
    required String legacyStopReason,
  }) {
    // 中文注释: stop outcome 优先从中央兼容 stop reason 推导，这样 repair/wait/manual 的高层结局不再被子链私有 reason 带偏。
    if (legacyStopReason.trim().isNotEmpty) {
      final outcome = _stopOutcomeResolverService.fromLegacyStopReason(
        legacyStopReason,
        summary: _summaryForAction(bundle, action),
        metadata: <String, Object?>{
          'source': 'supervisor_decision',
          'action': action,
        },
      );
      if (outcome.present) {
        return outcome;
      }
    }
    if (bundle.stopOutcome.present) {
      return bundle.stopOutcome;
    }
    return const LongTaskStopOutcome();
  }

  LongTaskRunStatus _runStatusForAction(String action) {
    // 中文注释: run status 由中央动作统一投影，避免 runtime 各入口继续散落同一套状态选择规则。
    switch (action) {
      case SupervisorDecisionActions.continueRun:
      case SupervisorDecisionActions.remind:
      case SupervisorDecisionActions.adjustNext:
        return LongTaskRunStatus.running;
      case SupervisorDecisionActions.repair:
        return LongTaskRunStatus.recovering;
      case SupervisorDecisionActions.pause:
        return LongTaskRunStatus.paused;
      case SupervisorDecisionActions.waitingUser:
        return LongTaskRunStatus.waitingGate;
      case SupervisorDecisionActions.manualAttention:
        return LongTaskRunStatus.failedManualAttention;
    }
    return LongTaskRunStatus.running;
  }

  bool _isBudgetStop(String value) {
    // 中文注释: 预算边界是 supervisor 的控制面输入，不属于写作子链直接生成的 stop reason 语义。
    final clean = value.trim();
    return clean == 'max_steps' || clean == 'max_seconds';
  }

  bool _isRepairDeliveryState(String value) {
    // 中文注释: 这里显式列出可恢复交付态，避免 delivery 子链再直接把这些状态各自映射成长任务 stop reason。
    return value == ChapterDeliveryStateStatuses.deliveredNeedsRepair ||
        value == ChapterDeliveryStateStatuses.missingOutputRecoverable ||
        value == ChapterDeliveryStateStatuses.pathMismatchRecoverable;
  }

  bool _isManualDeliveryState(String value) {
    // 中文注释: 这里显式列出必须人工处理的交付态，保证 manual attention 由 supervisor 中央统一判定。
    return value == ChapterDeliveryStateStatuses.invalidOutputRewriteRequired ||
        value == ChapterDeliveryStateStatuses.manualAttentionRequired ||
        value == ChapterDeliveryStateStatuses.hardFailure;
  }

  String _firstNonEmpty(List<String> values) {
    // 中文注释: 多源摘要与原因优先级统一走这个 helper，避免每个分支各自实现一套空值回退规则。
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }
}
