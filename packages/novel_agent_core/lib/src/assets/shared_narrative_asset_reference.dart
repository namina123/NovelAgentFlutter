class SharedNarrativeAssetReference {
  const SharedNarrativeAssetReference({
    required this.referenceKey,
    required this.assetId,
    required this.assetKind,
    required this.displayName,
    this.summary = '',
    this.entityIds = const <String>[],
    this.relatedReferenceKeys = const <String>[],
    this.missingReferenceKeys = const <String>[],
    this.sourcePath = '',
  });

  final String referenceKey;
  final String assetId;
  final String assetKind;
  final String displayName;
  final String summary;
  final List<String> entityIds;
  final List<String> relatedReferenceKeys;
  final List<String> missingReferenceKeys;
  final String sourcePath;
}
