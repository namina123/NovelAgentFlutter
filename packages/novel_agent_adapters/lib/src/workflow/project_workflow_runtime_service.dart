import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../config/project_information_permission_settings_resolver_service.dart';
import '../config/project_tool_permission_settings_resolver_service.dart';
import '../runtime/long_task_supervisor.dart';
import '../runtime/project_long_task_run_registry_sync_service.dart';
import '../runtime/project_tool_permission_approval_record_service.dart';
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
import 'project_long_task_execution_constraint_repair_task_service.dart';
import 'project_long_task_postprocess_result_service.dart';
import 'project_long_task_revision_resolution_service.dart';
import 'project_long_task_review_repair_task_service.dart';
import 'project_mode_guidance_memory_section_service.dart';
import 'project_task_queue_runtime_option_resolver.dart';
import 'project_workflow_queue_runtime_service.dart';
import 'project_writing_execution_contract_service.dart';
import 'project_workflow_runtime_bridge_service.dart';
import 'project_workflow_review_runtime_service.dart';
import 'project_workflow_reviewer_dispatch_service.dart';
import 'project_workflow_task_selection_service.dart';
import 'task_center_runtime_query_port.dart';
import 'workflow_runtime_satisfied_output_path_service.dart';
import 'workflow_runtime_task_semantics_service.dart';

typedef WorkflowGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef WorkflowHostAwareGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings, {
      HostInformationPermissionContext? hostInformationPermissionContext,
      HostToolPermissionContext? hostToolPermissionContext,
    });
typedef LoadWorkflowProjectAgentGroupSelections =
    Future<List<ProjectAgentGroupSelection>> Function(
      ProjectDescriptor project,
    );
typedef LoadWorkflowAvailableAgents =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadWorkflowAvailableAgentGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);

class ProjectWorkflowRuntimeService implements TaskCenterRuntimeQueryPort {
  ProjectWorkflowRuntimeService({
    required ProjectTaskRepository taskRepository,
    required ProjectPromptTemplateService promptTemplateService,
    required WorkflowGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    WorkflowHostAwareGenerateDraftUseCaseFactory?
    hostAwareGenerateDraftUseCaseFactory,
    LoadWorkflowProjectAgentGroupSelections? loadProjectAgentGroupSelections,
    LoadWorkflowAvailableAgents? loadAvailableAgents,
    LoadWorkflowAvailableAgentGroups? loadAvailableAgentGroups,
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
    ProjectLongTaskExecutionConstraintRepairTaskService?
    executionConstraintRepairTaskService,
    ProjectLongTaskRevisionResolutionService? revisionResolutionService,
    ProjectLongTaskChapterGateService? chapterGateService,
    ProjectWorkflowQueueRuntimeService? workflowQueueRuntimeService,
    ProjectTaskQueueRuntimeOptionResolver? taskQueueRuntimeOptionResolver,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    ProjectWorkflowRuntimeBridgeService? workflowRuntimeBridgeService,
    ProjectWorkflowReviewRuntimeService? workflowReviewRuntimeService,
    WritingExecutionResultNormalizerService?
    writingExecutionResultNormalizerService,
    ProjectWritingExecutionContractService? writingExecutionContractService,
    WorkflowRuntimeTaskSemanticsService? workflowRuntimeTaskSemanticsService,
    WorkflowRuntimeSatisfiedOutputPathService?
    workflowRuntimeSatisfiedOutputPathService,
    ProjectInformationPermissionSettingsResolverService?
    informationPermissionSettingsResolverService,
    ProjectToolPermissionSettingsResolverService?
    toolPermissionSettingsResolverService,
    ProjectToolPermissionApprovalRecordService?
    toolPermissionApprovalRecordService,
    LongTaskSupervisor? longTaskSupervisor,
    ProjectLongTaskRunRegistrySyncService? longTaskRunRegistrySyncService,
  }) : _taskRepository = taskRepository,
       _promptTemplateService = promptTemplateService,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _hostAwareGenerateDraftUseCaseFactory =
           hostAwareGenerateDraftUseCaseFactory,
       _loadProjectAgentGroupSelections = loadProjectAgentGroupSelections,
       _loadAvailableAgents = loadAvailableAgents,
       _loadAvailableAgentGroups = loadAvailableAgentGroups,
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService(),
       _taskSelectionService =
           taskSelectionService ??
           TaskSelectionService(
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _workflowTaskSelectionService = ProjectWorkflowTaskSelectionService(
         taskSelectionService:
             taskSelectionService ??
             TaskSelectionService(
               taskDefinitionService:
                   taskDefinitionService ?? TaskDefinitionService(),
             ),
         longTaskPathPolicyService:
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
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
             longTaskSupervisor: longTaskSupervisor,
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
       _executionConstraintRepairTaskService =
           executionConstraintRepairTaskService ??
           ProjectLongTaskExecutionConstraintRepairTaskService(
             taskRepository: taskRepository,
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
       _reviewerDispatchService = ProjectWorkflowReviewerDispatchService(),
       _workflowRuntimeTaskSemanticsService =
           workflowRuntimeTaskSemanticsService ??
           WorkflowRuntimeTaskSemanticsService(),
       _workflowRuntimeSatisfiedOutputPathService =
           workflowRuntimeSatisfiedOutputPathService ??
           WorkflowRuntimeSatisfiedOutputPathService(
             taskRepository: taskRepository,
           ),
       _projectAgentGroupSelectionResolverService =
           const ProjectAgentGroupSelectionResolverService(),
       _writingExecutionResultNormalizerService =
           writingExecutionResultNormalizerService ??
           WritingExecutionResultNormalizerService(),
       _writingExecutionContractService =
           writingExecutionContractService ??
           const ProjectWritingExecutionContractService(),
       _informationPermissionSettingsResolverService =
           informationPermissionSettingsResolverService ??
           const ProjectInformationPermissionSettingsResolverService(),
       _toolPermissionSettingsResolverService =
           toolPermissionSettingsResolverService ??
           const ProjectToolPermissionSettingsResolverService(),
       _toolPermissionApprovalRecordService =
           toolPermissionApprovalRecordService ??
           ProjectToolPermissionApprovalRecordService(
             taskRepository: taskRepository,
           ),
       _longTaskRunRegistrySyncService =
           longTaskRunRegistrySyncService ??
           (longTaskSupervisor == null
               ? null
               : ProjectLongTaskRunRegistrySyncService(
                   supervisor: longTaskSupervisor,
                   taskRepository: taskRepository,
                 )) {
    _workflowQueueRuntimeService =
        workflowQueueRuntimeService ??
        ProjectWorkflowQueueRuntimeService(
          taskRepository: taskRepository,
          taskDefinitionService:
              taskDefinitionService ?? TaskDefinitionService(),
          taskSelectionService:
              taskSelectionService ??
              TaskSelectionService(
                taskDefinitionService:
                    taskDefinitionService ?? TaskDefinitionService(),
              ),
          workflowTaskSelectionService: ProjectWorkflowTaskSelectionService(
            taskSelectionService:
                taskSelectionService ??
                TaskSelectionService(
                  taskDefinitionService:
                      taskDefinitionService ?? TaskDefinitionService(),
                ),
            longTaskPathPolicyService:
                longTaskPathPolicyService ?? LongTaskPathPolicyService(),
          ),
          chapterQueueRuntimeService:
              chapterQueueRuntimeService ??
              ProjectLongTaskChapterQueueRuntimeService(
                taskRepository: taskRepository,
              ),
          longTaskModeService: longTaskModeService ?? LongTaskModeService(),
          longTaskPathPolicyService:
              longTaskPathPolicyService ?? LongTaskPathPolicyService(),
          buildLongTaskPlanUseCase:
              buildLongTaskPlanUseCase ??
              _defaultBuildLongTaskPlanUseCase(
                longTaskModeService ?? LongTaskModeService(),
                longTaskPathPolicyService ?? LongTaskPathPolicyService(),
              ),
          longTaskRunPathService:
              longTaskRunPathService ??
              LongTaskRunPathService(
                pathPolicyService:
                    longTaskPathPolicyService ?? LongTaskPathPolicyService(),
              ),
          buildLongTaskSchedulerSnapshotUseCase:
              buildLongTaskSchedulerSnapshotUseCase ??
              _defaultBuildLongTaskSchedulerSnapshotUseCase(
                longTaskModeService ?? LongTaskModeService(),
                longTaskPathPolicyService ?? LongTaskPathPolicyService(),
                taskDefinitionService ?? TaskDefinitionService(),
              ),
          lifecycleService: lifecycleService ?? LongTaskRunLifecycleService(),
          startLongTaskRunUseCase:
              startLongTaskRunUseCase ??
              _defaultStartLongTaskRunUseCase(
                longTaskModeService ?? LongTaskModeService(),
                longTaskPathPolicyService ?? LongTaskPathPolicyService(),
              ),
          taskQueueOptionService:
              taskQueueOptionService ?? TaskQueueOptionService(),
          taskQueueStopPolicyService:
              taskQueueStopPolicyService ??
              TaskQueueStopPolicyService(
                optionService:
                    taskQueueOptionService ?? TaskQueueOptionService(),
              ),
          taskQueueRuntimeOptionResolver:
              taskQueueRuntimeOptionResolver ??
              ProjectTaskQueueRuntimeOptionResolver(
                runtimeProfileRepository: ProjectRuntimeProfileRepository(
                  workspacePort: taskRepository.workspacePort,
                ),
              ),
          finishDispositionService:
              finishDispositionService ??
              _defaultFinishDispositionService(
                longTaskModeService ?? LongTaskModeService(),
              ),
          longTaskRunStepRecorderService:
              longTaskRunStepRecorderService ??
              LongTaskRunStepRecorderService(
                taskSummaryService: LongTaskTaskSummaryService(),
              ),
          checkpointActionService:
              checkpointActionService ??
              ProjectLongTaskCheckpointActionService(
                taskRepository: taskRepository,
                longTaskSupervisor: longTaskSupervisor,
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
          longTaskRunRegistrySyncService: _longTaskRunRegistrySyncService,
        );
    _workflowQueueRuntimeService.bindWorkflowTaskOnceRunner(
      runWorkflowTaskOnce,
    );
  }

  final ProjectTaskRepository _taskRepository;
  final ProjectPromptTemplateService _promptTemplateService;
  final WorkflowGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final WorkflowHostAwareGenerateDraftUseCaseFactory?
  _hostAwareGenerateDraftUseCaseFactory;
  final LoadWorkflowProjectAgentGroupSelections?
  _loadProjectAgentGroupSelections;
  final LoadWorkflowAvailableAgents? _loadAvailableAgents;
  final LoadWorkflowAvailableAgentGroups? _loadAvailableAgentGroups;
  final TaskDefinitionService _taskDefinitionService;
  final TaskSelectionService _taskSelectionService;
  final ProjectWorkflowTaskSelectionService _workflowTaskSelectionService;
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
  late final ProjectWorkflowQueueRuntimeService _workflowQueueRuntimeService;
  final ProjectLongTaskReviewRepairTaskService _reviewRepairTaskService;
  final ProjectLongTaskExecutionConstraintRepairTaskService
  _executionConstraintRepairTaskService;
  final ProjectLongTaskChapterGateService _chapterGateService;
  final ProjectTaskQueueRuntimeOptionResolver _taskQueueRuntimeOptionResolver;
  final ProjectDraftExecutionConstraintRuntimeService
  _draftExecutionConstraintRuntimeService;
  final ProjectLongTaskRevisionResolutionService _revisionResolutionService;
  final ProjectWorkflowRuntimeBridgeService _workflowRuntimeBridgeService;
  final ProjectWorkflowReviewRuntimeService _workflowReviewRuntimeService;
  final ProjectWorkflowReviewerDispatchService _reviewerDispatchService;
  final WorkflowRuntimeTaskSemanticsService
  _workflowRuntimeTaskSemanticsService;
  final WorkflowRuntimeSatisfiedOutputPathService
  _workflowRuntimeSatisfiedOutputPathService;
  final ProjectAgentGroupSelectionResolverService
  _projectAgentGroupSelectionResolverService;
  final WritingExecutionResultNormalizerService
  _writingExecutionResultNormalizerService;
  final ProjectWritingExecutionContractService _writingExecutionContractService;
  final ProjectInformationPermissionSettingsResolverService
  _informationPermissionSettingsResolverService;
  final ProjectToolPermissionSettingsResolverService
  _toolPermissionSettingsResolverService;
  final ProjectToolPermissionApprovalRecordService
  _toolPermissionApprovalRecordService;
  final ProjectLongTaskRunRegistrySyncService? _longTaskRunRegistrySyncService;

  List<JsonMap> listTaskRuntimeModes() {
    // 中文注释: 模式定义直接来自 core，确保任务中心和 CLI 的枚举完全同源。
    return _taskDefinitionService.modeDefinitions();
  }

  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.createLongTaskWorkflow(
      project,
      mode,
      options: options,
    );
  }

  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.listWorkflowTasks(
      project,
      filters: filters,
    );
  }

  Future<List<JsonMap>> _currentWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
  }

  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.nextWorkflowTask(
      project,
      filters: filters,
    );
  }

