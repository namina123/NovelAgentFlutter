abstract final class ContinuousTaskRunPhases {
  static const String draftingGuidance = 'drafting_guidance';
  static const String readyToStart = 'ready_to_start';
  static const String running = 'running';
  static const String waitingUser = 'waiting_user';
  static const String paused = 'paused';
  static const String recovering = 'recovering';
  static const String manualAttention = 'manual_attention';
  static const String stopped = 'stopped';

  static const List<String> knownValues = <String>[
    draftingGuidance,
    readyToStart,
    running,
    waitingUser,
    paused,
    recovering,
    manualAttention,
    stopped,
  ];
}
