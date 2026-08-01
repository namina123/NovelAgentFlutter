import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../app/state/project_lifecycle_coordinator.dart';
import '../../../../shared/services/user_facing_error_humanizer.dart';
import '../../../workbench/application/services/desktop_project_directory_picker_service.dart';
import '../../../workbench/application/services/project_creation_phase_resolver_service.dart';
import '../../../workbench/application/services/project_launcher_view_data_service.dart';
import '../../../workbench/presentation/models/project_creation_phase.dart';
import '../../../workbench/presentation/models/project_create_request_view_data.dart';
import '../../../workbench/presentation/models/project_launcher_view_data.dart';
import '../../../workbench/presentation/models/workbench_view_data.dart';
import '../services/project_creation_expression_constraint_defaults_service.dart';

class ProjectCreationController {
  ProjectCreationController({
    required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required DesktopProjectDirectoryPickerService
    desktopProjectDirectoryPickerService,
    required ProjectLauncherViewDataService projectLauncherViewDataService,
    required ProjectLifecycleCoordinator projectLifecycleCoordinator,
    required WorkbenchViewData Function() readWorkbench,
    required void Function(
      WorkbenchViewData Function(WorkbenchViewData current),
    )
    mutateWorkbench,
    required ProjectDescriptor? Function() readCurrentProject,
    Future<void> Function(ProjectDescriptor project)? onProjectCreatedAndOpened,
    required void Function({required String status})
    resetToProjectlessWorkbench,
    required void Function(String message) announce,
    required AppSettings? Function() readSettings,
    required ProjectGeneralContinuitySetupService
    projectGeneralContinuitySetupService,
    ProjectCreationExpressionConstraintDefaultsService?
    projectCreationExpressionConstraintDefaultsService,
    ProjectCreationPhaseResolverService? projectCreationPhaseResolverService,
    BookDeconstructionProjectSetupDocumentService?
    bookDeconstructionProjectSetupDocumentService,
    BookDeconstructionProjectSetupResolverService?
    bookDeconstructionProjectSetupResolverService,
    required String defaultProjectsRootPath,
    required bool isMobileProjectRootLocked,
  }) : _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _desktopProjectDirectoryPickerService =
           desktopProjectDirectoryPickerService,
       _projectLauncherViewDataService = projectLauncherViewDataService,
       _projectLifecycleCoordinator = projectLifecycleCoordinator,
       _readWorkbench = readWorkbench,
       _mutateWorkbench = mutateWorkbench,
       _readCurrentProject = readCurrentProject,
       _onProjectCreatedAndOpened = onProjectCreatedAndOpened,
       _resetToProjectlessWorkbench = resetToProjectlessWorkbench,
       _announce = announce,
       _readSettings = readSettings,
       _projectGeneralContinuitySetupService =
           projectGeneralContinuitySetupService,
       _projectCreationExpressionConstraintDefaultsService =
           projectCreationExpressionConstraintDefaultsService,
       _projectCreationPhaseResolverService =
           projectCreationPhaseResolverService ??
           const ProjectCreationPhaseResolverService(),
       _bookDeconstructionProjectSetupDocumentService =
           bookDeconstructionProjectSetupDocumentService ??
           BookDeconstructionProjectSetupDocumentService(),
       _bookDeconstructionProjectSetupResolverService =
           bookDeconstructionProjectSetupResolverService ??
           const BookDeconstructionProjectSetupResolverService(),
       _defaultProjectsRootPath = defaultProjectsRootPath,
       _isMobileProjectRootLocked = isMobileProjectRootLocked;

