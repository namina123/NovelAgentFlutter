import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_mode_guidance_repository.dart';
import '../storage/project_prompt_template_service.dart';
import '../storage/project_review_report_service.dart';
import '../storage/project_runtime_profile_repository.dart';
import '../storage/project_task_repository.dart';
import 'project_draft_execution_constraint_runtime_service.dart';
import 'project_context_activation_service.dart';
import 'project_long_task_chapter_queue_runtime_service.dart';
import 'project_long_task_checkpoint_action_service.dart';
import 'project_long_task_chapter_gate_service.dart';
import 'project_long_task_checkpoint_review_service.dart';
import 'project_long_task_checkpoint_review_task_service.dart';
import 'project_long_task_postprocess_result_service.dart';
import 'project_long_task_revision_resolution_service.dart';
import 'project_long_task_review_repair_task_service.dart';
import 'project_mode_guidance_memory_section_service.dart';
import 'project_task_queue_runtime_option_resolver.dart';
import 'project_workflow_runtime_bridge_service.dart';
import 'project_workflow_review_runtime_service.dart';

typedef WorkflowGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef LoadWorkflowProjectAgentGroupSelections =
    Future<List<ProjectAgentGroupSelection>> Function(
      ProjectDescriptor project,
    );

class ProjectWorkflowRuntimeService {
  ProjectWorkflowRuntimeService({
    required ProjectTaskRepository taskRepository,
    required ProjectPromptTemplateService promptTemplateService,
    required WorkflowGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    LoadWorkflowProjectAgentGroupSelections? loadProjectAgentGroupSelections,
    TaskDefinitionService? taskDefinitionService,
    TaskSelectionService? taskSelectionService,
    TaskQueueOptionService? taskQueueOptionService,
    TaskQueueStopPolicyService? taskQueueStopPolicyService,
    TaskQueuePreflightService? taskQueuePreflightService,
    LongTaskModeService? longTaskModeService,
    LongTaskPathPolicyService? longTaskPathPolicyService,
    BuildLongTaskPlanUseCase? buildLongTaskPlanUseCase,
    LongTaskRunPathService? longTaskRunPathService,
    StartLongTaskRunUseCase? startLongTaskRunUseCase,
    BuildLongTaskSchedulerSnapshotUseCase?
    buildLongTaskSchedulerSnapshotUseCase,
    BuildLongTaskPromptUseCase? buildLongTaskPromptUseCase,
    LongTaskPostprocessTransactionService? postprocessTransactionService,
    LongTaskPostprocessPromptRenderer? postprocessPromptRenderer,
    LongTaskRunStepRecorderService? longTaskRunStepRecorderService,
    LongTaskFinishDispositionService? finishDispositionService,
    LongTaskRunLifecycleService? lifecycleService,
    PrepareChapterAtomicExecutionUseCase? prepareExecutionUseCase,
    BuildLongTaskRevisionPlanUseCase? buildLongTaskRevisionPlanUseCase,
    LongTaskRevisionApplyService? longTaskRevisionApplyService,
    RevisionDiffPreviewService? revisionDiffPreviewService,
    RevisionDiffMarkdownRenderer? revisionDiffMarkdownRenderer,
    TaskChainViewService? taskChainViewService,
    TaskQueueRecordRenderer? taskQueueRecordRenderer,
    LongTaskRunMarkdownRenderer? longTaskRunMarkdownRenderer,
    ModelExecutionProfileService? modelExecutionProfileService,
    LongTaskProjectFileSectionPlanService?
    longTaskProjectFileSectionPlanService,
    LongTaskTaskCompletionPolicyService? taskCompletionPolicyService,
    ProjectModeGuidanceMemorySectionService? modeGuidanceMemorySectionService,
    ProjectLongTaskCheckpointReviewService? checkpointReviewService,
    ProjectLongTaskCheckpointReviewTaskService? checkpointReviewTaskService,
    ProjectLongTaskCheckpointActionService? checkpointActionService,
    ProjectLongTaskChapterQueueRuntimeService? chapterQueueRuntimeService,
    ProjectLongTaskPostprocessResultService? postprocessResultService,
    ProjectLongTaskReviewRepairTaskService? reviewRepairTaskService,
    ProjectLongTaskRevisionResolutionService? revisionResolutionService,
    ProjectLongTaskChapterGateService? chapterGateService,
    ProjectTaskQueueRuntimeOptionResolver? taskQueueRuntimeOptionResolver,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    ProjectWorkflowRuntimeBridgeService? workflowRuntimeBridgeService,
    ProjectWorkflowReviewRuntimeService? workflowReviewRuntimeService,
    WritingExecutionResultNormalizerService?
    writingExecutionResultNormalizerService,
  }) : _taskRepository = taskRepository,
       _promptTemplateService = promptTemplateService,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _loadProjectAgentGroupSelections = loadProjectAgentGroupSelections,
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService(),
       _taskSelectionService =
           taskSelectionService ??
           TaskSelectionService(
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _taskQueueOptionService =
           taskQueueOptionService ?? TaskQueueOptionService(),
       _taskQueueStopPolicyService =
           taskQueueStopPolicyService ??
           TaskQueueStopPolicyService(
             optionService: taskQueueOptionService ?? TaskQueueOptionService(),
           ),
       _taskQueuePreflightService =
           taskQueuePreflightService ??
           TaskQueuePreflightService(
             optionService: taskQueueOptionService ?? TaskQueueOptionService(),
             taskSelectionService:
                 taskSelectionService ??
                 TaskSelectionService(
                   taskDefinitionService:
                       taskDefinitionService ?? TaskDefinitionService(),
                 ),
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _longTaskModeService = longTaskModeService ?? LongTaskModeService(),
       _longTaskPathPolicyService =
           longTaskPathPolicyService ?? LongTaskPathPolicyService(),
       _buildLongTaskPlanUseCase =
           buildLongTaskPlanUseCase ??
           _defaultBuildLongTaskPlanUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRunPathService =
           longTaskRunPathService ??
           LongTaskRunPathService(
             pathPolicyService:
                 longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _startLongTaskRunUseCase =
           startLongTaskRunUseCase ??
           _defaultStartLongTaskRunUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _buildLongTaskSchedulerSnapshotUseCase =
           buildLongTaskSchedulerSnapshotUseCase ??
           _defaultBuildLongTaskSchedulerSnapshotUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
             taskDefinitionService ?? TaskDefinitionService(),
           ),
       _buildLongTaskPromptUseCase =
           buildLongTaskPromptUseCase ??
           _defaultBuildLongTaskPromptUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _postprocessTransactionService =
           postprocessTransactionService ??
           _defaultPostprocessTransactionService(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _postprocessPromptRenderer =
           postprocessPromptRenderer ??
           _defaultPostprocessPromptRenderer(
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRunStepRecorderService =
           longTaskRunStepRecorderService ??
           LongTaskRunStepRecorderService(
             taskSummaryService: LongTaskTaskSummaryService(),
           ),
       _finishDispositionService =
           finishDispositionService ??
           _defaultFinishDispositionService(
             longTaskModeService ?? LongTaskModeService(),
           ),
       _lifecycleService = lifecycleService ?? LongTaskRunLifecycleService(),
       _prepareExecutionUseCase =
           prepareExecutionUseCase ?? _defaultPrepareExecutionUseCase(),
       _buildLongTaskRevisionPlanUseCase =
           buildLongTaskRevisionPlanUseCase ??
           _defaultBuildLongTaskRevisionPlanUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRevisionApplyService =
           longTaskRevisionApplyService ??
           LongTaskRevisionApplyService(
             runPathService:
                 longTaskRunPathService ??
                 LongTaskRunPathService(
                   pathPolicyService:
                       longTaskPathPolicyService ?? LongTaskPathPolicyService(),
                 ),
             transitionService: TaskTransitionService(),
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _revisionDiffPreviewService =
           revisionDiffPreviewService ?? RevisionDiffPreviewService(),
       _revisionDiffMarkdownRenderer =
           revisionDiffMarkdownRenderer ?? RevisionDiffMarkdownRenderer(),
       _taskChainViewService = taskChainViewService ?? TaskChainViewService(),
       _taskQueueRecordRenderer =
           taskQueueRecordRenderer ?? TaskQueueRecordRenderer(),
       _longTaskRunMarkdownRenderer =
           longTaskRunMarkdownRenderer ?? LongTaskRunMarkdownRenderer(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _longTaskProjectFileSectionPlanService =
           longTaskProjectFileSectionPlanService ??
           LongTaskProjectFileSectionPlanService(
             pathPolicyService:
                 longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _taskCompletionPolicyService =
           taskCompletionPolicyService ??
           LongTaskTaskCompletionPolicyService(
             modeService: longTaskModeService ?? LongTaskModeService(),
           ),
       _modeGuidanceMemorySectionService =
           modeGuidanceMemorySectionService ??
           ProjectModeGuidanceMemorySectionService(
             repository: ProjectModeGuidanceRepository(
               workspacePort: taskRepository.workspacePort,
             ),
           ),
       _checkpointReviewService =
           checkpointReviewService ??
           ProjectLongTaskCheckpointReviewService(
             taskRepository: taskRepository,
           ),
       _postprocessResultService =
           postprocessResultService ??
           ProjectLongTaskPostprocessResultService(
             taskRepository: taskRepository,
             checkpointReviewService:
                 checkpointReviewService ??
                 ProjectLongTaskCheckpointReviewService(
                   taskRepository: taskRepository,
                 ),
           ),
       _checkpointReviewTaskService =
           checkpointReviewTaskService ??
           ProjectLongTaskCheckpointReviewTaskService(
             taskRepository: taskRepository,
             reviewReportService: ProjectReviewReportService(
               workspacePort: taskRepository.workspacePort,
               taskRepository: taskRepository,
             ),
           ),
       _checkpointActionService =
           checkpointActionService ??
           ProjectLongTaskCheckpointActionService(
             taskRepository: taskRepository,
             checkpointReviewTaskService:
                 checkpointReviewTaskService ??
                 ProjectLongTaskCheckpointReviewTaskService(
                   taskRepository: taskRepository,
                   reviewReportService: ProjectReviewReportService(
                     workspacePort: taskRepository.workspacePort,
                     taskRepository: taskRepository,
                   ),
                 ),
           ),
       _chapterQueueRuntimeService =
           chapterQueueRuntimeService ??
           ProjectLongTaskChapterQueueRuntimeService(
             taskRepository: taskRepository,
           ),
       _reviewRepairTaskService =
           reviewRepairTaskService ??
           ProjectLongTaskReviewRepairTaskService(
             taskRepository: taskRepository,
             reviewReportService: ProjectReviewReportService(
               workspacePort: taskRepository.workspacePort,
               taskRepository: taskRepository,
             ),
           ),
       _chapterGateService =
           chapterGateService ??
           ProjectLongTaskChapterGateService(
             taskRepository: taskRepository,
             reviewReportService: ProjectReviewReportService(
               workspacePort: taskRepository.workspacePort,
               taskRepository: taskRepository,
             ),
             reviewRepairTaskService:
                 reviewRepairTaskService ??
                 ProjectLongTaskReviewRepairTaskService(
                   taskRepository: taskRepository,
                   reviewReportService: ProjectReviewReportService(
                     workspacePort: taskRepository.workspacePort,
                     taskRepository: taskRepository,
                   ),
                 ),
           ),
       _taskQueueRuntimeOptionResolver =
           taskQueueRuntimeOptionResolver ??
           ProjectTaskQueueRuntimeOptionResolver(
             runtimeProfileRepository: ProjectRuntimeProfileRepository(
               workspacePort: taskRepository.workspacePort,
             ),
           ),
       _draftExecutionConstraintRuntimeService =
           draftExecutionConstraintRuntimeService ??
           ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
             workspacePort: taskRepository.workspacePort,
           ),
       _revisionResolutionService =
           revisionResolutionService ??
           ProjectLongTaskRevisionResolutionService(
             taskRepository: taskRepository,
             checkpointReviewTaskService:
                 checkpointReviewTaskService ??
                 ProjectLongTaskCheckpointReviewTaskService(
                   taskRepository: taskRepository,
                   reviewReportService: ProjectReviewReportService(
                     workspacePort: taskRepository.workspacePort,
                     taskRepository: taskRepository,
                   ),
                 ),
           ),
       _workflowRuntimeBridgeService =
           workflowRuntimeBridgeService ??
           ProjectWorkflowRuntimeBridgeService(
             contextActivationService: ProjectContextActivationService(
               workspacePort: taskRepository.workspacePort,
             ),
           ),
       _workflowReviewRuntimeService =
           workflowReviewRuntimeService ??
           ProjectWorkflowReviewRuntimeService(taskRepository: taskRepository),
       _projectAgentGroupSelectionResolverService =
           const ProjectAgentGroupSelectionResolverService(),
       _writingExecutionResultNormalizerService =
           writingExecutionResultNormalizerService ??
           WritingExecutionResultNormalizerService();

  final ProjectTaskRepository _taskRepository;
  final ProjectPromptTemplateService _promptTemplateService;
  final WorkflowGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final LoadWorkflowProjectAgentGroupSelections?
  _loadProjectAgentGroupSelections;
  final TaskDefinitionService _taskDefinitionService;
  final TaskSelectionService _taskSelectionService;
  final TaskQueueOptionService _taskQueueOptionService;
  final TaskQueueStopPolicyService _taskQueueStopPolicyService;
  final TaskQueuePreflightService _taskQueuePreflightService;
  final LongTaskModeService _longTaskModeService;
  final LongTaskPathPolicyService _longTaskPathPolicyService;
  final BuildLongTaskPlanUseCase _buildLongTaskPlanUseCase;
  final LongTaskRunPathService _longTaskRunPathService;
  final StartLongTaskRunUseCase _startLongTaskRunUseCase;
  final BuildLongTaskSchedulerSnapshotUseCase
  _buildLongTaskSchedulerSnapshotUseCase;
  final BuildLongTaskPromptUseCase _buildLongTaskPromptUseCase;
  final LongTaskPostprocessTransactionService _postprocessTransactionService;
  final LongTaskPostprocessPromptRenderer _postprocessPromptRenderer;
  final LongTaskRunStepRecorderService _longTaskRunStepRecorderService;
  final LongTaskFinishDispositionService _finishDispositionService;
  final LongTaskRunLifecycleService _lifecycleService;
  final PrepareChapterAtomicExecutionUseCase _prepareExecutionUseCase;
  final BuildLongTaskRevisionPlanUseCase _buildLongTaskRevisionPlanUseCase;
  final LongTaskRevisionApplyService _longTaskRevisionApplyService;
  final RevisionDiffPreviewService _revisionDiffPreviewService;
  final RevisionDiffMarkdownRenderer _revisionDiffMarkdownRenderer;
  final TaskChainViewService _taskChainViewService;
  final TaskQueueRecordRenderer _taskQueueRecordRenderer;
  final LongTaskRunMarkdownRenderer _longTaskRunMarkdownRenderer;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final LongTaskProjectFileSectionPlanService
  _longTaskProjectFileSectionPlanService;
  final LongTaskTaskCompletionPolicyService _taskCompletionPolicyService;
  final ProjectModeGuidanceMemorySectionService
  _modeGuidanceMemorySectionService;
  final ProjectLongTaskCheckpointReviewService _checkpointReviewService;
  final ProjectLongTaskPostprocessResultService _postprocessResultService;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;
  final ProjectLongTaskCheckpointActionService _checkpointActionService;
  final ProjectLongTaskChapterQueueRuntimeService _chapterQueueRuntimeService;
  final ProjectLongTaskReviewRepairTaskService _reviewRepairTaskService;
  final ProjectLongTaskChapterGateService _chapterGateService;
  final ProjectTaskQueueRuntimeOptionResolver _taskQueueRuntimeOptionResolver;
  final ProjectDraftExecutionConstraintRuntimeService
  _draftExecutionConstraintRuntimeService;
  final ProjectLongTaskRevisionResolutionService _revisionResolutionService;
  final ProjectWorkflowRuntimeBridgeService _workflowRuntimeBridgeService;
  final ProjectWorkflowReviewRuntimeService _workflowReviewRuntimeService;
  final ProjectAgentGroupSelectionResolverService
  _projectAgentGroupSelectionResolverService;
  final WritingExecutionResultNormalizerService
  _writingExecutionResultNormalizerService;

  List<JsonMap> listTaskRuntimeModes() {
    // 中文注释: 模式定义直接来自 core，确保任务中心和 CLI 的枚举完全同源。
    return _taskDefinitionService.modeDefinitions();
  }

  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 长任务开局同时落计划与任务文件，形成可恢复的项目级队列。
    final createdAt = DateTime.now().toIso8601String();
    final planId =
        'plan_${_longTaskPathPolicyService.safeId(mode)}_${DateTime.now().microsecondsSinceEpoch}';
    final planPath = 'tracking/long_task/$planId.plan.json';
    final planMarkdownPath = 'tracking/long_task/$planId.plan.md';
    final built = _buildLongTaskPlanUseCase.execute(
      mode,
      planId,
      options: options,
      createdAt: createdAt,
      planPath: planPath,
      planMarkdownPath: planMarkdownPath,
    );
    final fullTasks = ValueReaders.mapList(built['tasks'])
        .map(
          (task) => ValueReaders.deepCopyMap(task)
            ..['relative_path'] = _longTaskRunPathService.taskPathForNewTask(
              task,
            ),
        )
        .toList(growable: false);
    final materialized = _chapterQueueRuntimeService
        .materializeInitialPlanWindow(
          mode,
          ValueReaders.mapValue(built['plan']),
          fullTasks,
        );
    final tasks = ValueReaders.mapList(
      materialized['tasks'],
    ).map(ValueReaders.deepCopyMap).toList(growable: false);
    await _taskRepository.saveTasks(project, tasks);
    await _taskRepository.saveRecord(
      project,
      planPath,
      ValueReaders.mapValue(materialized['plan']),
    );
    await _taskRepository.writeTextFile(
      project,
      planMarkdownPath,
      ValueReaders.stringValue(materialized['markdown']),
    );
    return <String, Object?>{
      'ok': true,
      'mode': _longTaskModeService.normalizeMode(mode),
      'plan_id': planId,
      'created_tasks': tasks,
      'plan_path': planPath,
      'plan_markdown_path': planMarkdownPath,
      'changed_paths': <Object?>[
        planPath,
        planMarkdownPath,
        ...tasks.map((task) => ValueReaders.stringValue(task['relative_path'])),
      ],
    };
  }

  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 任务列表统一按 core 排序服务输出，保证不同宿主看到同一顺序。
    final tasks = await _taskRepository.listTasks(project, filters: filters);
    return _taskSelectionService.sortTasks(tasks, filters: filters);
  }

  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一可运行任务完全复用共享调度规则。
    var tasks = await listWorkflowTasks(project, filters: filters);
    var nextTask = _taskSelectionService.nextRunnableTaskFromTasks(tasks);
    if (nextTask.isNotEmpty) {
      return nextTask;
    }
    final materialized = await _chapterQueueRuntimeService
        .ensureMaterializedQueueForNextTask(project, tasks);
    if (!ValueReaders.boolValue(materialized['ok'])) {
      return <String, Object?>{};
    }
    if (!ValueReaders.boolValue(materialized['materialized'])) {
      return const <String, Object?>{};
    }
    tasks = await listWorkflowTasks(project, filters: filters);
    nextTask = _taskSelectionService.nextRunnableTaskFromTasks(tasks);
    return nextTask;
  }

  Future<JsonMap> nextWorkflowPostprocessTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一后处理任务与普通 runnable 分离选择，保持旧项目语义。
    final tasks = await listWorkflowTasks(project, filters: filters);
    return _taskSelectionService.nextPostprocessTaskFromTasks(tasks);
  }

  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 链路视图按 plan 分组并保留依赖/检查点信息，供 GUI/CLI 共用同一份恢复快照。
    final tasks = await listWorkflowTasks(project, filters: filters);
    final view = _taskChainViewService.buildView(tasks);
    return <String, Object?>{
      ...view,
      'next_task': _taskDefinitionService.taskSummary(
        _taskSelectionService.nextRunnableTaskFromTasks(tasks),
      ),
      'next_postprocess_task': _taskDefinitionService.taskSummary(
        _taskSelectionService.nextPostprocessTaskFromTasks(tasks),
      ),
    };
  }

  Future<JsonMap> saveWorkflowChainSnapshot(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 链路快照同时落 JSON 与 Markdown，方便 GUI 回放、CLI 检查和手工排障复用。
    final view = await workflowChainView(project, filters: filters);
    final snapshotId = 'task_chain_${DateTime.now().microsecondsSinceEpoch}';
    final jsonPath = 'tracking/task_chain_views/$snapshotId.json';
    final markdownPath = 'tracking/task_chain_views/$snapshotId.md';
    final snapshot = ValueReaders.deepCopyMap(view)
      ..['id'] = snapshotId
      ..['relative_path'] = jsonPath
      ..['markdown_path'] = markdownPath;
    await _taskRepository.saveRecord(project, jsonPath, snapshot);
    await _taskRepository.writeTextFile(
      project,
      markdownPath,
      _taskChainViewService.renderMarkdown(snapshot),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': jsonPath,
      'markdown_path': markdownPath,
      'view': snapshot,
      'changed_paths': <Object?>[jsonPath, markdownPath],
    };
  }

  Future<JsonMap> loadTaskQueueRun(
    ProjectDescriptor project,
    String relativePath,
  ) {
    // 中文注释: 队列运行详情保持走统一记录仓储，避免任务中心额外依赖底层 JSON 服务。
    return _taskRepository.loadRecord(project, relativePath);
  }

  Future<JsonMap> loadLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    // 中文注释: 长任务运行详情与队列运行详情共用记录读取入口，只在渲染器上分流。
    final record = await _taskRepository.loadRecord(project, relativePath);
    if (record.isEmpty) {
      return record;
    }
    final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      record,
      await listWorkflowTasks(project),
      options: ValueReaders.mapValue(record['options']),
    );
    final runCenterContract = _runCenterContractFromSchedulerSnapshot(
      schedulerSnapshot,
    );
    return <String, Object?>{
      ...record,
      'run_center_contract': runCenterContract,
      'scheduler_snapshot': <String, Object?>{
        ...schedulerSnapshot,
        'run_center_contract': runCenterContract,
      },
    };
  }

  Future<JsonMap> createCheckpointReviewTasks(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 该入口把已有检查点复盘手动物化成审稿任务，供 GUI/CLI 共用，不自动影响调度。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'tasks': const <Object?>[],
        'changed_paths': const <Object?>[],
      };
    }
    final checkpointReviewPath = ValueReaders.stringValue(
      selector['checkpoint_review_path'],
      ValueReaders.stringValue(task['checkpoint_review_path']),
    ).trim();
    if (checkpointReviewPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review path is missing.',
        'tasks': const <Object?>[],
        'changed_paths': const <Object?>[],
      };
    }
    final checkpointReview = await _taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    if (checkpointReview.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review not found.',
        'tasks': const <Object?>[],
        'changed_paths': const <Object?>[],
      };
    }
    final created = await _checkpointReviewTaskService.createTasks(
      project: project,
      task: task,
      checkpointReview: checkpointReview,
    );
    return <String, Object?>{
      ...created,
      'checkpoint_review_path': checkpointReviewPath,
      'task': _taskDefinitionService.taskSummary(task),
    };
  }

  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) {
    // 中文注释: checkpoint 动作包通过共享 adapter 入口暴露，供任务中心和 CLI 后续直接接线。
    return _checkpointActionService.buildActionPackage(
      project,
      checkpointReviewPath,
    );
  }

  Future<JsonMap> buildCheckpointGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) {
    // 中文注释: 任务中心与 CLI 可通过这个只读入口直接加载长期约束回看包，而不触发任何任务写盘。
    return _checkpointActionService.buildGuidanceRevisitPackage(
      project,
      checkpointReviewPath,
    );
  }

  Future<JsonMap> applyCheckpointReviewAction(
    ProjectDescriptor project,
    String checkpointReviewPath,
    String command,
  ) {
    // 中文注释: checkpoint 动作统一由 adapter 层物化，GUI/CLI 不直接操心后续审稿、返工或长期约束回看细节。
    return _checkpointActionService.applyAction(
      project,
      checkpointReviewPath,
      command,
    );
  }

  Future<JsonMap> createWorkflowReviewRepairTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 该入口把 review 任务产出的报告继续转成修复任务，让 mode 1 后续返工也能共用同一条链。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'changed_paths': const <Object?>[],
      };
    }
    final created = await _reviewRepairTaskService.createTask(
      project: project,
      task: task,
      reviewReportPath: ValueReaders.stringValue(
        selector['review_report_path'],
      ),
    );
    return <String, Object?>{
      ...created,
      'source_task': _taskDefinitionService.taskSummary(task),
    };
  }

  String renderTaskQueueRunMarkdown(JsonMap record) {
    // 中文注释: 队列运行 Markdown 供 GUI 日志面板和 CLI 直接复用。
    return _taskQueueRecordRenderer.renderMarkdown(record);
  }

  String renderLongTaskRunMarkdown(JsonMap record) {
    // 中文注释: 长任务运行 Markdown 保留步骤回放信息，方便快速排查哪一步停住。
    return _longTaskRunMarkdownRenderer.renderMarkdown(record);
  }

  Future<JsonMap> saveWorkflowTaskPlan(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 当前单任务计划先落共享事务提示，足够支撑“先看再跑”的旧工作流。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    final memorySections = await _modeGuidanceMemorySectionService.buildForTask(
      project,
      task,
    );
    final projectFileContents = await _readPlannedProjectFileContents(
      project,
      task,
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      task,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
        'memory_sections': memorySections,
        'project_file_contents': projectFileContents,
      },
    );
    final safeId = _longTaskPathPolicyService.safeId(
      ValueReaders.stringValue(task['id']),
      fallbackPrefix: 'task',
    );
    final relativePath = 'tracking/task_plans/$safeId.plan.md';
    await _taskRepository.writeTextFile(project, relativePath, prompt);
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'markdown_path': relativePath,
      'prompt': prompt,
      'changed_paths': <Object?>[relativePath],
    };
  }

  Future<JsonMap> prepareWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector, {
    JsonMap projectInfo = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
  }) async {
    // 中文注释: 执行包准备会把 execution JSON 和 checklist Markdown 一起落盘。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusPlanning,
      note: '开始准备章节原子执行包。',
    );
    final memorySections = await _modeGuidanceMemorySectionService.buildForTask(
      project,
      task,
    );
    final executionConstraints = await _draftExecutionConstraintRuntimeService
        .resolve(
          project,
          appliesTo: _constraintAppliesToForTask(task),
          agentId: ValueReaders.stringValue(agent['id']),
          modeId: ValueReaders.stringValue(task['mode']),
          stageId: ValueReaders.stringValue(
            ValueReaders.mapValue(task['metadata'])['stage'],
            'draft',
          ),
          intent: 'workflow_task',
          taskType: ValueReaders.stringValue(task['task_type']),
          legacyChapterLengthOptions: ValueReaders.mapValue(task['metadata']),
        );
    final effectiveTask = _taskWithExecutionConstraintMetadata(
      task,
      executionConstraints,
    );
    final workflowBridge = await _workflowRuntimeBridgeService.buildTaskBridge(
      project,
      task,
    );
    final projectFileContents = await _readPlannedProjectFileContents(
      project,
      task,
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      effectiveTask,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
        'memory_sections': memorySections,
        'project_file_contents': projectFileContents,
        'expression_constraint_profiles': ValueReaders.objectList(
          executionConstraints['expression_constraint_profiles'],
        ),
        'project_expression_constraint_bindings': ValueReaders.objectList(
          executionConstraints['project_expression_constraint_bindings'],
        ),
      },
    );
    final entries = await _taskRepository.workspacePort.listEntries(
      project.rootPath,
    );
    final result = _prepareExecutionUseCase.execute(<String, Object?>{
      'project': projectInfo.isEmpty
          ? <String, Object?>{
              'id': project.id,
              'title': project.name,
              'path': project.rootPath,
              'project_type': project.projectType,
            }
          : projectInfo,
      'task': effectiveTask,
      'project_files': entries,
      'session_context': _mergeSessionContexts(
        ValueReaders.stringValue(workflowBridge['activation_context_markdown']),
        ValueReaders.stringValue(
          executionConstraints['session_context_markdown'],
        ),
      ),
      'current_file_body': '',
      'current_file_path': '',
      'user_prompt': prompt,
      'agent': agent,
      'optional_agents': const <Object?>[],
      'context_settings': contextSettings,
      'model_profile': modelProfile,
      'memory_sections': memorySections,
      'expression_constraint_profiles': ValueReaders.objectList(
        executionConstraints['expression_constraint_profiles'],
      ),
      'project_expression_constraint_bindings': ValueReaders.objectList(
        executionConstraints['project_expression_constraint_bindings'],
      ),
      'project_file_section_plan': _longTaskProjectFileSectionPlanService.build(
        task,
      ),
      'project_file_contents': projectFileContents,
    });
    if (!ValueReaders.boolValue(result['ok'])) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: '章节原子执行包准备失败：${ValueReaders.stringValue(result["error"])}',
      );
      return result;
    }
    final safeId = _longTaskPathPolicyService.safeId(
      ValueReaders.stringValue(task['id']),
      fallbackPrefix: 'task',
    );
    final activationReportPath =
        'tracking/chapter_atomic/$safeId.activation_report.json';
    final execution =
        _workflowRuntimeBridgeService.attachPreparationArtifacts(
            ValueReaders.mapValue(result['execution'])
              ..['prompt_preview_markdown'] = prompt,
            workflowBridge,
            activationReportPath: activationReportPath,
          )
          ..['effective_task'] = ValueReaders.deepCopyMap(effectiveTask)
          ..['execution_constraint_bridge_report'] = ValueReaders.deepCopyMap(
            ValueReaders.mapValue(executionConstraints['runtime_report']),
          );
    final executionPath = ValueReaders.stringValue(result['execution_path']);
    final checklistPath = ValueReaders.stringValue(result['checklist_path']);
    await _taskRepository.saveRecord(
      project,
      activationReportPath,
      ValueReaders.mapValue(workflowBridge['activation_report']),
    );
    await _taskRepository.saveRecord(project, executionPath, execution);
    await _taskRepository.writeTextFile(project, checklistPath, prompt);
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusPlanning,
      note: '章节原子执行包已准备，等待模型执行。',
      extra: <String, Object?>{
        'atomic_execution_path': executionPath,
        'atomic_checklist_path': checklistPath,
        'context_pack_id': ValueReaders.stringValue(result['context_pack_id']),
        'proposed_output_paths': ValueReaders.mapValue(
          result['proposed_output_paths'],
        ),
        'activation_report_path': activationReportPath,
        'activation_report_summary': ValueReaders.stringValue(
          ValueReaders.mapValue(workflowBridge['activation_report'])['summary'],
        ),
      },
    );
    return <String, Object?>{
      'ok': true,
      'execution_path': executionPath,
      'checklist_path': checklistPath,
      'relative_path': executionPath,
      'context_pack_id': ValueReaders.stringValue(result['context_pack_id']),
      'activation_report_path': activationReportPath,
      'execution': execution,
      'changed_paths': <Object?>[
        executionPath,
        checklistPath,
        activationReportPath,
      ],
    };
  }

  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 执行包详情统一通过任务记录中的 atomic_execution_path 定位。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{};
    }
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim();
    if (executionPath.isEmpty) {
      return <String, Object?>{};
    }
    return _taskRepository.loadRecord(project, executionPath);
  }

  Future<JsonMap> runWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 单步执行复用共享生成用例和项目工具调度，形成 GUI/CLI 共用运行链。
    final provider = settings.defaultProvider();
    if (provider == null) {
      return <String, Object?>{
        'ok': false,
        'error': '未找到可用 provider。',
        'response': <String, Object?>{},
      };
    }
    var task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'response': <String, Object?>{},
      };
    }
    final reviewPreflight = await _workflowReviewRuntimeService
        .preflightReviewTask(project: project, task: task);
    if (ValueReaders.stringValue(reviewPreflight['action']) ==
        'skip_review_create_recovery') {
      final transitioned = await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusSucceeded,
        note: '正文尚未形成可审稿交付，已跳过语义审稿并创建 recovery 任务。',
        extra: <String, Object?>{
          'review_skipped_reason': ValueReaders.stringValue(
            ValueReaders.mapValue(reviewPreflight['delivery_state'])['reason'],
          ),
          'review_skipped_delivery_state': ValueReaders.stringValue(
            ValueReaders.mapValue(reviewPreflight['delivery_state'])['state'],
          ),
          'recovery_task_id': ValueReaders.stringValue(
            ValueReaders.mapValue(reviewPreflight['recovery_task'])['id'],
          ),
          'recovery_task_path': ValueReaders.stringValue(
            ValueReaders.mapValue(
              reviewPreflight['recovery_task'],
            )['relative_path'],
          ),
        },
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: const <String, Object?>{},
        executionConstraints: const <String, Object?>{},
        checkpointReview: const <String, Object?>{},
        deliveryOverride: ValueReaders.mapValue(
          reviewPreflight['delivery_state'],
        ),
      );
      return <String, Object?>{
        'ok': true,
        'skipped_review': true,
        'review_preflight': reviewPreflight,
        'recovery_task': ValueReaders.mapValue(
          reviewPreflight['recovery_task'],
        ),
        'writing_execution_result': writingExecutionResult,
        'response': const <String, Object?>{},
        'output_paths': const <Object?>[],
        'changed_paths': <Object?>[
          ...ValueReaders.objectList(reviewPreflight['changed_paths']),
          ValueReaders.stringValue(transitioned['relative_path']),
        ],
      };
    }
    if (ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim().isEmpty) {
      final prepared = await prepareWorkflowTaskExecution(
        project,
        selector,
        modelProfile: <String, Object?>{
          'id': provider.id,
          'base_url': provider.baseUrl,
          'model_id': provider.modelId,
        },
        contextSettings: settings.contextSettings,
      );
      if (!ValueReaders.boolValue(prepared['ok'])) {
        return <String, Object?>{
          'ok': false,
          'error': ValueReaders.stringValue(
            prepared['error'],
            'Prepare task failed.',
          ),
          'response': <String, Object?>{},
        };
      }
      task = await _taskRepository.loadTask(project, selector);
    }
    final memorySections = await _modeGuidanceMemorySectionService.buildForTask(
      project,
      task,
    );
    final executionConstraints = await _draftExecutionConstraintRuntimeService
        .resolve(
          project,
          appliesTo: _constraintAppliesToForTask(task),
          agentId: ValueReaders.stringValue(agent['id']),
          modeId: ValueReaders.stringValue(task['mode']),
          stageId: ValueReaders.stringValue(
            ValueReaders.mapValue(task['metadata'])['stage'],
            'draft',
          ),
          intent: 'workflow_task',
          taskType: ValueReaders.stringValue(task['task_type']),
          legacyChapterLengthOptions: ValueReaders.mapValue(task['metadata']),
        );
    final effectiveTask = _taskWithExecutionConstraintMetadata(
      task,
      executionConstraints,
    );
    final workflowBridge = await _workflowRuntimeBridgeService.buildTaskBridge(
      project,
      task,
    );
    final projectFileSectionPlan = _longTaskProjectFileSectionPlanService.build(
      task,
    );
    final projectFileContents = await _readPlannedProjectFileContents(
      project,
      task,
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      effectiveTask,
      runRecord: runRecord,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
        'memory_sections': memorySections,
        'project_file_contents': projectFileContents,
        'expression_constraint_profiles': ValueReaders.objectList(
          executionConstraints['expression_constraint_profiles'],
        ),
        'project_expression_constraint_bindings': ValueReaders.objectList(
          executionConstraints['project_expression_constraint_bindings'],
        ),
      },
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusRunning,
      note: '章节原子任务开始单步模型执行。',
      extra: const <String, Object?>{
        'postprocess_ran_at': '',
        'postprocess_review_report_path': '',
        'postprocess_review_report_json_path': '',
        'postprocess_checkpoint_review_path': '',
        'postprocess_checkpoint_review_summary': '',
      },
    );
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      agent: agent,
    );
    final useCase = _generateDraftUseCaseFactory(
      provider,
      settings.networkSettings,
    );
    final selectedCollaborationGroup =
        await _resolveSelectedCollaborationGroupForTask(
          project: project,
          task: task,
          agent: agent,
        );
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: ValueReaders.stringValue(
        executionProfile['resolved_model_id'],
        settings.defaultModelId.trim().isEmpty
            ? provider.modelId
            : settings.defaultModelId,
      ),
      title: ValueReaders.stringValue(task['title']),
      intent: 'workflow_task',
      agent: agent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      requestOptions: ValueReaders.mapValue(
        executionProfile['request_options'],
      ),
      contextSettings: settings.contextSettings,
      modelProfile: <String, Object?>{
        'id': provider.id,
        'base_url': provider.baseUrl,
        'model_id': provider.modelId,
      },
      skillRoutingContext: <String, Object?>{
        'task_type': ValueReaders.stringValue(task['task_type']),
        'mode': ValueReaders.stringValue(task['mode']),
        'title': ValueReaders.stringValue(task['title']),
        'goal': ValueReaders.stringValue(task['goal']),
        'brief': ValueReaders.stringValue(task['brief']),
        'review_type': ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['review_type'],
        ),
      },
      memorySections: memorySections,
      projectFileSectionPlan: projectFileSectionPlan,
      projectFileContents: projectFileContents,
      expressionConstraintProfiles: ValueReaders.objectList(
        executionConstraints['expression_constraint_profiles'],
      ),
      projectExpressionConstraintBindings: ValueReaders.objectList(
        executionConstraints['project_expression_constraint_bindings'],
      ),
      subAgentRuntimeSettings: settings,
      subAgentBindingModeId: ValueReaders.stringValue(task['mode']),
      subAgentBindingStageId: ValueReaders.stringValue(
        ValueReaders.mapValue(task['metadata'])['stage'],
        'draft',
      ),
      sessionContext: _mergeSessionContexts(
        ValueReaders.stringValue(workflowBridge['activation_context_markdown']),
        ValueReaders.stringValue(
          executionConstraints['session_context_markdown'],
        ),
      ),
      exposedToolIds: ValueReaders.stringList(
        workflowBridge['workflow_tool_ids'],
      ),
    );
    var outputPaths = _workflowRuntimeBridgeService.resolveOutputPaths(
      executedTools: result.executedTools,
      writtenPaths: result.writtenPaths,
    );
    final semanticReviewArtifacts = await _workflowReviewRuntimeService
        .persistSemanticReviewArtifacts(
          project: project,
          task: task,
          executedTools: result.executedTools,
        );
    outputPaths = _mergePaths(
      outputPaths,
      ValueReaders.stringList(semanticReviewArtifacts['output_paths']),
    );
    final workflowChangedPaths = _mergePaths(
      result.changedPaths,
      ValueReaders.stringList(semanticReviewArtifacts['changed_paths']),
    );
    JsonMap revisionDiff = const <String, Object?>{};
    if (ValueReaders.stringValue(task['task_type']) == 'revision') {
      revisionDiff = await _saveRevisionDiffIfNeeded(
        project,
        task,
        result.executedTools,
      );
    }
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    );
    JsonMap executionRecord = const <String, Object?>{};
    if (executionPath.trim().isNotEmpty) {
      executionRecord = await _taskRepository.loadRecord(
        project,
        executionPath,
      );
      if (executionRecord.isNotEmpty) {
        var nextExecution = ValueReaders.deepCopyMap(executionRecord);
        if (ValueReaders.stringValue(
          nextExecution['activation_report_path'],
        ).trim().isEmpty) {
          final safeId = _longTaskPathPolicyService.safeId(
            ValueReaders.stringValue(task['id']),
            fallbackPrefix: 'task',
          );
          final activationReportPath =
              'tracking/chapter_atomic/$safeId.activation_report.json';
          await _taskRepository.saveRecord(
            project,
            activationReportPath,
            ValueReaders.mapValue(workflowBridge['activation_report']),
          );
          nextExecution = _workflowRuntimeBridgeService
              .attachPreparationArtifacts(
                nextExecution,
                workflowBridge,
                activationReportPath: activationReportPath,
              );
        }
        nextExecution = _workflowRuntimeBridgeService.attachRunArtifacts(
          nextExecution,
          executedTools: result.executedTools,
          writtenPaths: result.writtenPaths,
          draftPreview: result.draftMarkdown,
        );
        nextExecution = _workflowReviewRuntimeService.attachReviewArtifacts(
          nextExecution,
          semanticReviewArtifacts,
        );
        if (ValueReaders.boolValue(revisionDiff['ok'])) {
          nextExecution['revision_diff_path'] = ValueReaders.stringValue(
            revisionDiff['relative_path'],
          );
        }
        await _taskRepository.saveRecord(project, executionPath, nextExecution);
        executionRecord = nextExecution;
      }
    }
    JsonMap checkpointReview = const <String, Object?>{};
    if (result.executedTools.isNotEmpty ||
        outputPaths.isNotEmpty ||
        result.draftMarkdown.trim().isNotEmpty) {
      checkpointReview = await _checkpointReviewService.saveReview(
        project: project,
        task: task,
        result: <String, Object?>{
          'ok': true,
          'output_paths': outputPaths,
          'changed_paths': workflowChangedPaths,
          'executed_tools': result.executedTools,
          'response': _resultAsResponse(result),
        },
        memorySections: memorySections,
        execution: executionRecord,
      );
    }
    final gateOutcome = await _chapterGateService.applyReviewOutcome(
      project: project,
      task: task,
    );
    if (!ValueReaders.boolValue(gateOutcome['ok'], true)) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: '章级闸门返工链创建失败：${ValueReaders.stringValue(gateOutcome["error"])}',
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: checkpointReview,
        result: result,
        recoveryPlan: <String, Object?>{
          'action': 'pause_for_failure',
          'reason': 'chapter_gate_failed',
          'note': ValueReaders.stringValue(
            gateOutcome['error'],
            '章级闸门返工链创建失败。',
          ),
        },
        transportFailed: true,
      );
      executionRecord = await _persistWritingExecutionResult(
        project,
        executionPath,
        executionRecord,
        writingExecutionResult,
      );
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          gateOutcome['error'],
          'Chapter gate handling failed.',
        ),
        'response': _resultAsResponse(result),
        'output_paths': outputPaths,
        'execution': executionRecord,
        'activation_report_path': ValueReaders.stringValue(
          executionRecord['activation_report_path'],
        ),
        'activation_report_summary': ValueReaders.stringValue(
          executionRecord['activation_report_summary'],
        ),
        'chapter_delivery': ValueReaders.mapValue(
          executionRecord['chapter_delivery'],
        ),
        'chapter_delivery_state': ValueReaders.stringValue(
          executionRecord['chapter_delivery_state'],
        ),
        'chapter_delivery_path': ValueReaders.stringValue(
          executionRecord['chapter_delivery_path'],
        ),
        'revision_diff': revisionDiff,
        'checkpoint_review': checkpointReview,
        'gate_outcome': gateOutcome,
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': _mergePaths(
          workflowChangedPaths,
          ValueReaders.stringList(gateOutcome['changed_paths']),
        ),
      };
    }
    final formalChapterDecision = _formalChapterCompletionDecision(
      task: task,
      result: result,
      outputPaths: outputPaths,
      executionRecord: executionRecord,
    );
    if (ValueReaders.stringValue(formalChapterDecision['action']) ==
        'wait_user') {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusWaitingUser,
        note: ValueReaders.stringValue(formalChapterDecision['note']),
        extra: <String, Object?>{
          'output_paths': outputPaths,
          'waiting_for_user_choice': true,
          if (ValueReaders.boolValue(checkpointReview['ok']))
            'checkpoint_review_path': ValueReaders.stringValue(
              checkpointReview['relative_path'],
            ),
          if (ValueReaders.boolValue(checkpointReview['ok']))
            'checkpoint_review_summary': ValueReaders.stringValue(
              ValueReaders.mapValue(checkpointReview['review'])['summary'],
            ),
        },
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: checkpointReview,
        result: result,
        recoveryPlan: <String, Object?>{
          'action': 'resume_when_user_confirms',
          'reason': 'formal_chapter_waiting_user',
          'note': ValueReaders.stringValue(formalChapterDecision['note']),
        },
      );
      executionRecord = await _persistWritingExecutionResult(
        project,
        executionPath,
        executionRecord,
        writingExecutionResult,
      );
      return <String, Object?>{
        'ok': true,
        'response': _resultAsResponse(result),
        'waiting_for_user_choice': true,
        'output_paths': outputPaths,
        'execution': executionRecord,
        'activation_report_path': ValueReaders.stringValue(
          executionRecord['activation_report_path'],
        ),
        'activation_report_summary': ValueReaders.stringValue(
          executionRecord['activation_report_summary'],
        ),
        'chapter_delivery': ValueReaders.mapValue(
          executionRecord['chapter_delivery'],
        ),
        'chapter_delivery_state': ValueReaders.stringValue(
          executionRecord['chapter_delivery_state'],
        ),
        'chapter_delivery_path': ValueReaders.stringValue(
          executionRecord['chapter_delivery_path'],
        ),
        'revision_diff': revisionDiff,
        'checkpoint_review': checkpointReview,
        'gate_outcome': gateOutcome,
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': _mergePaths(
          workflowChangedPaths,
          ValueReaders.stringList(gateOutcome['changed_paths']),
        ),
      };
    }
    if (ValueReaders.stringValue(formalChapterDecision['action']) == 'fail') {
      final error = ValueReaders.stringValue(
        formalChapterDecision['error'],
        'Formal chapter completion is missing.',
      );
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: error,
        extra: <String, Object?>{
          'output_paths': outputPaths,
          if (ValueReaders.boolValue(checkpointReview['ok']))
            'checkpoint_review_path': ValueReaders.stringValue(
              checkpointReview['relative_path'],
            ),
          if (ValueReaders.boolValue(checkpointReview['ok']))
            'checkpoint_review_summary': ValueReaders.stringValue(
              ValueReaders.mapValue(checkpointReview['review'])['summary'],
            ),
        },
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: checkpointReview,
        result: result,
        recoveryPlan: _formalChapterRecoveryPlan(
          executionRecord: executionRecord,
          note: error,
        ),
      );
      executionRecord = await _persistWritingExecutionResult(
        project,
        executionPath,
        executionRecord,
        writingExecutionResult,
      );
      return <String, Object?>{
        'ok': false,
        'error': error,
        'response': _resultAsResponse(result),
        'waiting_for_user_choice': false,
        'output_paths': outputPaths,
        'execution': executionRecord,
        'activation_report_path': ValueReaders.stringValue(
          executionRecord['activation_report_path'],
        ),
        'activation_report_summary': ValueReaders.stringValue(
          executionRecord['activation_report_summary'],
        ),
        'chapter_delivery': ValueReaders.mapValue(
          executionRecord['chapter_delivery'],
        ),
        'chapter_delivery_state': ValueReaders.stringValue(
          executionRecord['chapter_delivery_state'],
        ),
        'chapter_delivery_path': ValueReaders.stringValue(
          executionRecord['chapter_delivery_path'],
        ),
        'revision_diff': revisionDiff,
        'checkpoint_review': checkpointReview,
        'gate_outcome': gateOutcome,
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': _mergePaths(
          workflowChangedPaths,
          ValueReaders.stringList(gateOutcome['changed_paths']),
        ),
      };
    }
    final defaultNextStatus = _taskCompletionPolicyService
        .statusAfterSuccessfulModelStep(task);
    final nextStatus = _resolveStatusAfterGate(defaultNextStatus, gateOutcome);
    await _taskRepository.transitionTask(
      project,
      selector,
      nextStatus,
      note: _completionNote(nextStatus, outputPaths),
      extra: <String, Object?>{
        'output_paths': outputPaths,
        if (ValueReaders.boolValue(revisionDiff['ok']))
          'revision_diff_path': ValueReaders.stringValue(
            revisionDiff['relative_path'],
          ),
        if (ValueReaders.boolValue(revisionDiff['ok']))
          'revision_diff_summary': ValueReaders.stringValue(
            ValueReaders.mapValue(revisionDiff['report'])['summary'],
          ),
        if (ValueReaders.boolValue(checkpointReview['ok']))
          'checkpoint_review_path': ValueReaders.stringValue(
            checkpointReview['relative_path'],
          ),
        if (ValueReaders.boolValue(checkpointReview['ok']))
          'checkpoint_review_summary': ValueReaders.stringValue(
            ValueReaders.mapValue(checkpointReview['review'])['summary'],
          ),
        if (ValueReaders.stringValue(gateOutcome['action']).isNotEmpty)
          'chapter_gate_action': ValueReaders.stringValue(
            gateOutcome['action'],
          ),
        if (ValueReaders.stringValue(
          gateOutcome['gate_disposition'],
        ).isNotEmpty)
          'chapter_gate_disposition': ValueReaders.stringValue(
            gateOutcome['gate_disposition'],
          ),
        if (ValueReaders.stringValue(gateOutcome['gate_reason']).isNotEmpty)
          'chapter_gate_reason': ValueReaders.stringValue(
            gateOutcome['gate_reason'],
          ),
        if (ValueReaders.boolValue(gateOutcome['blocks_auto_advance']))
          'chapter_gate_blocks_auto_advance': true,
        if (ValueReaders.boolValue(gateOutcome['manual_attention_required']))
          'chapter_gate_manual_attention_required': true,
        if (ValueReaders.stringValue(
          gateOutcome['review_report_path'],
        ).isNotEmpty)
          'chapter_gate_review_report_path': ValueReaders.stringValue(
            gateOutcome['review_report_path'],
          ),
      },
    );
    final writingExecutionResult = _buildWritingExecutionResult(
      task: task,
      executionRecord: executionRecord,
      executionConstraints: executionConstraints,
      checkpointReview: checkpointReview,
      result: result,
      recoveryPlan: _successRecoveryPlan(
        nextStatus: nextStatus,
        gateOutcome: gateOutcome,
        waitingForUserChoice: result.waitingForUserChoice,
      ),
    );
    executionRecord = await _persistWritingExecutionResult(
      project,
      executionPath,
      executionRecord,
      writingExecutionResult,
    );
    return <String, Object?>{
      'ok': true,
      'response': _resultAsResponse(result),
      'waiting_for_user_choice': result.waitingForUserChoice,
      'output_paths': outputPaths,
      'execution': executionRecord,
      'activation_report_path': ValueReaders.stringValue(
        executionRecord['activation_report_path'],
      ),
      'activation_report_summary': ValueReaders.stringValue(
        executionRecord['activation_report_summary'],
      ),
      'chapter_delivery': ValueReaders.mapValue(
        executionRecord['chapter_delivery'],
      ),
      'chapter_delivery_state': ValueReaders.stringValue(
        executionRecord['chapter_delivery_state'],
      ),
      'chapter_delivery_path': ValueReaders.stringValue(
        executionRecord['chapter_delivery_path'],
      ),
      'revision_diff': revisionDiff,
      'checkpoint_review': checkpointReview,
      'gate_outcome': gateOutcome,
      'writing_execution_result': writingExecutionResult,
      'executed_tools': result.executedTools,
      'changed_paths': _mergePaths(
        workflowChangedPaths,
        ValueReaders.stringList(gateOutcome['changed_paths']),
      ),
    };
  }

  String _completionNote(String status, List<String> outputPaths) {
    // 中文注释: 成功后的说明与状态一起收束，避免章节自动完成后仍留下“等待确认”的误导文案。
    if (status == TaskRuntimeConstants.statusSucceeded) {
      return outputPaths.isEmpty
          ? '模型单步已完成，本任务按当前模式自动标记完成。'
          : '模型已写入项目文件，本任务按当前模式自动标记完成。';
    }
    return outputPaths.isEmpty ? '模型已返回，等待用户确认后继续。' : '模型已写入项目文件，等待用户确认后继续。';
  }

  JsonMap _formalChapterCompletionDecision({
    required JsonMap task,
    required DraftGenerationResult result,
    required List<String> outputPaths,
    required JsonMap executionRecord,
  }) {
    if (!_requiresFormalWorkflowChapterCompletion(task)) {
      return const <String, Object?>{'action': 'pass'};
    }
    if (result.cancelledByUser) {
      return const <String, Object?>{'action': 'pass'};
    }
    if (_hasFormalWorkflowChapterArtifact(outputPaths, executionRecord)) {
      return const <String, Object?>{'action': 'pass'};
    }
    if (result.waitingForUserChoice) {
      return <String, Object?>{
        'action': 'wait_user',
        'note': _formalWorkflowChapterWaitingMessage(result),
      };
    }
    return <String, Object?>{
      'action': 'fail',
      'error': _formalWorkflowChapterFailureMessage(result),
    };
  }

  bool _requiresFormalWorkflowChapterCompletion(JsonMap task) {
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    return taskType == 'chapter' || taskType == 'revision';
  }

  bool _hasFormalWorkflowChapterArtifact(
    List<String> outputPaths,
    JsonMap executionRecord,
  ) {
    for (final path in <String>[
      ...outputPaths,
      ...ValueReaders.stringList(executionRecord['output_paths']),
      ValueReaders.stringValue(executionRecord['chapter_delivery_path']),
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          executionRecord['chapter_delivery'],
        )['chapter_path'],
      ),
    ]) {
      if (_isWorkflowChapterPath(path)) {
        return true;
      }
    }
    return false;
  }

  bool _isWorkflowChapterPath(String path) {
    final clean = path.trim().replaceAll('\\', '/').toLowerCase();
    return clean.startsWith('chapters/') && clean.endsWith('.md');
  }

  String _formalWorkflowChapterWaitingMessage(DraftGenerationResult result) {
    final trace = _formalWorkflowChapterToolTrace(result);
    return '长任务正式章节任务停在用户选择点：本轮只执行了用户选项/计划/读取类工具（$trace），没有形成正式章节正文或交付。';
  }

  String _formalWorkflowChapterFailureMessage(DraftGenerationResult result) {
    final toolNames = _distinctWorkflowToolNames(result.executedTools);
    final trace = toolNames.isEmpty ? '无工具调用' : toolNames.join('、');
    final onlyNonDelivering =
        toolNames.isNotEmpty && toolNames.every(_isNonDeliveringWorkflowTool);
    if (onlyNonDelivering) {
      return '长任务正式章节任务未形成正式交付：本轮只执行了计划/选项/读取类工具（$trace），没有写出章节正文，也没有 submit_chapter_delivery。';
    }
    return '长任务正式章节任务未形成正式交付：缺少章节正文输出或 submit_chapter_delivery。当前工具轨迹：$trace';
  }

  String _formalWorkflowChapterToolTrace(DraftGenerationResult result) {
    final toolNames = _distinctWorkflowToolNames(result.executedTools);
    return toolNames.isEmpty ? '无工具调用' : toolNames.join('、');
  }

  List<String> _distinctWorkflowToolNames(List<Object?> executedTools) {
    final names = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isEmpty || names.contains(name)) {
        continue;
      }
      names.add(name);
    }
    return names;
  }

  bool _isNonDeliveringWorkflowTool(String toolName) {
    return const <String>{
      'present_user_options',
      'load_agent_skill',
      'read_project_file',
      'get_project_file_info',
      'list_project_files',
      'search_project_files',
      'call_sub_agent',
      'set_agent_tasks',
      'summarize_context',
      'submit_semantic_review',
      'request_profile_clarification',
      'propose_narrative_profile_update',
      'propose_constraint_binding',
      'submit_narrative_state_claims',
    }.contains(toolName);
  }

  String _resolveStatusAfterGate(String defaultStatus, JsonMap gateOutcome) {
    // 中文注释: review -> gate 决策后的任务状态统一在 runtime 层做最终落点，但规则仍来自 core 返回的 disposition。
    final decision = ValueReaders.mapValue(gateOutcome['gate_decision']);
    if (decision.isEmpty) {
      return defaultStatus;
    }
    return LongTaskChapterGatePolicyService().statusAfterReviewOutcome(
      decision,
      defaultStatus,
    );
  }

  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 下一任务单步执行只是对 next runnable 的薄包装。
    final task = await nextWorkflowTask(project);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前没有可运行任务。',
        'response': <String, Object?>{},
      };
    }
    return runWorkflowTaskOnce(project, settings, <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    }, agent: agent);
  }

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 预检只读任务与最近运行摘要，解释“能不能跑、为什么会停”。
    return _taskQueuePreflightService.preflightFromTasks(
      await listWorkflowTasks(project),
      options: options,
      recentRuns: await listTaskQueueRuns(project),
    );
  }

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    // 中文注释: 受控队列运行记录统一保存在 tracking/task_queue_runs/。
    return _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/task_queue_runs/',
      limit: limit,
    );
  }

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    // 中文注释: 长任务运行记录统一保存在 tracking/long_task_runs/。
    return _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/long_task_runs/',
      limit: limit,
    );
  }

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 调度 tick 计划既支持指定运行记录，也支持默认使用最近一条长任务记录。
    var runPath = relativePath.trim();
    if (runPath.isEmpty) {
      final recentRuns = await listLongTaskRuns(project, limit: 1);
      if (recentRuns.isNotEmpty) {
        runPath = ValueReaders.stringValue(recentRuns.first['relative_path']);
      }
    }
    if (runPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
        'action': 'idle',
      };
    }
    final record = await _taskRepository.loadRecord(project, runPath);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
        'action': 'idle',
      };
    }
    final snapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      record,
      await listWorkflowTasks(project),
      options: options,
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': runPath,
      ...snapshot,
      ...ValueReaders.mapValue(snapshot['scheduler_plan']),
    };
  }

  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String relativePath, {
    String note = '用户暂停长任务。',
  }) async {
    // 中文注释: 暂停只改运行记录，不隐式改动任务文件状态。
    final record = await _taskRepository.loadRecord(project, relativePath);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
      };
    }
    final updated = _lifecycleService.pauseRecord(
      record,
      reason: 'manual_pause',
      note: note,
    );
    await _taskRepository.saveRecord(project, relativePath, updated);
    final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      updated,
      await listWorkflowTasks(project),
      options: ValueReaders.mapValue(updated['options']),
    );
    final runCenterContract = _runCenterContractFromSchedulerSnapshot(
      schedulerSnapshot,
    );
    return <String, Object?>{
      'ok': true,
      'record': updated,
      'run_center_contract': runCenterContract,
      'scheduler_snapshot': <String, Object?>{
        ...schedulerSnapshot,
        'run_center_contract': runCenterContract,
      },
    };
  }

  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings,
    String relativePath, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 恢复长任务直接复用队列运行入口，并显式传入继续的运行记录路径。
    return runWorkflowTaskQueue(
      project,
      settings,
      options: <String, Object?>{
        ...options,
        'continue_long_task_run_path': relativePath,
      },
      agent: agent,
    );
  }

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 受控连续运行按安全步数推进，并把队列记录与长任务记录都写到 tracking/。
    final resolvedOptions = await _taskQueueRuntimeOptionResolver.resolve(
      project,
      options: options,
    );
    final cleanOptions = _taskQueueOptionService.normalizeOptions(
      resolvedOptions,
    );
    final queueId = 'task_queue_${DateTime.now().microsecondsSinceEpoch}';
    final queuePath = 'tracking/task_queue_runs/$queueId.json';
    var queueRecord = <String, Object?>{
      'schema_version': 1,
      'id': queueId,
      'status': 'running',
      'options': cleanOptions,
      'steps': <Object?>[],
      'completed_steps': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'relative_path': queuePath,
      'summary_path': 'tracking/task_queue_runs/$queueId.md',
    };
    await _taskRepository.saveRecord(project, queuePath, queueRecord);

    var longRunPath = ValueReaders.stringValue(
      resolvedOptions['continue_long_task_run_path'],
      ValueReaders.stringValue(resolvedOptions['long_task_run_path']),
    ).trim();
    JsonMap longRunRecord = const <String, Object?>{};
    if (longRunPath.isEmpty) {
      final start = _startLongTaskRunUseCase.execute(
        await listWorkflowTasks(project),
        options: cleanOptions,
      );
      longRunPath = ValueReaders.stringValue(start['relative_path']);
      longRunRecord = ValueReaders.mapValue(start['record']);
      await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
    } else {
      longRunRecord = await _taskRepository.loadRecord(project, longRunPath);
      if (longRunRecord.isNotEmpty) {
        longRunRecord = _lifecycleService.resumeRecord(longRunRecord);
        await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      }
    }

    var stepsRun = 0;
    var stopReason = '';
    var stopNote = '';
    JsonMap lastResult = const <String, Object?>{};
    while (stepsRun < ValueReaders.intValue(cleanOptions['max_steps'], 3)) {
      final nextTask = await nextWorkflowTask(project);
      if (nextTask.isEmpty) {
        stopReason = 'no_runnable_task';
        stopNote = '当前没有依赖满足且处于 queued/retrying 的任务。';
        break;
      }
      lastResult = await runWorkflowTaskOnce(
        project,
        settings,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
        },
        runRecord: longRunRecord,
        agent: agent,
      );
      stepsRun += 1;
      final updatedTask = await _taskRepository.loadTask(
        project,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
        },
      );
      queueRecord = _appendQueueStep(
        queueRecord,
        updatedTask,
        lastResult,
        index: stepsRun,
      );
      await _taskRepository.saveRecord(project, queuePath, queueRecord);

      if (longRunRecord.isNotEmpty) {
        longRunRecord = _longTaskRunStepRecorderService.recordStep(
          longRunRecord,
          updatedTask,
          lastResult,
        );
        await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      }

      final stopDecision = _taskQueueStopPolicyService.stopAfterStep(
        lastResult,
        updatedTask,
        options: cleanOptions,
      );
      if (ValueReaders.boolValue(stopDecision['stop'])) {
        stopReason = ValueReaders.stringValue(stopDecision['reason']);
        stopNote = ValueReaders.stringValue(stopDecision['note']);
        break;
      }
    }

    if (stopReason.isEmpty) {
      stopReason =
          stepsRun >= ValueReaders.intValue(cleanOptions['max_steps'], 3)
          ? 'max_steps'
          : 'completed';
      stopNote = stopReason == 'max_steps' ? '已达到本批最大步数。' : '队列已完成。';
    }
    queueRecord = ValueReaders.deepCopyMap(queueRecord)
      ..['status'] = _taskQueueStopPolicyService.statusForReason(stopReason)
      ..['completed_steps'] = stepsRun
      ..['stop_reason'] = stopReason
      ..['stop_note'] = stopNote
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _taskRepository.saveRecord(project, queuePath, queueRecord);
    await _taskRepository.writeTextFile(
      project,
      ValueReaders.stringValue(queueRecord['summary_path']),
      TaskQueueRecordRenderer().renderMarkdown(queueRecord),
    );

    if (longRunRecord.isNotEmpty) {
      final disposition = _finishDispositionService.finishDisposition(
        stopReason,
        stepsRun,
        options: <String, Object?>{
          ...cleanOptions,
          'mode': ValueReaders.stringValue(longRunRecord['mode']),
          'stop_note': stopNote,
        },
      );
      longRunRecord =
          ValueReaders.stringValue(disposition['record_action']) == 'pause'
          ? _lifecycleService.pauseRecord(
              longRunRecord,
              reason: ValueReaders.stringValue(disposition['reason']),
              note: ValueReaders.stringValue(disposition['note']),
            )
          : _lifecycleService.finishRecord(
              longRunRecord,
              reason: ValueReaders.stringValue(disposition['terminal_reason']),
              note: ValueReaders.stringValue(disposition['note']),
            );
      await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
        longRunRecord,
        await listWorkflowTasks(project),
        options: cleanOptions,
      );
      await _taskRepository.writeTextFile(
        project,
        ValueReaders.stringValue(longRunRecord['summary_path']),
        ValueReaders.stringValue(schedulerSnapshot['markdown']),
      );
    }

    return <String, Object?>{
      'ok': ValueReaders.boolValue(lastResult['ok'], true) || stepsRun == 0,
      'relative_path': queuePath,
      'summary_path': ValueReaders.stringValue(queueRecord['summary_path']),
      'stop_reason': stopReason,
      'stop_note': stopNote,
      'steps_run': stepsRun,
      'last_result': lastResult,
      'record': queueRecord,
      'long_task_run_path': longRunPath,
      'long_task_record': longRunRecord,
      'long_task_run_center_contract': longRunRecord.isEmpty
          ? const <String, Object?>{}
          : _runCenterContractFromSchedulerSnapshot(
              _buildLongTaskSchedulerSnapshotUseCase.execute(
                longRunRecord,
                await listWorkflowTasks(project),
                options: cleanOptions,
              ),
            ),
    };
  }

  Future<JsonMap> runWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 后处理提示明确“不要重写正文”，只推进摘要、记忆与检查产物。
    final provider = settings.defaultProvider();
    if (provider == null) {
      return <String, Object?>{
        'ok': false,
        'error': '未找到可用 provider。',
        'response': <String, Object?>{},
      };
    }
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'response': <String, Object?>{},
      };
    }
    final execution = await loadWorkflowTaskExecution(project, selector);
    if (execution.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '请先准备执行包并执行一次正文生成。',
        'response': <String, Object?>{},
      };
    }
    final draftPaths = ValueReaders.stringList(
      execution.containsKey('output_paths')
          ? execution['output_paths']
          : task['output_paths'],
    );
    final memorySections = await _modeGuidanceMemorySectionService.buildForTask(
      project,
      task,
    );
    final prompt = _postprocessPromptRenderer.renderPostprocessPrompt(
      _postprocessTransactionService.buildPostprocessTransaction(
        task,
        execution,
        draftPaths,
        options: <String, Object?>{
          'project_templates': await _templateMap(project),
          'memory_sections': memorySections,
          'creative_rule_stack': ValueReaders.mapValue(
            ValueReaders.mapValue(
              execution['context_pack'],
            )['creative_rule_stack'],
          ),
        },
      ),
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusRunning,
      note: '章节原子任务开始单步后处理。',
    );
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      agent: agent,
    );
    final useCase = _generateDraftUseCaseFactory(
      provider,
      settings.networkSettings,
    );
    final selectedCollaborationGroup =
        await _resolveSelectedCollaborationGroupForTask(
          project: project,
          task: task,
          agent: agent,
        );
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: ValueReaders.stringValue(
        executionProfile['resolved_model_id'],
        settings.defaultModelId.trim().isEmpty
            ? provider.modelId
            : settings.defaultModelId,
      ),
      title: ValueReaders.stringValue(task['title']),
      intent: 'workflow_postprocess',
      agent: agent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      requestOptions: ValueReaders.mapValue(
        executionProfile['request_options'],
      ),
      subAgentRuntimeSettings: settings,
      subAgentBindingModeId: ValueReaders.stringValue(task['mode']),
      subAgentBindingStageId: ValueReaders.stringValue(
        ValueReaders.mapValue(task['metadata'])['stage'],
        'draft',
      ),
    );
    final mergedOutputs = _mergePaths(
      ValueReaders.stringList(task['output_paths']),
      result.writtenPaths,
    );
    final savedPostprocess = await _postprocessResultService.saveResult(
      project: project,
      task: task,
      execution: execution,
      result: result,
      memorySections: memorySections,
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusWaitingUser,
      note: '后处理已返回，等待用户确认是否标记完成或继续修订。',
      extra: <String, Object?>{
        'output_paths': mergedOutputs,
        'postprocess_ran_at': DateTime.now().toIso8601String(),
        'postprocess_review_report_path': ValueReaders.stringValue(
          savedPostprocess['postprocess_review_report_path'],
        ),
        'postprocess_review_report_json_path': ValueReaders.stringValue(
          savedPostprocess['postprocess_review_report_json_path'],
        ),
        if (ValueReaders.boolValue(
          ValueReaders.mapValue(savedPostprocess['checkpoint_review'])['ok'],
        ))
          'postprocess_checkpoint_review_path': ValueReaders.stringValue(
            ValueReaders.mapValue(
              savedPostprocess['checkpoint_review'],
            )['relative_path'],
          ),
        if (ValueReaders.boolValue(
          ValueReaders.mapValue(savedPostprocess['checkpoint_review'])['ok'],
        ))
          'postprocess_checkpoint_review_summary': ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                savedPostprocess['checkpoint_review'],
              )['review'],
            )['summary'],
          ),
      },
    );
    return <String, Object?>{
      'ok': true,
      'response': _resultAsResponse(result),
      'output_paths': result.writtenPaths,
      'tool_names': _toolNamesFromExecutedTools(result.executedTools),
      'execution': ValueReaders.mapValue(savedPostprocess['execution']),
      'checkpoint_review': ValueReaders.mapValue(
        savedPostprocess['checkpoint_review'],
      ),
      'postprocess_review_report_path': ValueReaders.stringValue(
        savedPostprocess['postprocess_review_report_path'],
      ),
      'postprocess_review_report_json_path': ValueReaders.stringValue(
        savedPostprocess['postprocess_review_report_json_path'],
      ),
      'changed_paths': _mergePaths(
        result.changedPaths,
        ValueReaders.stringList(savedPostprocess['changed_paths']),
      ),
    };
  }

  Future<JsonMap> runNextWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 自动选择下一条等待后处理任务，并只跑一次后处理。
    final task = await nextWorkflowPostprocessTask(project);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前没有可后处理任务。',
        'response': <String, Object?>{},
      };
    }
    return runWorkflowTaskPostprocessOnce(project, settings, <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    }, agent: agent);
  }

  Future<JsonMap> completeWorkflowTaskAndRunNext(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 完成当前任务后立刻安全推进下一任务一个单步。
    final completion = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: '用户确认任务完成，并请求继续下一任务。',
    );
    if (!ValueReaders.boolValue(completion['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          completion['error'],
          'Task completion failed.',
        ),
        'completion': completion,
        'next_result': <String, Object?>{},
      };
    }
    final nextTask = await nextWorkflowTask(project);
    if (nextTask.isEmpty) {
      return <String, Object?>{
        'ok': true,
        'completion': completion,
        'next_result': <String, Object?>{},
        'stop_reason': 'no_runnable_task',
      };
    }
    final nextResult = await runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
      },
      agent: agent,
    );
    return <String, Object?>{
      'ok': ValueReaders.boolValue(nextResult['ok']),
      'error': ValueReaders.stringValue(nextResult['error']),
      'completion': completion,
      'next_task': nextTask,
      'next_result': nextResult,
    };
  }

  Future<JsonMap> buildRevisionResolution(
    ProjectDescriptor project,
    JsonMap selector,
  ) {
    // 中文注释: 修订收口动作合同从共享规则生成，供 GUI/CLI 后续直接消费。
    return _revisionResolutionService.buildResolution(
      project: project,
      selector: selector,
    );
  }

  Future<JsonMap> applyRevisionResolutionAction(
    ProjectDescriptor project,
    JsonMap selector,
    String command,
  ) {
    // 中文注释: 修订收口动作统一经过 adapter 服务，避免 UI/CLI 各自实现接受、返工、回滚细节。
    return _revisionResolutionService.applyAction(
      project: project,
      selector: selector,
      command: command,
    );
  }

  Future<JsonMap> acceptRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) {
    // 中文注释: 兼容旧入口，内部转发到新的修订收口动作层。
    return applyRevisionResolutionAction(project, selector, 'accept_revision');
  }

  Future<JsonMap> rollbackRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) {
    // 中文注释: 兼容旧入口，内部转发到新的修订收口动作层。
    return applyRevisionResolutionAction(
      project,
      selector,
      'rollback_revision',
    );
  }

  Future<JsonMap> transitionWorkflowTask(
    ProjectDescriptor project,
    JsonMap selector,
    String status, {
    String note = '',
    JsonMap extra = const <String, Object?>{},
  }) {
    // 中文注释: 手动暂停、恢复、重试、取消等动作统一走共享状态迁移入口。
    return _taskRepository.transitionTask(
      project,
      selector,
      status,
      note: note,
      extra: extra,
    );
  }

  Future<JsonMap> buildLongTaskRevisionPlan(
    ProjectDescriptor project,
    String command, {
    String runPath = '',
    JsonMap arguments = const <String, Object?>{},
  }) async {
    // 中文注释: 修订计划先输出补丁合同，真正落盘由 applyLongTaskRevisionPlan 处理。
    JsonMap record = const <String, Object?>{};
    if (runPath.trim().isNotEmpty) {
      record = await _taskRepository.loadRecord(project, runPath);
    } else {
      final recentRuns = await listLongTaskRuns(project, limit: 1);
      if (recentRuns.isNotEmpty) {
        record = recentRuns.first;
      }
    }
    return _buildLongTaskRevisionPlanUseCase.execute(
      record,
      await listWorkflowTasks(project),
      command,
      arguments: arguments,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<JsonMap> applyLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap revision,
  ) async {
    // 中文注释: 修订补丁应用阶段只负责真正把新任务与更新后的任务文件写回项目。
    final applied = _longTaskRevisionApplyService.applyRevisionPlan(
      await listWorkflowTasks(project),
      revision,
      createdAt: DateTime.now().toIso8601String(),
    );
    if (!ValueReaders.boolValue(applied['ok'])) {
      return applied;
    }
    final tasks = await _taskRepository.saveTasks(
      project,
      ValueReaders.objectList(applied['tasks']),
    );
    return <String, Object?>{
      'ok': true,
      'tasks': tasks,
      'changed_paths': ValueReaders.stringList(applied['changed_paths']),
      'changed_task_ids': ValueReaders.stringList(applied['changed_task_ids']),
    };
  }

  Future<JsonMap> _templateMap(ProjectDescriptor project) async {
    // 中文注释: 模板映射给任务提示和后处理提示复用，避免上层反复组装。
    final result = <String, Object?>{};
    final templates = await _promptTemplateService.listMergedTemplates(project);
    for (final template in templates) {
      final id = ValueReaders.stringValue(template['id']).trim();
      if (id.isNotEmpty) {
        result[id] = ValueReaders.stringValue(template['content']);
      }
    }
    return result;
  }

  String _constraintAppliesToForTask(JsonMap task) {
    return switch (ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim()) {
      'revision' => ConstraintBindingAppliesTo.repair,
      'review' => ConstraintBindingAppliesTo.review,
      _ => ConstraintBindingAppliesTo.writing,
    };
  }

  JsonMap _taskWithExecutionConstraintMetadata(
    JsonMap task,
    JsonMap executionConstraints,
  ) {
    final merged = ValueReaders.deepCopyMap(task);
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(task['metadata']),
    );
    final chapterLengthMetadata = ValueReaders.mapValue(
      executionConstraints['chapter_length_metadata'],
    );
    if (chapterLengthMetadata.isNotEmpty) {
      metadata.addAll(chapterLengthMetadata);
    }
    merged['metadata'] = metadata;
    return merged;
  }

  String _mergeSessionContexts(String left, String right) {
    final parts = <String>[];
    final cleanLeft = left.trim();
    final cleanRight = right.trim();
    if (cleanLeft.isNotEmpty) {
      parts.add(cleanLeft);
    }
    if (cleanRight.isNotEmpty) {
      parts.add(cleanRight);
    }
    return parts.join('\n\n');
  }

  JsonMap _resultAsResponse(DraftGenerationResult result) {
    // 中文注释: 任务运行结果折叠成旧 AppState 风格字典，方便 UI/CLI 沿用同一渲染口径。
    return <String, Object?>{
      'content': result.draftMarkdown,
      'tool_calls': result.executedTools,
      'waiting_for_user_choice': result.waitingForUserChoice,
      'selected_paths': result.selectedPaths,
      'context_pack_summary': ValueReaders.stringValue(
        result.contextPack['summary'],
      ),
      'prompt_preview_markdown': result.prompt,
    };
  }

  Future<JsonMap> _resolveSelectedCollaborationGroupForTask({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap agent,
  }) async {
    // 中文注释: workflow runtime 优先尊重项目已保存的组选择；旧单智能体项目则退化为单成员组合同。
    final loader = _loadProjectAgentGroupSelections;
    if (loader != null) {
      try {
        final selections = await loader(project);
        final preferred = _projectAgentGroupSelectionResolverService
            .resolvePreferredSelection(
              selections,
              modeId: ValueReaders.stringValue(task['mode']),
              stageId: ValueReaders.stringValue(
                ValueReaders.mapValue(task['metadata'])['stage'],
              ),
            );
        if (preferred != null) {
          return <String, Object?>{
            'id': preferred.groupId,
            'name': preferred.displayName.trim().isNotEmpty
                ? preferred.displayName.trim()
                : preferred.groupId,
            'source': 'project_group_selection',
            'enabled': preferred.enabled,
            'metadata': <String, Object?>{
              'selected_by_default': preferred.selectedByDefault,
              'mode_ids': preferred.modeIds,
              'stage_ids': preferred.stageIds,
              ...preferred.metadata,
            },
          };
        }
      } catch (_) {}
    }
    return _singleMemberCollaborationGroup(agent);
  }

  JsonMap _singleMemberCollaborationGroup(JsonMap agent) {
    final agentId = ValueReaders.stringValue(agent['id']).trim();
    if (agentId.isEmpty) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': 'single_agent_$agentId',
      'name': ValueReaders.stringValue(agent['name'], agentId),
      'description': '由当前 workflow 主智能体自动包装得到的单成员协作组。',
      'orchestration': 'main_with_children',
      'source': 'derived_single_agent_group',
      'enabled': true,
      'agents': <String>[agentId],
      'primary_agent_id': agentId,
      'metadata': <String, Object?>{
        'derived_from_single_agent': true,
        'agent_id': agentId,
      },
    };
  }

  JsonMap _appendQueueStep(
    JsonMap record,
    JsonMap task,
    JsonMap result, {
    required int index,
  }) {
    // 中文注释: 队列记录只保留审计摘要，不重复持久化大段正文和上下文包。
    final next = ValueReaders.deepCopyMap(record);
    final steps = ValueReaders.objectList(next['steps']);
    steps.add(<String, Object?>{
      'index': index,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title']),
      'task_relative_path': ValueReaders.stringValue(task['relative_path']),
      'task_status_after': ValueReaders.stringValue(task['status']),
      'ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'output_paths': ValueReaders.stringList(result['output_paths']),
      'activation_report_path': ValueReaders.stringValue(
        result['activation_report_path'],
      ),
      'activation_report_summary': ValueReaders.stringValue(
        result['activation_report_summary'],
      ),
      'chapter_delivery_state': ValueReaders.stringValue(
        result['chapter_delivery_state'],
      ),
      'chapter_delivery_path': ValueReaders.stringValue(
        result['chapter_delivery_path'],
      ),
      'created_at': DateTime.now().toIso8601String(),
    });
    next['steps'] = steps;
    next['completed_steps'] = steps.length;
    next['last_task_id'] = ValueReaders.stringValue(task['id']);
    next['last_task_relative_path'] = ValueReaders.stringValue(
      task['relative_path'],
    );
    next['last_activation_report_path'] = ValueReaders.stringValue(
      result['activation_report_path'],
    );
    next['last_chapter_delivery_state'] = ValueReaders.stringValue(
      result['chapter_delivery_state'],
    );
    next['last_chapter_delivery_path'] = ValueReaders.stringValue(
      result['chapter_delivery_path'],
    );
    next['updated_at'] = DateTime.now().toIso8601String();
    return next;
  }

  JsonMap _buildWritingExecutionResult({
    required JsonMap task,
    required JsonMap executionRecord,
    required JsonMap executionConstraints,
    required JsonMap checkpointReview,
    DraftGenerationResult? result,
    JsonMap deliveryOverride = const <String, Object?>{},
    JsonMap recoveryPlan = const <String, Object?>{},
    bool transportFailed = false,
  }) {
    final executionId = ValueReaders.stringValue(
      executionRecord['relative_path'],
      ValueReaders.stringValue(task['id']),
    ).trim();
    final review = ValueReaders.mapValue(checkpointReview['review']);
    return _writingExecutionResultNormalizerService
        .normalize(
          executionId: executionId.isEmpty
              ? 'workflow_task_${DateTime.now().microsecondsSinceEpoch}'
              : executionId,
          workflowKind: 'workflow_task',
          deliveryState: _chapterDeliveryStateResultFromMaps(
            executionRecord: executionRecord,
            deliveryOverride: deliveryOverride,
          ),
          constraintBridgeResult: executionConstraints.isEmpty
              ? null
              : WritingExecutionConstraintBridgeResult.fromJson(
                  executionConstraints,
                ),
          expressionConstraintReview:
              ExpressionConstraintReviewProjection.fromJson(
                ValueReaders.mapValue(review['expression_constraint_review']),
              ),
          activationReport: _activationReportFromExecution(executionRecord),
          informationSignal: _informationSignal(checkpointReview),
          collaborationResults: _collaborationResults(result),
          recoveryPlan: recoveryPlan,
          transportFailed: transportFailed,
          metadata: <String, Object?>{
            'task_id': ValueReaders.stringValue(task['id']),
            'task_type': ValueReaders.stringValue(task['task_type']),
            'checkpoint_review_path': ValueReaders.stringValue(
              checkpointReview['relative_path'],
            ),
          },
        )
        .toJson();
  }

  Future<JsonMap> _persistWritingExecutionResult(
    ProjectDescriptor project,
    String executionPath,
    JsonMap executionRecord,
    JsonMap writingExecutionResult,
  ) async {
    if (writingExecutionResult.isEmpty) {
      return executionRecord;
    }
    final next = ValueReaders.deepCopyMap(executionRecord)
      ..['writing_execution_result'] = writingExecutionResult;
    if (executionPath.trim().isNotEmpty && next.isNotEmpty) {
      await _taskRepository.saveRecord(project, executionPath, next);
    }
    return next;
  }

  ChapterDeliveryStateResult? _chapterDeliveryStateResultFromMaps({
    required JsonMap executionRecord,
    required JsonMap deliveryOverride,
  }) {
    final delivery = deliveryOverride.isNotEmpty
        ? deliveryOverride
        : ValueReaders.mapValue(executionRecord['chapter_delivery']);
    final stateResult = ValueReaders.mapValue(delivery['state_result']);
    final state = ValueReaders.stringValue(
      stateResult['state'],
      ValueReaders.stringValue(
        delivery['delivery_state'],
        ValueReaders.stringValue(executionRecord['chapter_delivery_state']),
      ),
    ).trim();
    if (state.isEmpty) {
      return null;
    }
    return ChapterDeliveryStateResult(
      deliveryId: ValueReaders.stringValue(
        stateResult['delivery_id'],
        ValueReaders.stringValue(delivery['delivery_id']),
      ),
      state: state,
      recommendedAction: ValueReaders.stringValue(
        stateResult['recommended_action'],
      ),
      suggestedOutcomeStatus: ValueReaders.stringValue(
        stateResult['suggested_outcome_status'],
      ),
      reason: ValueReaders.stringValue(stateResult['reason']),
      summary: ValueReaders.stringValue(stateResult['summary']),
      blocksProgress: ValueReaders.boolValue(stateResult['blocks_progress']),
      chapterBodyDelivered: ValueReaders.boolValue(
        stateResult['chapter_body_delivered'],
      ),
      submissionAccepted: ValueReaders.boolValue(
        stateResult['submission_accepted'],
      ),
      retryable: ValueReaders.boolValue(stateResult['retryable']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(stateResult['metadata']).isNotEmpty
            ? ValueReaders.mapValue(stateResult['metadata'])
            : <String, Object?>{
                'chapter_path': ValueReaders.stringValue(
                  delivery['chapter_path'],
                  ValueReaders.stringValue(
                    executionRecord['chapter_delivery_path'],
                  ),
                ),
              },
      ),
    );
  }

  ContextActivationReport? _activationReportFromExecution(
    JsonMap executionRecord,
  ) {
    final activationReport = ValueReaders.mapValue(
      executionRecord['activation_report'],
    );
    if (activationReport.isEmpty) {
      return null;
    }
    return ContextActivationReport.fromJson(activationReport);
  }

  JsonMap _informationSignal(JsonMap checkpointReview) {
    final review = ValueReaders.mapValue(checkpointReview['review']);
    final informationSignal = ValueReaders.mapValue(
      review['information_signal'],
    );
    if (informationSignal.isNotEmpty) {
      return informationSignal;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(review['narrative_supervisor_risk'])['information'],
    );
  }

  List<Object?> _collaborationResults(DraftGenerationResult? result) {
    if (result == null) {
      return const <Object?>[];
    }
    final collaborationResults = <Object?>[];
    for (final rawTool in result.executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'call_sub_agent') {
        continue;
      }
      final toolResult = ValueReaders.mapValue(tool['result']);
      if (toolResult.isNotEmpty) {
        collaborationResults.add(toolResult);
      }
    }
    return collaborationResults;
  }

  JsonMap _formalChapterRecoveryPlan({
    required JsonMap executionRecord,
    required String note,
  }) {
    final deliveryState = ValueReaders.stringValue(
      executionRecord['chapter_delivery_state'],
    ).trim();
    if (<String>{
      ChapterDeliveryStateStatuses.missingOutputRecoverable,
      ChapterDeliveryStateStatuses.pathMismatchRecoverable,
      ChapterDeliveryStateStatuses.deliveredNeedsRepair,
      ChapterDeliveryStateStatuses.waitingUserChoice,
      ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
      ChapterDeliveryStateStatuses.manualAttentionRequired,
      ChapterDeliveryStateStatuses.hardFailure,
    }.contains(deliveryState)) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'action': 'pause_for_repair',
      'reason': 'formal_chapter_recovery_required',
      'note': note,
    };
  }

  JsonMap _successRecoveryPlan({
    required String nextStatus,
    required JsonMap gateOutcome,
    required bool waitingForUserChoice,
  }) {
    if (ValueReaders.boolValue(gateOutcome['manual_attention_required'])) {
      return <String, Object?>{
        'action': 'pause_for_manual_attention',
        'reason': ValueReaders.stringValue(
          gateOutcome['gate_reason'],
          'chapter_gate_manual_attention',
        ),
        'note': '章级闸门要求人工复核后再继续。',
      };
    }
    if (waitingForUserChoice ||
        nextStatus == TaskRuntimeConstants.statusWaitingUser) {
      return <String, Object?>{
        'action': 'resume_when_user_confirms',
        'reason': waitingForUserChoice
            ? 'waiting_user_choice'
            : ValueReaders.stringValue(
                gateOutcome['gate_reason'],
                'gate_waiting_user',
              ),
        'note': waitingForUserChoice ? '当前步骤正在等待用户确认。' : '当前节点需要用户确认后再继续。',
      };
    }
    return const <String, Object?>{};
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    // 中文注释: 输出路径合并后保持先前顺序，避免后处理覆盖正文阶段的重要定位。
    final result = <String>[...left];
    for (final item in right) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  List<String> _toolNamesFromExecutedTools(List<Object?> executedTools) {
    // 中文注释: 紧凑工具名摘要供后处理结果页和 CLI 输出使用。
    final result = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isNotEmpty && !result.contains(name)) {
        result.add(name);
      }
    }
    return result;
  }

  JsonMap _runCenterContractFromSchedulerSnapshot(JsonMap schedulerSnapshot) {
    // 中文注释: 兼容旧/新 snapshot 结构，优先顶层，缺失时再回退到 scheduler_plan 内。
    final topLevel = ValueReaders.mapValue(
      schedulerSnapshot['run_center_contract'],
    );
    if (topLevel.isNotEmpty) {
      return topLevel;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(
        schedulerSnapshot['scheduler_plan'],
      )['run_center_contract'],
    );
  }

  Future<JsonMap> _saveRevisionDiffIfNeeded(
    ProjectDescriptor project,
    JsonMap task,
    List<Object?> executedTools,
  ) async {
    // 中文注释: 修复 diff 报告从本轮工具结果抽取 backup_path/relative_path 配对，保障可回滚链条。
    final pairs = <JsonMap>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      final backupPath = ValueReaders.stringValue(result['backup_path']).trim();
      final targetPath = ValueReaders.stringValue(
        result['relative_path'],
      ).trim();
      if (backupPath.isEmpty || targetPath.isEmpty) {
        continue;
      }
      pairs.add(
        _revisionDiffPreviewService.buildPair(
          targetPath: targetPath,
          backupPath: backupPath,
          beforeText:
              await _taskRepository.readTextFile(project, backupPath) ?? '',
          afterText:
              await _taskRepository.readTextFile(project, targetPath) ?? '',
        ),
      );
    }
    if (pairs.isEmpty) {
      return <String, Object?>{};
    }
    final safeId = _longTaskPathPolicyService.safeId(
      ValueReaders.stringValue(task['id']),
      fallbackPrefix: 'revision',
    );
    final jsonPath =
        'tracking/revision_diffs/$safeId.${DateTime.now().microsecondsSinceEpoch}.json';
    final markdownPath = jsonPath.replaceAll('.json', '.md');
    final report = <String, Object?>{
      'schema_version': 1,
      'kind': 'revision_diff',
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title']),
      'task_relative_path': ValueReaders.stringValue(task['relative_path']),
      'summary': _revisionDiffPreviewService.summaryText(pairs),
      'pairs': pairs,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _taskRepository.saveRecord(project, jsonPath, report);
    await _taskRepository.writeTextFile(
      project,
      markdownPath,
      _revisionDiffMarkdownRenderer.renderMarkdown(report),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': markdownPath,
      'json_path': jsonPath,
      'report': report,
      'changed_paths': <Object?>[jsonPath, markdownPath],
    };
  }

  static BuildLongTaskPlanUseCase _defaultBuildLongTaskPlanUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final taskFactoryService = LongTaskTaskFactoryService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    return BuildLongTaskPlanUseCase(
      taskFactoryService: taskFactoryService,
      planRecordService: LongTaskPlanRecordService(modeService: modeService),
      changedPathsService: LongTaskPlanChangedPathsService(),
      markdownRenderer: LongTaskPlanMarkdownRenderer(),
    );
  }

  static StartLongTaskRunUseCase _defaultStartLongTaskRunUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    return StartLongTaskRunUseCase(
      planIdentityService: LongTaskRunPlanIdentityService(
        modeService: modeService,
      ),
      runRecordService: LongTaskRunRecordService(
        modeService: modeService,
        strategyService: strategyService,
        optionService: LongTaskRunOptionService(),
        taskSummaryService: LongTaskTaskSummaryService(),
      ),
      runPathService: LongTaskRunPathService(
        pathPolicyService: pathPolicyService,
      ),
    );
  }

  static BuildLongTaskSchedulerSnapshotUseCase
  _defaultBuildLongTaskSchedulerSnapshotUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
    TaskDefinitionService taskDefinitionService,
  ) {
    final taskSelectionService = TaskSelectionService(
      taskDefinitionService: taskDefinitionService,
    );
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    final profileService = LongTaskControllerProfileService(
      modeService: modeService,
      strategyService: strategyService,
    );
    final unattendedStrategyService = LongTaskUnattendedStrategyService(
      modeService: modeService,
      strategyService: strategyService,
      profileService: profileService,
    );
    final taskSummaryService = LongTaskTaskSummaryService();
    final nextBatchPlanService = LongTaskNextBatchPlanService(
      modeService: modeService,
      profileService: profileService,
      unattendedStrategyService: unattendedStrategyService,
      taskSummaryService: taskSummaryService,
      taskSelectionService: taskSelectionService,
    );
    final runCenterContractService = LongTaskRunCenterContractService(
      nextBatchPlanService: nextBatchPlanService,
      taskSummaryService: taskSummaryService,
    );
    final schedulerTickPlanService = LongTaskSchedulerTickPlanService(
      modeService: modeService,
      recoveryService: LongTaskRecoveryService(),
      nextBatchPlanService: nextBatchPlanService,
      runCenterContractService: runCenterContractService,
    );
    return BuildLongTaskSchedulerSnapshotUseCase(
      schedulerTickPlanService: schedulerTickPlanService,
      batchOptionService: LongTaskBatchOptionService(),
      schedulerMarkdownRenderer: LongTaskSchedulerMarkdownRenderer(),
    );
  }

  static BuildLongTaskPromptUseCase _defaultBuildLongTaskPromptUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    final contextService = LongTaskTransactionContextService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    final contractService = LongTaskTransactionContractService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    return BuildLongTaskPromptUseCase(
      transactionService: LongTaskTaskTransactionService(
        modeService: modeService,
        strategyService: strategyService,
        contextService: contextService,
        contractService: contractService,
      ),
      promptRenderer: LongTaskTaskPromptRenderer(
        contractService: contractService,
      ),
    );
  }

  static LongTaskPostprocessTransactionService
  _defaultPostprocessTransactionService(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return LongTaskPostprocessTransactionService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
      contextService: LongTaskTransactionContextService(
        modeService: modeService,
        pathPolicyService: pathPolicyService,
      ),
    );
  }

  static LongTaskPostprocessPromptRenderer _defaultPostprocessPromptRenderer(
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return LongTaskPostprocessPromptRenderer(
      contractService: LongTaskTransactionContractService(
        modeService: LongTaskModeService(),
        pathPolicyService: pathPolicyService,
      ),
    );
  }

  static LongTaskFinishDispositionService _defaultFinishDispositionService(
    LongTaskModeService modeService,
  ) {
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    return LongTaskFinishDispositionService(
      profileService: LongTaskControllerProfileService(
        modeService: modeService,
        strategyService: strategyService,
      ),
    );
  }

  static PrepareChapterAtomicExecutionUseCase
  _defaultPrepareExecutionUseCase() {
    return PrepareChapterAtomicExecutionUseCase(
      executionBuilderService: ChapterAtomicExecutionBuilderService(
        promptBuilderService: ChapterAtomicPromptBuilderService(
          taskDefinitionService: TaskDefinitionService(),
        ),
        intentService: ChapterAtomicIntentService(),
        outputPathService: ChapterAtomicOutputPathService(),
        stepStateService: ChapterAtomicStepStateService(),
        eventService: ChapterAtomicEventService(),
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        executionPlanService: TaskExecutionPlanService(
          taskDefinitionService: TaskDefinitionService(),
        ),
      ),
    );
  }

  Future<JsonMap> _readPlannedProjectFileContents(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    // 中文注释: 执行包准备只预读计划片段中明确点名的文件，避免又退回整仓扫读。
    final plan = _longTaskProjectFileSectionPlanService.build(task);
    final contents = <String, Object?>{};
    for (final section in plan) {
      for (final path in ValueReaders.stringList(section['paths'])) {
        if (contents.containsKey(path)) {
          continue;
        }
        final content = await _taskRepository.readTextFile(project, path);
        if (content != null && content.trim().isNotEmpty) {
          contents[path] = content;
        }
      }
    }
    return contents;
  }

  static BuildLongTaskRevisionPlanUseCase
  _defaultBuildLongTaskRevisionPlanUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return BuildLongTaskRevisionPlanUseCase(
      revisionPlanService: LongTaskRevisionPlanService(
        dynamicTaskFactoryService: LongTaskDynamicTaskFactoryService(
          modeService: modeService,
          pathPolicyService: pathPolicyService,
        ),
      ),
    );
  }
}
