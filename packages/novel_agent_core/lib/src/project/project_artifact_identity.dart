final class ProjectArtifactIdentity {
  const ProjectArtifactIdentity({
    required this.kindId,
    required this.shortLabel,
    required this.detailLabel,
    this.isFormalAsset = false,
    this.isProjection = false,
    this.isCompatibilityEntry = false,
  });

  final String kindId;
  final String shortLabel;
  final String detailLabel;
  final bool isFormalAsset;
  final bool isProjection;
  final bool isCompatibilityEntry;

  bool get isKnown => kindId.isNotEmpty;

  static const ProjectArtifactIdentity unknown = ProjectArtifactIdentity(
    kindId: '',
    shortLabel: '',
    detailLabel: '',
  );
}
