import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SupervisorDecisionService', () {
    const service = SupervisorDecisionService();

    test('round-trips supervisor input bundle and decision contract', () {
      // 中文注释: 这里先验证 LTSR-08 新增的输入包与决策合同能稳定序列化回读，避免后续运行面继续退回松散 map。
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.success,
        summary: '当前共享写作结果允许继续推进。',
      );
      final bundle = SupervisorInputBundle.fromWritingExecutionResult(
        result,
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.completedNaturally,
          reason: 'completed_naturally',
          legacyStopReason: 'completed',
          summary: '当前共享写作结果允许继续推进。',
          completionReason: 'completed_naturally',
        ),
      );
      final decision = service.decide(bundle);
      final decodedBundle = SupervisorInputBundle.fromJson(bundle.toJson());
      final decodedDecision = SupervisorDecision.fromJson(decision.toJson());

      expect(decodedBundle.executionId, result.executionId);
      expect(decodedBundle.validateBasics(), isEmpty);
      expect(decodedDecision.action, SupervisorDecisionActions.continueRun);
      expect(decodedDecision.runStatus, LongTaskRunStatus.running.id);
      expect(decodedDecision.validateBasics(), isEmpty);
    });

    test('maps success into continue action', () {
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          _baseResult(
            overallStatus: WritingExecutionOutcomeStatuses.success,
            summary: '章节交付正常，可继续推进。',
          ),
          stopOutcome: const LongTaskStopOutcome(
            present: true,
            category: LongTaskStopOutcomeCategories.completedNaturally,
            reason: 'completed_naturally',
            legacyStopReason: 'completed',
            summary: '章节交付正常，可继续推进。',
            completionReason: 'completed_naturally',
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.continueRun);
      expect(decision.legacyStopReason, isEmpty);
      expect(decision.blocksProgress, isFalse);
    });

    test('maps warning-only information signal into remind action', () {
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          _baseResult(
            overallStatus: WritingExecutionOutcomeStatuses.success,
            summary: '当前有轻量 information 提醒。',
            information: const WritingExecutionInformationSummary(
              present: true,
              summary: '待研究 1 项，继续前建议关注资料缺口。',
              evidenceGate: InformationEvidenceGateSignal(
                present: true,
                severity: InformationEvidenceGateSeverities.warning,
                recommendedDisposition:
                    InformationEvidenceRecommendedDispositions.accept,
              ),
            ),
          ),
          stopOutcome: const LongTaskStopOutcome(
            present: true,
            category: LongTaskStopOutcomeCategories.completedNaturally,
            reason: 'completed_naturally',
            legacyStopReason: 'completed',
            completionReason: 'completed_naturally',
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.remind);
      expect(decision.blocksProgress, isFalse);
      expect(decision.legacyStopReason, isEmpty);
    });

    test('maps expression constraint adjust-next signal into adjust_next', () {
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          _baseResult(
            overallStatus: WritingExecutionOutcomeStatuses.success,
            summary: '表达限制建议下一章回调。',
            nextAction: 'adjust_next_chapter',
            constraints: const WritingExecutionConstraintSummary(
              present: true,
              expressionConstraintGate: ExpressionConstraintGateSignal(
                present: true,
                severity: ExpressionConstraintGateSeverities.warning,
                recommendedDisposition:
                    ExpressionConstraintGateRecommendedDispositions.adjustNext,
                reason: 'expression_constraint_runtime_escalated',
                adjustNextChapter: true,
              ),
            ),
          ),
          stopOutcome: const LongTaskStopOutcome(
            present: true,
            category: LongTaskStopOutcomeCategories.completedNaturally,
            reason: 'completed_naturally',
            legacyStopReason: 'completed',
            completionReason: 'completed_naturally',
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.adjustNext);
      expect(decision.recoveryAction, 'adjust_next_chapter');
      expect(decision.legacyStopReason, isEmpty);
    });

    test('maps chapter length adjust-next discipline into adjust_next', () {
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          _baseResult(
            overallStatus: WritingExecutionOutcomeStatuses.success,
            summary: '当前章字数偏离尚可消化，下一章应回调分布。',
            constraints: const WritingExecutionConstraintSummary(
              present: true,
              chapterLengthConfigured: true,
              chapterLengthLevel: 'needs_rebalance',
              chapterLengthRecommendedAction: 'adjust_next_chapter',
              chapterLengthDiscipline: ChapterLengthDisciplineSummary(
                present: true,
                configured: true,
                currentLength: 2680,
                targetLength: 2200,
                preferredMinLength: 1800,
                preferredMaxLength: 2600,
                mildDeviationRatioThreshold: 0.18,
                severeDeviationRatioThreshold: 0.35,
                mildAdjacentDeltaRatioThreshold: 0.22,
                severeAdjacentDeltaRatioThreshold: 0.45,
                targetDeviationRatio: 0.22,
                level: 'needs_rebalance',
                recommendedAction: 'adjust_next_chapter',
                reviewSuggested: true,
              ),
            ),
          ),
          stopOutcome: const LongTaskStopOutcome(
            present: true,
            category: LongTaskStopOutcomeCategories.completedNaturally,
            reason: 'completed_naturally',
            legacyStopReason: 'completed',
            completionReason: 'completed_naturally',
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.adjustNext);
      expect(decision.recoveryAction, 'adjust_next_chapter');
      expect(decision.legacyStopReason, isEmpty);
    });

    test('maps recoverable delivery failure into repair', () {
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.recoverableFailure,
        summary: '章节正文缺失，需要补交付。',
        delivery: const WritingExecutionDeliverySummary(
          present: true,
          deliveryId: 'delivery_001',
          state: ChapterDeliveryStateStatuses.missingOutputRecoverable,
          recommendedAction: 'request_chapter_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
          reason: 'chapter_content_missing',
          summary: '章节正文缺失，需要补交付。',
          blocksProgress: true,
          retryable: true,
        ),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_repair',
          reason: 'delivery_recovery_required',
          note: '先补写正文再继续。',
          requiresRepair: true,
          retryable: true,
        ),
      );
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          result,
          stopOutcome:
              const LongTaskStopOutcomeResolverService().fromWritingExecutionResult(
            result,
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.repair);
      expect(decision.runStatus, LongTaskRunStatus.recovering.id);
      expect(decision.legacyStopReason, 'delivery_repair_required');
      expect(decision.stopOutcome.category,
          LongTaskStopOutcomeCategories.deliveryFailure);
    });

    test('maps technical failure into pause', () {
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.technicalFailure,
        summary: 'provider 调用失败。',
        retryable: true,
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_failure',
          reason: 'provider_transport_failed',
          note: 'provider 调用失败。',
          retryable: true,
        ),
      );
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          result,
          stopOutcome:
              const LongTaskStopOutcomeResolverService().fromWritingExecutionResult(
            result,
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.pause);
      expect(decision.runStatus, LongTaskRunStatus.paused.id);
      expect(decision.legacyStopReason, 'step_failed');
    });

    test('maps waiting user into waiting_user', () {
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.userActionRequired,
        summary: '等待用户确认是否继续补研究。',
        requiresUserAction: true,
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'checkpoint_user',
          reason: 'information_waiting_user',
          summary: '待确认 1 项。',
          waitingUser: true,
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.blocking,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.checkpointUser,
            waitingUser: true,
          ),
        ),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'resume_when_user_confirms',
          reason: 'information_waiting_user',
          note: '等待用户确认是否继续补研究。',
          waitingUser: true,
        ),
      );
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          result,
          stopOutcome:
              const LongTaskStopOutcomeResolverService().fromWritingExecutionResult(
            result,
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.waitingUser);
      expect(decision.runStatus, LongTaskRunStatus.waitingGate.id);
      expect(decision.legacyStopReason, 'waiting_user_checkpoint');
    });

    test('maps content quality/manual attention into manual_attention', () {
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.contentQualityIssue,
        summary: '本轮输出只剩标题，需人工复核。',
        blocksProgress: true,
        delivery: const WritingExecutionDeliverySummary(
          present: true,
          deliveryId: 'delivery_002',
          state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
          recommendedAction: 'request_chapter_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
          reason: 'title_only_output',
          summary: '本轮输出只剩标题，需人工复核。',
          blocksProgress: true,
        ),
      );
      final decision = service.decide(
        SupervisorInputBundle.fromWritingExecutionResult(
          result,
          stopOutcome:
              const LongTaskStopOutcomeResolverService().fromWritingExecutionResult(
            result,
          ),
        ),
      );

      expect(decision.action, SupervisorDecisionActions.manualAttention);
      expect(decision.runStatus, LongTaskRunStatus.failedManualAttention.id);
      expect(decision.legacyStopReason, 'delivery_manual_attention');
    });

    test('signal service derives legacy stop reason from centralized decision', () {
      final result = _baseResult(
        overallStatus: WritingExecutionOutcomeStatuses.recoverableFailure,
        summary: '信息网关失败，需要先修复。',
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'repair',
          reason: 'information_gateway_failed',
          summary: '研究网关失败 1 项。',
          requiresRepair: true,
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.blocking,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.repair,
            requiresRepair: true,
          ),
        ),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_repair',
          reason: 'information_gateway_failed',
          note: '信息网关失败，需要先修复。',
          requiresRepair: true,
          retryable: true,
        ),
      );
      final signal = const LongTaskWritingExecutionSignalService()
          .signalFromWritingExecutionResult(result);
      final decision = SupervisorDecision.fromJson(
        ValueReaders.mapValue(signal['supervisor_decision']),
      );

      expect(ValueReaders.stringValue(signal['category']), 'recoverable');
      expect(ValueReaders.stringValue(signal['legacy_stop_reason']),
          decision.legacyStopReason);
      expect(decision.action, SupervisorDecisionActions.repair);
      expect(decision.legacyStopReason, 'information_repair_required');
    });
  });
}

