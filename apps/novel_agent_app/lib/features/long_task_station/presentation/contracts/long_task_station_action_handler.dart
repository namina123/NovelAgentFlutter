abstract class LongTaskStationActionHandler {
  void onLongTaskStationRefreshRequested();

  void onLongTaskStationRunSelected(String runId);

  void onLongTaskStationPauseRequested(String runId);

  void onLongTaskStationResumeRequested(String runId);

  void onLongTaskStationStopRequested(String runId);

  void onLongTaskStationOpenProjectRequested(String runId);

  void onLongTaskStationResourceRequested(String runId, String relativePath);

  void onLongTaskStationCurrentProjectFilterToggled(bool selected);

  void onLongTaskStationTaskCenterRequested();
}
