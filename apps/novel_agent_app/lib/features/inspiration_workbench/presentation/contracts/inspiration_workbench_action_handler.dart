abstract class InspirationWorkbenchActionHandler {
  void onInspirationWorkbenchBackRequested();

  void onInspirationWorkbenchRefreshRequested();

  void onInspirationWorkbenchModeSelected(String modeId);

  void onInspirationWorkbenchStageSelected(String stageId);

  Future<void> onInspirationWorkbenchOptionSelected({
    required String stageId,
    required String fieldKey,
    required String value,
    required String label,
  });

  Future<void> onInspirationWorkbenchTextSubmitted({
    required String stageId,
    required String fieldKey,
    required String value,
  });

  Future<void> onInspirationWorkbenchLongTaskLaunchRequested();
}
