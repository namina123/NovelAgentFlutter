abstract final class SupervisorDecisionActions {
  static const String continueRun = 'continue';
  static const String remind = 'remind';
  static const String adjustNext = 'adjust_next';
  static const String repair = 'repair';
  static const String pause = 'pause';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';

  static const List<String> knownValues = <String>[
    continueRun,
    remind,
    adjustNext,
    repair,
    pause,
    waitingUser,
    manualAttention,
  ];
}
