final class ChapterAtomicConstants {
  static const String executionRoot = 'tracking/chapter_atomic';

  static const String stepPending = 'pending';
  static const String stepReady = 'ready';
  static const String stepRunning = 'running';
  static const String stepWaitingModel = 'waiting_model';
  static const String stepWaitingUser = 'waiting_user';
  static const String stepSucceeded = 'succeeded';
  static const String stepFailed = 'failed';
  static const String stepSkipped = 'skipped';

  static const List<String> validStepStatuses = <String>[
    stepPending,
    stepReady,
    stepRunning,
    stepWaitingModel,
    stepWaitingUser,
    stepSucceeded,
    stepFailed,
    stepSkipped,
  ];
}
