enum ContinuityFoundationBuildStageKind { preview, confirm, build, publish }

class ContinuityFoundationBuildStage {
  const ContinuityFoundationBuildStage({
    required this.kind,
    required this.displayName,
    this.summary = '',
    this.requiresUserInput = false,
    this.buildsArtifacts = false,
    this.publishesArtifacts = false,
    this.metadata = const <String, Object?>{},
  });

  final ContinuityFoundationBuildStageKind kind;
  final String displayName;
  final String summary;
  final bool requiresUserInput;
  final bool buildsArtifacts;
  final bool publishesArtifacts;
  final Map<String, Object?> metadata;
}
