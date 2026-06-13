abstract final class ToolExposureLevels {
  static const String defaultOpen = 'default_open';
  static const String requiresConfirmation = 'requires_confirmation';
  static const String hostOrSupervisorOnly = 'host_or_supervisor_only';

  static const List<String> values = <String>[
    defaultOpen,
    requiresConfirmation,
    hostOrSupervisorOnly,
  ];

  static bool contains(String candidate) {
    return values.contains(candidate.trim());
  }
}
