import 'package:novel_agent_core/novel_agent_core.dart';

abstract class TaskCenterRuntimeQueryPort {
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  });

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  });

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 12,
  });

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 12,
  });

  Future<JsonMap> loadLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> loadTaskQueueRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  );

  Future<JsonMap> buildCheckpointGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  );

  Future<JsonMap> buildRevisionResolution(
    ProjectDescriptor project,
    JsonMap selector,
  );

  List<JsonMap> listTaskRuntimeModes();

  String renderLongTaskRunMarkdown(JsonMap record);

  String renderTaskQueueRunMarkdown(JsonMap record);
}
