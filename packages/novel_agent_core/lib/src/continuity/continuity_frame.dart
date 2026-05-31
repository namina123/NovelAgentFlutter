import 'continuity_asset_reference.dart';

enum ContinuityFrameRelation {
  sameLine,
  childScope,
  fork,
  reset,
  replay,
  overwrite,
}

class ContinuityFrame {
  const ContinuityFrame({
    required this.id,
    required this.displayName,
    required this.scopeId,
    this.mechanicProfileId = '',
    this.parentFrameId = '',
    this.relation = ContinuityFrameRelation.sameLine,
    this.stateReferences = const <ContinuityAssetReference>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String scopeId;
  final String mechanicProfileId;
  final String parentFrameId;
  final ContinuityFrameRelation relation;
  final List<ContinuityAssetReference> stateReferences;
  final String notes;
  final Map<String, Object?> metadata;
}
