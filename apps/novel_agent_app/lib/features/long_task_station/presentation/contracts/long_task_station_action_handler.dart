abstract class LongTaskStationActionHandler {
  void onLongTaskStationRefreshRequested();

  void onLongTaskStationRunSelected(String runId);

  void onLongTaskStationPauseRequested(String runId);

  void onLongTaskStationResumeRequested(String runId);

  void onLongTaskStationStopRequested(String runId);
}
