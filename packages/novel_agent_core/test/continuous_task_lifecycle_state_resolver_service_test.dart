import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskLifecycleStateResolverService', () {
    const service = ContinuousTaskLifecycleStateResolverService();

    test('maps waiting gate into shared waiting-user phase', () {
      final state = service.fromLongTask(
        status: LongTaskRunStatus.waitingGate,
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.waitingUser,
          reason: 'information_waiting_user',
        ),
      );

      expect(state.validateBasics(), isEmpty);
      expect(state.runPhase, ContinuousTaskRunPhases.waitingUser);
      expect(state.requiresUserAction, isTrue);
      expect(state.terminalDisposition, isEmpty);
    });

    test('maps failed manual attention into shared manual-attention phase', () {
      final state = service.fromLongTask(
        status: LongTaskRunStatus.failedManualAttention,
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.manualAttention,
          reason: 'delivery_manual_attention',
        ),
      );

      expect(state.validateBasics(), isEmpty);
      expect(state.runPhase, ContinuousTaskRunPhases.manualAttention);
      expect(state.requiresManualAttention, isTrue);
      expect(state.isPausedLike, isTrue);
    });

    test('maps completed stop into terminal completed semantics', () {
      final state = service.fromLongTask(
        status: LongTaskRunStatus.stopped,
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.completedNaturally,
          reason: 'completed_naturally',
          legacyStopReason: 'completed',
        ),
      );

      expect(state.validateBasics(), isEmpty);
      expect(state.runPhase, ContinuousTaskRunPhases.stopped);
      expect(
        state.terminalDisposition,
        ContinuousTaskTerminalDispositions.completed,
      );
      expect(
        state.stopCategory,
        ContinuousTaskStopCategories.completedNaturally,
      );
    });

    test('maps technical failure stop into terminal failed semantics', () {
      final state = service.fromLongTask(
        status: LongTaskRunStatus.stopped,
        stopOutcome: const LongTaskStopOutcome(
          present: true,
          category: LongTaskStopOutcomeCategories.technicalFailure,
          reason: 'provider_transport_failed',
          legacyStopReason: 'step_failed',
        ),
      );

      expect(state.validateBasics(), isEmpty);
      expect(
        state.terminalDisposition,
        ContinuousTaskTerminalDispositions.failed,
      );
      expect(state.stopCategory, ContinuousTaskStopCategories.technicalFailure);
    });

    test(
      'maps user-requested stop into terminal cancelled semantics without inventing a new runtime path',
      () {
        final state = service.fromLongTask(
          status: LongTaskRunStatus.stopped,
          legacyStopReason: 'user_requested',
        );

        expect(state.validateBasics(), isEmpty);
        expect(
          state.terminalDisposition,
          ContinuousTaskTerminalDispositions.cancelled,
        );
        expect(state.stopCategory, ContinuousTaskStopCategories.cancelled);
        expect(state.reason, 'user_requested');
      },
    );

    test('maps budget stop into neutral stopped terminal semantics', () {
      final state = service.fromLongTask(
        status: LongTaskRunStatus.stopped,
        legacyStopReason: 'max_steps',
      );

      expect(state.validateBasics(), isEmpty);
      expect(
        state.terminalDisposition,
        ContinuousTaskTerminalDispositions.stopped,
      );
      expect(state.stopCategory, ContinuousTaskStopCategories.budgetExhausted);
    });
  });
}
