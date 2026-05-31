abstract class BookDeconstructionActionHandler {
  void onBookDeconstructionBackRequested();

  void onBookDeconstructionRefreshRequested();

  void onBookDeconstructionStepSelected(String stepId);

  Future<void> onBookDeconstructionImportFileRequested();

  void onBookDeconstructionSourceTitleChanged(String value);

  void onBookDeconstructionSourceContentChanged(String value);

  void onBookDeconstructionOperatorNotesChanged(String value);

  void onBookDeconstructionStyleSummaryChanged(String value);

  void onBookDeconstructionWorldRulesChanged(String value);

  void onBookDeconstructionCharacterLinesChanged(String value);

  void onBookDeconstructionOrganizationLinesChanged(String value);

  Future<void> onBookDeconstructionBuildPreviewRequested();

  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  });

  void onBookDeconstructionSelectAllRequested();

  void onBookDeconstructionClearSelectionRequested();

  Future<void> onBookDeconstructionConfirmRequested();
}
