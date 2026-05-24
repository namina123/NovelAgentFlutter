import '../models/task_center_view_data.dart';

abstract class TaskCenterActionHandler {
  void onTaskCenterBackRequested();

  void onTaskCenterRefreshRequested();

  void onTaskCenterTaskSelected(String taskId);

  void onTaskCenterTaskOpened(String taskId);

  void onTaskCenterWorkflowCreateSubmitted(
    TaskWorkflowCreateRequestViewData request,
  );

  void onTaskCenterSavePlanRequested();

  void onTaskCenterSaveChainSnapshotRequested();

  void onTaskCenterPrepareExecutionRequested();

  void onTaskCenterRunSelectedOnceRequested();

  void onTaskCenterRunNextOnceRequested();

  void onTaskCenterRunQueueRequested();

  void onTaskCenterPostprocessSelectedRequested();

  void onTaskCenterPostprocessNextRequested();

  void onTaskCenterMarkSucceededRequested();

  void onTaskCenterCompleteAndRunNextRequested();

  void onTaskCenterAcceptRevisionRequested();

  void onTaskCenterRollbackRevisionRequested();

  void onTaskCenterPauseRequested();

  void onTaskCenterResumeRequested();

  void onTaskCenterRetryRequested();

  void onTaskCenterCancelRequested();
}
