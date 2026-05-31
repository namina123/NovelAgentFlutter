import 'continuity_asset_reference.dart';

class ContinuationScopeOverlay {
  const ContinuationScopeOverlay({
    required this.id,
    required this.scopeId,
    required this.displayName,
    this.priority = 0,
    this.assetReferences = const <ContinuityAssetReference>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String scopeId;
  final String displayName;
  final int priority;
  final List<ContinuityAssetReference> assetReferences;
  final String notes;
  final Map<String, Object?> metadata;
}
