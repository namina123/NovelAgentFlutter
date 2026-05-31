import '../project/project_descriptor.dart';
import 'continuation_scope.dart';
import 'continuation_scope_overlay.dart';
import 'continuity_asset_reference.dart';
import 'continuity_frame.dart';
import 'continuity_mechanic_profile.dart';
import 'project_continuity_bundle.dart';
import 'project_continuity_input_profile.dart';

class GeneralProjectContinuityDefaultsService {
  const GeneralProjectContinuityDefaultsService();

  ProjectContinuityBundle buildBundle(
    ProjectDescriptor project, {
    ProjectContinuityInputProfile input = const ProjectContinuityInputProfile(),
  }) {
    final worldLabels = _normalizedWorldLabels(input);
    final scopes = <ContinuationScope>[
      const ContinuationScope(
        id: 'global',
        displayName: '全局',
        kind: ContinuationScopeKind.global,
      ),
      ...worldLabels.map(
        (label) => ContinuationScope(
          id: _scopeIdFromLabel(label),
          displayName: label,
          kind: ContinuationScopeKind.world,
          parentScopeId: 'global',
        ),
      ),
    ];
    final defaultScopeId = worldLabels.isEmpty
        ? 'global'
        : _scopeIdFromLabel(worldLabels.first);
    final mechanicProfile = ContinuityMechanicProfile(
      id: 'default_general_project',
      displayName: input.displayName.trim().isEmpty
          ? '默认连续性'
          : input.displayName.trim(),
      identityMode:
          input.identityModeOverride ??
          (input.requiresScopedIdentityOverlays || input.usesMultipleWorlds
              ? ContinuityIdentityMode.scopeOverlay
              : ContinuityIdentityMode.stable),
      memoryMode:
          input.memoryModeOverride ??
          (input.usesReplayResets
              ? ContinuityMemoryMode.protagonistOnly
              : ContinuityMemoryMode.continuous),
      stateMode:
          input.stateModeOverride ??
          (input.usesReplayResets
              ? ContinuityStateMode.partialCarryOver
              : ContinuityStateMode.accumulative),
      causalMode:
          input.causalModeOverride ??
          (input.usesReplayResets
              ? ContinuityCausalMode.replayAware
              : input.usesBranchingRoutes
              ? ContinuityCausalMode.forked
              : ContinuityCausalMode.linear),
      branchMode:
          input.branchModeOverride ??
          (input.usesBranchingRoutes
              ? ContinuityBranchMode.forkOnTransition
              : ContinuityBranchMode.singleLine),
      visibilityMode:
          input.visibilityModeOverride ??
          ContinuityVisibilityMode.defaultVisible,
      notes: input.notes,
      metadata: input.metadata,
    );
    final defaultFrame = ContinuityFrame(
      id: 'mainline',
      displayName: '主线',
      scopeId: defaultScopeId,
      mechanicProfileId: mechanicProfile.id,
      relation: ContinuityFrameRelation.sameLine,
      stateReferences: const <ContinuityAssetReference>[],
    );

    return ProjectContinuityBundle(
      id: project.id.trim().isEmpty
          ? 'project_continuity'
          : '${project.id}_continuity',
      displayName: '${project.name} 连续性',
      scopes: scopes,
      scopeOverlays: const <ContinuationScopeOverlay>[],
      canonicalAssetReferences: const <ContinuityAssetReference>[],
      mechanicProfiles: <ContinuityMechanicProfile>[mechanicProfile],
      frames: <ContinuityFrame>[defaultFrame],
      defaultMechanicProfileId: mechanicProfile.id,
      defaultFrameId: defaultFrame.id,
      notes: input.notes,
      metadata: <String, Object?>{
        'project_type': project.projectType,
        'general_project_seed': true,
        ...input.metadata,
      },
    );
  }

  List<String> _normalizedWorldLabels(ProjectContinuityInputProfile input) {
    final cleaned = input.worldLabels
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isNotEmpty) {
      return cleaned;
    }
    if (input.usesMultipleWorlds) {
      return const <String>['主世界'];
    }
    return const <String>[];
  }

  String _scopeIdFromLabel(String label) {
    final normalized = label
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\u4e00-\u9fff-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
    return normalized.isEmpty ? 'world' : 'world_$normalized';
  }
}