WritingExecutionResult _baseResult({
  required String overallStatus,
  required String summary,
  WritingExecutionDeliverySummary delivery = const WritingExecutionDeliverySummary(),
  WritingExecutionConstraintSummary constraints =
      const WritingExecutionConstraintSummary(),
  WritingExecutionInformationSummary information =
      const WritingExecutionInformationSummary(),
  WritingExecutionCollaborationSummary collaboration =
      const WritingExecutionCollaborationSummary(),
  WritingExecutionRecoverySummary recovery =
      const WritingExecutionRecoverySummary(),
  String nextAction = '',
  bool blocksProgress = false,
  bool retryable = false,
  bool requiresUserAction = false,
}) {
  // 中文注释: 这里统一生成最小共享写作结果夹具，保证 focused tests 覆盖 supervisor 合同而不是被无关组装噪音干扰。
  return WritingExecutionResult(
    executionId: 'supervisor_exec_001',
    workflowKind: 'long_task',
    overallStatus: overallStatus,
    summary: summary,
    delivery: delivery,
    constraints: constraints,
    information: information,
    collaboration: collaboration,
    recovery: recovery,
    nextAction: nextAction,
    blocksProgress: blocksProgress,
    retryable: retryable,
    requiresUserAction: requiresUserAction,
  );
}
