import 'shared_narrative_asset_reference.dart';

class SharedNarrativeAssetReferenceIndex {
  const SharedNarrativeAssetReferenceIndex({
    this.references = const <SharedNarrativeAssetReference>[],
  });

  final List<SharedNarrativeAssetReference> references;

  SharedNarrativeAssetReference? referenceOf(String assetKind, String assetId) {
    final referenceKey = '$assetKind:$assetId';
    for (final reference in references) {
      if (reference.referenceKey == referenceKey) {
        return reference;
      }
    }
    return null;
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
