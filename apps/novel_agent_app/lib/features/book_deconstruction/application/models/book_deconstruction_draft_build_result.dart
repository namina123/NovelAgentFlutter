import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionDraftBuildResult {
  const BookDeconstructionDraftBuildResult({
    required this.input,
    required this.extractionResult,
    required this.applicationPlan,
    required this.followupMenu,
    required this.narrativeArtifacts,
  });

  final BookDeconstructionInput input;
  final BookDeconstructionExtractionResult extractionResult;
  final BookDeconstructionApplicationPlan applicationPlan;
  final BookDeconstructionFollowupMenu followupMenu;
  final BookDeconstructionNarrativeArtifactBundle narrativeArtifacts;
}
