int nextWave2LongTaskStagnationCount({
  required int currentStagnationCount,
  required int previousEffectiveChapters,
  required int newEffectiveChapters,
  required bool structuralProgressObserved,
  required bool actionUsed,
  required bool pendingSharedActionAvailable,
}) {
  if (newEffectiveChapters > previousEffectiveChapters) {
    return 0;
  }
  if (structuralProgressObserved ||
      actionUsed ||
      pendingSharedActionAvailable) {
    return 0;
  }
  return currentStagnationCount + 1;
}

bool shouldStopWave2LongTaskLoop({
  required int stagnationCount,
  required bool pendingSharedActionAvailable,
}) {
  return stagnationCount >= 3 && !pendingSharedActionAvailable;
}
