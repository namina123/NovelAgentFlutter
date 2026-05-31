import 'continuation_scope.dart';
import 'continuation_scope_overlay.dart';
import 'continuity_asset_reference.dart';
import 'continuity_coverage.dart';
import 'continuity_frame.dart';
import 'continuity_mechanic_profile.dart';

class ProjectContinuityBundle {
  const ProjectContinuityBundle({
    required this.id,
    required this.displayName,
    this.coverage = const ContinuityCoverage(),
    this.canonicalAssetReferences = const <ContinuityAssetReference>[],
    this.scopes = const <ContinuationScope>[],
    this.scopeOverlays = const <ContinuationScopeOverlay>[],
    this.mechanicProfiles = const <ContinuityMechanicProfile>[],
    this.frames = const <ContinuityFrame>[],
    this.defaultMechanicProfileId = '',
    this.defaultFrameId = '',
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final ContinuityCoverage coverage;
  final List<ContinuityAssetReference> canonicalAssetReferences;
  final List<ContinuationScope> scopes;
  final List<ContinuationScopeOverlay> scopeOverlays;
  final List<ContinuityMechanicProfile> mechanicProfiles;
  final List<ContinuityFrame> frames;
  final String defaultMechanicProfileId;
  final String defaultFrameId;
  final String notes;
  final Map<String, Object?> metadata;
}
