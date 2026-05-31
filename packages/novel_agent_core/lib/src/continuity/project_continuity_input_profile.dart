import 'continuity_mechanic_profile.dart';

class ProjectContinuityInputProfile {
  const ProjectContinuityInputProfile({
    this.displayName = '',
    this.usesMultipleWorlds = false,
    this.usesBranchingRoutes = false,
    this.usesReplayResets = false,
    this.requiresScopedIdentityOverlays = false,
    this.worldLabels = const <String>[],
    this.identityModeOverride,
    this.memoryModeOverride,
    this.stateModeOverride,
    this.causalModeOverride,
    this.branchModeOverride,
    this.visibilityModeOverride,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String displayName;
  final bool usesMultipleWorlds;
  final bool usesBranchingRoutes;
  final bool usesReplayResets;
  final bool requiresScopedIdentityOverlays;
  final List<String> worldLabels;
  final ContinuityIdentityMode? identityModeOverride;
  final ContinuityMemoryMode? memoryModeOverride;
  final ContinuityStateMode? stateModeOverride;
  final ContinuityCausalMode? causalModeOverride;
  final ContinuityBranchMode? branchModeOverride;
  final ContinuityVisibilityMode? visibilityModeOverride;
  final String notes;
  final Map<String, Object?> metadata;
}
