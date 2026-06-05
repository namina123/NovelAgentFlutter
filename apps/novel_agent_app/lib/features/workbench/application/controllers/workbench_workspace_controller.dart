import 'dart:async';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import '../../../project_creation/application/controllers/project_creation_controller.dart';
import '../../presentation/contracts/document_workspace_action_handler.dart';
import '../../presentation/contracts/resource_manager_action_handler.dart';
import '../../presentation/models/conversation_agent_selector_view_data.dart';
import '../../presentation/models/project_create_request_view_data.dart';
import '../../presentation/models/conversation_group_selector_view_data.dart';
import '../../presentation/models/project_agent_group_workspace_view_data.dart';
import '../../presentation/models/selector_option_view_data.dart';
import '../../presentation/models/workbench_information_view_data.dart';
import '../../presentation/models/workbench_view_data.dart';
import '../models/open_document_state.dart';
import '../models/project_import_request.dart';
import '../models/workbench_project_runtime_state.dart';
import '../services/desktop_project_import_file_picker_service.dart';
import '../services/project_import_execution_service.dart';
import '../services/project_import_workspace_command_view_data_service.dart';
import '../services/project_long_task_summary_view_data_service.dart';
import '../services/project_subtitle_view_data_service.dart';
import '../services/workspace_command_default_target_service.dart';
import '../services/workspace_information_projection_service.dart';
import '../services/workspace_resource_display_service.dart';

