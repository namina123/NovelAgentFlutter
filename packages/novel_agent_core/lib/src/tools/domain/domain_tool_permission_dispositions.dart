abstract final class DomainToolPermissionDispositions {
  static const String accepted = 'accepted';
  static const String proposed = 'proposed';
  static const String rejected = 'rejected';
  static const String needsUserConfirmation = 'needs_user_confirmation';

  static const List<String> knownValues = <String>[
    accepted,
    proposed,
    rejected,
    needsUserConfirmation,
  ];
}
