enum ContinuityIdentityMode { stable, scopeOverlay, forkedAlias, resetPerFrame }

enum ContinuityMemoryMode {
  continuous,
  protagonistOnly,
  scoped,
  hiddenMetaOnly,
  resetPerFrame,
}

enum ContinuityStateMode {
  accumulative,
  scopedOverlay,
  partialCarryOver,
  resetPerFrame,
}

enum ContinuityCausalMode { linear, forked, replayAware, overwritten }

enum ContinuityBranchMode {
  singleLine,
  forkOnTransition,
  overwriteParent,
  parallelVisible,
}

enum ContinuityVisibilityMode {
  defaultVisible,
  frameScoped,
  metaOnly,
  hiddenFromCharacters,
}

class ContinuityMechanicProfile {
  const ContinuityMechanicProfile({
    required this.id,
    required this.displayName,
    this.identityMode = ContinuityIdentityMode.stable,
    this.memoryMode = ContinuityMemoryMode.continuous,
    this.stateMode = ContinuityStateMode.accumulative,
    this.causalMode = ContinuityCausalMode.linear,
    this.branchMode = ContinuityBranchMode.singleLine,
    this.visibilityMode = ContinuityVisibilityMode.defaultVisible,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final ContinuityIdentityMode identityMode;
  final ContinuityMemoryMode memoryMode;
  final ContinuityStateMode stateMode;
  final ContinuityCausalMode causalMode;
  final ContinuityBranchMode branchMode;
  final ContinuityVisibilityMode visibilityMode;
  final String notes;
  final Map<String, Object?> metadata;
}
