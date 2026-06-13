abstract final class ContinuousTaskTerminalDispositions {
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';
  static const String stopped = 'stopped';

  static const List<String> knownValues = <String>[
    completed,
    cancelled,
    failed,
    stopped,
  ];
}
