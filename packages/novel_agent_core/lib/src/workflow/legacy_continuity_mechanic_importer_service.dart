import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/continuation_scope_overlay.dart';
import '../continuity/continuity_asset_reference.dart';
import '../continuity/continuity_coverage.dart';
import '../continuity/continuity_frame.dart';
import '../continuity/continuity_mechanic_profile.dart';
import '../continuity/narrative_state/narrative_profile.dart';
import '../continuity/narrative_state/narrative_profile_lifecycle_status.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import '../continuity/narrative_state/narrative_reference_constants.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';
import '../continuity/project_continuity_bundle.dart';
import '../continuity/project_continuity_input_profile.dart';
import '../project/project_descriptor.dart';

const _legacySpecialMechanicNamespaceRoot = 'legacy.special_mechanic';

class LegacyContinuityMechanicImportPackage {
  const LegacyContinuityMechanicImportPackage({
    required this.profile,
    required this.claims,
  });

  final NarrativeProfile profile;
  final List<NarrativeStateClaim> claims;
}

/// Deprecated bridge-only importer for pre-ONS continuity/mechanic files.
///
/// It keeps legacy probe tags readable by importing them into
/// `legacy.special_mechanic.*` namespaces instead of reviving old logic.
class LegacyContinuityMechanicImporterService {
  const LegacyContinuityMechanicImporterService();

  LegacyContinuityMechanicImportPackage buildPackage({
    required ProjectDescriptor project,
    required ProjectContinuityBundle bundle,
    ProjectContinuityInputProfile? inputProfile,
  }) {
    // 中文注释: 这里只把旧 continuity/mechanic 事实降级投影进开放 namespace，不复活旧 special mechanic 业务。
    final bundleRef = NarrativeRef(
      refType: NarrativeRefTypes.asset,
      refId: 'legacy_continuity_bundle',
      displayName: bundle.displayName,
      relativePath: 'tracking/continuity/bundle.json',
      metadata: const <String, Object?>{
        'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
        'bridge_status': 'deprecated_bridge_only',
      },
    );
    final claims = <NarrativeStateClaim>[
      _claim(
        claimId: 'legacy_special_mechanic_bundle',
        claimNamespace: '$_legacySpecialMechanicNamespaceRoot.bundle',
        claimLabel: bundle.displayName.isEmpty ? 'Legacy continuity bundle' : bundle.displayName,
        claimPayload: _bundleToJson(bundle),
        affectedRefs: <NarrativeRef>[bundleRef],
        contextRefs: _contextRefsFromCoverage(bundle.coverage),
      ),
      if (_hasCoverage(bundle.coverage))
        _claim(
          claimId: 'legacy_special_mechanic_coverage',
          claimNamespace: '$_legacySpecialMechanicNamespaceRoot.coverage',
          claimLabel: 'Legacy continuity coverage',
          claimPayload: _coverageToJson(bundle.coverage),
          affectedRefs: <NarrativeRef>[bundleRef],
          contextRefs: _contextRefsFromCoverage(bundle.coverage),
        ),
      if (inputProfile != null)
        _claim(
          claimId: 'legacy_special_mechanic_input_profile',
          claimNamespace: '$_legacySpecialMechanicNamespaceRoot.input_profile',
          claimLabel: inputProfile.displayName.trim().isEmpty
              ? 'Legacy continuity input profile'
              : inputProfile.displayName.trim(),
          claimPayload: _inputProfileToJson(inputProfile),
          affectedRefs: const <NarrativeRef>[
            NarrativeRef(
              refType: NarrativeRefTypes.asset,
              refId: 'legacy_continuity_input_profile',
              relativePath: '.novel_agent/settings/project_continuity_input.json',
            ),
          ],
          contextRefs: <NarrativeRef>[bundleRef],
        ),
      ...bundle.mechanicProfiles.map(
        (profile) => _claim(
          claimId: 'legacy_special_mechanic_mechanic_profile_${_safeId(profile.id)}',
          claimNamespace:
              '$_legacySpecialMechanicNamespaceRoot.mechanic_profile',
          claimLabel: profile.displayName,
          claimPayload: _mechanicProfileToJson(profile),
          affectedRefs: <NarrativeRef>[bundleRef],
          contextRefs: <NarrativeRef>[bundleRef],
        ),
      ),
      ...bundle.frames.map(
        (frame) => _claim(
          claimId: 'legacy_special_mechanic_frame_${_safeId(frame.id)}',
          claimNamespace: '$_legacySpecialMechanicNamespaceRoot.frame',
          claimLabel: frame.displayName,
          claimPayload: _frameToJson(frame),
          affectedRefs: <NarrativeRef>[bundleRef],
          contextRefs: <NarrativeRef>[bundleRef],
        ),
      ),
      ...bundle.scopeOverlays.map(
        (overlay) => _claim(
          claimId: 'legacy_special_mechanic_scope_overlay_${_safeId(overlay.id)}',
          claimNamespace:
              '$_legacySpecialMechanicNamespaceRoot.scope_overlay',
          claimLabel: overlay.displayName,
          claimPayload: _scopeOverlayToJson(overlay),
          affectedRefs: <NarrativeRef>[bundleRef],
          contextRefs: <NarrativeRef>[bundleRef],
        ),
      ),
    ];
    final profile = NarrativeProfile(
      profileId: 'legacy_special_mechanic_profile',
      profileNamespace: '$_legacySpecialMechanicNamespaceRoot.profile',
      profileLabel: bundle.displayName.isEmpty
          ? 'Legacy continuity bridge'
          : 'Legacy continuity bridge: ${bundle.displayName}',
      lifecycleStatus: NarrativeProfileLifecycleStatus.deprecated,
      profilePayload: <String, Object?>{
        'project_id': project.id,
        'project_name': project.name,
        'bundle_id': bundle.id,
        'default_mechanic_profile_id': bundle.defaultMechanicProfileId,
        'default_frame_id': bundle.defaultFrameId,
        'mechanic_profile_count': bundle.mechanicProfiles.length,
        'frame_count': bundle.frames.length,
        'scope_count': bundle.scopes.length,
        'scope_overlay_count': bundle.scopeOverlays.length,
        'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
        'compatibility_aliases': const <String>['legacy.special_mechanic'],
      },
      profileExtensions: <String, Object?>{
        'bridge_status': 'deprecated_bridge_only',
        'legacy_special_mechanic_bundle': _bundleToJson(bundle),
        if (inputProfile != null)
          'legacy_special_mechanic_input_profile':
              _inputProfileToJson(inputProfile),
        'compatibility_aliases': const <String>['legacy.special_mechanic'],
        'pressure_probe_note':
            'Historical special-mechanic labels remain readable as probe input only.',
      },
      source: _legacySource(),
      confidence: 1,
      reason:
          'Legacy continuity/mechanic state imported into open narrative state bridge.',
      schemaVersion: 'ons-36',
      metadata: const <String, Object?>{
        'bridge_status': 'deprecated_bridge_only',
        'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
        'compatibility_aliases': <String>['legacy.special_mechanic'],
      },
    );
    return LegacyContinuityMechanicImportPackage(
      profile: profile,
      claims: claims,
    );
  }

