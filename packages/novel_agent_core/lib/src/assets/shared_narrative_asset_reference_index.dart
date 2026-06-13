import 'shared_narrative_asset_reference.dart';

class SharedNarrativeAssetReferenceIndex {
  const SharedNarrativeAssetReferenceIndex({
    this.references = const <SharedNarrativeAssetReference>[],
  });

  final List<SharedNarrativeAssetReference> references;

  SharedNarrativeAssetReference? referenceByKey(String referenceKey) {
    final cleanKey = referenceKey.trim();
    if (cleanKey.isEmpty) {
      return null;
    }
    for (final reference in references) {
      if (reference.referenceKey == cleanKey) {
        return reference;
      }
    }
    return null;
  }

  SharedNarrativeAssetReference? referenceOf(String assetKind, String assetId) {
    return referenceByKey('$assetKind:$assetId');
  }

  List<SharedNarrativeAssetReference> neighborsOf(
    String assetKind,
    String assetId,
  ) {
    final center = referenceOf(assetKind, assetId);
    if (center == null) {
      return const <SharedNarrativeAssetReference>[];
    }
    final neighbors = <SharedNarrativeAssetReference>[];
    for (final reference in references) {
      if (center.relatedReferenceKeys.contains(reference.referenceKey)) {
        neighbors.add(reference);
      }
    }
    return neighbors;
  }
}
