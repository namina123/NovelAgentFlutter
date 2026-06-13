import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskStopOutcomeResolverService', () {
    const resolver = LongTaskStopOutcomeResolverService();

    test('round-trips taxonomy contract for natural completion', () {
      // 中文注释: 这里验证新的 stop outcome 合同可以稳定序列化回读，并保留 completion reason。
      const outcome = LongTaskStopOutcome(
        present: true,
        category: LongTaskStopOutcomeCategories.completedNaturally,
        reason: 'completed_naturally',
        legacyStopReason: 'completed',
        summary: '长任务自然完成。',
        completionReason: 'completed_naturally',
      );

      final roundTrip = LongTaskStopOutcome.fromJson(outcome.toJson());

      expect(roundTrip.category, LongTaskStopOutcomeCategories.completedNaturally);
      expect(roundTrip.legacyStopReason, 'completed');
      expect(roundTrip.completionReason, 'completed_naturally');
      expect(roundTrip.validateBasics(), isEmpty);
    });

    test('maps legacy stop reasons into unified categories', () {
      // 中文注释: 这里验证常见旧字符串至少能稳定归到八类正式结局之一，避免后续 session 再各自硬编码。
      final budget = resolver.fromLegacyStopReason('max_steps');
      final waiting = resolver.fromLegacyStopReason('waiting_user_checkpoint');
      final manual = resolver.fromLegacyStopReason('delivery_manual_attention');

      expect(budget.category, LongTaskStopOutcomeCategories.budgetExhausted);
      expect(waiting.category, LongTaskStopOutcomeCategories.waitingUser);
      expect(manual.category, LongTaskStopOutcomeCategories.manualAttention);
    });

    test('maps recoverable delivery failure into delivery_failure', () {
      // 中文注释: 这里验证 chapter delivery block 会先落到正式 delivery_failure，而不是继续混成 failed_task。
      final result = WritingExecutionResult(
        executionId: 'exec_delivery_failure',
        workflowKind: 'long_task',
        overallStatus: WritingExecutionOutcomeStatuses.recoverableFailure,
        summary: '章节正文缺失，需要补交付。',
        delivery: const WritingExecutionDeliverySummary(
          present: true,
          deliveryId: 'delivery_1',
          state: ChapterDeliveryStateStatuses.missingOutputRecoverable,
          recommendedAction: 'request_chapter_repair',
          reason: 'chapter_content_missing',
          summary: '章节正文缺失。',
          blocksProgress: true,
          retryable: true,
        ),
        constraints: const WritingExecutionConstraintSummary(),
        information: const WritingExecutionInformationSummary(),
        collaboration: const WritingExecutionCollaborationSummary(),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_repair',
          reason: 'delivery_recovery_required',
          requiresRepair: true,
        ),
        blocksProgress: true,
        retryable: true,
      );

      final outcome = resolver.fromWritingExecutionResult(result);

      expect(outcome.category, LongTaskStopOutcomeCategories.deliveryFailure);
      expect(outcome.reason, 'chapter_content_missing');
      expect(outcome.legacyStopReason, 'delivery_repair_required');
      expect(outcome.validateBasics(), isEmpty);
    });

    test('maps hard constraint gate into constraint_gate_pause', () {
      // 中文注释: 这里验证表达限制等 shared constraint 的硬 gate 会进入统一约束暂停，而不是误记为 delivery/manual attention。
      final result = WritingExecutionResult(
        executionId: 'exec_constraint_pause',
        workflowKind: 'long_task',
        overallStatus: WritingExecutionOutcomeStatuses.contentQualityIssue,
        summary: '表达限制硬 gate 阻断继续。',
        delivery: const WritingExecutionDeliverySummary(),
        constraints: const WritingExecutionConstraintSummary(
          present: true,
          hardConstraintTriggered: true,
          repairRequired: true,
          hardGateReasons: <String>['expression_constraint_review_missing'],
        ),
        information: const WritingExecutionInformationSummary(),
        collaboration: const WritingExecutionCollaborationSummary(),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_repair',
          reason: 'constraint_repair_required',
          requiresRepair: true,
        ),
        blocksProgress: true,
      );

      final outcome = resolver.fromWritingExecutionResult(result);

      expect(outcome.category, LongTaskStopOutcomeCategories.constraintGatePause);
      expect(outcome.reason, 'expression_constraint_review_missing');
      expect(outcome.validateBasics(), isEmpty);
    });

    test('maps user action required into waiting_user', () {
      // 中文注释: 这里验证 information/recovery 层等待确认会进入 waiting_user，而不是被 generic recoverable failure 吞掉。
      final result = WritingExecutionResult(
        executionId: 'exec_waiting_user',
        workflowKind: 'long_task',
        overallStatus: WritingExecutionOutcomeStatuses.userActionRequired,
        summary: '等待用户确认是否继续补研究。',
        delivery: const WritingExecutionDeliverySummary(),
        constraints: const WritingExecutionConstraintSummary(),
        information: const WritingExecutionInformationSummary(
          present: true,
          waitingUser: true,
          summary: '待确认 1 项。',
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.checkpointUser,
            waitingUser: true,
          ),
        ),
        collaboration: const WritingExecutionCollaborationSummary(),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'resume_when_user_confirms',
          reason: 'information_waiting_user',
          waitingUser: true,
        ),
        requiresUserAction: true,
      );

      final outcome = resolver.fromWritingExecutionResult(result);

      expect(outcome.category, LongTaskStopOutcomeCategories.waitingUser);
      expect(outcome.reason, 'information_waiting_user');
      expect(outcome.legacyStopReason, 'waiting_user_checkpoint');
      expect(outcome.validateBasics(), isEmpty);
    });

    test('maps information repair into delivery-failure category with stable reason', () {
      final result = WritingExecutionResult(
        executionId: 'exec_information_repair',
        workflowKind: 'long_task',
        overallStatus: WritingExecutionOutcomeStatuses.recoverableFailure,
        summary: '信息网关失败，需要先修复。',
        delivery: const WritingExecutionDeliverySummary(),
        constraints: const WritingExecutionConstraintSummary(),
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
            gatewayFailureCount: 1,
            requiresRepair: true,
          ),
        ),
        collaboration: const WritingExecutionCollaborationSummary(),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_repair',
          reason: 'information_gateway_failed',
          requiresRepair: true,
        ),
        blocksProgress: true,
        retryable: true,
      );

      final outcome = resolver.fromWritingExecutionResult(result);

      expect(outcome.category, LongTaskStopOutcomeCategories.deliveryFailure);
      expect(outcome.reason, 'information_gateway_failed');
      expect(outcome.legacyStopReason, 'information_repair_required');
      expect(outcome.validateBasics(), isEmpty);
    });
  });
}
