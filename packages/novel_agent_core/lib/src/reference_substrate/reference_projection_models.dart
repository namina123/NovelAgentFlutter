class ReferenceProjectionRequest {
  const ReferenceProjectionRequest({
    required this.packageId,
    required this.requestedBy,
    this.packageVersionId = '',
    this.entryIds = const <String>[],
    this.explicitConfirmationGranted = false,
  });

  final String packageId;
  final String packageVersionId;
  final List<String> entryIds;
  final String requestedBy;
  final bool explicitConfirmationGranted;
}

class ReferenceProjectionResult {
  const ReferenceProjectionResult({
    required this.status,
    required this.packageId,
    required this.packageVersionId,
    this.knowledgeCardIds = const <String>[],
    this.designElementIds = const <String>[],
    this.researchNoteIds = const <String>[],
    this.referenceWorkIds = const <String>[],
    this.generatedProjectionPaths = const <String>[],
    this.warnings = const <String>[],
  });

  final String status;
  final String packageId;
  final String packageVersionId;
  final List<String> knowledgeCardIds;
  final List<String> designElementIds;
  final List<String> researchNoteIds;
  final List<String> referenceWorkIds;
  final List<String> generatedProjectionPaths;
  final List<String> warnings;
}

class ReferencePromotionRequest {
  const ReferencePromotionRequest({
    required this.packageId,
    required this.packageKind,
    required this.displayName,
    required this.packageVersionId,
    required this.versionLabel,
    required this.sourceProjectId,
    required this.sourceArtifactKind,
    required this.sourceArtifactId,
    required this.promotedAt,
    required this.promotedBy,
    this.packageNamespace = '',
    this.targetEntryId = '',
    this.targetEntryNamespace = '',
    this.targetEntryKind = '',
  });

  final String packageId;
  final String packageKind;
  final String displayName;
  final String packageNamespace;
  final String packageVersionId;
  final String versionLabel;
  final String sourceProjectId;
  final String sourceArtifactKind;
  final String sourceArtifactId;
  final String promotedAt;
  final String promotedBy;
  final String targetEntryId;
  final String targetEntryNamespace;
  final String targetEntryKind;
}

class ReferencePromotionResult {
  const ReferencePromotionResult({
    required this.status,
    required this.packageId,
    required this.packageVersionId,
    this.entryId = '',
    this.warnings = const <String>[],
  });

  final String status;
  final String packageId;
  final String packageVersionId;
  final String entryId;
  final List<String> warnings;
}