  Future<JsonMap> nextWorkflowPostprocessTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一后处理任务与普通 runnable 分离选择，保持旧项目语义。
    final tasks = _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
    return _taskSelectionService.nextPostprocessTaskFromTasks(tasks);
  }

  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 链路视图按 plan 分组并保留依赖/检查点信息，供 GUI/CLI 共用同一份恢复快照。
    final tasks = _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
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
      await _currentWorkflowTasks(project),
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
    // 中文注释: 该入口把已有检查点复盘物化成正式审稿门，供 GUI/CLI 与 runtime 共用同一条接线。
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
    String expressionConstraintPolicyMode = '',
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
    final runtimeTask = _workflowRuntimeTaskSemanticsService.taskForRuntime(
      task,
    );
    final recentExpressionConstraintSummaries =
        await _recentExpressionConstraintSummariesForTask(project, task);
    final selectedCollaborationGroup =
        await _resolveSelectedCollaborationGroupForTask(
          project: project,
          task: task,
          agent: agent,
        );
    final executionConstraints = await _draftExecutionConstraintRuntimeService
        .resolve(
          project,
          appliesTo: _constraintAppliesToForTask(runtimeTask),
          agentId: ValueReaders.stringValue(agent['id']),
          modeId: ValueReaders.stringValue(runtimeTask['mode']),
          stageId: ValueReaders.stringValue(
            ValueReaders.mapValue(runtimeTask['metadata'])['stage'],
            'draft',
          ),
          intent: 'workflow_task',
          taskType: ValueReaders.stringValue(runtimeTask['task_type']),
          expressionConstraintPolicyMode: expressionConstraintPolicyMode,
          legacyChapterLengthOptions: ValueReaders.mapValue(
            runtimeTask['metadata'],
          ),
          recentExpressionConstraintSummaries:
              recentExpressionConstraintSummaries,
        );
    final effectiveTask = _taskWithExecutionConstraintMetadata(
      runtimeTask,
      executionConstraints,
    );
    final workflowBridge = await _workflowRuntimeBridgeService.buildTaskBridge(
      project,
      runtimeTask,
      selectedCollaborationGroup: selectedCollaborationGroup,
    );
    final projectFileContents = await _readPlannedProjectFileContents(
      project,
      task,
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      _taskWithResumeDispatchPromptAppendix(
        _taskWithSelectedUserChoiceContext(effectiveTask),
      ),
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
        runtimeTask,
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
    final execution = _workflowRuntimeBridgeService.attachPreparationArtifacts(
      ValueReaders.mapValue(result['execution'])
        ..['prompt_preview_markdown'] = prompt,
      workflowBridge,
      activationReportPath: activationReportPath,
    )..['effective_task'] = ValueReaders.deepCopyMap(effectiveTask);
    final persistedExecution = _attachExecutionConstraintArtifacts(
      execution,
      executionConstraints,
    );
    final executionPath = ValueReaders.stringValue(result['execution_path']);
    final checklistPath = ValueReaders.stringValue(result['checklist_path']);
    await _taskRepository.saveRecord(
      project,
      activationReportPath,
      ValueReaders.mapValue(workflowBridge['activation_report']),
    );
    await _taskRepository.saveRecord(
      project,
      executionPath,
      persistedExecution,
    );
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
      'execution': persistedExecution,
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
    JsonMap options = const <String, Object?>{},
    DraftGenerationCancellationToken? cancellationToken,
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
    var runtimeTask = _workflowRuntimeTaskSemanticsService.taskForRuntime(task);
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
        task: runtimeTask,
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
        expressionConstraintPolicyMode:
            _expressionConstraintPolicyModeFromOptions(options),
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
      runtimeTask = _workflowRuntimeTaskSemanticsService.taskForRuntime(task);
    }
    final selectedCollaborationGroup =
        await _resolveSelectedCollaborationGroupForTask(
          project: project,
          task: task,
          agent: agent,
        );
    final memorySections = await _modeGuidanceMemorySectionService.buildForTask(
      project,
      task,
    );
    final recentExpressionConstraintSummaries =
        await _recentExpressionConstraintSummariesForTask(project, task);
    final executionConstraints = await _draftExecutionConstraintRuntimeService
        .resolve(
          project,
          appliesTo: _constraintAppliesToForTask(runtimeTask),
          agentId: ValueReaders.stringValue(agent['id']),
          modeId: ValueReaders.stringValue(runtimeTask['mode']),
          stageId: ValueReaders.stringValue(
            ValueReaders.mapValue(runtimeTask['metadata'])['stage'],
            'draft',
          ),
          intent: 'workflow_task',
          taskType: ValueReaders.stringValue(runtimeTask['task_type']),
          expressionConstraintPolicyMode:
              _expressionConstraintPolicyModeFromOptions(options),
          legacyChapterLengthOptions: ValueReaders.mapValue(
            runtimeTask['metadata'],
          ),
          recentExpressionConstraintSummaries:
              recentExpressionConstraintSummaries,
        );
    final effectiveTask = _taskWithExecutionConstraintMetadata(
      runtimeTask,
      executionConstraints,
    );
    final workflowBridge = await _workflowRuntimeBridgeService.buildTaskBridge(
      project,
      runtimeTask,
      selectedCollaborationGroup: selectedCollaborationGroup,
    );
    final projectFileSectionPlan = _longTaskProjectFileSectionPlanService.build(
      runtimeTask,
    );
    final projectFileContents = await _readPlannedProjectFileContents(
      project,
      task,
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      _taskWithResumeDispatchPromptAppendix(
        _taskWithSelectedUserChoiceContext(effectiveTask),
      ),
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
      extra: <String, Object?>{
        'postprocess_ran_at': '',
        'postprocess_review_report_path': '',
        'postprocess_review_report_json_path': '',
        'postprocess_checkpoint_review_path': '',
        'postprocess_checkpoint_review_summary': '',
        'selected_user_option_prompt': '',
        'selected_user_option_label': '',
        'selected_user_option_description': '',
        'selected_user_option_question': '',
      },
    );
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      agent: agent,
    );
    final taskHostToolPermissionContext =
        await _consumeWorkflowTaskToolPermissionOverride(
          project: project,
          task: runtimeTask,
        );
    final useCase = _workflowGenerateDraftUseCase(
      provider: provider,
      settings: settings,
      hostToolPermissionContextOverride: taskHostToolPermissionContext,
    );
    final reviewerDispatch = await _resolveReviewerDispatchForTask(
      project: project,
      task: task,
      agent: agent,
      selectedCollaborationGroup: selectedCollaborationGroup,
    );
    final resolvedModelId = ValueReaders.stringValue(
      executionProfile['resolved_model_id'],
      settings.defaultModelId.trim().isEmpty
          ? provider.modelId
          : settings.defaultModelId,
    );
    final requestOptions = ValueReaders.mapValue(
      executionProfile['request_options'],
    );
    final modelProfile = <String, Object?>{
      'id': provider.id,
      'base_url': provider.baseUrl,
      'model_id': provider.modelId,
    };
    final skillRoutingContext = <String, Object?>{
      'task_type': ValueReaders.stringValue(runtimeTask['task_type']),
      'mode': ValueReaders.stringValue(runtimeTask['mode']),
      'title': ValueReaders.stringValue(runtimeTask['title']),
      'goal': ValueReaders.stringValue(runtimeTask['goal']),
      'brief': ValueReaders.stringValue(runtimeTask['brief']),
      'review_type': ValueReaders.stringValue(
        ValueReaders.mapValue(runtimeTask['metadata'])['review_type'],
      ),
      'workflow_task_context': <String, Object?>{
        'id': ValueReaders.stringValue(runtimeTask['id']),
        'title': ValueReaders.stringValue(runtimeTask['title']),
        'task_type': ValueReaders.stringValue(runtimeTask['task_type']),
        'mode': ValueReaders.stringValue(runtimeTask['mode']),
        'workflow_mode': ValueReaders.stringValue(runtimeTask['mode']),
        'relative_path': ValueReaders.stringValue(runtimeTask['relative_path']),
        'metadata': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(runtimeTask['metadata']),
        ),
      },
    };
    final sessionContext = _mergeSessionContexts(
      ValueReaders.stringValue(workflowBridge['activation_context_markdown']),
      ValueReaders.stringValue(
        executionConstraints['session_context_markdown'],
      ),
    );
    DraftGenerationResult result;
    try {
      result = ValueReaders.boolValue(reviewerDispatch['should_delegate'])
          ? await useCase.executeDelegatedSubAgentTask(
              project: project,
              userPrompt: prompt,
              modelId: resolvedModelId,
              childAgentId: ValueReaders.stringValue(
                reviewerDispatch['agent_id'],
              ),
              childTask: _delegatedReviewerTask(task),
              title: ValueReaders.stringValue(runtimeTask['title']),
              intent: 'workflow_task',
              parentAgent: agent,
              selectedCollaborationGroup: selectedCollaborationGroup,
              requestOptions: requestOptions,
              contextSettings: settings.contextSettings,
              modelProfile: modelProfile,
              skillRoutingContext: skillRoutingContext,
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
              subAgentBindingModeId: ValueReaders.stringValue(
                runtimeTask['mode'],
              ),
              subAgentBindingStageId: ValueReaders.stringValue(
                ValueReaders.mapValue(runtimeTask['metadata'])['stage'],
                'draft',
              ),
              sessionContext: sessionContext,
              sourcePaths: ValueReaders.stringList(runtimeTask['source_paths']),
              constraints: _delegatedReviewerConstraints(task),
              expectedOutput:
                  '返回可合并的审稿结论；形成正式结论时优先使用 submit_semantic_review 提交结构化结果。',
            )
          : await useCase.execute(
              project: project,
              userPrompt: prompt,
              modelId: resolvedModelId,
              title: ValueReaders.stringValue(runtimeTask['title']),
              intent: 'workflow_task',
              agent: agent,
              selectedCollaborationGroup: selectedCollaborationGroup,
              requestOptions: requestOptions,
              contextSettings: settings.contextSettings,
              modelProfile: modelProfile,
              skillRoutingContext: skillRoutingContext,
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
              subAgentBindingModeId: ValueReaders.stringValue(
                runtimeTask['mode'],
              ),
              subAgentBindingStageId: ValueReaders.stringValue(
                ValueReaders.mapValue(runtimeTask['metadata'])['stage'],
                'draft',
              ),
              sessionContext: sessionContext,
              exposedToolIds: ValueReaders.stringList(
                workflowBridge['workflow_tool_ids'],
              ),
              cancellationToken: cancellationToken,
            );
      final persistedApprovals = await _toolPermissionApprovalRecordService
          .persistPendingApprovalsForExecutedTools(
            project,
            scopeType: ProjectToolPermissionApprovalScopes.workflowTask,
            executedTools: result.executedTools,
            taskPath: ValueReaders.stringValue(runtimeTask['relative_path']),
            executionPath: ValueReaders.stringValue(
              runtimeTask['atomic_execution_path'],
            ),
          );
      result = _resultWithExecutedTools(
        result,
        executedTools: ValueReaders.objectList(
          persistedApprovals['executed_tools'],
        ),
      );
    } catch (error) {
      if (!_isRetryableWorkflowTaskTransportFailure(error)) {
        rethrow;
      }
      return _handleRetryableWorkflowTaskTransportFailure(
        project: project,
        selector: selector,
        task: task,
        runtimeTask: runtimeTask,
        executionConstraints: executionConstraints,
        options: options,
        error: error,
      );
    }
    if (cancellationToken?.isCancellationRequested == true) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusQueued,
        note: '当前批次已达到最长时间限制，已取消本步，等待后续继续。',
      );
      return <String, Object?>{
        'ok': false,
        'error': '当前任务执行超过本批最长时间限制。',
        'timeout': true,
        'response': _resultAsResponse(result),
        'waiting_for_user_choice': false,
        'output_paths': result.writtenPaths,
        'changed_paths': result.changedPaths,
        'executed_tools': result.executedTools,
      };
    }
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
    var workflowChangedPaths = _mergePaths(
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
        nextExecution['response'] = _resultAsResponse(result);
        nextExecution['executed_tools'] = ValueReaders.deepCopyList(
          result.executedTools,
        );
        nextExecution['pending_user_options'] = ValueReaders.deepCopyList(
          _pendingUserOptionsFromExecutedTools(result.executedTools),
        );
        if (ValueReaders.boolValue(reviewerDispatch['applicable'])) {
          nextExecution['reviewer_dispatch'] = ValueReaders.deepCopyMap(
            reviewerDispatch,
          );
        }
        nextExecution = _workflowReviewRuntimeService.attachReviewArtifacts(
          nextExecution,
          semanticReviewArtifacts,
        );
        nextExecution = _attachExecutionConstraintArtifacts(
          nextExecution,
          executionConstraints,
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
    final planningBoundaryDecision = await _planningTaskBoundaryDecision(
      project: project,
      task: task,
      result: result,
      outputPaths: outputPaths,
      executionRecord: executionRecord,
    );
    if (ValueReaders.stringValue(planningBoundaryDecision['action']) ==
        'retry') {
      final note = ValueReaders.stringValue(
        planningBoundaryDecision['note'],
        '自治规划尚未形成最小规划产物，已安排重试。',
      );
      final retryBudget = _directRecoveryRetryBudget(
        task: task,
        options: options,
      );
      final retryCount = ValueReaders.intValue(task['recovery_retry_count']);
      final canRetry = retryCount < retryBudget;
      final nextRetryCount = canRetry ? retryCount + 1 : retryCount;
      final recoveryPlan = canRetry
          ? <String, Object?>{
              'action': 'resume_dispatch',
              'reason': 'autonomous_planning_retry_scheduled',
              'note': note,
              'safe_after_crash': true,
              'status': 'retrying',
            }
          : <String, Object?>{
              'action': 'pause_for_failure',
              'reason': 'autonomous_planning_retry_budget_exhausted',
              'note': note,
            };
      final writingExecutionResult = _buildWritingExecutionResult(
        task: runtimeTask,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: const <String, Object?>{},
        result: result,
        recoveryPlan: recoveryPlan,
      );
      final persistedFailureExtra = <String, Object?>{
        'output_paths': outputPaths,
        'last_writing_execution_result': writingExecutionResult,
        'recovery_retry_count': retryCount,
        'recovery_retry_budget': retryBudget,
      };
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: note,
        extra: persistedFailureExtra,
      );
      if (canRetry) {
        await _taskRepository.transitionTask(
          project,
          selector,
          TaskRuntimeConstants.statusRetrying,
          note: '自治规划未完整落盘，已自动安排重试继续补齐规划产物。',
          extra: <String, Object?>{
            ...persistedFailureExtra,
            'recovery_retry_count': nextRetryCount,
          },
        );
      }
      executionRecord = await _persistWritingExecutionResult(
        project,
        executionPath,
        executionRecord,
        writingExecutionResult,
      );
      return <String, Object?>{
        'ok': canRetry,
        if (!canRetry) 'error': note,
        'response': <String, Object?>{
          ..._resultAsResponse(result),
          'waiting_for_user_choice': false,
        },
        'waiting_for_user_choice': false,
        'retry_scheduled': canRetry,
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
        'checkpoint_review': const <String, Object?>{},
        'gate_outcome': const <String, Object?>{},
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': workflowChangedPaths,
      };
    }
    if (ValueReaders.stringValue(planningBoundaryDecision['action']) ==
        'fail') {
      final error = ValueReaders.stringValue(
        planningBoundaryDecision['error'],
        'Planning task crossed into chapter delivery.',
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: const <String, Object?>{},
        result: result,
        recoveryPlan: <String, Object?>{
          'action': 'pause_for_failure',
          'reason': 'planning_task_boundary_violation',
          'note': error,
        },
      );
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: error,
        extra: <String, Object?>{
          'output_paths': outputPaths,
          'last_writing_execution_result': writingExecutionResult,
        },
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
        'checkpoint_review': const <String, Object?>{},
        'gate_outcome': const <String, Object?>{},
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': workflowChangedPaths,
      };
    }
    outputPaths = await _workflowRuntimeSatisfiedOutputPathService
        .mergeSatisfiedOutputPaths(
          project: project,
          task: runtimeTask,
          outputPaths: outputPaths,
          executionRecord: executionRecord,
        );
    executionRecord = await _persistExecutionOutputPaths(
      project: project,
      executionPath: executionPath,
      executionRecord: executionRecord,
      outputPaths: outputPaths,
    );
    final reviewSubmissionDecision = _reviewTaskSubmissionDecision(
      task: task,
      result: result,
      semanticReviewArtifacts: semanticReviewArtifacts,
      executionRecord: executionRecord,
    );
    if (ValueReaders.stringValue(reviewSubmissionDecision['action']) ==
        'fail') {
      final error = ValueReaders.stringValue(
        reviewSubmissionDecision['error'],
        'Review task did not submit semantic review.',
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: task,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: const <String, Object?>{},
        result: result,
        recoveryPlan: <String, Object?>{
          'action': 'pause_for_failure',
          'reason': 'review_submission_missing',
          'note': error,
        },
      );
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: error,
        extra: <String, Object?>{
          'output_paths': outputPaths,
          'last_writing_execution_result': writingExecutionResult,
        },
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
        'checkpoint_review': const <String, Object?>{},
        'gate_outcome': const <String, Object?>{},
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': workflowChangedPaths,
      };
    }
    JsonMap checkpointReview = const <String, Object?>{};
    if (result.executedTools.isNotEmpty ||
        outputPaths.isNotEmpty ||
        result.draftMarkdown.trim().isNotEmpty) {
      checkpointReview = await _checkpointReviewService.saveReview(
        project: project,
        task: runtimeTask,
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
      task: runtimeTask,
    );
    if (!ValueReaders.boolValue(gateOutcome['ok'], true)) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: '章级闸门返工链创建失败：${ValueReaders.stringValue(gateOutcome["error"])}',
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: runtimeTask,
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
      task: runtimeTask,
      result: result,
      outputPaths: outputPaths,
      executionRecord: executionRecord,
    );
    if (ValueReaders.stringValue(formalChapterDecision['action']) == 'retry') {
      final note = ValueReaders.stringValue(
        formalChapterDecision['note'],
        '自治正式章节任务在交付前停回用户选择，已安排自动重试。',
      );
      final retryBudget = _directRecoveryRetryBudget(
        task: task,
        options: options,
      );
      final retryCount = ValueReaders.intValue(task['recovery_retry_count']);
      final canRetry = retryCount < retryBudget;
      final nextRetryCount = canRetry ? retryCount + 1 : retryCount;
      final recoveryPlan = canRetry
          ? <String, Object?>{
              'action': 'resume_dispatch',
              'reason': 'autonomous_formal_chapter_retry_scheduled',
              'note': note,
              'safe_after_crash': true,
              'status': 'retrying',
            }
          : <String, Object?>{
              'action': 'pause_for_failure',
              'reason': 'autonomous_formal_chapter_retry_budget_exhausted',
              'note': note,
            };
      final writingExecutionResult = _buildWritingExecutionResult(
        task: runtimeTask,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: const <String, Object?>{},
        result: result,
        recoveryPlan: recoveryPlan,
      );
      final persistedFailureExtra = <String, Object?>{
        'output_paths': outputPaths,
        'last_writing_execution_result': writingExecutionResult,
        'recovery_retry_count': retryCount,
        'recovery_retry_budget': retryBudget,
        'waiting_for_user_choice': false,
        if (ValueReaders.stringValue(
          formalChapterDecision['resume_dispatch_prompt_appendix'],
        ).trim().isNotEmpty)
          'resume_dispatch_prompt_appendix': ValueReaders.stringValue(
            formalChapterDecision['resume_dispatch_prompt_appendix'],
          ),
      };
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: note,
        extra: persistedFailureExtra,
      );
      if (canRetry) {
        await _taskRepository.transitionTask(
          project,
          selector,
          TaskRuntimeConstants.statusRetrying,
          note: '自治正式章节任务在交付前误停，已自动安排重试继续完成交付。',
          extra: <String, Object?>{
            ...persistedFailureExtra,
            'recovery_retry_count': nextRetryCount,
          },
        );
      }
      executionRecord = await _persistWritingExecutionResult(
        project,
        executionPath,
        executionRecord,
        writingExecutionResult,
      );
      return <String, Object?>{
        'ok': canRetry,
        if (!canRetry) 'error': note,
        'response': <String, Object?>{
          ..._resultAsResponse(result),
          'waiting_for_user_choice': false,
        },
        'waiting_for_user_choice': false,
        'retry_scheduled': canRetry,
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
        'checkpoint_review': const <String, Object?>{},
        'gate_outcome': const <String, Object?>{},
        'writing_execution_result': writingExecutionResult,
        'executed_tools': result.executedTools,
        'changed_paths': workflowChangedPaths,
      };
    }
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
        task: runtimeTask,
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
      final recoveryPlan = _formalChapterRecoveryPlan(
        executionRecord: executionRecord,
        note: error,
      );
      final writingExecutionResult = _buildWritingExecutionResult(
        task: runtimeTask,
        executionRecord: executionRecord,
        executionConstraints: executionConstraints,
        checkpointReview: checkpointReview,
        result: result,
        deliveryOverride: _formalChapterFailureDeliveryOverride(
          executionRecord: executionRecord,
          note: error,
        ),
        recoveryPlan: recoveryPlan,
      );
      final autoRetryScheduled = _shouldScheduleDirectRetry(
        task: task,
        writingExecutionResult: writingExecutionResult,
        options: options,
      );
      final nextRetryCount = autoRetryScheduled
          ? ValueReaders.intValue(task['recovery_retry_count']) + 1
          : ValueReaders.intValue(task['recovery_retry_count']);
      final persistedFailureExtra = <String, Object?>{
        'output_paths': outputPaths,
        'last_writing_execution_result': writingExecutionResult,
        'recovery_retry_count': ValueReaders.intValue(
          task['recovery_retry_count'],
        ),
        'recovery_retry_budget': _directRecoveryRetryBudget(
          task: task,
          options: options,
        ),
        if (ValueReaders.boolValue(checkpointReview['ok']))
          'checkpoint_review_path': ValueReaders.stringValue(
            checkpointReview['relative_path'],
          ),
        if (ValueReaders.boolValue(checkpointReview['ok']))
          'checkpoint_review_summary': ValueReaders.stringValue(
            ValueReaders.mapValue(checkpointReview['review'])['summary'],
          ),
      };
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: error,
        extra: persistedFailureExtra,
      );
      if (autoRetryScheduled) {
        await _taskRepository.transitionTask(
          project,
          selector,
          TaskRuntimeConstants.statusRetrying,
          note: '检测到可恢复的正式章节未交付，已按预算自动安排重试。',
          extra: <String, Object?>{
            ...persistedFailureExtra,
            'recovery_retry_count': nextRetryCount,
          },
        );
      }
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
        'retry_scheduled': autoRetryScheduled,
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
    JsonMap scheduledRepair = const <String, Object?>{};
    if (_shouldScheduleExecutionConstraintRepair(
      task: task,
      checkpointReview: checkpointReview,
    )) {
      scheduledRepair = await _executionConstraintRepairTaskService
          .createTaskIfNeeded(
            project: project,
            task: task,
            checkpointReview: ValueReaders.mapValue(checkpointReview['review']),
            checkpointReviewPath: ValueReaders.stringValue(
              checkpointReview['relative_path'],
            ),
          );
      if (!ValueReaders.boolValue(scheduledRepair['ok'], true)) {
        await _taskRepository.transitionTask(
          project,
          selector,
          TaskRuntimeConstants.statusPaused,
          note:
              '执行约束修订任务创建失败：${ValueReaders.stringValue(scheduledRepair["error"])}',
          extra: <String, Object?>{
            'output_paths': outputPaths,
            if (ValueReaders.boolValue(checkpointReview['ok']))
              'checkpoint_review_path': ValueReaders.stringValue(
                checkpointReview['relative_path'],
              ),
          },
        );
        final writingExecutionResult = _buildWritingExecutionResult(
          task: runtimeTask,
          executionRecord: executionRecord,
          executionConstraints: executionConstraints,
          checkpointReview: checkpointReview,
          result: result,
          recoveryPlan: <String, Object?>{
            'action': 'pause_for_repair',
            'reason': 'execution_constraint_repair_task_failed',
            'note': ValueReaders.stringValue(
              scheduledRepair['error'],
              '执行约束修订任务创建失败。',
            ),
          },
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
            scheduledRepair['error'],
            'Failed to create execution constraint repair task.',
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
          'scheduled_repair': scheduledRepair,
          'writing_execution_result': writingExecutionResult,
          'executed_tools': result.executedTools,
          'changed_paths': _mergePaths(
            workflowChangedPaths,
            ValueReaders.stringList(scheduledRepair['changed_paths']),
          ),
        };
      }
    }
    JsonMap checkpointFollowup = const <String, Object?>{};
    if (!(ValueReaders.boolValue(scheduledRepair['created']) ||
        ValueReaders.boolValue(scheduledRepair['duplicated']))) {
      checkpointFollowup = await _autoScheduleLongTaskCheckpointFollowup(
        project: project,
        task: runtimeTask,
        checkpointReview: checkpointReview,
      );
      if (!ValueReaders.boolValue(checkpointFollowup['ok'], true)) {
        await _taskRepository.transitionTask(
          project,
          selector,
          TaskRuntimeConstants.statusPaused,
          note:
              '检查点后续复核任务创建失败：${ValueReaders.stringValue(checkpointFollowup["error"])}',
          extra: <String, Object?>{
            'output_paths': outputPaths,
            if (ValueReaders.boolValue(checkpointReview['ok']))
              'checkpoint_review_path': ValueReaders.stringValue(
                checkpointReview['relative_path'],
              ),
          },
        );
        final writingExecutionResult = _buildWritingExecutionResult(
          task: runtimeTask,
          executionRecord: executionRecord,
          executionConstraints: executionConstraints,
          checkpointReview: checkpointReview,
          result: result,
          recoveryPlan: <String, Object?>{
            'action': 'pause_for_manual_attention',
            'reason': 'checkpoint_followup_scheduling_failed',
            'note': ValueReaders.stringValue(
              checkpointFollowup['error'],
              '检查点后续复核任务创建失败。',
            ),
          },
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
            checkpointFollowup['error'],
            'Failed to schedule checkpoint follow-up reviews.',
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
          'checkpoint_followup': checkpointFollowup,
          'writing_execution_result': writingExecutionResult,
          'executed_tools': result.executedTools,
          'changed_paths': _mergePaths(
            workflowChangedPaths,
            ValueReaders.stringList(checkpointFollowup['changed_paths']),
          ),
        };
      }
    }
    final defaultNextStatus = _taskCompletionPolicyService
        .statusAfterSuccessfulModelStep(runtimeTask);
    final nextStatus =
        ValueReaders.boolValue(scheduledRepair['ok']) &&
            (ValueReaders.boolValue(scheduledRepair['created']) ||
                ValueReaders.boolValue(scheduledRepair['duplicated']))
        ? TaskRuntimeConstants.statusSucceeded
        : _resolveStatusAfterCheckpointReview(
            defaultNextStatus,
            gateOutcome,
            checkpointReview,
            autoScheduledFollowup: ValueReaders.boolValue(
              checkpointFollowup['auto_scheduled'],
            ),
          );
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
        if (ValueReaders.boolValue(scheduledRepair['created']) ||
            ValueReaders.boolValue(scheduledRepair['duplicated']))
          'scheduled_repair_task_path': ValueReaders.stringValue(
            ValueReaders.mapValue(
              scheduledRepair['repair_task'],
            )['relative_path'],
          ),
        if (ValueReaders.boolValue(scheduledRepair['created']) ||
            ValueReaders.boolValue(scheduledRepair['duplicated']))
          'scheduled_repair_task_id': ValueReaders.stringValue(
            ValueReaders.mapValue(scheduledRepair['repair_task'])['id'],
          ),
        if (ValueReaders.boolValue(checkpointFollowup['auto_scheduled']))
          'checkpoint_followup_action': ValueReaders.stringValue(
            checkpointFollowup['command'],
          ),
        if (ValueReaders.boolValue(checkpointFollowup['auto_scheduled']))
          'checkpoint_followup_task_ids': ValueReaders.stringList(
            checkpointFollowup['review_task_ids'],
          ),
      },
    );
    final writingExecutionResult = _buildWritingExecutionResult(
      task: runtimeTask,
      executionRecord: executionRecord,
      executionConstraints: executionConstraints,
      checkpointReview: checkpointReview,
      result: result,
      recoveryPlan: _recoveryPlanAfterSuccessfulStep(
        nextStatus: nextStatus,
        gateOutcome: gateOutcome,
        checkpointReview: checkpointReview,
        waitingForUserChoice: result.waitingForUserChoice,
        scheduledRepair: scheduledRepair,
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
      'scheduled_repair': scheduledRepair,
      'checkpoint_followup': checkpointFollowup,
      'writing_execution_result': writingExecutionResult,
      'executed_tools': result.executedTools,
      'changed_paths': _mergePaths(
        _mergePaths(
          workflowChangedPaths,
          ValueReaders.stringList(gateOutcome['changed_paths']),
        ),
        _mergePaths(
          ValueReaders.stringList(scheduledRepair['changed_paths']),
          ValueReaders.stringList(checkpointFollowup['changed_paths']),
        ),
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
      if (_isContinuousAutonomousFormalChapterTask(task)) {
        return <String, Object?>{
          'action': 'retry',
          'note': _autonomousFormalChapterRetryMessage(result),
          'resume_dispatch_prompt_appendix':
              _autonomousFormalChapterRetryPromptAppendix(
                task,
                reason: _formalWorkflowChapterWaitingMessage(result),
              ),
        };
      }
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

  Future<JsonMap> _planningTaskBoundaryDecision({
    required ProjectDescriptor project,
    required JsonMap task,
    required DraftGenerationResult result,
    required List<String> outputPaths,
    required JsonMap executionRecord,
  }) async {
    if (!_isPlanningStageWorkflowTask(task)) {
      return const <String, Object?>{'action': 'pass'};
    }
    final forbiddenPaths =
        <String>[
              ...outputPaths.where(_isForbiddenPlanningOutputPath),
              ...ValueReaders.stringList(
                executionRecord['output_paths'],
              ).where(_isForbiddenPlanningOutputPath),
              ValueReaders.stringValue(
                executionRecord['chapter_delivery_path'],
              ),
              ValueReaders.stringValue(
                ValueReaders.mapValue(
                  executionRecord['chapter_delivery'],
                )['chapter_path'],
              ),
            ]
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false);
    final usedFormalDelivery = result.executedTools.any(
      (rawTool) =>
          ValueReaders.stringValue(
            ValueReaders.mapValue(rawTool)['name'],
          ).trim() ==
          'submit_chapter_delivery',
    );
    if (forbiddenPaths.isEmpty && !usedFormalDelivery) {
      if (!_requiresCanonicalPlanningArtifacts(task)) {
        return const <String, Object?>{'action': 'pass'};
      }
      final missingPlanningArtifacts = await _missingPlanningArtifactPaths(
        project,
        outputPaths,
        executionRecord,
      );
      if (missingPlanningArtifacts.isEmpty || result.cancelledByUser) {
        return const <String, Object?>{'action': 'pass'};
      }
      if (_isContinuousAutonomousPlanningTask(task)) {
        return <String, Object?>{
          'action': 'retry',
          'note': _planningTaskIncompleteArtifactMessage(
            missingPaths: missingPlanningArtifacts,
            result: result,
          ),
        };
      }
      return const <String, Object?>{'action': 'pass'};
    }
    return <String, Object?>{
      'action': 'fail',
      'error': _planningTaskBoundaryFailureMessage(
        forbiddenPaths: forbiddenPaths,
        result: result,
      ),
    };
  }

  JsonMap _reviewTaskSubmissionDecision({
    required JsonMap task,
    required DraftGenerationResult result,
    required JsonMap semanticReviewArtifacts,
    required JsonMap executionRecord,
  }) {
    if (ValueReaders.stringValue(task['task_type']).trim() != 'review') {
      return const <String, Object?>{'action': 'pass'};
    }
    if (ValueReaders.stringList(
      semanticReviewArtifacts['review_ids'],
    ).isNotEmpty) {
      return const <String, Object?>{'action': 'pass'};
    }
    return <String, Object?>{
      'action': 'fail',
      'error': _reviewTaskMissingSubmissionMessage(
        result: result,
        executionRecord: executionRecord,
      ),
    };
  }

  bool _requiresFormalWorkflowChapterCompletion(JsonMap task) {
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    if (taskType == 'chapter') {
      return true;
    }
    if (taskType != 'revision') {
      return false;
    }
    return _targetsWorkflowChapterOutput(task);
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

  bool _targetsWorkflowChapterOutput(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final candidatePaths = <String>[
      ...ValueReaders.stringList(task['output_paths']),
      ...ValueReaders.stringList(task['source_paths']),
      ValueReaders.stringValue(task['chapter']),
      ValueReaders.stringValue(metadata['chapter_path']),
      ValueReaders.stringValue(metadata['resolved_chapter_path']),
    ];
    return candidatePaths.any(_isWorkflowChapterPath);
  }

  bool _isForbiddenPlanningOutputPath(String path) {
    final clean = path.trim().replaceAll('\\', '/').toLowerCase();
    if (clean.isEmpty) {
      return false;
    }
    return _isWorkflowChapterPath(clean) ||
        (clean.startsWith('tasks/') && clean.endsWith('.json'));
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

  String _planningTaskBoundaryFailureMessage({
    required List<String> forbiddenPaths,
    required DraftGenerationResult result,
  }) {
    final toolTrace = _formalWorkflowChapterToolTrace(result);
    final pathSummary = forbiddenPaths.isEmpty
        ? '未记录到章节路径，但已触发正式章节交付'
        : forbiddenPaths.join('、');
    return '规划任务越界：planning 阶段任务只允许产出规格/大纲，不允许写章节正文、tasks/*.json 任务文件或提交正式章节交付。'
        '本轮越界产物：$pathSummary。工具轨迹：$toolTrace';
  }

  String _planningTaskIncompleteArtifactMessage({
    required List<String> missingPaths,
    required DraftGenerationResult result,
  }) {
    final toolTrace = _formalWorkflowChapterToolTrace(result);
    return 'continuous_autonomous 规划任务未形成最小规划产物：仍缺少 ${missingPaths.join('、')}。'
        '本轮不会停在 waiting_user，而是自动重试继续补齐规划。工具轨迹：$toolTrace';
  }

  String _reviewTaskMissingSubmissionMessage({
    required DraftGenerationResult result,
    required JsonMap executionRecord,
  }) {
    final toolTrace = _formalWorkflowChapterToolTrace(result);
    final chapterDeliveryPath = ValueReaders.stringValue(
      executionRecord['chapter_delivery_path'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          executionRecord['chapter_delivery'],
        )['chapter_path'],
      ),
    ).trim();
    if (chapterDeliveryPath.isNotEmpty) {
      return '审稿任务未形成正式语义审稿交付：检测到 submit_chapter_delivery 写入 $chapterDeliveryPath。'
          'review task 必须用 submit_semantic_review 提交结构化结论，不能用章节交付冒充完成。工具轨迹：$toolTrace';
    }
    final invalidSemanticReview = _firstInvalidSemanticReviewAttempt(
      result.executedTools,
    );
    if (invalidSemanticReview.isNotEmpty) {
      final parseIssues = ValueReaders.mapList(
        ValueReaders.mapValue(
          invalidSemanticReview['result'],
        )['domain_parse_issues'],
      );
      final parseSummary = parseIssues
          .map(
            (issue) =>
                '${ValueReaders.stringValue(issue['field_path'])}: '
                '${ValueReaders.stringValue(issue['message'])}',
          )
          .where((item) => item.trim().isNotEmpty)
          .join('；');
      return '审稿任务未形成正式语义审稿交付：本轮尝试调用了 submit_semantic_review，'
          '但结构化参数未通过校验。'
          '${parseSummary.trim().isEmpty ? '' : '校验问题：$parseSummary。'}'
          'review task 必须提交合法的 findings / recommended_disposition 合同。工具轨迹：$toolTrace';
    }
    return '审稿任务未形成正式语义审稿交付：本轮没有 submit_semantic_review。'
        'review task 必须提交结构化 findings 和 recommended_disposition。工具轨迹：$toolTrace';
  }

  JsonMap _firstInvalidSemanticReviewAttempt(List<Object?> executedTools) {
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name == 'submit_semantic_review') {
        final result = ValueReaders.mapValue(tool['result']);
        if (ValueReaders.boolValue(tool['not_executed']) ||
            ValueReaders.boolValue(result['not_executed']) ||
            ValueReaders.mapList(result['domain_parse_issues']).isNotEmpty) {
          return tool;
        }
      }
      if (name != 'call_sub_agent') {
        continue;
      }
      final nested = _firstInvalidSemanticReviewAttempt(
        ValueReaders.objectList(
          ValueReaders.mapValue(tool['result'])['tool_calls'],
        ),
      );
      if (nested.isNotEmpty) {
        return nested;
      }
    }
    return const <String, Object?>{};
  }

  Future<List<String>> _missingPlanningArtifactPaths(
    ProjectDescriptor project,
    List<String> outputPaths,
    JsonMap executionRecord,
  ) async {
    final planningArtifactPathService =
        const LongTaskPlanningArtifactPathService();
    final actualPaths = <String>{
      ...outputPaths.map((item) => item.trim().replaceAll('\\', '/')),
      ...ValueReaders.stringList(
        executionRecord['output_paths'],
      ).map((item) => item.trim().replaceAll('\\', '/')),
    }.where((item) => item.isNotEmpty).toSet();
    final requiredPaths = <String>[
      LongTaskPlanningArtifactPathService.projectSpecPath,
      planningArtifactPathService.storyOutlinePath(),
      planningArtifactPathService.chapterPlanPath(),
    ];
    final missingPaths = <String>[];
    for (final path in requiredPaths) {
      if (actualPaths.contains(path)) {
        continue;
      }
      final existing = await _taskRepository.readTextFile(project, path);
      if ((existing ?? '').trim().isNotEmpty) {
        continue;
      }
      missingPaths.add(path);
    }
    return List<String>.unmodifiable(missingPaths);
  }

  bool _isContinuousAutonomousPlanningTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    return _requiresCanonicalPlanningArtifacts(task) &&
        ValueReaders.stringValue(metadata['runtime_baseline_id']).trim() ==
            'continuous_autonomous';
  }

  bool _isPlanningStageWorkflowTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['stage']).trim() != 'planning') {
      return false;
    }
    return ValueReaders.stringValue(task['task_type']).trim() == 'planning' ||
        _isLongTaskManagedWorkflowTask(task);
  }

  bool _requiresCanonicalPlanningArtifacts(JsonMap task) {
    return ValueReaders.stringValue(task['task_type']).trim() == 'planning';
  }

  bool _isContinuousAutonomousFormalChapterTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    return _requiresFormalWorkflowChapterCompletion(task) &&
        ValueReaders.stringValue(metadata['runtime_baseline_id']).trim() ==
            'continuous_autonomous';
  }

  String _autonomousFormalChapterRetryMessage(DraftGenerationResult result) {
    final trace = _formalWorkflowChapterToolTrace(result);
    return 'continuous_autonomous 正式章节任务不允许在正式交付前停回 waiting_user：'
        '本轮只执行了用户选项/计划/读取类工具（$trace），没有形成正式章节正文或 submit_chapter_delivery。'
        '系统将自动重试，并要求直接读取现有规划继续完成交付。';
  }

  String _autonomousFormalChapterRetryPromptAppendix(
    JsonMap task, {
    String reason = '',
  }) {
    final planningArtifactPathService =
        const LongTaskPlanningArtifactPathService();
    final sourceChapterPaths = ValueReaders.stringList(
      task['source_paths'],
    ).where(_isWorkflowChapterPath).toSet().toList(growable: false);
    final lines = <String>[
      '自治续跑补充：上轮在正式章节交付前错误停回用户选择点，系统现已改为自动续跑。',
      if (reason.trim().isNotEmpty) '上轮停顿原因：${reason.trim()}',
      '优先读取并尊重既有规划：${LongTaskPlanningArtifactPathService.projectSpecPath}、${planningArtifactPathService.storyOutlinePath()}、${planningArtifactPathService.chapterPlanPath()}。',
      if (sourceChapterPaths.isNotEmpty)
        '如需承接前情，只读取必要的既有章节正文：${sourceChapterPaths.join('、')}。',
      '不要再次因为“规划不完整”或一般方向分叉调用 present_user_options；只要关键文件真实存在，就继续写作并通过 submit_chapter_delivery 交付当前任务。',
      '只有在关键规划、必要前文或修订依据真实缺失到无法成稿时，才允许提出新的用户阻塞。',
    ];
    return lines.join('\n\n');
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

  String _resolveStatusAfterCheckpointReview(
    String defaultStatus,
    JsonMap gateOutcome,
    JsonMap checkpointReview, {
    bool autoScheduledFollowup = false,
  }) {
    final review = ValueReaders.mapValue(checkpointReview['review']);
    final continuationDisposition = ValueReaders.stringValue(
      review['continuation_disposition'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(review['disposition'])['disposition'],
      ),
    ).trim();
    if (continuationDisposition == 'manual_attention') {
      return TaskRuntimeConstants.statusPaused;
    }
    if (continuationDisposition == 'blocked_wait_user') {
      if (autoScheduledFollowup) {
        final gateResolvedStatus = _resolveStatusAfterGate(
          defaultStatus,
          gateOutcome,
        );
        return gateResolvedStatus == TaskRuntimeConstants.statusWaitingUser
            ? TaskRuntimeConstants.statusSucceeded
            : gateResolvedStatus;
      }
      return TaskRuntimeConstants.statusWaitingUser;
    }
    return _resolveStatusAfterGate(defaultStatus, gateOutcome);
  }

  Future<JsonMap> _autoScheduleLongTaskCheckpointFollowup({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap checkpointReview,
  }) async {
    if (!ValueReaders.boolValue(checkpointReview['ok'])) {
      return const <String, Object?>{
        'ok': true,
        'auto_scheduled': false,
        'changed_paths': <Object?>[],
      };
    }
    if (!_isLongTaskManagedWorkflowTask(task)) {
      return const <String, Object?>{
        'ok': true,
        'auto_scheduled': false,
        'changed_paths': <Object?>[],
      };
    }
    final review = ValueReaders.mapValue(checkpointReview['review']);
    if (review.isEmpty) {
      return const <String, Object?>{
        'ok': true,
        'auto_scheduled': false,
        'changed_paths': <Object?>[],
      };
    }
    final disposition = ValueReaders.mapValue(review['disposition']);
    String command = '';
    if (ValueReaders.boolValue(disposition['request_revision_followup'])) {
      command = 'request_revision_followup';
    } else if (ValueReaders.boolValue(
      disposition['create_followup_review_tasks'],
    )) {
      command = 'create_followup_review_tasks';
    }
    if (command.isEmpty) {
      return const <String, Object?>{
        'ok': true,
        'auto_scheduled': false,
        'changed_paths': <Object?>[],
      };
    }
    final checkpointReviewPath = ValueReaders.stringValue(
      checkpointReview['relative_path'],
    ).trim();
    if (checkpointReviewPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review path is missing for follow-up scheduling.',
        'command': command,
        'changed_paths': const <Object?>[],
      };
    }
    final applied = await _checkpointActionService.applyAction(
      project,
      checkpointReviewPath,
      command,
    );
    if (!ValueReaders.boolValue(applied['ok'], true)) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          applied['error'],
          'Checkpoint follow-up scheduling failed.',
        ),
        'command': command,
        'changed_paths': ValueReaders.objectList(applied['changed_paths']),
      };
    }
    final relatedTasks =
        ValueReaders.mapList(applied['review_tasks']).isNotEmpty
        ? ValueReaders.mapList(applied['review_tasks'])
        : ValueReaders.mapList(applied['tasks']);
    return <String, Object?>{
      ...applied,
      'ok': true,
      'command': command,
      'auto_scheduled':
          relatedTasks.isNotEmpty ||
          ValueReaders.mapList(applied['rewired_tasks']).isNotEmpty,
      'review_task_ids': relatedTasks
          .map((item) => ValueReaders.stringValue(item['id']))
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false),
    };
  }

  bool _isLongTaskManagedWorkflowTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['plan_id']).trim().isNotEmpty ||
        ValueReaders.stringValue(
          metadata['runtime_baseline_id'],
        ).trim().isNotEmpty ||
        ValueReaders.stringValue(metadata['generated_by']).trim() ==
            'LongTaskPlanner') {
      return true;
    }
    final mode = _longTaskModeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    return mode == TaskRuntimeConstants.modeSeedToFullNovel ||
        mode == TaskRuntimeConstants.modeSupervisedChapterQueue;
  }

  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.runNextWorkflowTaskOnce(
      project,
      settings,
      agent: agent,
    );
  }

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.taskQueuePreflight(
      project,
      options: options,
    );
  }

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    return _workflowQueueRuntimeService.listTaskQueueRuns(
      project,
      limit: limit,
    );
  }

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    return _workflowQueueRuntimeService.listLongTaskRuns(project, limit: limit);
  }

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.longTaskSchedulerPlan(
      project,
      relativePath: relativePath,
      options: options,
    );
  }

  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String relativePath, {
    String note = '用户暂停长任务。',
  }) async {
    return _workflowQueueRuntimeService.pauseLongTaskRun(
      project,
      relativePath,
      note: note,
    );
  }

  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings,
    String relativePath, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.resumeLongTaskRun(
      project,
      settings,
      relativePath,
      options: options,
      agent: agent,
    );
  }

  Future<JsonMap> stopLongTaskRun(
    ProjectDescriptor project,
    String relativePath, {
    String note = '用户请求停止长任务。',
  }) async {
    return _workflowQueueRuntimeService.stopLongTaskRun(
      project,
      relativePath,
      note: note,
    );
  }

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    return _workflowQueueRuntimeService.runWorkflowTaskQueue(
      project,
      settings,
      options: options,
      agent: agent,
    );
  }

  bool _isRetryableWorkflowTaskTransportFailure(Object error) {
    if (error is TimeoutException) {
      return true;
    }
    final message = '$error'.toLowerCase();
    return message.contains('socketexception') ||
        message.contains('handshakeexception') ||
        message.contains('connection closed before full header') ||
        message.contains('connection reset') ||
        message.contains('connection terminated') ||
        message.contains('broken pipe') ||
        message.contains('流式响应在完成前被中断') ||
        message.contains('模型请求失败(502)') ||
        message.contains('模型请求失败(503)') ||
        message.contains('模型请求失败(504)') ||
        message.contains('模型请求失败(520)') ||
        message.contains('模型请求失败(522)') ||
        message.contains('模型请求失败(524)');
  }

  Future<JsonMap> _handleRetryableWorkflowTaskTransportFailure({
    required ProjectDescriptor project,
    required JsonMap selector,
    required JsonMap task,
    required JsonMap runtimeTask,
    required JsonMap executionConstraints,
    required JsonMap options,
    required Object error,
  }) async {
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    );
    var executionRecord = executionPath.trim().isEmpty
        ? const <String, Object?>{}
        : await _taskRepository.loadRecord(project, executionPath);
    final isPlanning = _isContinuousAutonomousPlanningTask(runtimeTask);
    final isFormalChapter = _isContinuousAutonomousFormalChapterTask(
      runtimeTask,
    );
    final retryBudget = _directRecoveryRetryBudget(
      task: task,
      options: options,
    );
    final retryCount = ValueReaders.intValue(task['recovery_retry_count']);
    final canRetry =
        (isPlanning || isFormalChapter) && retryCount < retryBudget;
    final nextRetryCount = canRetry ? retryCount + 1 : retryCount;
    final errorDetail = '$error'.trim();
    final detailSuffix = errorDetail.isEmpty ? '' : '：$errorDetail';
    final note = canRetry
        ? (isPlanning
              ? '自治规划任务模型传输中断$detailSuffix，已按预算自动安排重试。'
              : '自治正式章节任务模型传输中断$detailSuffix，已按预算自动安排重试继续完成交付。')
        : (isPlanning
              ? '自治规划任务模型传输中断$detailSuffix，自动重试预算已耗尽，已暂停等待处理。'
              : isFormalChapter
              ? '自治正式章节任务模型传输中断$detailSuffix，自动重试预算已耗尽，已暂停等待处理。'
              : '工作流任务模型传输中断$detailSuffix，本步已暂停等待重试或人工处理。');
    final recoveryPlan = canRetry
        ? <String, Object?>{
            'action': 'resume_dispatch',
            'reason': isPlanning
                ? 'autonomous_planning_transport_retry_scheduled'
                : 'autonomous_formal_chapter_transport_retry_scheduled',
            'note': note,
            'safe_after_crash': true,
            'status': 'retrying',
          }
        : <String, Object?>{
            'action': 'pause_for_failure',
            'reason': isPlanning || isFormalChapter
                ? 'workflow_task_transport_retry_budget_exhausted'
                : 'workflow_task_transport_failed',
            'note': note,
          };
    final outputPaths = await _workflowRuntimeSatisfiedOutputPathService
        .mergeSatisfiedOutputPaths(
          project: project,
          task: task,
          outputPaths: ValueReaders.stringList(task['output_paths']),
          executionRecord: executionRecord,
        );
    final writingExecutionResult = _buildWritingExecutionResult(
      task: runtimeTask,
      executionRecord: executionRecord,
      executionConstraints: executionConstraints,
      checkpointReview: const <String, Object?>{},
      recoveryPlan: recoveryPlan,
      transportFailed: true,
    );
    final persistedFailureExtra = <String, Object?>{
      'output_paths': outputPaths,
      'last_writing_execution_result': writingExecutionResult,
      'recovery_retry_count': retryCount,
      'recovery_retry_budget': retryBudget,
      'waiting_for_user_choice': false,
      if (canRetry && isFormalChapter)
        'resume_dispatch_prompt_appendix':
            _autonomousFormalChapterRetryPromptAppendix(
              task,
              reason: errorDetail.isEmpty
                  ? '上轮在模型传输阶段中断。'
                  : '上轮在模型传输阶段中断：$errorDetail',
            ),
    };
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusFailed,
      note: note,
      extra: persistedFailureExtra,
    );
    if (canRetry) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusRetrying,
        note: isPlanning
            ? '检测到可重试的规划传输故障，已自动安排重试。'
            : '检测到可重试的正式章节传输故障，已自动安排重试。',
        extra: <String, Object?>{
          ...persistedFailureExtra,
          'recovery_retry_count': nextRetryCount,
        },
      );
    }
    final resolvedExecutionPath = ValueReaders.stringValue(
      executionRecord['relative_path'],
      executionPath,
    );
    var nextExecutionRecord = executionRecord;
    if (resolvedExecutionPath.trim().isNotEmpty) {
      nextExecutionRecord = await _persistExecutionOutputPaths(
        project: project,
        executionPath: resolvedExecutionPath,
        executionRecord: executionRecord,
        outputPaths: outputPaths,
      );
      nextExecutionRecord = await _persistWritingExecutionResult(
        project,
        resolvedExecutionPath,
        nextExecutionRecord,
        writingExecutionResult,
      );
    }
    return <String, Object?>{
      'ok': false,
      'error': note,
      'response': const <String, Object?>{'waiting_for_user_choice': false},
      'waiting_for_user_choice': false,
      'retry_scheduled': canRetry,
      'output_paths': outputPaths,
      'execution': nextExecutionRecord,
      'activation_report_path': ValueReaders.stringValue(
        nextExecutionRecord['activation_report_path'],
      ),
      'activation_report_summary': ValueReaders.stringValue(
        nextExecutionRecord['activation_report_summary'],
      ),
      'chapter_delivery': ValueReaders.mapValue(
        nextExecutionRecord['chapter_delivery'],
      ),
      'chapter_delivery_state': ValueReaders.stringValue(
        nextExecutionRecord['chapter_delivery_state'],
      ),
      'chapter_delivery_path': ValueReaders.stringValue(
        nextExecutionRecord['chapter_delivery_path'],
      ),
      'checkpoint_review': const <String, Object?>{},
      'gate_outcome': const <String, Object?>{},
      'writing_execution_result': writingExecutionResult,
      'executed_tools': const <Object?>[],
      'changed_paths': const <Object?>[],
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
    final taskHostToolPermissionContext =
        await _consumeWorkflowTaskToolPermissionOverride(
          project: project,
          task: task,
        );
    final useCase = _workflowGenerateDraftUseCase(
      provider: provider,
      settings: settings,
      hostToolPermissionContextOverride: taskHostToolPermissionContext,
    );
    final selectedCollaborationGroup =
        await _resolveSelectedCollaborationGroupForTask(
          project: project,
          task: task,
          agent: agent,
        );
    var result = await useCase.execute(
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
    final persistedApprovals = await _toolPermissionApprovalRecordService
        .persistPendingApprovalsForExecutedTools(
          project,
          scopeType: ProjectToolPermissionApprovalScopes.workflowTask,
          executedTools: result.executedTools,
          taskPath: ValueReaders.stringValue(task['relative_path']),
          executionPath: ValueReaders.stringValue(
            task['atomic_execution_path'],
          ),
        );
    result = _resultWithExecutedTools(
      result,
      executedTools: ValueReaders.objectList(
        persistedApprovals['executed_tools'],
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

  Future<JsonMap> applyWorkflowTaskUserChoice(
    ProjectDescriptor project,
    JsonMap selector, {
    required String prompt,
    String label = '',
    String description = '',
    String sourceQuestion = '',
    String permissionApprovalId = '',
    String permissionApprovalOptionId = '',
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'User option prompt is empty.',
      };
    }
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'Task not found.'};
    }
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    final nextStatus = taskType == 'checkpoint'
        ? TaskRuntimeConstants.statusSucceeded
        : TaskRuntimeConstants.statusQueued;
    JsonMap permissionApprovalResolution = const <String, Object?>{};
    if (permissionApprovalId.trim().isNotEmpty &&
        permissionApprovalOptionId.trim().isNotEmpty) {
      permissionApprovalResolution = await _toolPermissionApprovalRecordService
          .resolveSelection(
            project,
            approvalId: permissionApprovalId.trim(),
            optionId: permissionApprovalOptionId.trim(),
          );
      if (!ValueReaders.boolValue(permissionApprovalResolution['ok'])) {
        return permissionApprovalResolution;
      }
    }
    final transition = await _taskRepository.transitionTask(
      project,
      selector,
      nextStatus,
      note: taskType == 'checkpoint'
          ? (label.trim().isEmpty
                ? '已记录用户选择，并确认当前检查点继续。'
                : '已记录用户选择：$label，并确认当前检查点继续。')
          : (label.trim().isEmpty
                ? '已记录用户选择，任务将按确认方向继续。'
                : '已记录用户选择：$label，任务将按确认方向继续。'),
      extra: <String, Object?>{
        'selected_user_option_prompt': cleanPrompt,
        'selected_user_option_label': label.trim(),
        'selected_user_option_description': description.trim(),
        'selected_user_option_question': sourceQuestion.trim(),
        'waiting_for_user_choice': false,
        'auto_confirmed_from_user_option': taskType == 'checkpoint',
        'selected_host_tool_permission_approval_id': permissionApprovalId
            .trim(),
        'selected_host_tool_permission_option_id': permissionApprovalOptionId
            .trim(),
        'selected_host_tool_permission_option_kind': ValueReaders.stringValue(
          permissionApprovalResolution['selected_option_kind'],
        ).trim(),
      },
    );
    final changedPaths = <String>[];
    final transitionPath = ValueReaders.stringValue(
      transition['relative_path'],
      ValueReaders.stringValue(task['relative_path']),
    ).trim();
    if (transitionPath.isNotEmpty) {
      changedPaths.add(transitionPath);
    }
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim();
    JsonMap execution = const <String, Object?>{};
    if (executionPath.isNotEmpty) {
      execution = await _taskRepository.loadRecord(project, executionPath);
      if (execution.isNotEmpty) {
        final nextExecution = ValueReaders.deepCopyMap(execution)
          ..['selected_user_option'] = <String, Object?>{
            'label': label.trim(),
            'description': description.trim(),
            'prompt': cleanPrompt,
            'source_question': sourceQuestion.trim(),
            'selected_at': DateTime.now().toIso8601String(),
            if (permissionApprovalId.trim().isNotEmpty)
              'permission_approval_id': permissionApprovalId.trim(),
            if (permissionApprovalOptionId.trim().isNotEmpty)
              'permission_approval_option_id': permissionApprovalOptionId
                  .trim(),
          };
        await _taskRepository.saveRecord(project, executionPath, nextExecution);
        execution = nextExecution;
        changedPaths.add(executionPath);
      }
    }
    return <String, Object?>{
      'ok': true,
      'task': await _taskRepository.loadTask(project, selector),
      'transition': transition,
      'execution': execution,
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'changed_paths': changedPaths,
      'auto_confirmed_checkpoint': taskType == 'checkpoint',
      'permission_approval': permissionApprovalResolution,
    };
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

  Future<JsonMap> applyLongTaskFailureAction(
    ProjectDescriptor project, {
    required JsonMap selector,
    required String command,
    String runPath = '',
  }) async {
    // 中文注释: 失败恢复入口让 GUI/CLI 都走同一条正式 runtime 链，而不是各自手写任务与运行记录补丁。
    JsonMap record = const <String, Object?>{};
    if (runPath.trim().isNotEmpty) {
      record = await _taskRepository.loadRecord(project, runPath);
    } else {
      final recentRuns = await listLongTaskRuns(project, limit: 1);
      if (recentRuns.isNotEmpty) {
        record = recentRuns.first;
      }
    }
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
      };
    }
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'Task not found.'};
    }
    final failureActionService = LongTaskFailureActionService(
      lifecycleService: _lifecycleService,
    );
    final result = failureActionService.failureAction(
      record,
      task,
      command,
      createdAt: DateTime.now().toIso8601String(),
    );
    if (!ValueReaders.boolValue(result['ok'])) {
      return result;
    }
    final recordPath = ValueReaders.stringValue(record['relative_path']).trim();
    if (recordPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run path is missing.',
      };
    }
    final savedRecord = await _taskRepository.saveRecord(
      project,
      recordPath,
      ValueReaders.mapValue(result['record']),
    );
    final taskTransition = await _taskRepository.transitionTask(
      project,
      selector,
      ValueReaders.stringValue(result['task_status']),
      note: ValueReaders.stringValue(result['note']),
    );
    if (!ValueReaders.boolValue(taskTransition['ok'])) {
      return taskTransition;
    }
    final reloadedRun = await loadLongTaskRun(project, recordPath);
    final changedPaths = <String>{
      recordPath,
      ValueReaders.stringValue(taskTransition['relative_path']).trim(),
    }..removeWhere((path) => path.isEmpty);
    return <String, Object?>{
      'ok': true,
      'record': savedRecord,
      'task': ValueReaders.mapValue(taskTransition['task']),
      'relative_path': ValueReaders.stringValue(
        taskTransition['relative_path'],
      ),
      'run_center_contract': ValueReaders.mapValue(
        reloadedRun['run_center_contract'],
      ),
      'scheduler_snapshot': ValueReaders.mapValue(
        reloadedRun['scheduler_snapshot'],
      ),
      'changed_paths': changedPaths.toList(growable: false),
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

  String _expressionConstraintPolicyModeFromOptions(JsonMap options) {
    return ValueReaders.stringValue(
      options['expression_constraint_policy_mode'],
      ValueReaders.stringValue(options['expressionConstraintPolicyMode']),
    ).trim();
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
    final availableGroups = await _loadAvailableAgentGroupsSafe(project);
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
          final fullGroup = _groupById(preferred.groupId, availableGroups);
          final base = fullGroup.isEmpty
              ? const <String, Object?>{}
              : ValueReaders.deepCopyMap(fullGroup);
          final baseMetadata = ValueReaders.mapValue(base['metadata']);
          return <String, Object?>{
            ...base,
            'id': preferred.groupId,
            'name': preferred.displayName.trim().isNotEmpty
                ? preferred.displayName.trim()
                : ValueReaders.stringValue(
                    base['name'],
                    preferred.groupId,
                  ).trim(),
            'source': ValueReaders.stringValue(
              base['source'],
              'project_group_selection',
            ),
            'enabled': preferred.enabled,
            'metadata': <String, Object?>{
              ...baseMetadata,
              'selected_by_default': preferred.selectedByDefault,
              'mode_ids': preferred.modeIds,
              'stage_ids': preferred.stageIds,
              'task_family_ids': preferred.taskFamilyIds,
              ...preferred.metadata,
            },
          };
        }
      } catch (_) {}
    }
    return _singleMemberCollaborationGroup(agent);
  }

  JsonMap _groupById(String groupId, List<JsonMap> groups) {
    final cleanGroupId = groupId.trim();
    for (final group in groups) {
      if (ValueReaders.stringValue(group['id']).trim() == cleanGroupId) {
        return ValueReaders.deepCopyMap(group);
      }
    }
    return const <String, Object?>{};
  }

  Future<JsonMap> _resolveReviewerDispatchForTask({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap agent,
    required JsonMap selectedCollaborationGroup,
  }) async {
    final availableAgents = await _loadAvailableAgentsSafe(project);
    final availableGroups = await _loadAvailableAgentGroupsSafe(project);
    return _reviewerDispatchService.resolve(
      task: task,
      mainAgent: agent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
    );
  }

  Future<List<JsonMap>> _loadAvailableAgentsSafe(
    ProjectDescriptor project,
  ) async {
    final loader = _loadAvailableAgents;
    if (loader == null) {
      return const <JsonMap>[];
    }
    try {
      return await loader(project);
    } catch (_) {
      return const <JsonMap>[];
    }
  }

  Future<List<JsonMap>> _loadAvailableAgentGroupsSafe(
    ProjectDescriptor project,
  ) async {
    final loader = _loadAvailableAgentGroups;
    if (loader == null) {
      return const <JsonMap>[];
    }
    try {
      return await loader(project);
    } catch (_) {
      return const <JsonMap>[];
    }
  }

  String _delegatedReviewerTask(JsonMap task) {
    final reviewType = ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['review_type'],
      ReviewTypeConstants.general,
    );
    return '请以当前 workflow 审稿执行者身份完成本次 $reviewType review task。'
        '必要时读取项目文件，形成结构化审稿结论后优先使用 submit_semantic_review 提交；'
        '不要请求用户，不要调度其他任务，也不要直接推进章节交付。';
  }

  List<String> _delegatedReviewerConstraints(JsonMap task) {
    return <String>[
      '只处理当前 review task，不扩展到其他任务。',
      '保持审稿结果可供主流程合并与持久化。',
      if (ValueReaders.stringValue(task['chapter']).trim().isNotEmpty)
        '聚焦章节：${ValueReaders.stringValue(task['chapter'])}',
    ];
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
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
        ],
      },
    };
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
    final effectiveExecutionConstraints = executionConstraints.isEmpty
        ? ValueReaders.mapValue(executionRecord['execution_constraints'])
        : executionConstraints;
    final executionId = ValueReaders.stringValue(
      executionRecord['relative_path'],
      ValueReaders.stringValue(task['id']),
    ).trim();
    final review = ValueReaders.mapValue(checkpointReview['review']);
    final resultJson = _writingExecutionResultNormalizerService
        .normalize(
          executionId: executionId.isEmpty
              ? 'workflow_task_${DateTime.now().microsecondsSinceEpoch}'
              : executionId,
          workflowKind: 'workflow_task',
          deliveryState: _writingExecutionContractService
              .chapterDeliveryStateFromDelivery(
                delivery: deliveryOverride.isNotEmpty
                    ? deliveryOverride
                    : ValueReaders.mapValue(
                        executionRecord['chapter_delivery'],
                      ),
                fallbackState: ValueReaders.stringValue(
                  executionRecord['chapter_delivery_state'],
                ),
                fallbackChapterPath: ValueReaders.stringValue(
                  executionRecord['chapter_delivery_path'],
                ),
              ),
          constraintBridgeResult: _writingExecutionContractService
              .constraintBridgeResult(effectiveExecutionConstraints),
          activationReport: _writingExecutionContractService
              .activationReportFromJson(
                ValueReaders.mapValue(executionRecord['activation_report']),
              ),
          expressionConstraintReview:
              ExpressionConstraintReviewProjection.fromJson(
                ValueReaders.mapValue(review['expression_constraint_review']),
              ),
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
            'formal_review_completed':
                ValueReaders.stringValue(task['task_type']) == 'review' &&
                ValueReaders.mapValue(
                  executionRecord['semantic_review'],
                ).isNotEmpty,
          },
        )
        .toJson();
    return _writingExecutionContractService.attachDerivedProjections(
      resultJson,
    );
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

  JsonMap _attachExecutionConstraintArtifacts(
    JsonMap execution,
    JsonMap executionConstraints,
  ) {
    final next = ValueReaders.deepCopyMap(execution);
    if (executionConstraints.isNotEmpty) {
      next['execution_constraints'] = ValueReaders.deepCopyMap(
        executionConstraints,
      );
    }
    final runtimeReport = ValueReaders.mapValue(
      executionConstraints['runtime_report'],
    );
    if (runtimeReport.isNotEmpty) {
      next['execution_constraint_bridge_report'] = ValueReaders.deepCopyMap(
        runtimeReport,
      );
    }
    return next;
  }

  Future<List<WritingExecutionConstraintSummary>>
  _recentExpressionConstraintSummariesForTask(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    final planId = ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['plan_id'],
    ).trim();
    if (planId.isEmpty) {
      return const <WritingExecutionConstraintSummary>[];
    }
    final currentTaskId = ValueReaders.stringValue(task['id']).trim();
    final currentExecutionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim();
    final tasks = await _taskRepository.listTasks(project);
    final candidates =
        tasks
            .where((candidate) {
              if (ValueReaders.stringValue(
                    ValueReaders.mapValue(candidate['metadata'])['plan_id'],
                  ).trim() !=
                  planId) {
                return false;
              }
              if (ValueReaders.stringValue(candidate['id']).trim() ==
                  currentTaskId) {
                return false;
              }
              final taskType = ValueReaders.stringValue(
                candidate['task_type'],
              ).trim();
              if (!<String>{'chapter', 'revision'}.contains(taskType)) {
                return false;
              }
              final executionPath = ValueReaders.stringValue(
                candidate['atomic_execution_path'],
              ).trim();
              return executionPath.isNotEmpty &&
                  executionPath != currentExecutionPath;
            })
            .toList(growable: false)
          ..sort(_compareConstraintSummaryCandidateTasks);
    final summaries = <WritingExecutionConstraintSummary>[];
    for (final candidate in candidates) {
      final executionRecord = await _taskRepository.loadRecord(
        project,
        ValueReaders.stringValue(candidate['atomic_execution_path']),
      );
      final summary = _constraintSummaryFromExecutionRecord(executionRecord);
      if (summary == null) {
        continue;
      }
      summaries.add(summary);
      if (summaries.length >= 4) {
        break;
      }
    }
    return List<WritingExecutionConstraintSummary>.unmodifiable(summaries);
  }

  int _compareConstraintSummaryCandidateTasks(JsonMap left, JsonMap right) {
    final leftSort = ValueReaders.intValue(
      ValueReaders.mapValue(left['metadata'])['sort_order'],
    );
    final rightSort = ValueReaders.intValue(
      ValueReaders.mapValue(right['metadata'])['sort_order'],
    );
    if (leftSort != rightSort) {
      return rightSort.compareTo(leftSort);
    }
    final leftUpdated = ValueReaders.stringValue(
      left['updated_at'],
      ValueReaders.stringValue(left['created_at']),
    );
    final rightUpdated = ValueReaders.stringValue(
      right['updated_at'],
      ValueReaders.stringValue(right['created_at']),
    );
    return rightUpdated.compareTo(leftUpdated);
  }

  WritingExecutionConstraintSummary? _constraintSummaryFromExecutionRecord(
    JsonMap executionRecord,
  ) {
    final writingExecutionResult = ValueReaders.mapValue(
      executionRecord['writing_execution_result'],
    );
    if (writingExecutionResult.isEmpty) {
      return null;
    }
    final constraints = ValueReaders.mapValue(
      writingExecutionResult['constraints'],
    );
    if (constraints.isEmpty) {
      return null;
    }
    return WritingExecutionConstraintSummary.fromJson(constraints);
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
    if (deliveryState == ChapterDeliveryStateStatuses.waitingUserChoice) {
      return <String, Object?>{
        'action': 'resume_when_user_confirms',
        'reason': 'formal_chapter_waiting_user',
        'note': note,
      };
    }
    if (<String>{
      ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
      ChapterDeliveryStateStatuses.manualAttentionRequired,
      ChapterDeliveryStateStatuses.hardFailure,
    }.contains(deliveryState)) {
      return <String, Object?>{
        'action': 'pause_for_manual_attention',
        'reason': 'formal_chapter_manual_attention_required',
        'note': note,
      };
    }
    if (deliveryState == ChapterDeliveryStateStatuses.deliveredNeedsRepair) {
      return <String, Object?>{
        'action': 'pause_for_repair',
        'reason': 'formal_chapter_repair_required',
        'note': note,
      };
    }
    if (<String>{
      '',
      ChapterDeliveryStateStatuses.missingOutputRecoverable,
      ChapterDeliveryStateStatuses.pathMismatchRecoverable,
    }.contains(deliveryState)) {
      return <String, Object?>{
        'action': 'pause_for_failure',
        'reason': 'formal_chapter_retryable_failure',
        'note': note,
      };
    }
    return <String, Object?>{
      'action': 'pause_for_repair',
      'reason': 'formal_chapter_recovery_required',
      'note': note,
    };
  }

  JsonMap _formalChapterFailureDeliveryOverride({
    required JsonMap executionRecord,
    required String note,
  }) {
    if (ValueReaders.stringValue(
      executionRecord['chapter_delivery_state'],
    ).trim().isNotEmpty) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'present': true,
      'delivery_state': ChapterDeliveryStateStatuses.missingOutputRecoverable,
      'state_result': <String, Object?>{
        'state': ChapterDeliveryStateStatuses.missingOutputRecoverable,
        'summary': note,
        'reason': 'formal_chapter_missing_delivery',
        'retryable': true,
        'blocks_progress': true,
        'chapter_body_delivered': false,
        'submission_accepted': false,
      },
      'submission_present': false,
    };
  }

  bool _shouldScheduleDirectRetry({
    required JsonMap task,
    required JsonMap writingExecutionResult,
    required JsonMap options,
  }) {
    if (!ValueReaders.boolValue(writingExecutionResult['retryable'])) {
      return false;
    }
    if (ValueReaders.stringValue(
          writingExecutionResult['next_action'],
        ).trim() !=
        'pause_for_failure') {
      return false;
    }
    final budget = _directRecoveryRetryBudget(task: task, options: options);
    if (budget <= 0) {
      return false;
    }
    final retryCount = ValueReaders.intValue(task['recovery_retry_count']);
    return retryCount < budget;
  }

  int _directRecoveryRetryBudget({
    required JsonMap task,
    required JsonMap options,
  }) {
    return ValueReaders.intValue(
      options['recovery_retry_budget'],
      ValueReaders.intValue(task['recovery_retry_budget'], 1),
    ).clamp(0, 10);
  }

  bool _shouldScheduleExecutionConstraintRepair({
    required JsonMap task,
    required JsonMap checkpointReview,
  }) {
    if (!ValueReaders.boolValue(checkpointReview['ok'])) {
      return false;
    }
    final taskType = ValueReaders.stringValue(task['task_type']).trim();
    if (!<String>{'chapter', 'revision'}.contains(taskType)) {
      return false;
    }
    final review = ValueReaders.mapValue(checkpointReview['review']);
    final expressionSignal = ValueReaders.mapValue(
      review['expression_constraint_signal'],
    );
    final narrativeExpression = ValueReaders.mapValue(
      ValueReaders.mapValue(
        review['narrative_supervisor_risk'],
      )['expression_constraints'],
    );
    final gateDisposition = ValueReaders.stringValue(
      expressionSignal['gate_disposition'],
      ValueReaders.stringValue(narrativeExpression['gate_disposition']),
    ).trim();
    return ValueReaders.boolValue(expressionSignal['repair_required']) ||
        ValueReaders.boolValue(narrativeExpression['repair_required']) ||
        gateDisposition ==
            ExpressionConstraintGateRecommendedDispositions.repair;
  }

  JsonMap _recoveryPlanAfterSuccessfulStep({
    required String nextStatus,
    required JsonMap gateOutcome,
    required JsonMap checkpointReview,
    required bool waitingForUserChoice,
    required JsonMap scheduledRepair,
  }) {
    final repairTask = ValueReaders.mapValue(scheduledRepair['repair_task']);
    if (repairTask.isNotEmpty &&
        (ValueReaders.boolValue(scheduledRepair['created']) ||
            ValueReaders.boolValue(scheduledRepair['duplicated']))) {
      return <String, Object?>{
        'action': 'run_scheduled_repair',
        'reason': 'execution_constraint_repair_scheduled',
        'note': '执行约束风险已物化为队列内修订任务，下一步应先运行该修订再继续主链。',
        'task': repairTask,
        'status': ValueReaders.boolValue(scheduledRepair['created'])
            ? 'created'
            : 'duplicated',
        'safe_after_crash': true,
      };
    }
    return _successRecoveryPlan(
      nextStatus: nextStatus,
      gateOutcome: gateOutcome,
      checkpointReview: checkpointReview,
      waitingForUserChoice: waitingForUserChoice,
    );
  }

  JsonMap _successRecoveryPlan({
    required String nextStatus,
    required JsonMap gateOutcome,
    required JsonMap checkpointReview,
    required bool waitingForUserChoice,
  }) {
    final informationSignal = _informationSignal(checkpointReview);
    final informationCategory = ValueReaders.stringValue(
      informationSignal['category'],
    ).trim();
    final informationSummary = ValueReaders.stringValue(
      informationSignal['summary'],
    ).trim();
    if (informationCategory == 'manual_attention') {
      return <String, Object?>{
        'action': 'pause_for_manual_attention',
        'reason': ValueReaders.stringValue(
          informationSignal['reason'],
          'information_manual_attention',
        ),
        'note': informationSummary.isEmpty
            ? '信息层信号要求人工介入后再继续。'
            : informationSummary,
      };
    }
    if (informationCategory == 'repair') {
      return <String, Object?>{
        'action': 'pause_for_repair',
        'reason': ValueReaders.stringValue(
          informationSignal['reason'],
          'information_repair_required',
        ),
        'note': informationSummary.isEmpty
            ? '信息层信号要求先补研究、补上下文或修复资料链路。'
            : informationSummary,
      };
    }
    if (informationCategory == 'checkpoint_user') {
      return <String, Object?>{
        'action': 'resume_when_user_confirms',
        'reason': ValueReaders.stringValue(
          informationSignal['reason'],
          'information_waiting_user',
        ),
        'note': informationSummary.isEmpty
            ? '信息层信号要求先停在用户确认点。'
            : informationSummary,
      };
    }
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

  GenerateDraftUseCase _workflowGenerateDraftUseCase({
    required ProviderEndpointSettings provider,
    required AppSettings settings,
    HostToolPermissionContext? hostToolPermissionContextOverride,
  }) {
    final hostAwareFactory = _hostAwareGenerateDraftUseCaseFactory;
    if (hostAwareFactory == null) {
      return _generateDraftUseCaseFactory(provider, settings.networkSettings);
    }
    return hostAwareFactory(
      provider,
      settings.networkSettings,
      hostInformationPermissionContext:
          _informationPermissionSettingsResolverService.resolveFromAppSettings(
            settings,
            source: 'workflow_runtime.app_settings.permission_settings',
          ),
      hostToolPermissionContext:
          hostToolPermissionContextOverride ??
          _toolPermissionSettingsResolverService.resolveFromAppSettings(
            settings,
            source: 'workflow_runtime.app_settings.permission_settings',
          ),
    );
  }

  Future<HostToolPermissionContext?>
  _consumeWorkflowTaskToolPermissionOverride({
    required ProjectDescriptor project,
    required JsonMap task,
  }) async {
    final approvalId = ValueReaders.stringValue(
      task['selected_host_tool_permission_approval_id'],
    ).trim();
    if (approvalId.isEmpty) {
      return null;
    }
    final consumed = await _toolPermissionApprovalRecordService
        .consumeResolvedOverrideContext(project, approvalId: approvalId);
    if (!ValueReaders.boolValue(consumed['ok'])) {
      return null;
    }
    final contextJson = ValueReaders.mapValue(
      consumed['host_tool_permission_context'],
    );
    if (contextJson.isEmpty) {
      return null;
    }
    return HostToolPermissionContext.fromJson(contextJson);
  }

  DraftGenerationResult _resultWithExecutedTools(
    DraftGenerationResult source, {
    required List<Object?> executedTools,
  }) {
    return DraftGenerationResult(
      project: source.project,
      projectInfo: source.projectInfo,
      userPrompt: source.userPrompt,
      prompt: source.prompt,
      modelId: source.modelId,
      draftMarkdown: source.draftMarkdown,
      contextPack: source.contextPack,
      selectedPaths: source.selectedPaths,
      executedTools: List<Object?>.unmodifiable(executedTools),
      writtenPaths: source.writtenPaths,
      changedPaths: source.changedPaths,
      transcriptMessages: source.transcriptMessages,
      waitingForUserChoice: source.waitingForUserChoice,
      reasoningContent: source.reasoningContent,
      stoppedByToolError: source.stoppedByToolError,
      toolErrorSummary: source.toolErrorSummary,
      cancelledByUser: source.cancelledByUser,
      stopPhase: source.stopPhase,
      partialContentAccepted: source.partialContentAccepted,
    );
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

  Future<JsonMap> _persistExecutionOutputPaths({
    required ProjectDescriptor project,
    required String executionPath,
    required JsonMap executionRecord,
    required List<String> outputPaths,
  }) async {
    if (executionPath.trim().isEmpty || executionRecord.isEmpty) {
      return executionRecord;
    }
    final currentPaths = ValueReaders.stringList(
      executionRecord['output_paths'],
    );
    if (_samePathList(currentPaths, outputPaths)) {
      return executionRecord;
    }
    final nextExecution = ValueReaders.deepCopyMap(executionRecord)
      ..['output_paths'] = outputPaths;
    await _taskRepository.saveRecord(project, executionPath, nextExecution);
    return nextExecution;
  }

  bool _samePathList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
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

  List<Object?> _pendingUserOptionsFromExecutedTools(
    List<Object?> executedTools,
  ) {
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      final options = ValueReaders.objectList(result['options']);
      if (options.isEmpty) {
        continue;
      }
      final toolName = ValueReaders.stringValue(tool['name']);
      final supportsPendingSurface =
          toolName == 'present_user_options' ||
          ValueReaders.boolValue(result['waiting_for_user_choice']);
      if (!supportsPendingSurface) {
        continue;
      }
      final question = ValueReaders.stringValue(result['question']);
      return options
          .map(ValueReaders.mapValue)
          .where((entry) => entry.isNotEmpty)
          .map(
            (entry) => <String, Object?>{
              'label': ValueReaders.stringValue(
                entry['label'],
                ValueReaders.stringValue(
                  entry['title'],
                  ValueReaders.stringValue(entry['name'], '选项'),
                ),
              ),
              'description': ValueReaders.stringValue(
                entry['description'],
                ValueReaders.stringValue(
                  entry['detail'],
                  ValueReaders.stringValue(entry['summary']),
                ),
              ),
              'prompt': ValueReaders.stringValue(
                entry['prompt'],
                ValueReaders.stringValue(
                  entry['value'],
                  ValueReaders.stringValue(
                    entry['title'],
                    ValueReaders.stringValue(entry['label']),
                  ),
                ),
              ),
              'source_question': question,
              'approval_record_id': ValueReaders.stringValue(
                entry['approval_record_id'],
              ),
              'approval_option_id': ValueReaders.stringValue(
                entry['approval_option_id'],
              ),
            },
          )
          .toList(growable: false);
    }
    return const <Object?>[];
  }

  JsonMap _taskWithSelectedUserChoiceContext(JsonMap task) {
    final selectedPrompt = ValueReaders.stringValue(
      task['selected_user_option_prompt'],
    ).trim();
    if (selectedPrompt.isEmpty) {
      return task;
    }
    final selectedLabel = ValueReaders.stringValue(
      task['selected_user_option_label'],
    ).trim();
    final selectedDescription = ValueReaders.stringValue(
      task['selected_user_option_description'],
    ).trim();
    final selectedQuestion = ValueReaders.stringValue(
      task['selected_user_option_question'],
    ).trim();
    final originalBrief = ValueReaders.stringValue(task['brief']).trim();
    final continuationLines = <String>[
      if (originalBrief.isNotEmpty) originalBrief,
      '续跑补充：上轮这里停在用户选择点，用户现在已经给出明确确认。',
      if (selectedQuestion.isNotEmpty) '上轮问题：$selectedQuestion',
      if (selectedLabel.isNotEmpty) '用户所选方向：$selectedLabel',
      if (selectedDescription.isNotEmpty) '补充说明：$selectedDescription',
      '用户确认内容：$selectedPrompt',
      if (_isPlanningStageWorkflowTask(task))
        '当前任务仍处于 planning 阶段：只允许完善 specs/project_spec.md、outlines/story/总纲.md、outlines/chapters/章节任务清单.md 等规划产物；不要写 chapters/ 正文，不要写 tasks/*.json 任务文件，不要提交正式章节交付，也不要提前生成后续审稿任务。',
      '请吸收这个确认后继续推进当前任务，不要重复提出同一选择，除非出现新的真实阻塞。',
    ];
    return ValueReaders.deepCopyMap(task)
      ..['brief'] = continuationLines.join('\n\n');
  }

  JsonMap _taskWithResumeDispatchPromptAppendix(JsonMap task) {
    final appendix = ValueReaders.stringValue(
      task['resume_dispatch_prompt_appendix'],
    ).trim();
    if (appendix.isEmpty) {
      return task;
    }
    final originalBrief = ValueReaders.stringValue(task['brief']).trim();
    final continuationLines = <String>[
      if (originalBrief.isNotEmpty) originalBrief,
      appendix,
    ];
    return ValueReaders.deepCopyMap(task)
      ..['brief'] = continuationLines.join('\n\n');
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

  List<JsonMap> _workflowScopedTasks(List<JsonMap> tasks) {
    // 中文注释: 兼容旧调用点的薄包装，正式 workflow 选路已迁出到 ProjectWorkflowTaskSelectionService。
    return _workflowTaskSelectionService.workflowScopedTasks(tasks);
  }

  List<JsonMap> _workflowPrimaryTasks(List<JsonMap> tasks) {
    // 中文注释: 兼容旧调用点的薄包装，正式主链筛选已迁出到 ProjectWorkflowTaskSelectionService。
    return _workflowTaskSelectionService.workflowPrimaryTasks(tasks);
  }

  JsonMap _nextRunnablePrimaryTask({
    required List<JsonMap> primaryTasks,
    required List<JsonMap> allTasks,
  }) {
    // 中文注释: 兼容旧调用点的薄包装，主链下一步选择已迁出到专用 service。
    return _workflowTaskSelectionService.nextRunnablePrimaryTask(
      primaryTasks: primaryTasks,
      allTasks: allTasks,
    );
  }

  bool _belongsToWorkflowPlan(JsonMap task) {
    // 中文注释: 兼容旧调用点的薄包装，plan 边界判断已迁出到专用 service。
    return _workflowTaskSelectionService.belongsToWorkflowPlan(task);
  }

  bool _isRecognizedWorkflowPlanTask(JsonMap task) {
    // 中文注释: 兼容旧调用点的薄包装，recognition 规则已迁出到专用 service。
    return _workflowTaskSelectionService.isRecognizedWorkflowPlanTask(task);
  }

  bool _hasCanonicalWorkflowTaskPath(JsonMap task) {
    // 中文注释: 兼容旧调用点的薄包装，canonical 路径校验已迁出到专用 service。
    return _workflowTaskSelectionService.hasCanonicalWorkflowTaskPath(task);
  }

  bool _isDeferredCheckpointFollowupTask(JsonMap task) {
    // 中文注释: 兼容旧调用点的薄包装，follow-up 识别已迁出到专用 service。
    return _workflowTaskSelectionService.isDeferredCheckpointFollowupTask(task);
  }

  JsonMap _nextBlockingDeferredCheckpointFollowupTask(
    List<JsonMap> tasks, {
    required List<JsonMap> primaryTasks,
  }) {
    // 中文注释: 兼容旧调用点的薄包装，blocking follow-up 选择已迁出到专用 service。
    return _workflowTaskSelectionService
        .nextBlockingDeferredCheckpointFollowupTask(
          tasks,
          primaryTasks: primaryTasks,
        );
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