  NarrativeStateClaim _claim({
    required String claimId,
    required String claimNamespace,
    required String claimLabel,
    required JsonMap claimPayload,
    List<NarrativeRef> affectedRefs = const <NarrativeRef>[],
    List<NarrativeRef> contextRefs = const <NarrativeRef>[],
  }) {
    return NarrativeStateClaim(
      claimId: claimId,
      claimNamespace: claimNamespace,
      claimLabel: claimLabel,
      claimPayload: claimPayload,
      affectedRefs: affectedRefs,
      contextRefs: contextRefs,
      source: _legacySource(),
      confidence: 1,
      uncertainty: 'Imported from deprecated legacy continuity/mechanic bridge.',
      schemaVersion: 'ons-36',
      metadata: const <String, Object?>{
        'bridge_status': 'deprecated_bridge_only',
        'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
      },
    );
  }

  NarrativeSourceRef _legacySource() {
    return const NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.system,
      sourceId: 'legacy_continuity_mechanic_importer',
      // 中文注释: 显式 stamp 稳定 sourceAssetId / displayName / sourceKind，避免 toJson/fromJson
      // 往返时 resolver 重新推导出不同的值（首次写空、读回填派生值），导致二次迁移被判定为"发生变化"而不幂等。
      sourceAssetId: 'legacy_continuity_mechanic_importer',
      displayName: 'Legacy continuity bridge importer',
      sourceKind: NarrativeSourceTypes.system,
      label: 'Legacy continuity bridge importer',
      description:
          'Deprecated bridge-only importer for pre-ONS continuity state and historical special-mechanic aliases.',
      metadata: <String, Object?>{
        'bridge_status': 'deprecated_bridge_only',
        'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
        'compatibility_aliases': <String>['legacy.special_mechanic'],
      },
    );
  }

  JsonMap _bundleToJson(ProjectContinuityBundle bundle) {
    return <String, Object?>{
      'id': bundle.id,
      'display_name': bundle.displayName,
      'coverage': _coverageToJson(bundle.coverage),
      'canonical_asset_references': bundle.canonicalAssetReferences
          .map(_assetReferenceToJson)
          .toList(growable: false),
      'scope_ids': bundle.scopes
          .map((scope) => scope.id)
          .toList(growable: false),
      'scope_overlay_ids': bundle.scopeOverlays
          .map((overlay) => overlay.id)
          .toList(growable: false),
      'mechanic_profiles': bundle.mechanicProfiles
          .map(_mechanicProfileToJson)
          .toList(growable: false),
      'frames': bundle.frames.map(_frameToJson).toList(growable: false),
      'default_mechanic_profile_id': bundle.defaultMechanicProfileId,
      'default_frame_id': bundle.defaultFrameId,
      'notes': bundle.notes,
      'metadata': ValueReaders.deepCopyMap(bundle.metadata),
    };
  }

  JsonMap _inputProfileToJson(ProjectContinuityInputProfile inputProfile) {
    return <String, Object?>{
      'display_name': inputProfile.displayName,
      'uses_multiple_worlds': inputProfile.usesMultipleWorlds,
      'uses_branching_routes': inputProfile.usesBranchingRoutes,
      'uses_replay_resets': inputProfile.usesReplayResets,
      'requires_scoped_identity_overlays':
          inputProfile.requiresScopedIdentityOverlays,
      'world_labels': inputProfile.worldLabels,
      'identity_mode_override': inputProfile.identityModeOverride?.name ?? '',
      'memory_mode_override': inputProfile.memoryModeOverride?.name ?? '',
      'state_mode_override': inputProfile.stateModeOverride?.name ?? '',
      'causal_mode_override': inputProfile.causalModeOverride?.name ?? '',
      'branch_mode_override': inputProfile.branchModeOverride?.name ?? '',
      'visibility_mode_override':
          inputProfile.visibilityModeOverride?.name ?? '',
      'notes': inputProfile.notes,
      'metadata': ValueReaders.deepCopyMap(inputProfile.metadata),
    };
  }

  JsonMap _mechanicProfileToJson(ContinuityMechanicProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'display_name': profile.displayName,
      'identity_mode': profile.identityMode.name,
      'memory_mode': profile.memoryMode.name,
      'state_mode': profile.stateMode.name,
      'causal_mode': profile.causalMode.name,
      'branch_mode': profile.branchMode.name,
      'visibility_mode': profile.visibilityMode.name,
      'notes': profile.notes,
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
    };
  }

  JsonMap _frameToJson(ContinuityFrame frame) {
    return <String, Object?>{
      'id': frame.id,
      'display_name': frame.displayName,
      'scope_id': frame.scopeId,
      'mechanic_profile_id': frame.mechanicProfileId,
      'parent_frame_id': frame.parentFrameId,
      'relation': frame.relation.name,
      'state_references': frame.stateReferences
          .map(_assetReferenceToJson)
          .toList(growable: false),
      'notes': frame.notes,
      'metadata': ValueReaders.deepCopyMap(frame.metadata),
    };
  }

  JsonMap _scopeOverlayToJson(ContinuationScopeOverlay overlay) {
    return <String, Object?>{
      'id': overlay.id,
      'scope_id': overlay.scopeId,
      'display_name': overlay.displayName,
      'priority': overlay.priority,
      'asset_references': overlay.assetReferences
          .map(_assetReferenceToJson)
          .toList(growable: false),
      'notes': overlay.notes,
      'metadata': ValueReaders.deepCopyMap(overlay.metadata),
    };
  }

  JsonMap _coverageToJson(ContinuityCoverage coverage) {
    return <String, Object?>{
      'source_label': coverage.sourceLabel,
      'source_paths': coverage.sourcePaths,
      'chapter_start': coverage.chapterStart,
      'chapter_end': coverage.chapterEnd,
      'is_partial': coverage.isPartial,
      'inferred_sections': coverage.inferredSections,
      'notes': coverage.notes,
      'metadata': ValueReaders.deepCopyMap(coverage.metadata),
    };
  }

  JsonMap _assetReferenceToJson(ContinuityAssetReference reference) {
    return <String, Object?>{
      'asset_id': reference.assetId,
      'display_name': reference.displayName,
      'source_path': reference.sourcePath,
      'asset_kind': reference.assetKind.name,
      'role': reference.role.name,
      'note': reference.note,
      'metadata': ValueReaders.deepCopyMap(reference.metadata),
    };
  }

  List<NarrativeRef> _contextRefsFromCoverage(ContinuityCoverage coverage) {
    return coverage.sourcePaths
        .map(
          (path) => NarrativeRef(
            refType: NarrativeRefTypes.asset,
            refId: _safeId(path),
            relativePath: path,
            sourcePath: path,
            metadata: const <String, Object?>{
              'legacy_namespace_root': _legacySpecialMechanicNamespaceRoot,
            },
          ),
        )
        .toList(growable: false);
  }

  bool _hasCoverage(ContinuityCoverage coverage) {
    return coverage.sourceLabel.trim().isNotEmpty ||
        coverage.sourcePaths.isNotEmpty ||
        coverage.chapterStart > 0 ||
        coverage.chapterEnd > 0 ||
        coverage.isPartial ||
        coverage.inferredSections.isNotEmpty ||
        coverage.notes.trim().isNotEmpty ||
        coverage.metadata.isNotEmpty;
  }

  String _safeId(String raw) {
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
    return normalized.isEmpty ? 'legacy' : normalized;
  }
}
