abstract class ReviewCenterActionHandler {
  void onReviewCenterBackRequested();

  void onReviewCenterRefreshRequested();

  void onReviewCenterEntrySelected(String entryId);

  void onReviewCenterEntryOpened(String entryId);

  void onReviewCenterCreateCurrentReviewRequested();

  void onReviewCenterCreateRepairTaskRequested();

  void onReviewCenterFilterSubmitted({
    required String reviewType,
    required String scope,
    required String sourcePath,
  });

  void onReviewCenterFilterCleared();
}
