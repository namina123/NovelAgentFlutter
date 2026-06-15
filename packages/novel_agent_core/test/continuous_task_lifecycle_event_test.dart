import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskLifecycleEvent', () {
    const resolver = ContinuousTaskLifecycleEventResolverService();

    test('projects pause and resume lifecycle facts into shared events', () {
      final paused = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.running,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.paused,
          stopCategory: ContinuousTaskStopCategories.constraintGatePause,
          reason: 'constraint_gate_pause',
          metadata: <String, Object?>{'watchdog_pulse': 'pulse_001'},
        ),
      );
      final resumed = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.paused,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.running,
          reason: 'resume_dispatch',
          metadata: <String, Object?>{'source_contract': 'supervisor'},
        ),
      );

      expect(paused.validateBasics(), isEmpty);
      expect(paused.kind, ContinuousTaskLifecycleEventKinds.pause);
      expect(paused.isPauseLike, isTrue);
      expect(paused.isTerminal, isFalse);
      expect(
        paused.toJson()['metadata'],
        containsPair('watchdog_pulse', 'pulse_001'),
      );

      expect(resumed.validateBasics(), isEmpty);
      expect(resumed.kind, ContinuousTaskLifecycleEventKinds.resume);
      expect(resumed.isResumeLike, isTrue);
      expect(resumed.toRunPhase, ContinuousTaskRunPhases.running);
    });

    test('projects waiting-user, manual-attention and terminal outcomes', () {
      final waitingUser = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.running,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.waitingUser,
          stopCategory: ContinuousTaskStopCategories.waitingUser,
          reason: 'information_waiting_user',
        ),
      );
      final manualAttention = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.running,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.manualAttention,
          stopCategory: ContinuousTaskStopCategories.manualAttention,
          reason: 'delivery_manual_attention',
        ),
      );
      final finished = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.running,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.stopped,
          terminalDisposition: ContinuousTaskTerminalDispositions.completed,
          stopCategory: ContinuousTaskStopCategories.completedNaturally,
          reason: 'completed_naturally',
        ),
      );
      final failed = resolver.fromTransition(
        fromRunPhase: ContinuousTaskRunPhases.running,
        toState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.stopped,
          terminalDisposition: ContinuousTaskTerminalDispositions.failed,
          stopCategory: ContinuousTaskStopCategories.technicalFailure,
          reason: 'provider_transport_failed',
        ),
      );

      expect(waitingUser.validateBasics(), isEmpty);
      expect(waitingUser.kind, ContinuousTaskLifecycleEventKinds.waitingUser);
      expect(waitingUser.isWaitingUserLike, isTrue);
      expect(waitingUser.isPauseLike, isTrue);

      expect(manualAttention.validateBasics(), isEmpty);
      expect(
        manualAttention.kind,
        ContinuousTaskLifecycleEventKinds.manualAttention,
      );
      expect(manualAttention.isManualAttentionLike, isTrue);
      expect(manualAttention.isPauseLike, isTrue);

      expect(finished.validateBasics(), isEmpty);
      expect(finished.kind, ContinuousTaskLifecycleEventKinds.finish);
      expect(finished.isTerminal, isTrue);
      expect(
        finished.terminalDisposition,
        ContinuousTaskTerminalDispositions.completed,
      );

      expect(failed.validateBasics(), isEmpty);
      expect(failed.kind, ContinuousTaskLifecycleEventKinds.fail);
      expect(failed.isTerminal, isTrue);
      expect(failed.stopCategory, ContinuousTaskStopCategories.technicalFailure);
    });

    test('serializes and validates the unified event contract', () {
      const event = ContinuousTaskLifecycleEvent(
        kind: ContinuousTaskLifecycleEventKinds.recover,
        fromRunPhase: ContinuousTaskRunPhases.paused,
        toRunPhase: ContinuousTaskRunPhases.recovering,
        stopCategory: ContinuousTaskStopCategories.technicalFailure,
        reason: 'provider_transport_failed',
        metadata: <String, Object?>{'watchdog_pulse': 'pulse_001'},
      );
      final roundTripped = ContinuousTaskLifecycleEvent.fromJson(event.toJson());

      expect(roundTripped.validateBasics(), isEmpty);
      expect(roundTripped.kind, ContinuousTaskLifecycleEventKinds.recover);
      expect(roundTripped.fromRunPhase, ContinuousTaskRunPhases.paused);
      expect(roundTripped.toRunPhase, ContinuousTaskRunPhases.recovering);
      expect(
        ValueReaders.stringValue(roundTripped.metadata['watchdog_pulse']),
        'pulse_001',
      );
    });
  });
}
