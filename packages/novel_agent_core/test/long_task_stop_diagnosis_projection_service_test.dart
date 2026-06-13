import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskStopDiagnosisProjectionService', () {
    const service = LongTaskStopDiagnosisProjectionService();

    test('prefers formal stop outcome taxonomy over legacy reason', () {
      final diagnosis = service.project(
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.waitingUser,
          reason: 'information_waiting_user',
          legacyStopReason: 'waiting_user_checkpoint',
          summary: '等待用户确认是否继续补研究。',
        ),
        legacyReason: 'failed_task',
      );

      expect(diagnosis.present, isTrue);
      expect(diagnosis.category, LongTaskStopOutcomeCategories.waitingUser);
      expect(diagnosis.label, '等待用户确认');
      expect(diagnosis.summary, '等待用户确认是否继续补研究。');
    });

    test(
      'uses review summary for manual attention instead of raw gate reason',
      () {
        final diagnosis = service.project(
          legacyReason: 'delivery_manual_attention',
          reviewSummary: '结尾冲突不足，需要人工复核。',
          note: 'content quality gate triggered',
        );

        expect(
          diagnosis.category,
          LongTaskStopOutcomeCategories.manualAttention,
        );
        expect(diagnosis.label, '需要人工处理');
        expect(diagnosis.summary, '结尾冲突不足，需要人工复核。');
      },
    );

    test('maps recovery repair state into constraint gate pause', () {
      final diagnosis = service.project(
        recoveryState: const LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.repairRequired,
          runStatus: 'paused',
          recommendedAction: 'pause_for_repair',
          reason: 'delivery_repair_required',
          note: '当前运行停在返工关口。',
          requiresRepair: true,
          blocksProgress: true,
        ),
        legacyReason: 'failed_task',
      );

      expect(
        diagnosis.category,
        LongTaskStopOutcomeCategories.constraintGatePause,
      );
      expect(diagnosis.label, '需修补后继续');
      expect(diagnosis.summary, '当前运行停在返工关口。');
    });

    test('maps budget stop and natural completion separately', () {
      final budget = service.project(legacyReason: 'max_steps');
      final completed = service.project(legacyReason: 'completed');

      expect(budget.category, LongTaskStopOutcomeCategories.budgetExhausted);
      expect(budget.label, '预算边界已到');
      expect(
        completed.category,
        LongTaskStopOutcomeCategories.completedNaturally,
      );
      expect(completed.label, '自然完成');
    });
  });
}
