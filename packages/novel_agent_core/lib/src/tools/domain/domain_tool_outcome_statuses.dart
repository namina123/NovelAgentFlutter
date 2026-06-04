abstract final class DomainToolOutcomeStatuses {
  static const String accepted = 'accepted';
  static const String proposed = 'proposed';
  static const String rejected = 'rejected';
  static const String needsUserConfirmation = 'needs_user_confirmation';
  static const String invalidPayload = 'invalid_payload';
  static const String executionFailed = 'execution_failed';

  static const List<String> knownValues = <String>[
    accepted,
    proposed,
    rejected,
    needsUserConfirmation,
    invalidPayload,
    executionFailed,
  ];
}
