import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import '../../../project_creation/application/controllers/project_creation_controller.dart';
import '../../presentation/contracts/document_workspace_action_handler.dart';
import '../../presentation/contracts/pending_research_action_handler.dart';
import '../../presentation/contracts/resource_manager_action_handler.dart';
import '../../presentation/models/conversation_agent_selector_view_data.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/project_create_request_view_data.dart';
import '../../presentation/models/conversation_group_selector_view_data.dart';
import '../../presentation/models/project_agent_group_workspace_view_data.dart';
import '../../presentation/models/selector_option_view_data.dart';
import '../../presentation/models/session_history_entry_view_data.dart';
import '../../presentation/models/sub_agent_run_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';
import '../../presentation/models/workbench_information_view_data.dart';
import '../../presentation/models/workbench_view_data.dart';
import 'generate_draft_use_case_factory.dart';
import '../models/open_document_state.dart';
import '../models/project_import_action_policy.dart';
import '../models/project_import_request.dart';
import '../models/workbench_project_runtime_state.dart';
import '../services/desktop_project_import_file_picker_service.dart';
import '../services/project_import_execution_service.dart';
import '../services/project_import_workspace_command_view_data_service.dart';
import '../services/project_long_task_summary_view_data_service.dart';
import '../services/project_subtitle_view_data_service.dart';
import '../services/project_type_transition_workspace_command_view_data_service.dart';
import '../services/workbench_draft_recovery_snapshot_service.dart';
import '../services/workspace_command_default_target_service.dart';
import '../services/workspace_information_projection_service.dart';
import '../services/workspace_primary_document_selection_service.dart';
import '../services/workspace_resource_display_service.dart';

part 'workbench_workspace_state_controller.dart';
part 'workbench_project_navigation_bridge.dart';
part 'workbench_project_action_facade.dart';

typedef WorkbenchProjectLongTaskDetailLoader =
    Future<ProjectLongTaskStationDetail> Function(RunInstance run);

