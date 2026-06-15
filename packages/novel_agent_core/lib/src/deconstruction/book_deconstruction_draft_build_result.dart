import 'book_deconstruction_extraction_result.dart';
import 'book_deconstruction_followup_menu.dart';
import 'book_deconstruction_input.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';
import 'book_deconstruction_application_plan.dart';

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
