import 'book_deconstruction_plan_group_view_data.dart';
import 'book_deconstruction_continuity_view_data.dart';
import 'book_deconstruction_preview_section_view_data.dart';
import 'book_deconstruction_step_view_data.dart';

class BookDeconstructionViewData {
  const BookDeconstructionViewData({
    required this.projectTitle,
    required this.status,
    required this.isLoading,
    required this.activeStepId,
    required this.steps,
    required this.sourceAbsolutePath,
    required this.sourceTitle,
    required this.sourceContent,
    required this.operatorNotes,
    required this.styleSummary,
    required this.worldRulesText,
    required this.characterLinesText,
    required this.organizationLinesText,
    required this.previewSections,
    required this.planGroups,
    required this.selectedItemCount,
    required this.totalItemCount,
    required this.confirmedPreviewPath,
    required this.canBuildPreview,
    required this.canConfirmSelection,
    this.continuity,
  });

  factory BookDeconstructionViewData.initial() {
    return const BookDeconstructionViewData(
      projectTitle: '',
      status: '',
      isLoading: false,
      activeStepId: '',
      steps: <BookDeconstructionStepViewData>[],
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      operatorNotes: '',
      styleSummary: '',
      worldRulesText: '',
      characterLinesText: '',
      organizationLinesText: '',
      previewSections: <BookDeconstructionPreviewSectionViewData>[],
      planGroups: <BookDeconstructionPlanGroupViewData>[],
      selectedItemCount: 0,
      totalItemCount: 0,
      confirmedPreviewPath: '',
      canBuildPreview: false,
      canConfirmSelection: false,
      continuity: null,
    );
  }

  final String projectTitle;
  final String status;
  final bool isLoading;
  final String activeStepId;
  final List<BookDeconstructionStepViewData> steps;
  final String sourceAbsolutePath;
  final String sourceTitle;
  final String sourceContent;
  final String operatorNotes;
  final String styleSummary;
  final String worldRulesText;
  final String characterLinesText;
  final String organizationLinesText;
  final List<BookDeconstructionPreviewSectionViewData> previewSections;
  final List<BookDeconstructionPlanGroupViewData> planGroups;
  final int selectedItemCount;
  final int totalItemCount;
  final String confirmedPreviewPath;
  final bool canBuildPreview;
  final bool canConfirmSelection;
  final BookDeconstructionContinuityViewData? continuity;
}
