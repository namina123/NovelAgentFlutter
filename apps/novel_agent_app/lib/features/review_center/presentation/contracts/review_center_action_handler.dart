abstract class ReviewCenterActionHandler {
  void onReviewCenterBackRequested();

  void onReviewCenterRefreshRequested();

  void onReviewCenterEntrySelected(String entryId);

  void onReviewCenterEntryOpened(String entryId);

  void onReviewCenterCreateCurrentReviewRequested();

  void onReviewCenterCreateRepairTaskRequested();

  void onReviewCenterRewriteModeSelected(String rewriteMode);

  void onReviewCenterSuggestionToggled(String suggestionId, bool selected);

  void onReviewCenterSegmentToggled(String segmentId, bool selected);

  void onReviewCenterPlanRequested();

  void onReviewCenterMaterializeRewriteRequested();

  void onReviewCenterFilterSubmitted({
    required String reviewType,
    required String scope,
    required String sourcePath,
  });

  void onReviewCenterFilterCleared();
}
