import '../common/json_types.dart';
import '../project/project_descriptor.dart';
import '../runtime/draft_generation_result.dart';
import '../settings/app_settings.dart';

abstract class WorkflowRuntimeFacade {
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> saveWorkflowChainSnapshot(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> loadTaskQueueRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> loadLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  );

  List<JsonMap> listTaskRuntimeModes();

  String renderLongTaskRunMarkdown(JsonMap record);

  String renderTaskQueueRunMarkdown(JsonMap record);
}

abstract class WorkflowQueueRuntime {
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  });

  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> nextWorkflowPostprocessTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  });

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 12,
  });

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 12,
  });

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  });

  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> stopLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  );

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    JsonMap queueOptions,
  );

  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });
}

abstract class WorkflowReviewRuntime {
  Future<JsonMap> createCheckpointReviewTasks(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> createWorkflowReviewRepairTask(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> runWorkflowTaskOnce(
    ProjectDescriptor project,
    JsonMap task, {
    String source = '',
  });
}

abstract class WorkflowCheckpointRuntime {
  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  );

  Future<JsonMap> buildCheckpointGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  );

  Future<JsonMap> applyCheckpointReviewAction(
    ProjectDescriptor project,
    String checkpointReviewPath,
    String command,
  );
}

abstract class WorkflowRepairRuntime {
  Future<JsonMap> buildRevisionResolution(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> applyRevisionResolutionAction(
    ProjectDescriptor project,
    JsonMap selector,
    String action,
    {String note = ''});

  Future<JsonMap> acceptRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> rollbackRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  );

  Future<JsonMap> transitionWorkflowTask(
    ProjectDescriptor project,
    JsonMap selector,
    String status, {
    String note = '',
  });

  Future<JsonMap> buildLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap record,
    JsonMap task, {
    JsonMap arguments = const <String, Object?>{},
  });

  Future<JsonMap> applyLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap revision, {
    String createdAt = '',
  });

  Future<JsonMap> applyLongTaskFailureAction(
    ProjectDescriptor project,
    JsonMap task,
    String action, {
    JsonMap options = const <String, Object?>{},
  });
}

abstract class WorkflowPostprocessRuntime {
  Future<JsonMap> saveWorkflowTaskPlan(
    ProjectDescriptor project,
    JsonMap selector, {
    JsonMap options = const <String, Object?>{},
  });

  Future<JsonMap> runWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    required JsonMap execution,
    required DraftGenerationResult result,
    required List<JsonMap> memorySections,
  });

  Future<JsonMap> runNextWorkflowTaskPostprocessOnce(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  });

  Future<JsonMap> completeWorkflowTaskAndRunNext(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    required JsonMap execution,
    required DraftGenerationResult result,
    required List<JsonMap> memorySections,
  });
}

abstract class WorkflowPermissionBridge {
  Future<JsonMap> prepareWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap task, {
    JsonMap options = const <String, Object?>{},
  });

  Future<JsonMap> applyWorkflowTaskUserChoice(
    ProjectDescriptor project,
    JsonMap task, {
    required String prompt,
    String permissionApprovalId = '',
    String permissionApprovalOptionId = '',
  });
}