  final CreateProjectWorkspaceUseCase _createProjectWorkspaceUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final DesktopProjectDirectoryPickerService
  _desktopProjectDirectoryPickerService;
  final ProjectLauncherViewDataService _projectLauncherViewDataService;
  final ProjectLifecycleCoordinator _projectLifecycleCoordinator;
  final WorkbenchViewData Function() _readWorkbench;
  final void Function(WorkbenchViewData Function(WorkbenchViewData current))
  _mutateWorkbench;
  final ProjectDescriptor? Function() _readCurrentProject;
  final Future<void> Function(ProjectDescriptor project)? _onProjectCreatedAndOpened;
  final void Function({required String status}) _resetToProjectlessWorkbench;
  final void Function(String message) _announce;
  final AppSettings? Function() _readSettings;
  final ProjectGeneralContinuitySetupService
  _projectGeneralContinuitySetupService;
  final ProjectCreationExpressionConstraintDefaultsService?
  _projectCreationExpressionConstraintDefaultsService;
  final ProjectCreationPhaseResolverService
  _projectCreationPhaseResolverService;
  final BookDeconstructionProjectSetupDocumentService
  _bookDeconstructionProjectSetupDocumentService;
  final BookDeconstructionProjectSetupResolverService
  _bookDeconstructionProjectSetupResolverService;
  final String _defaultProjectsRootPath;
  final bool _isMobileProjectRootLocked;

  Future<void> loadDefaultProject() async {
    // 中文注释: 默认项目恢复属于项目创建域入口，避免壳层自己理解“无项目时该怎么办”。
    final result = await _projectLifecycleCoordinator.loadDefaultProject();
    if (!result.isLoaded) {
      _resetToProjectlessWorkbench(status: result.statusMessage);
      await showLauncher(
        result.launcherMode ?? ProjectLauncherMode.create,
        status: result.launcherStatus,
        canDismiss: result.canDismiss,
      );
    }
  }

  Future<void> onCreateProjectRequested() async {
    // 中文注释: 新建项目入口先只负责拉起创建向导，不直接碰工作区状态。
    await showLauncher(
      ProjectLauncherMode.create,
      canDismiss: _readCurrentProject() != null,
    );
  }

