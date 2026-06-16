abstract final class HostToolPermissionDispositions {
  static const String accepted = 'accepted';
  static const String needsUserConfirmation = 'needs_user_confirmation';
  static const String blocked = 'blocked';

  static const List<String> knownValues = <String>[
    accepted,
    needsUserConfirmation,
    blocked,
  ];
}
