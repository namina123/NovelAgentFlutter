class RuntimeBaseline {
  const RuntimeBaseline({
    required this.id,
    required this.title,
    required this.description,
    required this.supportedProjectTypeIds,
    this.defaultHeartbeatInterval = const Duration(seconds: 45),
    this.waitingGateHeartbeatInterval = const Duration(seconds: 90),
    this.recoveringHeartbeatInterval = const Duration(seconds: 20),
    this.staleAfter = const Duration(minutes: 5),
    this.unattended = true,
    this.keepAliveAcrossProjectSwitch = true,
    this.autoAdvanceChapters = true,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String description;
  final List<String> supportedProjectTypeIds;
  final Duration defaultHeartbeatInterval;
  final Duration waitingGateHeartbeatInterval;
  final Duration recoveringHeartbeatInterval;
  final Duration staleAfter;
  final bool unattended;
  final bool keepAliveAcrossProjectSwitch;
  final bool autoAdvanceChapters;
  final bool enabled;

  bool supportsProjectType(String projectTypeId) {
    final cleanProjectTypeId = projectTypeId.trim();
    return supportedProjectTypeIds.contains(cleanProjectTypeId);
  }
}
