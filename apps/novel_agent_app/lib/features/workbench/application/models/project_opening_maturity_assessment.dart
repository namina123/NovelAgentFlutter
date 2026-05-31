import 'project_opening_maturity_stage.dart';

class ProjectOpeningMaturityAssessment {
  const ProjectOpeningMaturityAssessment({
    required this.stage,
    required this.summary,
    required this.authoredFoundationFileCount,
    required this.narrativeFileCount,
  });

  final ProjectOpeningMaturityStage stage;
  final String summary;
  final int authoredFoundationFileCount;
  final int narrativeFileCount;

  bool get shouldShowOpeningEntry =>
      stage != ProjectOpeningMaturityStage.continueReady;

  bool get isFresh => stage == ProjectOpeningMaturityStage.fresh;

  bool get isOpeningInProgress =>
      stage == ProjectOpeningMaturityStage.openingInProgress;

  bool get isContinueReady =>
      stage == ProjectOpeningMaturityStage.continueReady;
}
