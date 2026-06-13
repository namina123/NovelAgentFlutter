abstract class LongTaskWatchdogDispatchPort {
  bool get isWatchdogRunning;

  void clearDispatchState(String runId);
}
