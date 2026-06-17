import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('workflow runtime family contracts can be consumed by a single stub', () {
    final runtime = _WorkflowRuntimeFamilyStub();

    final modes = runtime.listTaskRuntimeModes();
    expect(modes, hasLength(1));
    expect(
      modes.single,
      isA<Map<String, Object?>>().having(
        (mode) => mode['id'],
        'id',
        'stub',
      ),
    );
    expect(
      runtime.renderLongTaskRunMarkdown(const <String, Object?>{}),
      'long-task',
    );
    expect(
      runtime.renderTaskQueueRunMarkdown(const <String, Object?>{}),
      'queue-task',
    );
  });
}

class _WorkflowRuntimeFamilyStub
    implements
        WorkflowRuntimeFacade,
        WorkflowQueueRuntime,
        WorkflowReviewRuntime,
        WorkflowCheckpointRuntime,
        WorkflowRepairRuntime,
        WorkflowPostprocessRuntime,
        WorkflowPermissionBridge {
  @override
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <JsonMap>[];

  @override
  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> saveWorkflowChainSnapshot(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> loadTaskQueueRun(
    ProjectDescriptor project,
    String relativePath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> loadLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  List<JsonMap> listTaskRuntimeModes() => const <JsonMap>[
    <String, Object?>{'id': 'stub'},
  ];

  @override
  String renderLongTaskRunMarkdown(JsonMap record) => 'long-task';

  @override
  String renderTaskQueueRunMarkdown(JsonMap record) => 'queue-task';

  @override
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> nextWorkflowPostprocessTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 12,
  }) async =>
      const <JsonMap>[];

  @override
  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 12,
  }) async =>
      const <JsonMap>[];

  @override
  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> stopLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    JsonMap queueOptions,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> createCheckpointReviewTasks(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> createWorkflowReviewRepairTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> runWorkflowTaskOnce(
    ProjectDescriptor project,
    JsonMap task, {
    String source = '',
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> buildCheckpointGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> applyCheckpointReviewAction(
    ProjectDescriptor project,
    String checkpointReviewPath,
    String command,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> buildRevisionResolution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> applyRevisionResolutionAction(
    ProjectDescriptor project,
    JsonMap selector,
    String action, {
    String note = '',
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> acceptRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> rollbackRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> transitionWorkflowTask(
    ProjectDescriptor project,
    JsonMap selector,
    String status, {
    String note = '',
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> buildLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap record,
    JsonMap task, {
    JsonMap arguments = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> applyLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap revision, {
    String createdAt = '',
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> applyLongTaskFailureAction(
    ProjectDescriptor project,
    JsonMap task,
    String action, {
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> saveWorkflowTaskPlan(
    ProjectDescriptor project,
    JsonMap selector, {
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> runWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    required JsonMap execution,
    required DraftGenerationResult result,
    required List<JsonMap> memorySections,
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> runNextWorkflowTaskPostprocessOnce(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> completeWorkflowTaskAndRunNext(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    required JsonMap execution,
    required DraftGenerationResult result,
    required List<JsonMap> memorySections,
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> prepareWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap task, {
    JsonMap options = const <String, Object?>{},
  }) async =>
      const <String, Object?>{};

  @override
  Future<JsonMap> applyWorkflowTaskUserChoice(
    ProjectDescriptor project,
    JsonMap task, {
    required String prompt,
    String permissionApprovalId = '',
    String permissionApprovalOptionId = '',
  }) async =>
      const <String, Object?>{};
}
