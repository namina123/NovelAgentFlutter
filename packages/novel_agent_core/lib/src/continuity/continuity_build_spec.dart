enum ContinuityBuildTier { quickBridge, standardFoundation, deepReconstruction }

enum ContinuityBuildOutputKind {
  tailBridge,
  globalBible,
  stageSummaries,
  stateTables,
  conflictGapAnalysis,
}

enum ContinuityBuildRuntimeHost { directExecution, resumableWorkflowEngine }

class ContinuityBuildSpec {
  const ContinuityBuildSpec({
    required this.id,
    required this.displayName,
    this.summary = '',
    this.tier = ContinuityBuildTier.standardFoundation,
    this.focusScopeIds = const <String>[],
    this.focusFrameId = '',
    this.requestedOutputs = const <ContinuityBuildOutputKind>[],
    this.preferredRuntimeHost = ContinuityBuildRuntimeHost.directExecution,
    this.recommended = false,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final ContinuityBuildTier tier;
  final List<String> focusScopeIds;
  final String focusFrameId;
  final List<ContinuityBuildOutputKind> requestedOutputs;
  final ContinuityBuildRuntimeHost preferredRuntimeHost;
  final bool recommended;
  final String notes;
  final Map<String, Object?> metadata;
}
