import 'active_continuity_frame.dart';
import 'active_scope_chain.dart';
import 'continuation_scope.dart';
import 'continuation_scope_overlay.dart';
import 'continuity_asset_reference.dart';
import 'continuity_frame.dart';
import 'continuity_mechanic_profile.dart';
import 'continuity_resolution_result.dart';
import 'project_continuity_bundle.dart';

class ContinuityRuntimeResolverService {
  const ContinuityRuntimeResolverService();

  ContinuityResolutionResult resolve(
    ProjectContinuityBundle bundle, {
    String frameId = '',
    String scopeId = '',
    String mechanicProfileId = '',
  }) {
    final scopesById = <String, ContinuationScope>{
      for (final scope in bundle.scopes) scope.id: scope,
    };
    final framesById = <String, ContinuityFrame>{
      for (final frame in bundle.frames) frame.id: frame,
    };
    final selectedFrame = _selectFrame(bundle, framesById, frameId, scopeId);
    final activeFrame = ActiveContinuityFrame(
      frame: selectedFrame,
      frameChain: _resolveFrameChain(framesById, selectedFrame),
    );
    final selectedScopeId = selectedFrame?.scopeId ?? scopeId;
    final scopeChain = ActiveScopeChain(
      activeScope: scopesById[selectedScopeId],
      scopes: _resolveScopeChain(scopesById, selectedScopeId),
    );
    final mechanicProfile = _selectMechanicProfile(
      bundle,
      activeFrame.frame,
      mechanicProfileId,
    );
    final overlayAssetReferences = _resolveOverlayAssetReferences(
      bundle.scopeOverlays,
      scopeChain.scopeIds,
    );
    final stateAssetReferences = _resolveStateAssetReferences(
      activeFrame,
      mechanicProfile,
    );
    final inheritsParentState =
        activeFrame.hasParent &&
        _inheritsParentState(activeFrame.frame!, mechanicProfile);
    final inheritsParentMemory =
        activeFrame.hasParent &&
        _inheritsParentMemory(activeFrame.frame!, mechanicProfile);
    final effectiveAssetReferences = <ContinuityAssetReference>[
      ...bundle.canonicalAssetReferences,
      ...overlayAssetReferences,
      ...stateAssetReferences,
    ];

    return ContinuityResolutionResult(
      bundleId: bundle.id,
      scopeChain: scopeChain,
      activeFrame: activeFrame,
      mechanicProfile: mechanicProfile,
      canonicalAssetReferences: bundle.canonicalAssetReferences,
      overlayAssetReferences: overlayAssetReferences,
      stateAssetReferences: stateAssetReferences,
      effectiveAssetReferences: effectiveAssetReferences,
      inheritsParentState: inheritsParentState,
      inheritsParentMemory: inheritsParentMemory,
      branchesFromParent:
          activeFrame.frame?.relation == ContinuityFrameRelation.fork ||
          mechanicProfile.branchMode == ContinuityBranchMode.forkOnTransition,
      replayAware:
          activeFrame.frame?.relation == ContinuityFrameRelation.replay ||
          mechanicProfile.causalMode == ContinuityCausalMode.replayAware,
    );
  }

  ContinuityFrame? _selectFrame(
    ProjectContinuityBundle bundle,
    Map<String, ContinuityFrame> framesById,
    String frameId,
    String scopeId,
  ) {
    if (frameId.isNotEmpty) {
      return framesById[frameId];
    }
    if (bundle.defaultFrameId.isNotEmpty) {
      return framesById[bundle.defaultFrameId];
    }
    if (scopeId.isNotEmpty) {
      for (final frame in bundle.frames) {
        if (frame.scopeId == scopeId) {
          return frame;
        }
      }
    }
    return bundle.frames.isEmpty ? null : bundle.frames.first;
  }

  List<ContinuityFrame> _resolveFrameChain(
    Map<String, ContinuityFrame> framesById,
    ContinuityFrame? selectedFrame,
  ) {
    if (selectedFrame == null) {
      return const <ContinuityFrame>[];
    }
    final reversed = <ContinuityFrame>[];
    final visited = <String>{};
    ContinuityFrame? current = selectedFrame;
    while (current != null &&
        current.id.isNotEmpty &&
        !visited.contains(current.id)) {
      reversed.add(current);
      visited.add(current.id);
      if (current.parentFrameId.isEmpty) {
        break;
      }
      current = framesById[current.parentFrameId];
    }
    return reversed.reversed.toList(growable: false);
  }