class WorkbenchWorkspaceController
    implements
        ResourceManagerActionHandler,
        DocumentWorkspaceActionHandler,
        PendingResearchActionHandler {
  WorkbenchWorkspaceController({
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required ReadProjectFileUseCase readProjectFileUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required CreateProjectEntryUseCase createProjectEntryUseCase,
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    ExecuteProjectTypeTransitionUseCase? executeProjectTypeTransitionUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required LongTaskSupervisor longTaskSupervisor,
    required ProjectReviewReportService reviewReportService,
    required ProjectRuntimeProfileRepository projectRuntimeProfileRepository,
    required WorkbenchProjectRuntimeState Function() readProjectState,
    required void Function(WorkbenchProjectRuntimeState state)
    writeProjectState,
    required void Function() resetConversationRuntimeState,
    required Future<void> Function(ProjectDescriptor project)
    restoreConversationRuntimeState,
    required WorkbenchViewData Function() readWorkbench,
    required void Function(
      WorkbenchViewData Function(WorkbenchViewData current),
    )
    mutateWorkbench,
    required WorkbenchViewData Function(WorkbenchViewData base)
    applyConversationState,
    required AppSettings? Function() readSettings,
    required Future<void> Function(AppSettings nextSettings)
    saveSettingsSilently,
    required void Function() refreshSettingsViewData,
    required Future<void> Function() refreshAgentEcosystem,
    required Future<void> Function() refreshActiveDestinationAfterProjectLoad,
    required List<SelectorOptionViewData> Function(AppSettings settings)
    modelOptionsBuilder,
    required ProjectAgentGroupWorkspaceViewData? Function()
    readProjectAgentGroupWorkspaceViewData,
    required Future<ProjectAgentGroupWorkspaceViewData?> Function(
      String groupId,
    )
    selectProjectAgentGroup,
    required Future<void> Function() showSettings,
    required Future<void> Function() showAgentEcosystem,
    required Future<void> Function() showLongTaskStation,
    required Future<void> Function() showInspirationWorkbench,
    required Future<void> Function() showPromptTemplates,
    required Future<void> Function() showProjectAssets,
    required Future<void> Function() showProjectRagAssets,
    required Future<void> Function(String agentId) showCurrentAgentSkillLoadout,
    required Future<void> Function(String agentId)
    showCurrentAgentExpressionConstraints,
    required void Function(String message) announce,
    ProjectSubtitleViewDataService? projectSubtitleViewDataService,
    ProjectLongTaskSummaryViewDataService?
    projectLongTaskSummaryViewDataService,
    WorkspaceCommandDefaultTargetService? workspaceCommandDefaultTargetService,
    DesktopProjectImportFilePickerService?
    desktopProjectImportFilePickerService,
    ProjectImportWorkspaceCommandViewDataService?
    projectImportWorkspaceCommandViewDataService,
    ProjectImportExecutionService? projectImportExecutionService,
    WorkspaceInformationProjectionService?
    workspaceInformationProjectionService,
    WorkbenchDraftRecoverySnapshotService?
    workbenchDraftRecoverySnapshotService,
    ProjectPendingResearchActionService? pendingResearchActionService,
    WorkbenchProjectLongTaskDetailLoader? projectLongTaskDetailLoader,
  }) : _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _createProjectEntryUseCase = createProjectEntryUseCase,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _executeProjectTypeTransitionUseCase =
           executeProjectTypeTransitionUseCase,
       _longTaskSupervisor = longTaskSupervisor,
       _reviewReportService = reviewReportService,
       _projectRuntimeProfileRepository = projectRuntimeProfileRepository,
       _readProjectState = readProjectState,
       _writeProjectState = writeProjectState,
       _resetConversationRuntimeState = resetConversationRuntimeState,
       _restoreConversationRuntimeState = restoreConversationRuntimeState,
       _readWorkbench = readWorkbench,
       _mutateWorkbench = mutateWorkbench,
       _applyConversationState = applyConversationState,
       _readSettings = readSettings,
       _saveSettingsSilently = saveSettingsSilently,
       _refreshSettingsViewData = refreshSettingsViewData,
       _refreshAgentEcosystem = refreshAgentEcosystem,
       _refreshActiveDestinationAfterProjectLoad =
           refreshActiveDestinationAfterProjectLoad,
       _modelOptionsBuilder = modelOptionsBuilder,
       _readProjectAgentGroupWorkspaceViewData =
           readProjectAgentGroupWorkspaceViewData,
       _selectProjectAgentGroup = selectProjectAgentGroup,
       _showSettings = showSettings,
       _showAgentEcosystem = showAgentEcosystem,
       _showLongTaskStation = showLongTaskStation,
       _showInspirationWorkbench = showInspirationWorkbench,
       _showPromptTemplates = showPromptTemplates,
       _showProjectAssets = showProjectAssets,
       _showProjectRagAssets = showProjectRagAssets,
       _showCurrentAgentSkillLoadout = showCurrentAgentSkillLoadout,
       _showCurrentAgentExpressionConstraints =
           showCurrentAgentExpressionConstraints,
       _announce = announce,
       _entryAvailabilityPolicyService = const EntryAvailabilityPolicyService(),
       _projectSubtitleViewDataService =
           projectSubtitleViewDataService ?? ProjectSubtitleViewDataService(),
       _projectLongTaskSummaryViewDataService =
           projectLongTaskSummaryViewDataService ??
           const ProjectLongTaskSummaryViewDataService(),
       _workspaceCommandDefaultTargetService =
           workspaceCommandDefaultTargetService ??
           WorkspaceCommandDefaultTargetService(),
       _desktopProjectImportFilePickerService =
           desktopProjectImportFilePickerService ??
           const DesktopProjectImportFilePickerService(),
       _projectToolHostPort = projectToolHostPort,
       _projectImportWorkspaceCommandViewDataService =
           projectImportWorkspaceCommandViewDataService ??
           ProjectImportWorkspaceCommandViewDataService(),
       _projectImportExecutionService =
           projectImportExecutionService ??
           ProjectImportExecutionService(
             importProjectFilesUseCase: importProjectFilesUseCase,
             projectToolHostPort: projectToolHostPort,
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
             narrativePersistenceService: narrativePersistenceService,
             readSettings: readSettings,
             generateDraftUseCaseFactory: generateDraftUseCaseFactory,
           ),
       _workspaceInformationProjectionService =
           workspaceInformationProjectionService ??
           const WorkspaceInformationProjectionService(),
       _workbenchDraftRecoverySnapshotService =
           workbenchDraftRecoverySnapshotService ??
           const WorkbenchDraftRecoverySnapshotService(),
       _pendingResearchActionService = pendingResearchActionService,
       _projectLongTaskDetailLoader = projectLongTaskDetailLoader {
    _workspaceStateController = WorkbenchWorkspaceStateController(this);
    _projectNavigationBridge = WorkbenchProjectNavigationBridge(this);
    _projectActionFacade = WorkbenchProjectActionFacade(this);
  }

  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final CreateProjectEntryUseCase _createProjectEntryUseCase;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final ExecuteProjectTypeTransitionUseCase?
  _executeProjectTypeTransitionUseCase;
  final LongTaskSupervisor _longTaskSupervisor;
  final ProjectReviewReportService _reviewReportService;
  final ProjectRuntimeProfileRepository _projectRuntimeProfileRepository;
  final WorkbenchProjectRuntimeState Function() _readProjectState;
  final void Function(WorkbenchProjectRuntimeState state) _writeProjectState;
  final void Function() _resetConversationRuntimeState;
  final Future<void> Function(ProjectDescriptor project)
  _restoreConversationRuntimeState;
  final WorkbenchViewData Function() _readWorkbench;
  final void Function(WorkbenchViewData Function(WorkbenchViewData current))
  _mutateWorkbench;
  final WorkbenchViewData Function(WorkbenchViewData base)
  _applyConversationState;
  final AppSettings? Function() _readSettings;
  final Future<void> Function(AppSettings nextSettings) _saveSettingsSilently;
  final void Function() _refreshSettingsViewData;
  final Future<void> Function() _refreshAgentEcosystem;
  final Future<void> Function() _refreshActiveDestinationAfterProjectLoad;
  final List<SelectorOptionViewData> Function(AppSettings settings)
  _modelOptionsBuilder;
  final ProjectAgentGroupWorkspaceViewData? Function()
  _readProjectAgentGroupWorkspaceViewData;
  final Future<ProjectAgentGroupWorkspaceViewData?> Function(String groupId)
  _selectProjectAgentGroup;
  final Future<void> Function() _showSettings;
  final Future<void> Function() _showAgentEcosystem;
  final Future<void> Function() _showLongTaskStation;
  final Future<void> Function() _showInspirationWorkbench;
  final Future<void> Function() _showPromptTemplates;
  final Future<void> Function() _showProjectAssets;
  final Future<void> Function() _showProjectRagAssets;
  final Future<void> Function(String agentId) _showCurrentAgentSkillLoadout;
  final Future<void> Function(String agentId)
  _showCurrentAgentExpressionConstraints;
  final void Function(String message) _announce;
  final EntryAvailabilityPolicyService _entryAvailabilityPolicyService;
  final ProjectSubtitleViewDataService _projectSubtitleViewDataService;
  final ProjectLongTaskSummaryViewDataService
  _projectLongTaskSummaryViewDataService;
  final ProjectToolHostPort _projectToolHostPort;
  final WorkspaceCommandDefaultTargetService
  _workspaceCommandDefaultTargetService;
  final DesktopProjectImportFilePickerService
  _desktopProjectImportFilePickerService;
  final ProjectImportWorkspaceCommandViewDataService
  _projectImportWorkspaceCommandViewDataService;
  final ProjectImportExecutionService _projectImportExecutionService;
  final WorkspaceInformationProjectionService
  _workspaceInformationProjectionService;
  final WorkbenchDraftRecoverySnapshotService
  _workbenchDraftRecoverySnapshotService;
  final ProjectPendingResearchActionService? _pendingResearchActionService;
  final WorkbenchProjectLongTaskDetailLoader? _projectLongTaskDetailLoader;
  Timer? _workbenchSnapshotDebounceTimer;
  bool _pendingWorkbenchSnapshotNeedsDraftRecoveries = false;
  final WorkspaceResourceDisplayService _workspaceResourceDisplayService =
      const WorkspaceResourceDisplayService();
  final WorkspacePrimaryDocumentSelectionService
  _workspacePrimaryDocumentSelectionService =
      const WorkspacePrimaryDocumentSelectionService();
  final ProjectTypeTransitionPreparationService
  _projectTypeTransitionPreparationService =
      const ProjectTypeTransitionPreparationService();
  final ProjectTypeTransitionWorkspaceCommandViewDataService
  _projectTypeTransitionCommandViewDataService =
      ProjectTypeTransitionWorkspaceCommandViewDataService();
  WorkbenchInformationViewData _latestInformationViewData =
      const WorkbenchInformationViewData();

  late final WorkbenchWorkspaceStateController _workspaceStateController;
  late final WorkbenchProjectNavigationBridge _projectNavigationBridge;
  late final WorkbenchProjectActionFacade _projectActionFacade;

  ProjectCreationController? _projectCreationController;

  void attachProjectCreationController(ProjectCreationController controller) {
    // 中文注释: 项目创建控制器后挂载，避免工作台与项目创建之间出现构造环依赖。
    _projectCreationController = controller;
  }

  ProjectDescriptor? get currentProject => _readProjectState().currentProject;

  ProjectRuntimeProfile? get currentProjectRuntimeProfile =>
      _readProjectState().currentRuntimeProfile;

  WorkbenchProjectRuntimeState get currentProjectRuntimeState =>
      _readProjectState();

  JsonMap currentProjectInfo() {
    // 中文注释: 会话与主动作需要轻量项目摘要，继续由状态层统一输出。
    return _workspaceStateController.currentProjectInfo();
  }

  String get activeDocumentPath => _workspaceStateController.activeDocumentPath;

  String get activeDocumentBody => _workspaceStateController.activeDocumentBody;

  OpenDocumentState? activeOpenDocument() =>
      _workspaceStateController.activeOpenDocument();

  Future<void> openResource(String relativePath) async {
    // 中文注释: 资源打开入口继续交给状态层，只保留受控的公开方法。
    await _workspaceStateController.openResource(relativePath);
  }

  Future<void> saveCurrentDocument() async {
    // 中文注释: 活动文档保存只属于状态层。
    await _workspaceStateController.saveCurrentDocument();
  }

  bool stageGeneratedDraftOnActiveDocument(String content) {
    // 中文注释: 普通会话 fallback 仍然只能暂存到当前文档。
    return _workspaceStateController.stageGeneratedDraftOnActiveDocument(
      content,
    );
  }

  WorkbenchViewData applyWorkbenchState(WorkbenchViewData base) {
    // 中文注释: 工作台文档与资源树投影统一由状态层生成。
    return _projectedWorkbenchState(base);
  }

  Future<bool> loadProject(String rootPath) async {
    // 中文注释: 工作区项目加载只负责把有效快照转成工作台运行时状态，不再决定是否弹创建向导。
    _mutateWorkbench(
      (current) =>
          current.copyWith(generationStatus: '正在加载项目...', toolCoreStatus: ''),
    );
    final snapshot = await _loadProjectWorkspaceUseCase.execute(rootPath);
    if (snapshot == null) {
      _writeProjectState(
        _readProjectState().copyWith(
          currentProject: null,
          currentRuntimeProfile: null,
          resourceSnapshotEntries: const <JsonMap>[],
          expandedResourceDirectories: <String>{},
          openDocuments: const <OpenDocumentState>[],
          activeOpenDocumentId: '',
          currentProjectLongTaskRuns: const <RunInstance>[],
          currentProjectLongTaskRunDetails:
              const <String, ProjectLongTaskStationDetail>{},
          isProjectLongTaskSummaryLoading: false,
        ),
      );
      _resetConversationRuntimeState();
      _refreshSettingsViewData();
      return false;
    }

    final loadWarnings = <String>[];
    final runtimeProfile = await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '运行时配置恢复',
      action: () => _projectRuntimeProfileRepository.load(snapshot.project),
      fallback: () => null,
    );

    _writeProjectState(
      _readProjectState().copyWith(
        currentProject: snapshot.project,
        currentRuntimeProfile: runtimeProfile,
        resourceSnapshotEntries: snapshot.entries,
        expandedResourceDirectories: _defaultExpandedDirectories(
          snapshot.entries,
        ),
        openDocuments: const <OpenDocumentState>[],
        activeOpenDocumentId: '',
        currentProjectLongTaskRuns: const <RunInstance>[],
        currentProjectLongTaskRunDetails:
            const <String, ProjectLongTaskStationDetail>{},
        isProjectLongTaskSummaryLoading: true,
      ),
    );
    _resetConversationRuntimeState();
    await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '会话恢复',
      action: () => _restoreConversationRuntimeState(snapshot.project),
      fallback: () {},
    );
    _latestInformationViewData = await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '资料面板恢复',
      action: () =>
          _buildInformationViewData(snapshot.project, snapshot.entries),
      fallback: () => const WorkbenchInformationViewData(),
    );
    var workbench = _readWorkbench().copyWith(
      projectName: snapshot.project.name,
      projectSubtitle: _projectSubtitleViewDataService.build(
        snapshot.project,
        runtimeProfile: runtimeProfile,
      ),
      projectPath: snapshot.project.rootPath,
      projectTypeId: snapshot.project.projectType,
      projectTypeTransitionAvailability: _projectTypeTransitionAvailabilityFor(
        snapshot.project,
      ),
      toolCoreStatus: '',
      modelOptions: _readSettings() == null
          ? _readWorkbench().modelOptions
          : _modelOptionsBuilder(_readSettings()!),
      groupSelector: const ConversationGroupSelectorViewData.initial(),
      agentSelector: const ConversationAgentSelectorViewData.initial(),
      resourceEntries: _markResourceSelection(
        _resourceEntriesFrom(snapshot.entries),
        selectedId: '',
      ),
      informationViewData: _latestInformationViewData,
      contextSummary: '资源 ${snapshot.entries.length} 项',
      generationStatus: '',
      documents: const <DocumentTabViewData>[],
      activeDocumentTitle: '',
      activeDocumentPath: '',
      activeDocumentBody: '',
      activeDocumentDirty: false,
      activeDocumentBufferedDraft: false,
      projectLauncher: null,
      projectAgentGroupWorkspace: null,
      workspaceCommand: null,
      isGenerating: false,
      isDocumentsWorkspaceVisible: false,
    );
    final firstOpenable = _firstOpenablePath(snapshot.entries);
    if (firstOpenable.trim().isNotEmpty) {
      _expandResourceAncestors(firstOpenable);
      final content = await _readProjectFileUseCase.execute(
        snapshot.project,
        firstOpenable,
      );
      if (content != null && content.trim().isNotEmpty) {
        openOrActivateDocument(
          relativePath: firstOpenable,
          title: _displayNameOf(firstOpenable),
          content: content,
        );
        workbench = applyWorkbenchState(
          workbench.copyWith(
            resourceEntries: _markResourceSelection(
              workbench.resourceEntries,
              selectedId: firstOpenable,
            ),
            generationStatus: '已打开 $firstOpenable',
          ),
        );
      }
    }
    _refreshSettingsViewData();
    workbench = _applyConversationStateSafely(
      workbench,
      warnings: loadWarnings,
    );
    _mutateWorkbench((_) => workbench);
    await _persistLastProjectPath(snapshot.project.rootPath);
    await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '智能体生态刷新',
      action: _refreshAgentEcosystem,
      fallback: () {},
    );
    await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '工作台快照恢复',
      action: () => restoreWorkbenchSnapshot(snapshot.project),
      fallback: () {},
    );
    await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '长任务摘要刷新',
      action: refreshProjectLongTaskSummary,
      fallback: () {},
    );
    await _runNonFatalProjectLoadStage(
      warnings: loadWarnings,
      stageLabel: '目标页刷新',
      action: _refreshActiveDestinationAfterProjectLoad,
      fallback: () {},
    );
    if (loadWarnings.isNotEmpty) {
      final summary = _summarizeProjectLoadWarnings(loadWarnings);
      _mutateWorkbench(
        (current) => current.copyWith(generationStatus: summary),
      );
      _announce(summary);
    }
    return true;
  }

  WorkbenchViewData _projectedWorkbenchState(WorkbenchViewData base) {
    final state = _readProjectState();
    final activeDocument = _activeOpenDocument();
    final selectedResourceId = _selectedResourceIdForProjection(
      base: base,
      activeDocument: activeDocument,
    );
    return base.copyWith(
      projectLongTaskSummary: _projectLongTaskSummaryViewDataService.build(
        project: state.currentProject,
        runs: state.currentProjectLongTaskRuns,
        runDetails: state.currentProjectLongTaskRunDetails,
        isLoading: state.isProjectLongTaskSummaryLoading,
      ),
      documents: _documentTabsFromState(state),
      resourceEntries: _markResourceSelection(
        _resourceEntriesFrom(state.resourceSnapshotEntries),
        selectedId: selectedResourceId,
      ),
      informationViewData: _latestInformationViewData,
      activeDocumentTitle: activeDocument?.title ?? '',
      activeDocumentPath: activeDocument?.relativePath ?? '',
      activeDocumentBody: activeDocument?.content ?? '',
      activeDocumentDirty: activeDocument?.isDirty ?? false,
      activeDocumentBufferedDraft: activeDocument?.isBufferedDraft ?? false,
      activeDocumentCanRender: activeDocument?.canRender ?? false,
      isActiveDocumentRendered: activeDocument?.isRendered ?? false,
      isDocumentsWorkspaceVisible:
          activeDocument != null || state.openDocuments.isNotEmpty,
    );
  }

  List<DocumentTabViewData> _documentTabsFromState(
    WorkbenchProjectRuntimeState state,
  ) {
    return state.openDocuments
        .map(
          (document) => DocumentTabViewData(
            id: document.id,
            title: document.title,
            relativePath: document.relativePath,
            tooltip: document.relativePath,
            isActive: document.id == state.activeOpenDocumentId,
            isDirty: document.isDirty,
          ),
        )
        .toList(growable: false);
  }

  String _selectedResourceIdForProjection({
    required WorkbenchViewData base,
    required OpenDocumentState? activeDocument,
  }) {
    final activeDocumentPath = activeDocument?.relativePath.trim() ?? '';
    if (activeDocumentPath.isNotEmpty) {
      return activeDocumentPath;
    }
    for (final entry in base.resourceEntries) {
      if (entry.isSelected) {
        return entry.id;
      }
    }
    return '';
  }

  Future<T> _runNonFatalProjectLoadStage<T>({
    required List<String> warnings,
    required String stageLabel,
    required Future<T> Function() action,
    required T Function() fallback,
  }) async {
    try {
      return await action();
    } catch (error) {
      warnings.add('$stageLabel失败：$error');
      return fallback();
    }
  }

  WorkbenchViewData _applyConversationStateSafely(
    WorkbenchViewData base, {
    required List<String> warnings,
  }) {
    try {
      return _applyConversationState(base);
    } catch (error) {
      warnings.add('会话面板初始化失败：$error');
      return _buildConversationFallbackWorkbench(base);
    }
  }

  WorkbenchViewData _buildConversationFallbackWorkbench(
    WorkbenchViewData base,
  ) {
    return base.copyWith(
      openingPanel: null,
      openingState: null,
      conversationEntries: const <ConversationEntryViewData>[],
      pendingOptions: const <UserOptionViewData>[],
      subAgentRuns: const <SubAgentRunViewData>[],
      retryRequest: null,
      sessionHistoryEntries: const <SessionHistoryEntryViewData>[],
      activeSessionId: '',
      showSessionHistory: false,
      sessionRestoreResult: null,
      conversationContextProjection: null,
      contextSummary: '项目已打开，会话面板已降级为安全视图。',
      workflowDescription: '会话运行时恢复失败，请重新开始一个新会话或稍后再试。',
    );
  }

  String _summarizeProjectLoadWarnings(List<String> warnings) {
    final details = warnings.take(2).join('；');
    final suffix = warnings.length > 2 ? ' 等 ${warnings.length} 项问题' : '';
    return '项目已打开，但部分界面状态未完全恢复：$details$suffix';
  }

  Future<void> refreshProjectLongTaskSummary() async {
    final project = currentProject;
    if (project == null) {
      _writeProjectState(
        _readProjectState().copyWith(
          currentProjectLongTaskRuns: const <RunInstance>[],
          currentProjectLongTaskRunDetails:
              const <String, ProjectLongTaskStationDetail>{},
          isProjectLongTaskSummaryLoading: false,
        ),
      );
      _mutateWorkbench((current) => applyWorkbenchState(current));
      return;
    }
    _writeProjectState(
      _readProjectState().copyWith(isProjectLongTaskSummaryLoading: true),
    );
    _mutateWorkbench((current) => applyWorkbenchState(current));
    try {
      final runs = await _longTaskSupervisor.listProjectRuns(project.rootPath);
      final runDetails = await _loadProjectLongTaskRunDetails(runs);
      _writeProjectState(
        _readProjectState().copyWith(
          currentProjectLongTaskRuns: runs,
          currentProjectLongTaskRunDetails: runDetails,
          isProjectLongTaskSummaryLoading: false,
        ),
      );
    } catch (_) {
      _writeProjectState(
        _readProjectState().copyWith(
          currentProjectLongTaskRunDetails:
              const <String, ProjectLongTaskStationDetail>{},
          isProjectLongTaskSummaryLoading: false,
        ),
      );
    }
    _mutateWorkbench((current) => applyWorkbenchState(current));
  }

  Future<Map<String, ProjectLongTaskStationDetail>>
  _loadProjectLongTaskRunDetails(List<RunInstance> runs) async {
    final loader = _projectLongTaskDetailLoader;
    if (loader == null || runs.isEmpty) {
      return const <String, ProjectLongTaskStationDetail>{};
    }
    final loadedEntries = await Future.wait(
      runs.map((run) async {
        try {
          final detail = await loader(run);
          return MapEntry(run.id, detail);
        } catch (_) {
          return null;
        }
      }),
    );
    final result = <String, ProjectLongTaskStationDetail>{};
    for (final entry in loadedEntries) {
      if (entry != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  void resetToProjectlessWorkbench({required String status}) {
    // 中文注释: 无项目工作区重置只清空工作台相关状态，不触碰其他 feature 的独立状态。
    _latestInformationViewData = const WorkbenchInformationViewData();
    _writeProjectState(
      _readProjectState().copyWith(
        currentProject: null,
        currentRuntimeProfile: null,
        resourceSnapshotEntries: const <JsonMap>[],
        expandedResourceDirectories: <String>{},
        openDocuments: const <OpenDocumentState>[],
        activeOpenDocumentId: '',
        currentProjectLongTaskRuns: const <RunInstance>[],
        currentProjectLongTaskRunDetails:
            const <String, ProjectLongTaskStationDetail>{},
        isProjectLongTaskSummaryLoading: false,
      ),
    );
    _resetConversationRuntimeState();
    _mutateWorkbench(
      (current) => _applyConversationState(
        current.copyWith(
          projectName: '',
          projectSubtitle: '',
          projectPath: '',
          projectTypeId: '',
          resourceEntries: const [],
          informationViewData: const WorkbenchInformationViewData(),
          documents: const <DocumentTabViewData>[],
          activeDocumentTitle: '',
          activeDocumentPath: '',
          activeDocumentBody: '',
          activeDocumentDirty: false,
          activeDocumentBufferedDraft: false,
          generationStatus: status,
          contextSummary: '尚未打开项目',
          toolCoreStatus: '',
          projectLongTaskSummary: null,
          projectAgentGroupWorkspace: null,
          groupSelector: const ConversationGroupSelectorViewData.initial(),
          agentSelector: const ConversationAgentSelectorViewData.initial(),
          isGenerating: false,
          workspaceCommand: null,
          isDocumentsWorkspaceVisible: false,
        ),
      ),
    );
  }

  Future<List<ResourceEntryViewData>> reloadResourceEntries({
    required String selectedId,
  }) async {
    // 中文注释: 资源树刷新统一重走共享项目加载用例，保证界面和真实工作区一致。
    final project = currentProject;
    if (project == null) {
      return _readWorkbench().resourceEntries;
    }
    final snapshot = await _loadProjectWorkspaceUseCase.execute(
      project.rootPath,
    );
    if (snapshot == null) {
      return _readWorkbench().resourceEntries;
    }
    _writeProjectState(
      _readProjectState().copyWith(
        resourceSnapshotEntries: snapshot.entries,
        expandedResourceDirectories: _mergedExpandedDirectories(
          entries: snapshot.entries,
          selectedId: selectedId,
        ),
      ),
    );
    _latestInformationViewData = await _buildInformationViewData(
      snapshot.project,
      snapshot.entries,
    );
    return _markResourceSelection(
      _resourceEntriesFrom(snapshot.entries),
      selectedId: selectedId,
    );
  }

  Future<WorkbenchInformationViewData> _buildInformationViewData(
    ProjectDescriptor project,
    List<JsonMap> workspaceEntries,
  ) async {
    final entryByPath = <String, JsonMap>{};
    for (final entry in workspaceEntries) {
      final relativePath = _normalizeRelativePath(
        _stringValue(entry['relative_path']),
      );
      if (relativePath.isEmpty) {
        continue;
      }
      entryByPath[relativePath] = ValueReaders.deepCopyMap(entry);
    }

    for (final entry in await _scanInformationSupportEntries(
      project.rootPath,
    )) {
      final relativePath = _normalizeRelativePath(
        _stringValue(entry['relative_path']),
      );
      if (relativePath.isEmpty) {
        continue;
      }
      entryByPath[relativePath] = entry;
    }

    final fileContents = <String, String>{};
    for (final path in entryByPath.keys.toList()..sort()) {
      if (!_shouldReadInformationProjectionFile(path)) {
        continue;
      }
      final content = await _projectToolHostPort.readTextFile(
        project.rootPath,
        path,
      );
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      fileContents[path] = content!;
    }

    return _workspaceInformationProjectionService.build(
      workspaceEntries: entryByPath.values.toList(growable: false),
      fileContents: fileContents,
    );
  }

  Future<String> resolvedDocumentBody({
    required ProjectDescriptor project,
    required String generatedMarkdown,
    required String relativePath,
  }) async {
    // 中文注释: 工具直接落盘时，这里兜底读取真实文件内容给正文区展示。
    if (generatedMarkdown.trim().isNotEmpty) {
      return generatedMarkdown;
    }
    if (relativePath.trim().isEmpty) {
      return '';
    }
    final content = await _readProjectFileUseCase.execute(
      project,
      relativePath,
    );
    return content ?? '';
  }

  void openOrActivateDocument({
    required String relativePath,
    required String title,
    required String content,
  }) {
    // 中文注释: 文档打开与激活统一维护打开标签集合，避免不同入口生成重复文档标签。
    final documentId = relativePath.trim();
    final state = _readProjectState();
    final existingIndex = state.openDocuments.indexWhere(
      (document) => document.id == documentId,
    );
    final nextDocuments = List<OpenDocumentState>.from(state.openDocuments);
    if (existingIndex >= 0) {
      nextDocuments[existingIndex] = nextDocuments[existingIndex].copyWith(
        title: title,
        relativePath: relativePath,
        content: content,
        isDirty: false,
        isRendered: false,
        isBufferedDraft: false,
      );
    } else {
      nextDocuments.add(
        OpenDocumentState(
          id: documentId,
          title: title,
          relativePath: relativePath,
          content: content,
        ),
      );
    }
    _writeProjectState(
      state.copyWith(
        openDocuments: nextDocuments,
        activeOpenDocumentId: documentId,
      ),
    );
  }

  Future<void> restoreWorkbenchSnapshot(ProjectDescriptor project) async {
    // 中文注释: 工作台快照恢复只恢复文档和资源树显隐，不重新发起生成或改写会话记录。
    final settings = _readSettings();
    if (settings == null) {
      return;
    }
    final snapshot = _mapValue(settings.extraSettings['workbench_state']);
    if (_normalizePathForCompare(_stringValue(snapshot['project_root_path'])) !=
        _normalizePathForCompare(project.rootPath)) {
      return;
    }
    final knownDirectoryPaths = _readProjectState().resourceSnapshotEntries
        .where((entry) => entry['is_dir'] == true)
        .map((entry) => _stringValue(entry['relative_path']))
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final expandedDirectories = ValueReaders.stringList(
      snapshot['expanded_directories'],
    ).where(knownDirectoryPaths.contains).toSet();
    _writeProjectState(
      _readProjectState().copyWith(
        expandedResourceDirectories: expandedDirectories,
      ),
    );
    _mutateWorkbench(
      (current) => current.copyWith(
        resourceEntries: _markResourceSelection(
          _resourceEntriesFrom(_readProjectState().resourceSnapshotEntries),
          selectedId: '',
        ),
        informationViewData: _latestInformationViewData,
        agentSelector: current.agentSelector.copyWith(
          currentAgentId: _stringValue(
            snapshot['selected_conversation_agent_id'],
          ),
        ),
      ),
    );
    final activeDocumentPath = _stringValue(snapshot['active_document_path']);
    final parsedRecoveries = _workbenchDraftRecoverySnapshotService
        .parseRecoveries(snapshot['draft_recoveries']);
    for (final recovery in parsedRecoveries) {
      final relativePath = ValueReaders.stringValue(recovery['relative_path']);
      if (relativePath == activeDocumentPath) {
        continue;
      }
      _restoreRecoveredDocument(recovery);
    }
    if (_shouldRestoreWorkbenchDocument(activeDocumentPath)) {
      final activeRecovery = _workbenchDraftRecoverySnapshotService
          .recoveryForPath(parsedRecoveries, activeDocumentPath);
      if (activeRecovery != null) {
        _restoreRecoveredDocument(activeRecovery);
      } else {
        final content = await _readProjectFileUseCase.execute(
          project,
          activeDocumentPath,
        );
        if (content == null) {
          return;
        }
        openOrActivateDocument(
          relativePath: activeDocumentPath,
          title: _displayNameOf(activeDocumentPath),
          content: content,
        );
      }
    } else if (parsedRecoveries.isNotEmpty) {
      _restoreRecoveredDocument(parsedRecoveries.last);
    } else {
      return;
    }
    final restoredActivePath = _readWorkbench().activeDocumentPath.trim();
    final recoveredCount = _readProjectState().openDocuments
        .where((document) => document.isDirty)
        .length;
    _mutateWorkbench(
      (current) => applyWorkbenchState(
        current.copyWith(
          resourceEntries: _markResourceSelection(
            _resourceEntriesFrom(_readProjectState().resourceSnapshotEntries),
            selectedId: restoredActivePath,
          ),
          informationViewData: _latestInformationViewData,
          generationStatus: recoveredCount > 0
              ? '已恢复 $recoveredCount 个未正式保存的草稿。'
              : current.generationStatus,
        ),
      ),
    );
  }

  @override
  void onModelSettingsRequested() {
    // 中文注释: 资源区顶部模型入口只负责跳到设置页，不在工作区里再造一份设置逻辑。
    _showSettings();
  }

  @override
  void onCreateProjectRequested() {
    // 中文注释: 项目创建动作委派给专用控制器，避免工作区控制器再长创建向导状态机。
    _projectNavigationBridge.onCreateProjectRequested();
  }

  @override
  void onOpenProjectRequested() {
    // 中文注释: 打开已有项目同样委派给项目创建控制器，保持“项目入口”职责单点收束。
    _projectNavigationBridge.onOpenProjectRequested();
  }

  @override
  void onProjectLauncherDismissed() {
    // 中文注释: 启动器弹层生命周期完全交给项目创建控制器。
    _projectNavigationBridge.onProjectLauncherDismissed();
  }

  @override
  void onProjectLauncherRefreshRequested() {
    // 中文注释: 启动器列表刷新继续由项目创建控制器统一处理。
    _projectNavigationBridge.onProjectLauncherRefreshRequested();
  }

  @override
  void onProjectEntryOpened(String projectPath) {
    // 中文注释: 从项目列表选中项目时，工作区只做委派，不重写选择逻辑。
    _projectNavigationBridge.onProjectEntryOpened(projectPath);
  }

  @override
  void onProjectCreationBackRequested() {
    // 中文注释: 创建向导的返回动作继续委派给项目创建控制器，工作区不介入阶段状态机。
    _projectNavigationBridge.onProjectCreationBackRequested();
  }

  @override
  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) {
    // 中文注释: 项目创建表单提交继续由创建控制器处理，工作区层不再理解运行基准判断。
    _projectNavigationBridge.onProjectCreationSubmitted(request);
  }

  @override
  void onEditProjectInfoRequested() {
    // 中文注释: 项目信息编辑只负责弹出工作区命令，不直接改项目文件。
    final project = currentProject;
    _showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.editProjectInfo,
        title: '编辑项目信息',
        description: '更新项目标题、类型与简介文档。',
        confirmLabel: '保存项目',
        status: project == null ? '当前还没有打开项目。' : '',
        projectTitle: project?.name ?? '',
        projectType: project?.projectType ?? 'novel',
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  @override
  void onProjectTypeTransitionRequested() {
    // 中文注释: 项目类型转换入口先基于 core 计划投影出 blocker，再让用户在同一命令层完成确认。
    _projectActionFacade.onProjectTypeTransitionRequested();
  }

  @override
  void onRefreshFilesRequested() {
    // 中文注释: 刷新工作区时优先重载当前项目；如果还没有项目，则走默认项目恢复链。
    _projectActionFacade.onRefreshFilesRequested();
  }

  @override
  void onCreateFileRequested() {
    // 中文注释: 文件创建继续统一落到工作区命令表单，后续 CLI 也能共用同一用例。
    _projectActionFacade.onCreateFileRequested();
  }

  @override
  void onCreateFolderRequested() {
    // 中文注释: 新建文件夹与新建文件共用命令面板，减少壳层表单散落。
    _projectActionFacade.onCreateFolderRequested();
  }

  @override
  void onImportRequested() {
    // 中文注释: 导入入口统一走共享命令构建服务，项目类型差异留给策略层处理。
    _projectActionFacade.onImportRequested();
  }

  @override
  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    _projectActionFacade.onWorkspaceImportDirectoryPickRequested(request);
  }

  @override
  void onCreateChapterRequested() {
    // 中文注释: 当前章节创建仍走自然语言发送链，这里只给统一提示，不偷偷生成空稿。
    _announce('直接在右侧输入章节需求并发送；正式章节需由工具链提交，普通回复只会暂存为当前文档草稿。');
  }

  @override
  void onSaveCurrentRequested() {
    // 中文注释: 工具栏保存统一收口到当前工作区活动文档。
    _projectActionFacade.onSaveCurrentRequested();
  }

  @override
  void onProjectAgentGroupRequested() {
    // 中文注释: 项目级智能体组入口必须在任意已打开项目下稳定可达，因此这里直接打开正式配置浮层。
    _projectActionFacade.onProjectAgentGroupRequested();
  }

  @override
  void onProjectAgentGroupDismissed() {
    // 中文注释: 项目级组配置浮层关闭只清理当前 overlay 状态，不影响会话和资源区。
    _projectActionFacade.onProjectAgentGroupDismissed();
  }

  @override
  void onProjectAgentGroupSelected(String groupId) {
    // 中文注释: 组切换属于项目级协作基线变更，因此这里统一走共享选择链并在成功后刷新浮层内容。
    _projectActionFacade.onProjectAgentGroupSelected(groupId);
  }

  @override
  void onAgentEcosystemRequested() {
    // 中文注释: 工作区只发起全局导航请求，不直接操作生态页数据。
    _projectNavigationBridge.onAgentEcosystemRequested();
  }

  @override
  void onCurrentAgentSkillLoadoutRequested() {
    _projectNavigationBridge.onCurrentAgentSkillLoadoutRequested();
  }

  @override
  void onTasksRequested() {
    // 中文注释: 历史任务入口统一折返到长任务总站，工作台内不再保留第二套任务空间。
    _projectNavigationBridge.onTasksRequested();
  }

  void onLongTaskStationRequested() {
    // 中文注释: 长任务总站入口不再混进工作区自身状态机。
    _projectNavigationBridge.onLongTaskStationRequested();
  }

  @override
  void onReviewsRequested() {
    // 中文注释: 历史审稿入口同样折返到总站，具体结果查看回到工作台文件区。
    _projectNavigationBridge.onReviewsRequested();
  }

  @override
  void onTemplatesRequested() {
    // 中文注释: 模板页导航只发起全局切页请求，不带模板业务规则。
    _projectNavigationBridge.onTemplatesRequested();
  }

  @override
  void onProjectAssetsRequested() {
    // 中文注释: 项目资产页作为独立子域入口，从工作区只保留跳转动作。
    _projectNavigationBridge.onProjectAssetsRequested();
  }

  @override
  void onProjectRagRequested() {
    _projectNavigationBridge.onProjectRagRequested();
  }

  @override
  void onCurrentAgentExpressionConstraintsRequested() {
    _projectNavigationBridge.onCurrentAgentExpressionConstraintsRequested();
  }

  void onInspirationWorkbenchRequested() {
    // 中文注释: 灵感工作台从资源区独立进入，工作区只负责发起导航，不参与其状态机。
    _projectNavigationBridge.onInspirationWorkbenchRequested();
  }

  @override
  void onResourceEntrySelected(String entryId) {
    // 中文注释: 资源树点击统一走真实工作区读取链，避免 widget 直接读文件。
    _projectActionFacade.onResourceEntrySelected(entryId);
  }

  @override
  Future<void> onPendingResearchApproved(String requestId) async {
    await _projectActionFacade.onPendingResearchApproved(requestId);
  }

  @override
  Future<void> onPendingResearchRejected(String requestId) async {
    await _projectActionFacade.onPendingResearchRejected(requestId);
  }

  @override
  void onWorkspaceCommandDismissed() {
    // 中文注释: 工作区命令关闭只清理弹层状态，不触碰项目本身。
    _projectActionFacade.onWorkspaceCommandDismissed();
  }

  @override
  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    _projectActionFacade.onWorkspaceImportFilesPickRequested(request);
  }

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    // 中文注释: 工作区命令统一在这里分派到共享用例，界面层不直接碰业务依赖。
    _projectActionFacade.onWorkspaceCommandSubmitted(request);
  }

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    // 中文注释: 文档动作统一落到工作区控制器，保证文档标签、资源树和任务动作一起演进。
    _projectActionFacade.onDocumentActionRequested(action);
  }

  @override
  void onDocumentSelected(String documentId) {
    // 中文注释: 标签切换只修改活动文档指针，不产生读盘副作用。
    _projectActionFacade.onDocumentSelected(documentId);
  }

  @override
  void onDocumentClosed(String documentId) {
    // 中文注释: 关闭标签只变更内存态，保存行为仍旧必须显式触发。
    _projectActionFacade.onDocumentClosed(documentId);
  }

  @override
  void onDocumentBodyChanged(String value) {
    // 中文注释: 文本编辑只变更活动文档内容和脏标记，不在输入时做任何持久化。
    _projectActionFacade.onDocumentBodyChanged(value);
  }

  Future<void> _openResource(String relativePath) async {
    // 中文注释: 资源树点击先判断目录折叠，只有文本文件才进入打开链。
    final project = currentProject;
    if (project == null) {
      _announce('项目尚未加载完成。');
      return;
    }
    final selectedEntry = _resourceEntryById(relativePath);
    if (selectedEntry != null && selectedEntry.isDirectory) {
      _toggleResourceDirectory(relativePath);
      return;
    }
    _expandResourceAncestors(relativePath);
    final content = await _readProjectFileUseCase.execute(
      project,
      relativePath,
    );
    if (content == null) {
      _mutateWorkbench(
        (current) => current.copyWith(
          resourceEntries: _markResourceSelection(
            current.resourceEntries,
            selectedId: relativePath,
          ),
          generationStatus: '已选中目录或非文本资源：$relativePath',
        ),
      );
      return;
    }
    openOrActivateDocument(
      relativePath: relativePath,
      title: _displayNameOf(relativePath),
      content: content,
    );
    _mutateWorkbench(
      (current) => applyWorkbenchState(
        current.copyWith(
          resourceEntries: _markResourceSelection(
            current.resourceEntries,
            selectedId: relativePath,
          ),
          generationStatus: '已打开 $relativePath',
        ),
      ),
    );
    _scheduleWorkbenchSnapshotPersistence(refreshDraftRecoveries: false);
  }

  Future<void> _saveCurrentDocument() async {
    // 中文注释: 当前保存只处理活动文档，确保工具栏动作与项目写入规则解耦。
    final project = currentProject;
    final body = _readWorkbench().activeDocumentBody.trim();
    if (project == null || body.isEmpty) {
      _announce('当前没有可保存的正文内容。');
      return;
    }
    try {
      final savedPath = await _saveDraftUseCase.execute(
        project: project,
        content: _readWorkbench().activeDocumentBody,
        title: _readWorkbench().activeDocumentTitle,
        relativePath: _readWorkbench().activeDocumentPath,
      );
      final resourceEntries = await reloadResourceEntries(
        selectedId: savedPath,
      );
      final activeDocument = _activeOpenDocument();
      if (activeDocument != null) {
        _replaceOpenDocument(
          activeDocument.copyWith(
            id: savedPath,
            title: _readWorkbench().activeDocumentTitle,
            relativePath: savedPath,
            content: _readWorkbench().activeDocumentBody,
            isDirty: false,
            isBufferedDraft: false,
          ),
        );
        _writeProjectState(
          _readProjectState().copyWith(activeOpenDocumentId: savedPath),
        );
      }
      _mutateWorkbench(
        (current) => applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            informationViewData: _latestInformationViewData,
            generationStatus: '已保存到 $savedPath',
          ),
        ),
      );
      _scheduleWorkbenchSnapshotPersistence();
    } catch (error) {
      _announce('保存失败：$error');
    }
  }

  Future<void> _submitProjectInfoCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    // 中文注释: 项目信息更新先写共享用例，再重载当前项目，避免界面直接写文件。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final cleanTitle = request.projectTitle.trim();
    try {
      await _updateProjectManifestUseCase.execute(
        project: project,
        title: cleanTitle.isEmpty ? project.name : cleanTitle,
        projectType: request.projectType.trim().isEmpty
            ? project.projectType
            : request.projectType.trim(),
        genre: request.genre.trim(),
        premise: request.premise.trim(),
        notes: request.notes.trim(),
      );
      await loadProject(project.rootPath);
      _announce('已更新项目信息。');
    } catch (error) {
      _announce('保存项目信息失败：$error');
    }
  }

  Future<void> _submitProjectTypeTransitionCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    // 中文注释: 项目类型转换只在 core 计划可通过时执行，失败时把 blocker 原样投影回命令层。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final targetProjectTypeId = request.transitionTargetProjectTypeId.trim();
    if (targetProjectTypeId.isEmpty) {
      _announce('请先选择目标项目类型。');
      return;
    }
    final runtimeBaselineId = request.transitionRuntimeBaselineId.trim();
    final hasActiveLongTaskRun = _readProjectState().currentProjectLongTaskRuns
        .any((run) => run.isActive);
    final plan = _projectTypeTransitionPreparationService.prepare(
      project: project,
      targetProjectTypeId: targetProjectTypeId,
      runtimeBaselineId: runtimeBaselineId,
      hasActiveLongTaskRun: hasActiveLongTaskRun,
    );
    if (!plan.canTransition) {
      _showWorkspaceCommand(
        _projectTypeTransitionCommandViewDataService.build(
          project: project,
          plan: plan,
          runtimeBaselineId: runtimeBaselineId,
          status: _projectTypeTransitionCommandViewDataService.statusOf(plan),
          confirmLabel: '重新检查',
        ),
      );
      return;
    }
    final executor = _executeProjectTypeTransitionUseCase;
    if (executor == null) {
      return;
    }
    try {
      final updatedProject = await executor.execute(
        project: project,
        targetProjectTypeId: targetProjectTypeId,
        runtimeBaselineId: runtimeBaselineId,
        hasActiveLongTaskRun: hasActiveLongTaskRun,
      );
      await loadProject(updatedProject.rootPath);
      _announce('已完成项目类型转换：${updatedProject.name}');
    } catch (error) {
      _showWorkspaceCommand(
        _projectTypeTransitionCommandViewDataService.build(
          project: project,
          plan: plan,
          runtimeBaselineId: runtimeBaselineId,
          status: '项目类型转换失败：$error',
          confirmLabel: '重新检查',
        ),
      );
    }
  }

  Future<void> _submitCreateFileCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    // 中文注释: 文件创建统一复用项目入口用例，避免工作区自己理解底层目录规则。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final relativePath = _joinedProjectPath(
      request.relativePath,
      request.entryName,
      defaultFileName: 'new_file.md',
    );
    final initialContent = request.content.trim().isEmpty
        ? '# ${_displayNameOf(relativePath)}\n\n'
        : request.content;
    try {
      final result = await _createProjectEntryUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: initialContent,
      );
      if (_boolValue(result['ok']) != true) {
        _announce(_stringValue(result['error'], '创建文件失败。'));
        return;
      }
      final createdPath = _stringValue(result['relative_path']);
      final resourceEntries = await reloadResourceEntries(
        selectedId: createdPath,
      );
      final content = await _readProjectFileUseCase.execute(
        project,
        createdPath,
      );
      if (content != null) {
        openOrActivateDocument(
          relativePath: createdPath,
          title: _displayNameOf(createdPath),
          content: content,
        );
      }
      _mutateWorkbench(
        (current) => applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            informationViewData: _latestInformationViewData,
            workspaceCommand: null,
            generationStatus: '已创建文件：$createdPath',
          ),
        ),
      );
    } catch (error) {
      _announce('创建文件失败：$error');
    }
  }

  Future<void> _submitCreateFolderCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    // 中文注释: 目录创建也走共享入口用例，保证 GUI/CLI 与后续其他宿主的规则一致。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final relativePath = _joinedProjectPath(
      request.relativePath,
      request.entryName,
      defaultFileName: 'new_folder',
    );
    try {
      final result = await _createProjectEntryUseCase.execute(
        project: project,
        relativePath: relativePath,
        isFolder: true,
      );
      if (_boolValue(result['ok']) != true) {
        _announce(_stringValue(result['error'], '创建目录失败。'));
        return;
      }
      final createdPath = _stringValue(result['relative_path']);
      _expandResourceAncestors(createdPath);
      final resourceEntries = await reloadResourceEntries(
        selectedId: createdPath,
      );
      _mutateWorkbench(
        (current) => current.copyWith(
          resourceEntries: resourceEntries,
          informationViewData: _latestInformationViewData,
          workspaceCommand: null,
          generationStatus: '已创建目录：$createdPath',
        ),
      );
    } catch (error) {
      _announce('创建目录失败：$error');
    }
  }

  Future<void> _submitImportFilesCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    // 中文注释: 文件导入执行统一交给导入编排服务，控制器只做请求转换与界面回写。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final policy = _projectImportWorkspaceCommandViewDataService.resolvePolicy(
      request: request,
    );
    if (policy.sourcePaths.isEmpty) {
      _showImportWorkspaceCommand(request, status: '请先选择至少一个要导入的文件。');
      return;
    }
    _showImportWorkspaceCommand(
      request,
      isBusy: true,
      busyLabel: _importBusyLabel(policy),
      status: _importBusyStatus(policy),
    );
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final result = await _projectImportExecutionService.execute(
        project: project,
        request: ProjectImportRequest(
          sourcePaths: policy.sourcePaths,
          targetDirectory: policy.resolvedTargetDirectory,
          autoDeconstruct: policy.autoDeconstruct,
          smartAnalysis: policy.smartAnalysis,
          smartAnalysisProviderId: policy.smartAnalysisProviderId,
          smartAnalysisModelId: policy.smartAnalysisModelId,
          smartDeconstruction: policy.smartDeconstruction,
          smartDeconstructionProviderId: policy.smartDeconstructionProviderId,
          smartDeconstructionModelId: policy.smartDeconstructionModelId,
        ),
      );
      final selectedId = result.autoDeconstructionPreviewPath.trim().isNotEmpty
          ? result.autoDeconstructionPreviewPath.trim()
          : result.smartAnalysisReportPath.trim();
      if (selectedId.isNotEmpty) {
        _expandResourceAncestors(selectedId);
      }
      final resourceEntries = await reloadResourceEntries(
        selectedId: selectedId,
      );
      if (selectedId.isNotEmpty) {
        final content = await _readProjectFileUseCase.execute(
          project,
          selectedId,
        );
        if ((content ?? '').trim().isNotEmpty) {
          openOrActivateDocument(
            relativePath: selectedId,
            title: _displayNameOf(selectedId),
            content: content!,
          );
        }
      }
      _mutateWorkbench(
        (current) => applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            informationViewData: _latestInformationViewData,
            workspaceCommand: null,
            generationStatus: result.summary,
          ),
        ),
      );
      _announce(result.summary);
    } catch (error) {
      final message = '导入文件失败：$error';
      _showImportWorkspaceCommand(request, status: message);
      _announce(message);
    }
  }

  Future<void> _pickImportFiles(WorkspaceCommandRequestViewData request) async {
    // 中文注释: 文件选择器属于宿主动作，选完后只把结果回写到统一命令视图。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final sourcePaths = await _desktopProjectImportFilePickerService
        .pickFiles();
    if (sourcePaths.isEmpty) {
      return;
    }
    _showWorkspaceCommand(
      _projectImportWorkspaceCommandViewDataService.build(
        projectType: project.projectType,
        sourcePaths: sourcePaths,
        requestedTargetDirectory: request.targetDirectory,
        requestedAutoDeconstruct: request.autoDeconstruct,
        requestedSmartAnalysis: request.smartAnalysis,
        smartAnalysisProviderId: request.smartAnalysisProviderId,
        smartAnalysisModelId: request.smartAnalysisModelId,
        requestedSmartDeconstruction: request.smartDeconstruction,
        smartDeconstructionProviderId: request.smartDeconstructionProviderId,
        smartDeconstructionModelId: request.smartDeconstructionModelId,
        smartAnalysisModelOptions: _smartAnalysisModelOptions(),
        smartDeconstructionModelOptions: _smartDeconstructionModelOptions(),
      ),
    );
  }

  Future<void> _pickImportDirectory(
    WorkspaceCommandRequestViewData request,
  ) async {
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final sourcePaths = await _desktopProjectImportFilePickerService
        .pickDirectories();
    if (sourcePaths.isEmpty) {
      return;
    }
    _showWorkspaceCommand(
      _projectImportWorkspaceCommandViewDataService.build(
        projectType: project.projectType,
        sourcePaths: sourcePaths,
        requestedTargetDirectory: request.targetDirectory,
        requestedAutoDeconstruct: request.autoDeconstruct,
        requestedSmartAnalysis: request.smartAnalysis,
        smartAnalysisProviderId: request.smartAnalysisProviderId,
        smartAnalysisModelId: request.smartAnalysisModelId,
        requestedSmartDeconstruction: request.smartDeconstruction,
        smartDeconstructionProviderId: request.smartDeconstructionProviderId,
        smartDeconstructionModelId: request.smartDeconstructionModelId,
        smartAnalysisModelOptions: _smartAnalysisModelOptions(),
        smartDeconstructionModelOptions: _smartDeconstructionModelOptions(),
      ),
    );
  }

  Future<void> _createReviewTaskForCurrentDocument() async {
    // 中文注释: 文档工具栏的审稿入口直接复用共享工作流运行服务，不在控制器里重造审稿规则。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final relativePath = _readWorkbench().activeDocumentPath.trim();
    if (relativePath.isEmpty) {
      _announce('当前没有可审稿的文档。');
      return;
    }
    final result = await _reviewReportService
        .createReviewTask(project, <String, Object?>{
          'source_path': relativePath,
          'review_type': ReviewTypeConstants.continuity,
          'scope': relativePath,
        });
    _announce(_stringValue(result['message'], '已创建审稿任务。'));
  }

  void _openLikelyOutlineDocument() {
    // 中文注释: 大纲快捷入口只定位最可能的大纲文件，不在这里发散成新的搜索逻辑。
    final candidates = _workspaceResourceDisplayService
        .likelyOutlineDocumentCandidates();
    for (final candidate in candidates) {
      final entry = _resourceEntryById(candidate);
      if (entry != null) {
        _openResource(candidate);
        return;
      }
    }
    _announce('当前项目还没有可直接打开的大纲文件。');
  }

  void _toggleActiveDocumentRenderMode() {
    // 中文注释: 渲染模式只作用于当前 Markdown 文档，不影响落盘内容。
    final active = _activeOpenDocument();
    if (active == null) {
      _announce('当前没有可渲染的文档。');
      return;
    }
    if (!_canRender(active.relativePath)) {
      _announce('只有 Markdown 文档支持渲染。');
      return;
    }
    _replaceOpenDocument(active.copyWith(isRendered: !active.isRendered));
    _mutateWorkbench(
      (current) => applyWorkbenchState(
        current.copyWith(
          generationStatus: active.isRendered ? '已切回编辑模式。' : '已切到渲染模式。',
        ),
      ),
    );
  }

  String _projectTypeTransitionTargetId(String sourceProjectTypeId) {
    // 中文注释: 第一阶段的互转目标是固定的，workspace 只把这条静态图转成稳定 ID。
    switch (sourceProjectTypeId.trim()) {
      case 'novel':
        return 'long_novel';
      case 'long_novel':
        return 'novel';
      default:
        return '';
    }
  }

  EntryAvailabilityDecision _projectTypeTransitionAvailabilityFor(
    ProjectDescriptor project,
  ) {
    // 中文注释: 项目类型转换入口只在宿主接线且项目类型确实可互转时保留为正式入口。
    return _entryAvailabilityPolicyService.projectTypeTransition(
      hostWired: _executeProjectTypeTransitionUseCase != null,
      entryRelevant: _projectTypeTransitionTargetId(
        project.projectType,
      ).trim().isNotEmpty,
      ready: true,
      diagnosticReason: _executeProjectTypeTransitionUseCase == null
          ? 'workspace.transition_project_type.host_unwired'
          : 'workspace.transition_project_type.available',
    );
  }

  void _showWorkspaceCommand(WorkspaceCommandViewData command) {
    // 中文注释: 工作区命令弹层通过统一入口挂到工作台视图，避免每个按钮自己持有表单状态。
    _mutateWorkbench((current) => current.copyWith(workspaceCommand: command));
  }

  void _showImportWorkspaceCommand(
    WorkspaceCommandRequestViewData request, {
    String status = '',
    bool isBusy = false,
    String busyLabel = '',
  }) {
    _showWorkspaceCommand(
      _projectImportWorkspaceCommandViewDataService.rebuild(
        request: request,
        status: status,
        isBusy: isBusy,
        busyLabel: busyLabel,
      ),
    );
  }

  String _importBusyLabel(ProjectImportActionPolicy policy) {
    if (policy.projectType == BookDeconstructionConstants.projectTypeId) {
      if (policy.smartDeconstruction) {
        return '正在智能拆书';
      }
      if (policy.autoDeconstruct) {
        return '正在拆书';
      }
    }
    if (policy.smartAnalysis) {
      return '正在导入并分析';
    }
    return '正在导入';
  }

  String _importBusyStatus(ProjectImportActionPolicy policy) {
    if (policy.projectType == BookDeconstructionConstants.projectTypeId) {
      if (policy.smartDeconstruction) {
        return '正在导入并调用拆书专用智能体处理章节识别、清理干扰内容。';
      }
      if (policy.autoDeconstruct) {
        return '正在导入并生成拆书结构化预览。';
      }
      return '正在导入书籍原文。';
    }
    if (policy.smartAnalysis) {
      return '正在导入资料，并由内置分析器判断内容类型与建议落位。';
    }
    return '正在导入文件。';
  }

  Future<void> _selectProjectAgentGroupAndRefreshOverlay(String groupId) async {
    final cleanGroupId = groupId.trim();
    if (cleanGroupId.isEmpty) {
      return;
    }
    final currentOverlay = _readWorkbench().projectAgentGroupWorkspace;
    if (currentOverlay != null) {
      _mutateWorkbench(
        (current) => current.copyWith(
          projectAgentGroupWorkspace: currentOverlay.copyWith(
            statusMessage: '正在切换项目智能体组...',
          ),
        ),
      );
    }
    final refreshedViewData = await _selectProjectAgentGroup(cleanGroupId);
    if (refreshedViewData == null) {
      _mutateWorkbench(
        (current) => current.copyWith(projectAgentGroupWorkspace: null),
      );
      return;
    }
    _mutateWorkbench(
      (current) => current.copyWith(
        projectAgentGroupWorkspace: refreshedViewData.copyWith(
          statusMessage: '',
        ),
      ),
    );
  }

  Future<void> _persistLastProjectPath(String rootPath) async {
    // 中文注释: 最近项目路径属于用户级偏好，但由工作区层在成功切换项目后统一落盘。
    final settings = _readSettings();
    if (settings == null || rootPath.trim().isEmpty) {
      return;
    }
    if (_normalizePathForCompare(settings.defaultProjectPath) ==
        _normalizePathForCompare(rootPath)) {
      await _persistWorkbenchSnapshot();
      return;
    }
    await _saveSettingsSilently(
      settings.copyWith(defaultProjectPath: rootPath),
    );
    await _persistWorkbenchSnapshot();
  }

  void _scheduleWorkbenchSnapshotPersistence({
    bool refreshDraftRecoveries = true,
    Duration delay = const Duration(milliseconds: 220),
  }) {
    _pendingWorkbenchSnapshotNeedsDraftRecoveries =
        _pendingWorkbenchSnapshotNeedsDraftRecoveries || refreshDraftRecoveries;
    _workbenchSnapshotDebounceTimer?.cancel();
    _workbenchSnapshotDebounceTimer = Timer(delay, () {
      final needsDraftRecoveries =
          _pendingWorkbenchSnapshotNeedsDraftRecoveries;
      _pendingWorkbenchSnapshotNeedsDraftRecoveries = false;
      unawaited(
        _persistWorkbenchSnapshot(refreshDraftRecoveries: needsDraftRecoveries),
      );
    });
  }

  Future<void> _persistWorkbenchSnapshot({
    bool refreshDraftRecoveries = true,
  }) async {
    // 中文注释: 工作区快照只记录恢复工作台所需的轻量状态，不承担项目主存储职责。
    final settings = _readSettings();
    final project = currentProject;
    final state = _readProjectState();
    if (settings == null ||
        project == null ||
        state.isSavingWorkbenchSnapshot) {
      return;
    }
    _writeProjectState(state.copyWith(isSavingWorkbenchSnapshot: true));
    try {
      final persistedActiveDocumentPath = _persistableWorkbenchDocumentPath(
        _readWorkbench().activeDocumentPath,
      );
      final currentSnapshot = _mapValue(
        settings.extraSettings['workbench_state'],
      );
      final draftRecoveries = refreshDraftRecoveries
          ? _workbenchDraftRecoverySnapshotService.captureRecoveries(
              state.openDocuments,
            )
          : ValueReaders.mapList(currentSnapshot['draft_recoveries']);
      final payload = <String, Object?>{
        'project_root_path': project.rootPath,
        'active_document_path': persistedActiveDocumentPath,
        'expanded_directories': state.expandedResourceDirectories.toList(
          growable: false,
        ),
        'selected_conversation_agent_id':
            _readWorkbench().agentSelector.currentAgentId,
        'draft_recoveries': draftRecoveries,
      };
      if (_normalizePathForCompare(
            _stringValue(currentSnapshot['project_root_path']),
          ) ==
          _normalizePathForCompare(project.rootPath)) {
        if (_listEquals(
              ValueReaders.stringList(currentSnapshot['expanded_directories']),
              state.expandedResourceDirectories.toList(growable: false),
            ) &&
            _stringValue(currentSnapshot['active_document_path']) ==
                persistedActiveDocumentPath &&
            _stringValue(currentSnapshot['selected_conversation_agent_id']) ==
                _readWorkbench().agentSelector.currentAgentId &&
            _jsonEquals(
              currentSnapshot['draft_recoveries'],
              payload['draft_recoveries'],
            )) {
          return;
        }
      }
      await _saveSettingsSilently(
        settings.copyWith(
          extraSettings: <String, Object?>{
            ...settings.extraSettings,
            'workbench_state': payload,
          },
        ),
      );
    } finally {
      _writeProjectState(
        _readProjectState().copyWith(isSavingWorkbenchSnapshot: false),
      );
    }
  }

  List<SelectorOptionViewData> _smartDeconstructionModelOptions() {
    return _importAssistantModelOptions();
  }

  List<SelectorOptionViewData> _smartAnalysisModelOptions() {
    return _importAssistantModelOptions();
  }

  List<SelectorOptionViewData> _importAssistantModelOptions() {
    final settings = _readSettings();
    if (settings == null) {
      return const <SelectorOptionViewData>[];
    }
    final options = <SelectorOptionViewData>[];
    final seen = <String>{};
    for (final provider in settings.providers) {
      final providerId = provider.id.trim();
      final modelId = provider.modelId.trim();
      if (providerId.isEmpty || modelId.isEmpty) {
        continue;
      }
      final key = '$providerId::$modelId';
      if (!seen.add(key)) {
        continue;
      }
      final providerLabel = provider.title.trim().isEmpty
          ? providerId
          : provider.title.trim();
      options.add(
        SelectorOptionViewData(
          id: key,
          label: '$providerLabel · $modelId',
          note: providerId,
        ),
      );
    }
    return List<SelectorOptionViewData>.unmodifiable(options);
  }

  List<ResourceEntryViewData> _resourceEntriesFrom(List<JsonMap> entries) {
    // 中文注释: 资源树显示逻辑统一由工作区控制器完成，中文映射只停留在展示层。
    final visibleEntries = entries
        .where(
          (entry) => !_workspaceResourceDisplayService.shouldHidePath(
            _stringValue(entry['relative_path']),
          ),
        )
        .toList(growable: false);
    final byParent = <String, List<JsonMap>>{};
    for (final entry in visibleEntries) {
      final relativePath = _stringValue(entry['relative_path']);
      final parentPath = _parentPathOf(relativePath);
      byParent.putIfAbsent(parentPath, () => <JsonMap>[]).add(entry);
    }
    final result = <ResourceEntryViewData>[];

    void visit(String parentPath, int depth) {
      final siblings = byParent[parentPath];
      if (siblings == null || siblings.isEmpty) {
        return;
      }
      final orderedSiblings = siblings.toList(growable: true)
        ..sort(_workspaceResourceDisplayService.compareEntries);
      for (final entry in orderedSiblings) {
        final relativePath = _stringValue(entry['relative_path']);
        final isDirectory = entry['is_dir'] == true;
        final visibleChildren = (byParent[relativePath] ?? const <JsonMap>[]);
        final isExpanded =
            !isDirectory ||
            _readProjectState().expandedResourceDirectories.contains(
              relativePath,
            );
        result.add(
          ResourceEntryViewData(
            id: relativePath,
            title: _workspaceResourceDisplayService.titleOf(
              relativePath,
              isDirectory: isDirectory,
            ),
            relativePath: relativePath,
            depth: depth,
            isDirectory: isDirectory,
            childCount: visibleChildren.length,
            hasChildren: visibleChildren.isNotEmpty,
            isExpanded: isExpanded,
          ),
        );
        if (isDirectory && isExpanded) {
          visit(relativePath, depth + 1);
        }
      }
    }

    visit('', 0);
    return result;
  }

  List<ResourceEntryViewData> _markResourceSelection(
    List<ResourceEntryViewData> entries, {
    required String selectedId,
  }) {
    // 中文注释: 资源树选中态单独投影，避免原始目录快照被 UI 需求污染。
    return entries
        .map(
          (entry) => entry.copyWith(isSelected: entry.id == selectedId.trim()),
        )
        .toList(growable: false);
  }

  ResourceEntryViewData? _resourceEntryById(String entryId) {
    for (final entry in _resourceEntriesFrom(
      _readProjectState().resourceSnapshotEntries,
    )) {
      if (entry.id == entryId.trim()) {
        return entry;
      }
    }
    return null;
  }

  void _toggleResourceDirectory(String relativePath) {
    // 中文注释: 目录折叠只维护运行时显隐集合，不改动任何真实文件结构。
    final state = _readProjectState();
    final nextExpanded = Set<String>.from(state.expandedResourceDirectories);
    if (nextExpanded.contains(relativePath)) {
      nextExpanded.remove(relativePath);
    } else {
      nextExpanded.add(relativePath);
    }
    _writeProjectState(
      state.copyWith(expandedResourceDirectories: nextExpanded),
    );
    _mutateWorkbench(
      (current) => current.copyWith(
        resourceEntries: _resourceEntriesFrom(state.resourceSnapshotEntries),
        informationViewData: _latestInformationViewData,
      ),
    );
    _scheduleWorkbenchSnapshotPersistence(refreshDraftRecoveries: false);
  }

  Future<List<JsonMap>> _scanInformationSupportEntries(String rootPath) async {
    final entries = <JsonMap>[];
    final seenPaths = <String>{};

    Future<void> addFileIfExists(String relativePath) async {
      final normalizedPath = _normalizeRelativePath(relativePath);
      if (normalizedPath.isEmpty || seenPaths.contains(normalizedPath)) {
        return;
      }
      final resolved = _resolveProjectFilePath(rootPath, normalizedPath);
      if (!await File(resolved).exists()) {
        return;
      }
      seenPaths.add(normalizedPath);
      entries.add(<String, Object?>{
        'relative_path': normalizedPath,
        'display_name': normalizedPath.split('/').last,
        'is_dir': false,
      });
    }

    for (final projectionPath in _informationProjectionPaths) {
      await addFileIfExists(projectionPath);
    }

    await for (final relativePath in _scanRelativeFilesUnder(
      rootPath,
      '.novel_agent/information',
    )) {
      if (_isPendingInformationPath(relativePath)) {
        await addFileIfExists(relativePath);
      }
    }

    await for (final relativePath in _scanRelativeFilesUnder(
      rootPath,
      'tracking',
    )) {
      if (relativePath.endsWith('activation_report.json')) {
        await addFileIfExists(relativePath);
      }
    }

    await for (final relativePath in _scanRelativeFilesUnder(
      rootPath,
      '.novel_agent',
    )) {
      if (relativePath.endsWith('activation_report.json')) {
        await addFileIfExists(relativePath);
      }
    }

    return entries;
  }

  Stream<String> _scanRelativeFilesUnder(
    String rootPath,
    String relativeRoot,
  ) async* {
    final normalizedRoot = _normalizeRelativePath(relativeRoot);
    final directory = Directory(
      _resolveProjectFilePath(rootPath, normalizedRoot),
    );
    if (!await directory.exists()) {
      return;
    }
    FileSystemException? lastError;
    for (
      var attempt = 1;
      attempt <= _maxInformationSupportScanAttempts;
      attempt++
    ) {
      final pendingDirectories = <Directory>[directory];
      try {
        while (pendingDirectories.isNotEmpty) {
          final currentDirectory = pendingDirectories.removeLast();
          await for (final entity in currentDirectory.list(
            recursive: false,
            followLinks: false,
          )) {
            final relativePath = _relativePathFromAbsolute(
              rootPath,
              entity.path,
            );
            if (relativePath.isEmpty ||
                _shouldSkipInformationSupportScanPath(
                  scanRoot: normalizedRoot,
                  relativePath: relativePath,
                )) {
              continue;
            }
            if (entity is File) {
              yield relativePath;
              continue;
            }
            if (entity is Directory) {
              pendingDirectories.add(entity);
            }
          }
        }
        return;
      } on FileSystemException catch (error) {
        lastError = error;
        if (attempt >= _maxInformationSupportScanAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 80 * attempt));
      }
    }
    throw lastError ?? FileSystemException('扫描资料支持文件失败。', directory.path);
  }

  bool _shouldSkipInformationSupportScanPath({
    required String scanRoot,
    required String relativePath,
  }) {
    if (!scanRoot.startsWith('.novel_agent')) {
      return false;
    }
    return _informationSupportIgnoredRoots.any(
      (ignoredRoot) =>
          relativePath == ignoredRoot ||
          relativePath.startsWith('$ignoredRoot/'),
    );
  }

  bool _shouldReadInformationProjectionFile(String relativePath) {
    return _informationProjectionPaths.contains(relativePath) ||
        _isPendingInformationPath(relativePath) ||
        relativePath.endsWith('activation_report.json');
  }

  bool _isPendingInformationPath(String relativePath) {
    return relativePath.startsWith(
          '.novel_agent/information/knowledge_cards/',
        ) ||
        relativePath.startsWith('.novel_agent/information/design_elements/') ||
        relativePath.startsWith(
          '.novel_agent/information/research_requests/',
        ) ||
        relativePath.startsWith('.novel_agent/information/reference_works/');
  }

  String _resolveProjectFilePath(String rootPath, String relativePath) {
    final normalizedRoot = rootPath.replaceAll('\\', Platform.pathSeparator);
    final normalizedRelative = relativePath.replaceAll(
      '/',
      Platform.pathSeparator,
    );
    return '$normalizedRoot${Platform.pathSeparator}$normalizedRelative';
  }

  String _relativePathFromAbsolute(String rootPath, String absolutePath) {
    final normalizedRoot = _normalizeRelativePath(rootPath);
    final normalizedAbsolute = _normalizeRelativePath(absolutePath);
    if (normalizedRoot.isEmpty || normalizedAbsolute.isEmpty) {
      return '';
    }
    if (normalizedAbsolute == normalizedRoot) {
      return '';
    }
    final prefix = '$normalizedRoot/';
    if (!normalizedAbsolute.startsWith(prefix)) {
      return '';
    }
    return normalizedAbsolute.substring(prefix.length);
  }

  String _normalizeRelativePath(String value) {
    return ProjectSupportDocumentCatalog.canonicalizePath(value);
  }

  void _expandResourceAncestors(String relativePath) {
    // 中文注释: 打开文件时自动展开上级目录，保证资源树与当前文档焦点同步。
    final parts = relativePath.split('/');
    if (parts.length <= 1) {
      return;
    }
    final state = _readProjectState();
    final nextExpanded = <String>{...state.expandedResourceDirectories};
    var current = '';
    for (var index = 0; index < parts.length - 1; index++) {
      current = current.isEmpty ? parts[index] : '$current/${parts[index]}';
      nextExpanded.add(current);
    }
    _writeProjectState(
      state.copyWith(expandedResourceDirectories: nextExpanded),
    );
  }

  Set<String> _defaultExpandedDirectories(List<JsonMap> entries) {
    // 中文注释: 默认展开规则只展开首层目录，避免首次进入时资源树完全塌缩。
    return entries
        .where((entry) => entry['is_dir'] == true)
        .map((entry) => _stringValue(entry['relative_path']))
        .where((path) => path.isNotEmpty && !path.contains('/'))
        .toSet();
  }

  Set<String> _mergedExpandedDirectories({
    required List<JsonMap> entries,
    required String selectedId,
  }) {
    // 中文注释: 重刷资源树后尽量保留用户现有展开状态，并确保当前选中文件祖先可见。
    final knownDirectories = entries
        .where((entry) => entry['is_dir'] == true)
        .map((entry) => _stringValue(entry['relative_path']))
        .where((path) => path.isNotEmpty)
        .toSet();
    final nextExpanded = _readProjectState().expandedResourceDirectories
        .where(knownDirectories.contains)
        .toSet();
    final parts = selectedId.split('/');
    var current = '';
    for (var index = 0; index < parts.length - 1; index++) {
      current = current.isEmpty ? parts[index] : '$current/${parts[index]}';
      if (knownDirectories.contains(current)) {
        nextExpanded.add(current);
      }
    }
    if (nextExpanded.isEmpty) {
      return _defaultExpandedDirectories(entries);
    }
    return nextExpanded;
  }

  String _displayNameOf(String relativePath) {
    // 中文注释: 文件名展示依旧只做显示映射，不改真实英文路径。
    return _workspaceResourceDisplayService.titleOf(
      relativePath,
      isDirectory: false,
    );
  }

  String _firstOpenablePath(List<JsonMap> entries) {
    // 中文注释: 首次加载优先打开正式前提和总纲，再退回其他文本，避免 support overview 或随机文件抢占主入口。
    return _workspacePrimaryDocumentSelectionService.select(entries);
  }

  OpenDocumentState? _activeOpenDocument() {
    final state = _readProjectState();
    for (final document in state.openDocuments) {
      if (document.id == state.activeOpenDocumentId) {
        return document;
      }
    }
    return state.openDocuments.isEmpty ? null : state.openDocuments.last;
  }

  void _replaceOpenDocument(OpenDocumentState document) {
    // 中文注释: 已打开文档的替换逻辑单独收口，避免多个动作各自维护标签列表。
    final state = _readProjectState();
    final index = state.openDocuments.indexWhere(
      (item) => item.id == document.id,
    );
    if (index < 0) {
      return;
    }
    final nextDocuments = List<OpenDocumentState>.from(state.openDocuments);
    nextDocuments[index] = document;
    _writeProjectState(state.copyWith(openDocuments: nextDocuments));
  }

  void _restoreRecoveredDocument(JsonMap recovery) {
    final relativePath = _normalizeRelativePath(
      ValueReaders.stringValue(recovery['relative_path']),
    );
    final recoveryContent = ValueReaders.stringValue(recovery['content']);
    if (relativePath.isEmpty || recoveryContent.trim().isEmpty) {
      return;
    }
    final title = ValueReaders.stringValue(
      recovery['title'],
      _displayNameOf(relativePath),
    );
    openOrActivateDocument(
      relativePath: relativePath,
      title: title.isEmpty ? _displayNameOf(relativePath) : title,
      content: recoveryContent,
    );
    final active = _activeOpenDocument();
    if (active == null ||
        _normalizePathForCompare(active.relativePath) !=
            _normalizePathForCompare(relativePath)) {
      return;
    }
    _replaceOpenDocument(
      active.copyWith(
        content: recoveryContent,
        isDirty: true,
        isRendered: false,
        isBufferedDraft: true,
      ),
    );
  }

  bool _canReadAsText(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') ||
        lower.endsWith('.markdown') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.epub') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml');
  }

  bool _canRender(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.markdown');
  }

  bool _shouldRestoreWorkbenchDocument(String relativePath) {
    final normalized = _normalizeRelativePath(relativePath);
    if (normalized.isEmpty) {
      return false;
    }
    if (_workspaceResourceDisplayService.shouldHidePath(normalized)) {
      return false;
    }
    return _canReadAsText(normalized);
  }

  String _persistableWorkbenchDocumentPath(String relativePath) {
    final normalized = _normalizeRelativePath(relativePath);
    return _shouldRestoreWorkbenchDocument(normalized) ? normalized : '';
  }

  String _joinedProjectPath(
    String directoryPath,
    String entryName, {
    required String defaultFileName,
  }) {
    // 中文注释: 新建文件和目录时统一在这里拼接相对路径，避免命令分支各自处理斜杠与空值。
    final cleanDirectory = directoryPath.replaceAll('\\', '/').trim();
    final cleanEntryName = entryName.trim().isEmpty
        ? defaultFileName
        : entryName.trim();
    if (cleanDirectory.isEmpty) {
      return cleanEntryName;
    }
    final normalizedDirectory = cleanDirectory.replaceAll(RegExp(r'/+$'), '');
    final normalizedEntry = cleanEntryName.replaceAll(RegExp(r'^/+'), '');
    return '$normalizedDirectory/$normalizedEntry';
  }

  String _parentPathOf(String relativePath) {
    final separatorIndex = relativePath.lastIndexOf('/');
    if (separatorIndex <= 0) {
      return '';
    }
    return relativePath.substring(0, separatorIndex);
  }

  bool _listEquals(List<String> left, List<String> right) {
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

  String _normalizePathForCompare(String value) {
    return value.trim().replaceAll('\\', '/').toLowerCase();
  }

  bool _jsonEquals(Object? left, Object? right) {
    return jsonEncode(left) == jsonEncode(right);
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  JsonMap _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return ValueReaders.deepCopyMap(value);
    }
    if (value is Map) {
      final result = <String, Object?>{};
      value.forEach((key, item) {
        result[key.toString()] = item;
      });
      return result;
    }
    return const <String, Object?>{};
  }

  Future<void> _applyPendingResearchAction(
    String requestId, {
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectPendingResearchActionService service,
      ProjectDescriptor project,
      String requestId,
    )
    action,
  }) async {
    final project = currentProject;
    final service = _pendingResearchActionService;
    final cleanRequestId = requestId.trim();
    if (project == null || service == null || cleanRequestId.isEmpty) {
      return;
    }
    _mutateWorkbench(
      (current) => applyWorkbenchState(
        current.copyWith(generationStatus: '正在更新资料请求...'),
      ),
    );
    try {
      final result = await action(service, project, cleanRequestId);
      if (!ValueReaders.boolValue(result['ok'])) {
        final error = _stringValue(result['error'], '资料请求更新失败。');
        _mutateWorkbench(
          (current) =>
              applyWorkbenchState(current.copyWith(generationStatus: error)),
        );
        return;
      }
      final selectedId = _readWorkbench().activeDocumentPath;
      final resourceEntries = await reloadResourceEntries(
        selectedId: selectedId,
      );
      _mutateWorkbench(
        (current) => applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            informationViewData: _latestInformationViewData,
            generationStatus: successMessage,
          ),
        ),
      );
    } catch (error) {
      _mutateWorkbench(
        (current) => applyWorkbenchState(
          current.copyWith(generationStatus: '资料请求更新失败：$error'),
        ),
      );
    }
  }
}

const Set<String> _informationProjectionPaths = <String>{
  InformationProjectionDocument.knowledgeSummaryRelativePath,
  InformationProjectionDocument.designSummaryRelativePath,
  InformationProjectionDocument.researchSummaryRelativePath,
  InformationProjectionDocument.referenceBoundaryRelativePath,
};

const int _maxInformationSupportScanAttempts = 3;

const Set<String> _informationSupportIgnoredRoots = <String>{
  '.novel_agent/reference_extraction',
};
