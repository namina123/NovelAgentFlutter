import 'active_continuity_frame.dart';
import 'active_scope_chain.dart';
import 'continuity_asset_reference.dart';
import 'continuity_mechanic_profile.dart';

class ContinuityResolutionResult {
  const ContinuityResolutionResult({
    required this.bundleId,
    required this.scopeChain,
    required this.activeFrame,
    required this.mechanicProfile,
    this.canonicalAssetReferences = const <ContinuityAssetReference>[],
    this.overlayAssetReferences = const <ContinuityAssetReference>[],
    this.stateAssetReferences = const <ContinuityAssetReference>[],
    this.effectiveAssetReferences = const <ContinuityAssetReference>[],
    this.inheritsParentState = false,
    this.inheritsParentMemory = false,
    this.branchesFromParent = false,
    this.replayAware = false,
  });

  final String bundleId;
  final ActiveScopeChain scopeChain;
  final ActiveContinuityFrame activeFrame;
  final ContinuityMechanicProfile mechanicProfile;
  final List<ContinuityAssetReference> canonicalAssetReferences;
  final List<ContinuityAssetReference> overlayAssetReferences;
  final List<ContinuityAssetReference> stateAssetReferences;
  final List<ContinuityAssetReference> effectiveAssetReferences;
  final bool inheritsParentState;
  final bool inheritsParentMemory;
  final bool branchesFromParent;
  final bool replayAware;
}
