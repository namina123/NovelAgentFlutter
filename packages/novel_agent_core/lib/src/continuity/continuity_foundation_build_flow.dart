import 'continuity_build_spec.dart';
import 'continuity_foundation_build_stage.dart';

class ContinuityFoundationBuildFlow {
  const ContinuityFoundationBuildFlow({
    required this.id,
    required this.displayName,
    required this.summary,
    this.runtimeHost = ContinuityBuildRuntimeHost.directExecution,
    this.stages = const <ContinuityFoundationBuildStage>[],
    this.supportsStepRetry = false,
    this.supportsPartialArtifacts = false,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final ContinuityBuildRuntimeHost runtimeHost;
  final List<ContinuityFoundationBuildStage> stages;
  final bool supportsStepRetry;
  final bool supportsPartialArtifacts;
  final String notes;
  final Map<String, Object?> metadata;
}