  List<ContinuationScope> _resolveScopeChain(
    Map<String, ContinuationScope> scopesById,
    String selectedScopeId,
  ) {
    if (selectedScopeId.isEmpty) {
      return const <ContinuationScope>[];
    }
    final reversed = <ContinuationScope>[];
    final visited = <String>{};
    ContinuationScope? current = scopesById[selectedScopeId];
    while (current != null &&
        current.id.isNotEmpty &&
        !visited.contains(current.id)) {
      reversed.add(current);
      visited.add(current.id);
      if (current.parentScopeId.isEmpty) {
        break;
      }
      current = scopesById[current.parentScopeId];
    }
    return reversed.reversed.toList(growable: false);
  }

  ContinuityMechanicProfile _selectMechanicProfile(
    ProjectContinuityBundle bundle,
    ContinuityFrame? frame,
    String explicitMechanicProfileId,
  ) {
    final profilesById = <String, ContinuityMechanicProfile>{
      for (final profile in bundle.mechanicProfiles) profile.id: profile,
    };
    if (explicitMechanicProfileId.isNotEmpty) {
      return profilesById[explicitMechanicProfileId] ?? _defaultProfile();
    }
    if (frame != null && frame.mechanicProfileId.isNotEmpty) {
      return profilesById[frame.mechanicProfileId] ?? _defaultProfile();
    }
    if (bundle.defaultMechanicProfileId.isNotEmpty) {
      return profilesById[bundle.defaultMechanicProfileId] ?? _defaultProfile();
    }
    return bundle.mechanicProfiles.isEmpty
        ? _defaultProfile()
        : bundle.mechanicProfiles.first;
  }

  List<ContinuityAssetReference> _resolveOverlayAssetReferences(
    List<ContinuationScopeOverlay> overlays,
    List<String> scopeIds,
  ) {
    if (scopeIds.isEmpty || overlays.isEmpty) {
      return const <ContinuityAssetReference>[];
    }
    final matches = overlays
        .where((overlay) => scopeIds.contains(overlay.scopeId))
        .toList(growable: false);
    matches.sort((left, right) {
      final byScope = scopeIds
          .indexOf(left.scopeId)
          .compareTo(scopeIds.indexOf(right.scopeId));
      if (byScope != 0) {
        return byScope;
      }
      return left.priority.compareTo(right.priority);
    });
    return matches
        .expand((overlay) => overlay.assetReferences)
        .toList(growable: false);
  }

  List<ContinuityAssetReference> _resolveStateAssetReferences(
    ActiveContinuityFrame activeFrame,
    ContinuityMechanicProfile mechanicProfile,
  ) {
    if (activeFrame.frame == null) {
      return const <ContinuityAssetReference>[];
    }
    final frame = activeFrame.frame!;
    if (!_inheritsParentState(frame, mechanicProfile)) {
      return frame.stateReferences;
    }
    final merged = <ContinuityAssetReference>[];
    for (final ancestor in activeFrame.frameChain) {
      merged.addAll(ancestor.stateReferences);
    }
    return merged;
  }

  bool _inheritsParentState(
    ContinuityFrame frame,
    ContinuityMechanicProfile mechanicProfile,
  ) {
    if (frame.parentFrameId.isEmpty) {
      return false;
    }
    if (frame.relation == ContinuityFrameRelation.reset ||
        frame.relation == ContinuityFrameRelation.overwrite) {
      return false;
    }
    return mechanicProfile.stateMode != ContinuityStateMode.resetPerFrame;
  }

  bool _inheritsParentMemory(
    ContinuityFrame frame,
    ContinuityMechanicProfile mechanicProfile,
  ) {
    if (frame.parentFrameId.isEmpty) {
      return false;
    }
    if (frame.relation == ContinuityFrameRelation.reset ||
        frame.relation == ContinuityFrameRelation.overwrite) {
      return false;
    }
    return mechanicProfile.memoryMode != ContinuityMemoryMode.resetPerFrame;
  }

  ContinuityMechanicProfile _defaultProfile() {
    return const ContinuityMechanicProfile(
      id: 'default_continuity',
      displayName: 'Default Continuity',
    );
  }
}
