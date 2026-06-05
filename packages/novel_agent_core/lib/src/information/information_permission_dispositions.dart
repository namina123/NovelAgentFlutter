abstract final class InformationPermissionDispositions {
  static const String autoAccept = 'auto_accept';
  static const String proposed = 'proposed';
  static const String needsUserConfirmation = 'needs_user_confirmation';
  static const String forbiddenAutoApply = 'forbidden_auto_apply';

  static const List<String> knownValues = <String>[
    autoAccept,
    proposed,
    needsUserConfirmation,
    forbiddenAutoApply,
  ];
}