class WorkbenchWorkspaceController
    implements ResourceManagerActionHandler, DocumentWorkspaceActionHandler {
  WorkbenchWorkspaceController({
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required ReadProjectFileUseCase readProjectFileUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required CreateProjectEntryUseCase createProjectEntryUseCase,
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    required LongTaskSupervisor longTaskSupervisor,
    required ProjectReviewReportService reviewReportService,
    required ProjectRuntimeProfileRepository projectRuntimeProfileRepository,
    required WorkbenchProjectRuntimeState Function() readProjectState,
    required void Function(WorkbenchProjectRuntimeState state)
    writeProjectState,
    required void Function() resetConversationRuntimeState,
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
  }) : _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _createProjectEntryUseCase = createProjectEntryUseCase,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _longTaskSupervisor = longTaskSupervisor,
       _reviewReportService = reviewReportService,
       _projectRuntimeProfileRepository = projectRuntimeProfileRepository,
       _readProjectState = readProjectState,
       _writeProjectState = writeProjectState,
       _resetConversationRuntimeState = resetConversationRuntimeState,
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
       _showCurrentAgentSkillLoadout = showCurrentAgentSkillLoadout,
       _showCurrentAgentExpressionConstraints =
           showCurrentAgentExpressionConstraints,
       _announce = announce,
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
           ),
       _workspaceInformationProjectionService =
           workspaceInformationProjectionService ??
           const WorkspaceInformationProjectionService();

  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final CreateProjectEntryUseCase _createProjectEntryUseCase;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final LongTaskSupervisor _longTaskSupervisor;
  final ProjectReviewReportService _reviewReportService;
  final ProjectRuntimeProfileRepository _projectRuntimeProfileRepository;
  final WorkbenchProjectRuntimeState Function() _readProjectState;
  final void Function(WorkbenchProjectRuntimeState state) _writeProjectState;
  final void Function() _resetConversationRuntimeState;
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
  final Future<void> Function(String agentId) _showCurrentAgentSkillLoadout;
  final Future<void> Function(String agentId)
  _showCurrentAgentExpressionConstraints;
  final void Function(String message) _announce;
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
  final WorkspaceResourceDisplayService _workspaceResourceDisplayService =
      const WorkspaceResourceDisplayService();
  WorkbenchInformationViewData _latestInformationViewData =
      const WorkbenchInformationViewData();

  ProjectCreationController? _projectCreationController;

  void attachProjectCreationController(ProjectCreationController controller) {
    // 中文注释: 项目创建控制器后挂载，避免工作台与项目创建之间出现构造环依赖。
    _projectCreationController = controller;
  }

  ProjectDescriptor? get currentProject => _readProjectState().currentProject;

  ProjectRuntimeProfile? get currentProjectRuntimeProfile =>
      _readProjectState().currentRuntimeProfile;

  JsonMap currentProjectInfo() {
    // 中文注释: 会话与主动作需要轻量项目摘要，这里只返回运行时真正需要的字段。
    final project = currentProject;
    if (project == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
    };
  }

  String get activeDocumentPath => _readWorkbench().activeDocumentPath;

  String get activeDocumentBody => _activeOpenDocument()?.content ?? '';

  OpenDocumentState? activeOpenDocument() => _activeOpenDocument();

  Future<void> openResource(String relativePath) async {
    // 中文注释: 给壳层与其他子域暴露受控的资源打开入口，但具体读盘细节仍留在工作区控制器内部。
    await _openResource(relativePath);
  }

  Future<void> saveCurrentDocument() async {
    // 中文注释: 壳层如果需要触发保存，只能通过工作区控制器暴露的最小入口。
    await _saveCurrentDocument();
  }

  WorkbenchViewData applyWorkbenchState(WorkbenchViewData base) {
    // 中文注释: 工作台文档与资源树投影统一由工作区控制器生成，避免其他 feature 直接读内部状态。
    final active = _activeOpenDocument();
    final state = _readProjectState();
    return base.copyWith(
      projectLongTaskSummary: _projectLongTaskSummaryViewDataService.build(
        project: state.currentProject,
        runs: state.currentProjectLongTaskRuns,
        isLoading: state.isProjectLongTaskSummaryLoading,
      ),
      documents: state.openDocuments
          .map(
            (document) => DocumentTabViewData(
              id: document.id,
              title: document.title,
              relativePath: document.relativePath,
              isActive: document.id == state.activeOpenDocumentId,
              isDirty: document.isDirty,
            ),
          )
          .toList(growable: false),
      activeDocumentTitle: active?.title ?? '',
      activeDocumentPath: active?.relativePath ?? '',
      activeDocumentBody: active?.content ?? '',
      activeDocumentDirty: active?.isDirty ?? false,
      activeDocumentCanRender: _canRender(active?.relativePath ?? ''),
      isActiveDocumentRendered: active?.isRendered ?? false,
    );
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
          isProjectLongTaskSummaryLoading: false,
        ),
      );
      _resetConversationRuntimeState();
      _refreshSettingsViewData();
      return false;
    }

    final runtimeProfile = await _projectRuntimeProfileRepository.load(
      snapshot.project,
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
        isProjectLongTaskSummaryLoading: true,
      ),
    );
    _resetConversationRuntimeState();
    _latestInformationViewData = await _buildInformationViewData(
      snapshot.project,
      snapshot.entries,
    );
    var workbench = _readWorkbench().copyWith(
      projectName: snapshot.project.name,
      projectSubtitle: _projectSubtitleViewDataService.build(
        snapshot.project,
        runtimeProfile: runtimeProfile,
      ),
      projectPath: snapshot.project.rootPath,
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
    _mutateWorkbench((current) => _applyConversationState(workbench));
    await _persistLastProjectPath(snapshot.project.rootPath);
    await _refreshAgentEcosystem();
    await restoreWorkbenchSnapshot(snapshot.project);
    await refreshProjectLongTaskSummary();
    await _refreshActiveDestinationAfterProjectLoad();
    return true;
  }

  Future<void> refreshProjectLongTaskSummary() async {
    final project = currentProject;
    if (project == null) {
      _writeProjectState(
        _readProjectState().copyWith(
          currentProjectLongTaskRuns: const <RunInstance>[],
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
      _writeProjectState(
        _readProjectState().copyWith(
          currentProjectLongTaskRuns: runs,
          isProjectLongTaskSummaryLoading: false,
        ),
      );
    } catch (_) {
      _writeProjectState(
        _readProjectState().copyWith(isProjectLongTaskSummaryLoading: false),
      );
    }
    _mutateWorkbench((current) => applyWorkbenchState(current));
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
          resourceEntries: const [],
          informationViewData: const WorkbenchInformationViewData(),
          documents: const <DocumentTabViewData>[],
          activeDocumentTitle: '',
          activeDocumentPath: '',
          activeDocumentBody: '',
          activeDocumentDirty: false,
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
    if (activeDocumentPath.trim().isEmpty) {
      return;
    }
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
    _mutateWorkbench(
      (current) => applyWorkbenchState(
        current.copyWith(
          resourceEntries: _markResourceSelection(
            _resourceEntriesFrom(_readProjectState().resourceSnapshotEntries),
            selectedId: activeDocumentPath,
          ),
          informationViewData: _latestInformationViewData,
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
    _projectCreationController?.onCreateProjectRequested();
  }

  @override
  void onOpenProjectRequested() {
    // 中文注释: 打开已有项目同样委派给项目创建控制器，保持“项目入口”职责单点收束。
    _projectCreationController?.onOpenProjectRequested();
  }

  @override
  void onProjectLauncherDismissed() {
    // 中文注释: 启动器弹层生命周期完全交给项目创建控制器。
    _projectCreationController?.onProjectLauncherDismissed();
  }

  @override
  void onProjectLauncherRefreshRequested() {
    // 中文注释: 启动器列表刷新继续由项目创建控制器统一处理。
    _projectCreationController?.onProjectLauncherRefreshRequested();
  }

  @override
  void onProjectEntryOpened(String projectPath) {
    // 中文注释: 从项目列表选中项目时，工作区只做委派，不重写选择逻辑。
    _projectCreationController?.onProjectEntryOpened(projectPath);
  }

  @override
  void onProjectCreationBackRequested() {
    // 中文注释: 创建向导的返回动作继续委派给项目创建控制器，工作区不介入阶段状态机。
    _projectCreationController?.onProjectCreationBackRequested();
  }

  @override
  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) {
    // 中文注释: 项目创建表单提交继续由创建控制器处理，工作区层不再理解运行基准判断。
    _projectCreationController?.onProjectCreationSubmitted(request);
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
  void onRefreshFilesRequested() {
    // 中文注释: 刷新工作区时优先重载当前项目；如果还没有项目，则走默认项目恢复链。
    final project = currentProject;
    if (project != null) {
      loadProject(project.rootPath);
      return;
    }
    _projectCreationController?.loadDefaultProject();
  }

  @override
  void onCreateFileRequested() {
    // 中文注释: 文件创建继续统一落到工作区命令表单，后续 CLI 也能共用同一用例。
    _showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFile,
        title: '新建文件',
        description: '在项目目录下创建一个新文件。',
        confirmLabel: '创建文件',
        status: '',
        projectTitle: '',
        projectType: '',
        genre: '',
        premise: '',
        notes: '',
        relativePath: _workspaceCommandDefaultTargetService
            .createFileDirectory(),
        entryName: 'new_file.md',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  @override
  void onCreateFolderRequested() {
    // 中文注释: 新建文件夹与新建文件共用命令面板，减少壳层表单散落。
    _showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFolder,
        title: '新建文件夹',
        description: '在项目目录下创建一个新目录。',
        confirmLabel: '创建目录',
        status: '',
        projectTitle: '',
        projectType: '',
        genre: '',
        premise: '',
        notes: '',
        relativePath: _workspaceCommandDefaultTargetService
            .createFolderParentDirectory(),
        entryName: 'new_folder',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  @override
  void onImportRequested() {
    // 中文注释: 导入入口统一走共享命令构建服务，项目类型差异留给策略层处理。
    final project = currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    _showWorkspaceCommand(
      _projectImportWorkspaceCommandViewDataService.build(
        projectType: project.projectType,
      ),
    );
  }

  @override
  void onCreateChapterRequested() {
    // 中文注释: 当前章节创建仍走自然语言发送链，这里只给统一提示，不偷偷生成空稿。
    _announce('直接在右侧输入章节需求并发送，当前版本会自动保存到 chapters/。');
  }

  @override
  void onSaveCurrentRequested() {
    // 中文注释: 工具栏保存统一收口到当前工作区活动文档。
    _saveCurrentDocument();
  }

  @override
  void onProjectAgentGroupRequested() {
    // 中文注释: 项目级智能体组入口必须在任意已打开项目下稳定可达，因此这里直接打开正式配置浮层。
    final viewData = _readProjectAgentGroupWorkspaceViewData();
    if (viewData == null) {
      _announce('请先打开项目，再配置当前项目的智能体组。');
      return;
    }
    _mutateWorkbench(
      (current) => current.copyWith(projectAgentGroupWorkspace: viewData),
    );
  }

  @override
  void onProjectAgentGroupDismissed() {
    // 中文注释: 项目级组配置浮层关闭只清理当前 overlay 状态，不影响会话和资源区。
    _mutateWorkbench(
      (current) => current.copyWith(projectAgentGroupWorkspace: null),
    );
  }

  @override
  void onProjectAgentGroupSelected(String groupId) {
    // 中文注释: 组切换属于项目级协作基线变更，因此这里统一走共享选择链并在成功后刷新浮层内容。
    unawaited(_selectProjectAgentGroupAndRefreshOverlay(groupId));
  }

  @override
  void onAgentEcosystemRequested() {
    // 中文注释: 工作区只发起全局导航请求，不直接操作生态页数据。
    _showAgentEcosystem();
  }

  @override
  void onCurrentAgentSkillLoadoutRequested() {
    final agentId = _readWorkbench().agentSelector.currentAgentId.trim();
    if (agentId.isEmpty) {
      _announce('当前没有可定位的会话智能体。');
      return;
    }
    _showCurrentAgentSkillLoadout(agentId);
  }

  @override
  void onTasksRequested() {
    // 中文注释: 历史任务入口统一折返到长任务总站，工作台内不再保留第二套任务空间。
    _showLongTaskStation();
  }

  void onLongTaskStationRequested() {
    // 中文注释: 长任务总站入口不再混进工作区自身状态机。
    _showLongTaskStation();
  }

  @override
  void onReviewsRequested() {
    // 中文注释: 历史审稿入口同样折返到总站，具体结果查看回到工作台文件区。
    _showLongTaskStation();
  }

  @override
  void onTemplatesRequested() {
    // 中文注释: 模板页导航只发起全局切页请求，不带模板业务规则。
    _showPromptTemplates();
  }

  @override
  void onProjectAssetsRequested() {
    // 中文注释: 项目资产页作为独立子域入口，从工作区只保留跳转动作。
    _showProjectAssets();
  }

  @override
  void onCurrentAgentExpressionConstraintsRequested() {
    final agentId = _readWorkbench().agentSelector.currentAgentId.trim();
    if (agentId.isEmpty) {
      _announce('当前没有可定位的会话智能体。');
      return;
    }
    _showCurrentAgentExpressionConstraints(agentId);
  }

  void onInspirationWorkbenchRequested() {
    // 中文注释: 灵感工作台从资源区独立进入，工作区只负责发起导航，不参与其状态机。
    _showInspirationWorkbench();
  }

  @override
  void onResourceEntrySelected(String entryId) {
    // 中文注释: 资源树点击统一走真实工作区读取链，避免 widget 直接读文件。
    _openResource(entryId);
  }

  @override
  void onWorkspaceCommandDismissed() {
    // 中文注释: 工作区命令关闭只清理弹层状态，不触碰项目本身。
    _mutateWorkbench((current) => current.copyWith(workspaceCommand: null));
  }

  @override
  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    unawaited(_pickImportFiles(request));
  }

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    // 中文注释: 工作区命令统一在这里分派到共享用例，界面层不直接碰业务依赖。
    switch (request.mode) {
      case WorkspaceCommandMode.editProjectInfo:
        _submitProjectInfoCommand(request);
        return;
      case WorkspaceCommandMode.createFile:
        _submitCreateFileCommand(request);
        return;
      case WorkspaceCommandMode.createFolder:
        _submitCreateFolderCommand(request);
        return;
      case WorkspaceCommandMode.importFiles:
        _submitImportFilesCommand(request);
        return;
    }
  }

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    // 中文注释: 文档动作统一落到工作区控制器，保证文档标签、资源树和任务动作一起演进。
    switch (action) {
      case DocumentToolbarAction.save:
        _saveCurrentDocument();
        break;
      case DocumentToolbarAction.render:
        _toggleActiveDocumentRenderMode();
        break;
      case DocumentToolbarAction.outline:
        _openLikelyOutlineDocument();
        break;
      case DocumentToolbarAction.review:
        _createReviewTaskForCurrentDocument();
        break;
    }
  }

  @override
  void onDocumentSelected(String documentId) {
    // 中文注释: 标签切换只修改活动文档指针，不产生读盘副作用。
    final state = _readProjectState();
    if (documentId.trim().isEmpty || documentId == state.activeOpenDocumentId) {
      return;
    }
    _writeProjectState(state.copyWith(activeOpenDocumentId: documentId));
    _mutateWorkbench(
      (current) =>
          applyWorkbenchState(current.copyWith(generationStatus: '已切换文档。')),
    );
    _persistWorkbenchSnapshot();
  }

  @override
  void onDocumentClosed(String documentId) {
    // 中文注释: 关闭标签只变更内存态，保存行为仍旧必须显式触发。
    final state = _readProjectState();
    final index = state.openDocuments.indexWhere(
      (document) => document.id == documentId,
    );
    if (index < 0) {
      return;
    }
    final nextDocuments = List<OpenDocumentState>.from(state.openDocuments)
      ..removeAt(index);
    var nextActiveDocumentId = state.activeOpenDocumentId;
    if (nextActiveDocumentId == documentId) {
      if (nextDocuments.isEmpty) {
        nextActiveDocumentId = '';
      } else if (index >= nextDocuments.length) {
        nextActiveDocumentId = nextDocuments.last.id;
      } else {
        nextActiveDocumentId = nextDocuments[index].id;
      }
    }
    _writeProjectState(
      state.copyWith(
        openDocuments: nextDocuments,
        activeOpenDocumentId: nextActiveDocumentId,
      ),
    );
    _mutateWorkbench(
      (current) =>
          applyWorkbenchState(current.copyWith(generationStatus: '已关闭文档。')),
    );
    _persistWorkbenchSnapshot();
  }

  @override
  void onDocumentBodyChanged(String value) {
    // 中文注释: 文本编辑只变更活动文档内容和脏标记，不在输入时做任何持久化。
    final active = _activeOpenDocument();
    if (active == null) {
      return;
    }
    _replaceOpenDocument(
      active.copyWith(content: value, isDirty: true, isRendered: false),
    );
    _mutateWorkbench((current) => applyWorkbenchState(current));
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
    _persistWorkbenchSnapshot();
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
      _persistWorkbenchSnapshot();
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
      _announce('请先选择至少一个要导入的文件。');
      return;
    }
    try {
      final result = await _projectImportExecutionService.execute(
        project: project,
        request: ProjectImportRequest(
          sourcePaths: policy.sourcePaths,
          targetDirectory: policy.resolvedTargetDirectory,
          autoDeconstruct: policy.autoDeconstruct,
        ),
      );
      final selectedId = result.autoDeconstructionPreviewPath.trim();
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
      _announce('导入文件失败：$error');
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

  void _showWorkspaceCommand(WorkspaceCommandViewData command) {
    // 中文注释: 工作区命令弹层通过统一入口挂到工作台视图，避免每个按钮自己持有表单状态。
    _mutateWorkbench((current) => current.copyWith(workspaceCommand: command));
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

  Future<void> _persistWorkbenchSnapshot() async {
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
      final payload = <String, Object?>{
        'project_root_path': project.rootPath,
        'active_document_path': _readWorkbench().activeDocumentPath,
        'expanded_directories': state.expandedResourceDirectories.toList(
          growable: false,
        ),
        'selected_conversation_agent_id':
            _readWorkbench().agentSelector.currentAgentId,
      };
      final currentSnapshot = _mapValue(
        settings.extraSettings['workbench_state'],
      );
      if (_normalizePathForCompare(
            _stringValue(currentSnapshot['project_root_path']),
          ) ==
          _normalizePathForCompare(project.rootPath)) {
        if (_listEquals(
              ValueReaders.stringList(currentSnapshot['expanded_directories']),
              state.expandedResourceDirectories.toList(growable: false),
            ) &&
            _stringValue(currentSnapshot['active_document_path']) ==
                _readWorkbench().activeDocumentPath &&
            _stringValue(currentSnapshot['selected_conversation_agent_id']) ==
                _readWorkbench().agentSelector.currentAgentId) {
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
    _persistWorkbenchSnapshot();
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
    final directory = Directory(
      _resolveProjectFilePath(rootPath, relativeRoot),
    );
    if (!await directory.exists()) {
      return;
    }
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      final relativePath = _relativePathFromAbsolute(rootPath, entity.path);
      if (relativePath.isNotEmpty) {
        yield relativePath;
      }
    }
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
    return value.trim().replaceAll('\\', '/');
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
    // 中文注释: 首次加载项目时只找最合适的可读文本文件，不在这里做重型策略判断。
    for (final candidate
        in _workspaceResourceDisplayService.likelyOutlineDocumentCandidates()) {
      for (final entry in entries) {
        if (_stringValue(entry['relative_path']) == candidate &&
            entry['is_dir'] != true) {
          return candidate;
        }
      }
    }
    for (final entry in entries) {
      final relativePath = _stringValue(entry['relative_path']);
      if (entry['is_dir'] == true ||
          _workspaceResourceDisplayService.shouldHidePath(relativePath)) {
        continue;
      }
      if (_canReadAsText(relativePath)) {
        return relativePath;
      }
    }
    return '';
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

  bool _canReadAsText(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml');
  }

  bool _canRender(String relativePath) {
    return relativePath.toLowerCase().endsWith('.md');
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
}

const Set<String> _informationProjectionPaths = <String>{
  InformationProjectionDocument.knowledgeSummaryRelativePath,
  InformationProjectionDocument.designSummaryRelativePath,
  InformationProjectionDocument.researchSummaryRelativePath,
  InformationProjectionDocument.referenceBoundaryRelativePath,
};
