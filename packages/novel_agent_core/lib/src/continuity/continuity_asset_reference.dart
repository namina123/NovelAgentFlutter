enum ContinuityAssetKind {
  characterProfile,
  characterStageStateRecord,
  foreshadowRecord,
  organizationProfile,
  relationshipRecord,
  styleProfile,
  timelineRecord,
  worldRuleSet,
}

enum ContinuityAssetReferenceRole { canonicalFact, scopeOverlay, runtimeState }

class ContinuityAssetReference {
  const ContinuityAssetReference({
    required this.assetKind,
    required this.assetId,
    this.role = ContinuityAssetReferenceRole.canonicalFact,
    this.displayName = '',
    this.sourcePath = '',
    this.note = '',
    this.metadata = const <String, Object?>{},
  });

  final ContinuityAssetKind assetKind;
  final String assetId;
  final ContinuityAssetReferenceRole role;
  final String displayName;
  final String sourcePath;
  final String note;
  final Map<String, Object?> metadata;
}
