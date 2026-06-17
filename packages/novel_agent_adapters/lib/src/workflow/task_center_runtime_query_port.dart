import 'package:novel_agent_core/novel_agent_core.dart';

abstract class TaskCenterRuntimeQueryPort extends WorkflowRuntimeFacade {
  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  });

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 10,
  });

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 10,
  });

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  });

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
}
