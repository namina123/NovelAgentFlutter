class ProjectAgentModelOverride {
  const ProjectAgentModelOverride({
    required this.agentId,
    this.providerProfile = '',
    this.modelId = '',
    this.thinkingEnabled,
    this.thinkingEffort = '',
    this.temperature,
    this.topP,
    this.topK,
    this.advancedModelOverrides = const <Object?>[],
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final String providerProfile;
  final String modelId;
  final bool? thinkingEnabled;
  final String thinkingEffort;
  final double? temperature;
  final double? topP;
  final int? topK;
  final List<Object?> advancedModelOverrides;
  final Map<String, Object?> metadata;
}
