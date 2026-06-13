import 'package:flutter_test/flutter_test.dart';

import '../tool/hfvv_wave2_long_task_progress_support.dart';

void main() {
  group('nextWave2LongTaskStagnationCount', () {
    test('resets when chapters advance', () {
      final count = nextWave2LongTaskStagnationCount(
        currentStagnationCount: 2,
        previousEffectiveChapters: 2,
        newEffectiveChapters: 3,
        structuralProgressObserved: false,
        actionUsed: false,
        pendingSharedActionAvailable: false,
      );

      expect(count, 0);
    });

    test('resets when a queue settle surfaces a new shared action', () {
      final count = nextWave2LongTaskStagnationCount(
        currentStagnationCount: 2,
        previousEffectiveChapters: 2,
        newEffectiveChapters: 2,
        structuralProgressObserved: false,
        actionUsed: false,
        pendingSharedActionAvailable: true,
      );

      expect(count, 0);
    });

    test('resets when non-chapter task flow still advances structurally', () {
      final count = nextWave2LongTaskStagnationCount(
        currentStagnationCount: 2,
        previousEffectiveChapters: 2,
        newEffectiveChapters: 2,
        structuralProgressObserved: true,
        actionUsed: false,
        pendingSharedActionAvailable: false,
      );

      expect(count, 0);
    });

    test('increments only when no progress and no follow-up action exist', () {
      final count = nextWave2LongTaskStagnationCount(
        currentStagnationCount: 2,
        previousEffectiveChapters: 2,
        newEffectiveChapters: 2,
        structuralProgressObserved: false,
        actionUsed: false,
        pendingSharedActionAvailable: false,
      );

      expect(count, 3);
    });
  });

  group('shouldStopWave2LongTaskLoop', () {
    test('keeps loop alive when a pending shared action is available', () {
      expect(
        shouldStopWave2LongTaskLoop(
          stagnationCount: 3,
          pendingSharedActionAvailable: true,
        ),
        isFalse,
      );
    });

    test('stops after three stagnant rounds with no pending action', () {
      expect(
        shouldStopWave2LongTaskLoop(
          stagnationCount: 3,
          pendingSharedActionAvailable: false,
        ),
        isTrue,
      );
    });
  });
}
