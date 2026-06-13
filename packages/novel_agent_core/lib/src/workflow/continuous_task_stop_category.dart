abstract final class ContinuousTaskStopCategories {
  static const String completedNaturally = 'completed_naturally';
  static const String cancelled = 'cancelled';
  static const String budgetExhausted = 'budget_exhausted';
  static const String technicalFailure = 'technical_failure';
  static const String deliveryFailure = 'delivery_failure';
  static const String constraintGatePause = 'constraint_gate_pause';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';
  static const String recoveryExhausted = 'recovery_exhausted';

  static const List<String> knownValues = <String>[
    completedNaturally,
    cancelled,
    budgetExhausted,
    technicalFailure,
    deliveryFailure,
    constraintGatePause,
    waitingUser,
    manualAttention,
    recoveryExhausted,
  ];
}