  Future<void> onOpenProjectRequested() async {
    // 中文注释: 打开已有项目由该控制器统一处理桌面选路径与项目有效性探测。
    if (_isMobileProjectRootLocked) {
      _announce('移动端暂不支持打开外部目录，请在应用项目目录内选择或新建项目。');
      return;
    }
    final selectedPath = await _desktopProjectDirectoryPickerService
        .pickProjectDirectory();
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      if (_readCurrentProject() == null) {
        await showLauncher(
          ProjectLauncherMode.guard,
          status: '未选择目录。请创建项目，或重新选择已有项目目录。',
          canDismiss: false,
        );
      }
      return;
    }
    final normalizedPath = selectedPath.trim();
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: null,
        generationStatus: '正在打开项目...',
      ),
    );
    final result = await _projectLifecycleCoordinator.openProjectFromPath(
      normalizedPath,
      failureLauncherMode: _readCurrentProject() == null
          ? ProjectLauncherMode.guard
          : null,
      failureLauncherStatus: '所选目录不是有效项目。请选择项目根目录，或直接创建新项目。',
    );
    if (!result.isLoaded) {
      if (result.shouldShowLauncher) {
        await showLauncher(
          result.launcherMode ?? ProjectLauncherMode.guard,
          status: result.launcherStatus,
          canDismiss: result.canDismiss,
        );
      } else {
        _announce(result.statusMessage);
      }
    }
  }

  void onProjectLauncherDismissed() {
    // 中文注释: 弹层关闭只清理启动向导，不反向影响当前项目。
    if (_readCurrentProject() == null) {
      return;
    }
    _mutateWorkbench((current) => current.copyWith(projectLauncher: null));
  }

  Future<void> onProjectLauncherRefreshRequested() async {
    // 中文注释: 启动器刷新沿用当前模式与阶段，避免刷新后把用户带回错误步骤。
    final launcher = _readWorkbench().projectLauncher;
    if (launcher == null) {
      return;
    }
    await showLauncher(
      launcher.mode,
      status: launcher.status,
      draftTitle: launcher.draftTitle,
      selectedProjectTypeId: launcher.selectedProjectTypeId,
      selectedStorageStrategy: ProjectStorageStrategy.fromId(
        launcher.selectedStorageStrategyId,
      ),
      creationPhase: launcher.creationPhase,
      selectedKnowledgeBaseBranchId: launcher.selectedKnowledgeBaseBranchId,
      selectedBookDeconstructionFollowupRouteId:
          launcher.selectedBookDeconstructionFollowupRouteId,
      runtimeBaselineOptions: launcher.runtimeBaselineOptions
          .map(
            (option) => ProjectRuntimeBaselineDefinition(
              id: option.id,
              title: option.title,
              description: option.description,
            ),
          )
          .toList(growable: false),
      selectedRuntimeBaselineId: launcher.selectedRuntimeBaselineId,
      continuityInput: launcher.continuityInput,
      canDismiss: launcher.canDismiss,
    );
  }

  Future<void> onProjectEntryOpened(String projectPath) async {
    // 中文注释: 从列表打开项目时直接切换工作区，避免项目选择页继续持有业务状态。
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: null,
        generationStatus: '正在打开项目...',
      ),
    );
    final result = await _projectLifecycleCoordinator.openProjectFromPath(
      projectPath,
      failureLauncherMode: _readCurrentProject() == null
          ? ProjectLauncherMode.guard
          : null,
      failureLauncherStatus: '所选目录不是有效项目。请选择项目根目录，或直接创建新项目。',
    );
    if (!result.isLoaded) {
      if (result.shouldShowLauncher) {
        await showLauncher(
          result.launcherMode ?? ProjectLauncherMode.guard,
          status: result.launcherStatus,
          canDismiss: result.canDismiss,
        );
      } else {
        _announce(result.statusMessage);
      }
    }
  }

  Future<void> onProjectCreationSubmitted(
    ProjectCreateRequestViewData request,
  ) async {
    // 中文注释: 创建向导按项目类型对应的阶段树推进，拆书会插入“承接路线”，不会覆盖存储策略。
    final launcher = _readWorkbench().projectLauncher;
    final currentPhase =
        launcher?.creationPhase ?? ProjectCreationPhase.projectType;
    final cleanTitle = request.title.trim();
    final projectTypeId = request.projectTypeId.trim().isEmpty
        ? 'novel'
        : request.projectTypeId.trim();
    final requiresRuntimeBaseline = _requiresRuntimeBaseline(projectTypeId);
    // 中文注释: 默认跳过存储策略步时，若请求未显式带策略 id，则回落类型默认（通常 markdown；知识库 sqlite）。
    final storageStrategy = request.storageStrategyId.trim().isEmpty
        ? _projectCreationPhaseResolverService.defaultStorageStrategy(
            projectTypeId,
          )
        : ProjectStorageStrategy.fromId(request.storageStrategyId);
    final creationPlan = _createProjectWorkspaceUseCase.prepare(
      ProjectCreateRequest(
        title: cleanTitle,
        projectTypeId: projectTypeId,
        storageStrategy: storageStrategy,
        projectBranchId: request.knowledgeBaseBranchId.trim(),
        runtimeBaselineId: request.runtimeBaselineId.trim(),
      ),
    );
    final nextPhase = _projectCreationPhaseResolverService.nextPhaseAfter(
      currentPhase: currentPhase,
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaseline,
    );
    if (nextPhase != null) {
      await showLauncher(
        ProjectLauncherMode.create,
        status: _statusForNextPhase(nextPhase),
        draftTitle: cleanTitle,
        selectedProjectTypeId: projectTypeId,
        selectedStorageStrategy: storageStrategy,
        selectedKnowledgeBaseBranchId: request.knowledgeBaseBranchId,
        selectedBookDeconstructionFollowupRouteId:
            request.bookDeconstructionFollowupRouteId,
        continuityInput: request.continuityInput,
        creationPhase: nextPhase,
        runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
        selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
        canDismiss: _readCurrentProject() != null,
      );
      return;
    }
    if (!creationPlan.canCreate) {
      await showLauncher(
        ProjectLauncherMode.create,
        status: '当前项目类型需要先选择长任务运行基准。',
        draftTitle: creationPlan.request.title,
        selectedProjectTypeId: creationPlan.request.projectTypeId,
        selectedStorageStrategy: creationPlan.request.storageStrategy,
        selectedKnowledgeBaseBranchId: creationPlan.request.projectBranchId,
        selectedBookDeconstructionFollowupRouteId:
            request.bookDeconstructionFollowupRouteId,
        continuityInput: request.continuityInput,
        creationPhase: ProjectCreationPhase.runtimeBaseline,
        runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
        selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
        canDismiss: _readCurrentProject() != null,
      );
      return;
    }
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: _projectLauncherViewDataService.build(
          mode: ProjectLauncherMode.create,
          projectsRootPath: _defaultProjectsRootPath,
          projects: const <JsonMap>[],
          status: '正在创建项目：${cleanTitle.isEmpty ? '未命名项目' : cleanTitle}',
          draftTitle: creationPlan.request.title,
          selectedProjectTypeId: creationPlan.request.projectTypeId,
          selectedStorageStrategy: creationPlan.request.storageStrategy,
          selectedKnowledgeBaseBranchId: creationPlan.request.projectBranchId,
          selectedBookDeconstructionFollowupRouteId:
              request.bookDeconstructionFollowupRouteId,
          continuityInput: request.continuityInput,
          creationPhase: currentPhase,
          runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
          selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
          canDismiss: _readCurrentProject() != null,
          allowOpenExisting: !_isMobileProjectRootLocked,
        ),
      ),
    );
    ProjectDescriptor? createdProject;
    try {
      final project = await _createProjectWorkspaceUseCase.executePrepared(
        projectsRootPath: _defaultProjectsRootPath,
        plan: creationPlan,
      );
      createdProject = project;
      await _applyBookDeconstructionSetupIfNeeded(
        project,
        request.bookDeconstructionFollowupRouteId,
      );
      await _applyContinuityInputIfNeeded(project, request.continuityInput);
      final settings = _readSettings();
      if (settings != null) {
        await _projectCreationExpressionConstraintDefaultsService
            ?.applyDefaults(project, settings);
      }
      _mutateWorkbench((current) => current.copyWith(projectLauncher: null));
      final result = await _projectLifecycleCoordinator.openProjectFromPath(
        project.rootPath,
        failureLauncherMode: ProjectLauncherMode.create,
        failureLauncherStatus: '项目已创建，但自动打开失败：${project.rootPath}',
      );
      if (!result.isLoaded) {
        await showLauncher(
          result.launcherMode ?? ProjectLauncherMode.create,
          status: result.launcherStatus,
          canDismiss: result.canDismiss,
          draftTitle: creationPlan.request.title,
          selectedProjectTypeId: creationPlan.request.projectTypeId,
          selectedStorageStrategy: creationPlan.request.storageStrategy,
          selectedKnowledgeBaseBranchId: creationPlan.request.projectBranchId,
          selectedBookDeconstructionFollowupRouteId:
              request.bookDeconstructionFollowupRouteId,
          continuityInput: request.continuityInput,
          creationPhase: _failurePhaseFor(
            currentPhase: currentPhase,
            creationPlan: creationPlan,
          ),
          runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
          selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
        );
        _announce('项目已创建，但自动打开失败：${project.rootPath}');
        return;
      }
      await _onProjectCreatedAndOpened?.call(project);
      _mutateWorkbench(
        (current) => current.copyWith(
          projectLauncher: null,
          projectAgentGroupWorkspace: null,
          workspaceCommand: null,
        ),
      );
      try {
        _announce('已创建并打开新项目：${project.name}');
      } catch (_) {
        _mutateWorkbench(
          (current) =>
              current.copyWith(generationStatus: '已创建并打开新项目：${project.name}'),
        );
      }
    } catch (error) {
      final currentProject = _readCurrentProject();
      if (createdProject != null &&
          currentProject != null &&
          currentProject.rootPath.trim() == createdProject.rootPath.trim()) {
        _mutateWorkbench(
          (current) => current.copyWith(
            projectLauncher: null,
            projectAgentGroupWorkspace: null,
            workspaceCommand: null,
            generationStatus: '项目已创建并打开，但${UserFacingErrorHumanizer.humanize(error, action: '刷新界面')}',
          ),
        );
        _announce('项目已创建并打开，但${UserFacingErrorHumanizer.humanize(error, action: '刷新界面')}');
        return;
      }
      await showLauncher(
        ProjectLauncherMode.create,
        status: UserFacingErrorHumanizer.humanize(error, action: '创建项目'),
        draftTitle: creationPlan.request.title,
        selectedProjectTypeId: creationPlan.request.projectTypeId,
        selectedStorageStrategy: creationPlan.request.storageStrategy,
        selectedKnowledgeBaseBranchId: creationPlan.request.projectBranchId,
        selectedBookDeconstructionFollowupRouteId:
            request.bookDeconstructionFollowupRouteId,
        continuityInput: request.continuityInput,
        creationPhase: _failurePhaseFor(
          currentPhase: currentPhase,
          creationPlan: creationPlan,
        ),
        runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
        selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
      );
    }
  }

  Future<void> onProjectCreationBackRequested() async {
    // 中文注释: 返回动作只回退创建阶段，不关闭当前项目，也不在这里重置已选领域输入。
    final launcher = _readWorkbench().projectLauncher;
    if (launcher == null || launcher.mode != ProjectLauncherMode.create) {
      return;
    }
    switch (launcher.creationPhase) {
      case ProjectCreationPhase.projectType:
        if (_readCurrentProject() == null) {
          await showLauncher(
            ProjectLauncherMode.guard,
            status: '当前没有有效项目。请先创建项目，或打开已有项目。',
            canDismiss: false,
          );
        }
        return;
      case ProjectCreationPhase.knowledgeBaseBranch:
      case ProjectCreationPhase.storageStrategy:
      case ProjectCreationPhase.bookDeconstructionFollowup:
      case ProjectCreationPhase.runtimeBaseline:
        final previousPhase = _projectCreationPhaseResolverService
            .previousPhaseBefore(
              currentPhase: launcher.creationPhase,
              projectTypeId: launcher.selectedProjectTypeId,
              requiresRuntimeBaselineSelection: _requiresRuntimeBaseline(
                launcher.selectedProjectTypeId,
              ),
            );
        if (previousPhase == null) {
          return;
        }
        await showLauncher(
          ProjectLauncherMode.create,
          status: _statusForReturnPhase(previousPhase),
          draftTitle: launcher.draftTitle,
          selectedProjectTypeId: launcher.selectedProjectTypeId,
          selectedStorageStrategy: ProjectStorageStrategy.fromId(
            launcher.selectedStorageStrategyId,
          ),
          selectedKnowledgeBaseBranchId: launcher.selectedKnowledgeBaseBranchId,
          selectedBookDeconstructionFollowupRouteId:
              launcher.selectedBookDeconstructionFollowupRouteId,
          continuityInput: launcher.continuityInput,
          creationPhase: previousPhase,
          runtimeBaselineOptions: launcher.runtimeBaselineOptions
              .map(
                (option) => ProjectRuntimeBaselineDefinition(
                  id: option.id,
                  title: option.title,
                  description: option.description,
                ),
              )
              .toList(growable: false),
          selectedRuntimeBaselineId: launcher.selectedRuntimeBaselineId,
          canDismiss: launcher.canDismiss,
        );
        return;
    }
  }

  Future<void> showLauncher(
    ProjectLauncherMode mode, {
    String status = '',
    String draftTitle = '',
    String selectedProjectTypeId = 'novel',
    ProjectStorageStrategy selectedStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    ProjectCreationPhase creationPhase = ProjectCreationPhase.projectType,
    String selectedKnowledgeBaseBranchId = '',
    String selectedBookDeconstructionFollowupRouteId =
        BookDeconstructionProjectSetupResolverService.continuationRouteId,
    List<ProjectRuntimeBaselineDefinition> runtimeBaselineOptions =
        const <ProjectRuntimeBaselineDefinition>[],
    String selectedRuntimeBaselineId = '',
    ProjectContinuityInputProfile continuityInput =
        const ProjectContinuityInputProfile(),
    bool? canDismiss,
  }) async {
    // 中文注释: 项目创建与打开共用同一启动器数据源，避免两个入口各自拼装弹层。
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: _projectLauncherViewDataService.build(
          mode: mode,
          projectsRootPath: _defaultProjectsRootPath,
          projects: const <JsonMap>[],
          status: status,
          draftTitle: draftTitle,
          selectedProjectTypeId: selectedProjectTypeId,
          selectedStorageStrategy: selectedStorageStrategy,
          creationPhase: creationPhase,
          selectedKnowledgeBaseBranchId: selectedKnowledgeBaseBranchId,
          selectedBookDeconstructionFollowupRouteId:
              selectedBookDeconstructionFollowupRouteId,
          runtimeBaselineOptions: runtimeBaselineOptions,
          selectedRuntimeBaselineId: selectedRuntimeBaselineId,
          continuityInput: continuityInput,
          canDismiss: canDismiss ?? _readCurrentProject() != null,
          allowOpenExisting: !_isMobileProjectRootLocked,
        ),
        projectAgentGroupWorkspace: null,
        workspaceCommand: null,
      ),
    );
  }

  Future<void> _applyBookDeconstructionSetupIfNeeded(
    ProjectDescriptor project,
    String followupRouteId,
  ) async {
    if (project.projectType != 'book_deconstruction') {
      return;
    }
    final normalizedRouteId = _bookDeconstructionProjectSetupResolverService
        .normalizeRouteId(followupRouteId);
    final setup = _bookDeconstructionProjectSetupDocumentService.create(
      followupRouteId: normalizedRouteId,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: BookDeconstructionProjectSetupDocumentService.relativePath,
      content: _bookDeconstructionProjectSetupDocumentService.encode(setup),
    );
  }

  bool _requiresRuntimeBaseline(String projectTypeId) {
    final definition = const ProjectTypeCatalogService().definitionOf(
      projectTypeId,
    );
    return definition.requiresRuntimeBaselineSelection;
  }

  ProjectCreationPhase _failurePhaseFor({
    required ProjectCreationPhase currentPhase,
    required ProjectCreationPlan creationPlan,
  }) {
    if (creationPlan.request.runtimeBaselineId.trim().isNotEmpty) {
      return ProjectCreationPhase.runtimeBaseline;
    }
    if (currentPhase == ProjectCreationPhase.projectType) {
      return _projectCreationPhaseResolverService.nextPhaseAfter(
            currentPhase: currentPhase,
            projectTypeId: creationPlan.request.projectTypeId,
            requiresRuntimeBaselineSelection: _requiresRuntimeBaseline(
              creationPlan.request.projectTypeId,
            ),
          ) ??
          ProjectCreationPhase.runtimeBaseline;
    }
    return currentPhase;
  }

  String _statusForNextPhase(ProjectCreationPhase nextPhase) {
    switch (nextPhase) {
      case ProjectCreationPhase.projectType:
        return '继续确认项目类型。';
      case ProjectCreationPhase.knowledgeBaseBranch:
        return '已选择资料知识库，继续确定使用结构化资料库还是语料库。';
      case ProjectCreationPhase.storageStrategy:
        return '已确认上一步，继续确定主存储策略。';
      case ProjectCreationPhase.bookDeconstructionFollowup:
        return '已选择拆书项目类型，继续确定默认承接路线。';
      case ProjectCreationPhase.runtimeBaseline:
        return '继续选择长任务运行基准。';
    }
  }

  String _statusForReturnPhase(ProjectCreationPhase phase) {
    switch (phase) {
      case ProjectCreationPhase.projectType:
        return '返回项目类型选择。';
      case ProjectCreationPhase.knowledgeBaseBranch:
        return '返回知识库分支选择。';
      case ProjectCreationPhase.storageStrategy:
        return '返回主存储策略选择。';
      case ProjectCreationPhase.bookDeconstructionFollowup:
        return '返回拆书承接路线选择。';
      case ProjectCreationPhase.runtimeBaseline:
        return '返回长任务运行基准选择。';
    }
  }

  Future<void> _applyContinuityInputIfNeeded(
    ProjectDescriptor project,
    ProjectContinuityInputProfile input,
  ) async {
    if (!_supportsContinuityInput(project.projectType)) {
      return;
    }
    try {
      await _projectGeneralContinuitySetupService.applyInput(project, input);
    } catch (error) {
      _announce(
        '项目已创建，但${UserFacingErrorHumanizer.humanize(error, action: '写入连续性默认设置')}',
      );
    }
  }

  bool _supportsContinuityInput(String projectTypeId) {
    final cleanType = projectTypeId.trim();
    return cleanType == 'novel' || cleanType == 'long_novel';
  }
}
