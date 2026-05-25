import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../workbench/application/services/desktop_project_directory_picker_service.dart';
import '../../../workbench/application/services/project_launcher_view_data_service.dart';
import '../../../workbench/presentation/models/project_creation_phase.dart';
import '../../../workbench/presentation/models/project_create_request_view_data.dart';
import '../../../workbench/presentation/models/project_launcher_view_data.dart';
import '../../../workbench/presentation/models/workbench_view_data.dart';

class ProjectCreationController {
  ProjectCreationController({
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
    required DiscoverProjectsUseCase discoverProjectsUseCase,
    required DesktopProjectDirectoryPickerService
    desktopProjectDirectoryPickerService,
    required ProjectLauncherViewDataService projectLauncherViewDataService,
    required WorkbenchViewData Function() readWorkbench,
    required void Function(WorkbenchViewData Function(WorkbenchViewData current))
    mutateWorkbench,
    required ProjectDescriptor? Function() readCurrentProject,
    required Future<bool> Function(String rootPath) loadProject,
    required void Function({required String status}) resetToProjectlessWorkbench,
    required void Function(String message) announce,
    required AppSettings? Function() readSettings,
    required String defaultProjectsRootPath,
    required List<String> settingsSearchRoots,
    required bool isMobileProjectRootLocked,
  }) : _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _discoverProjectsUseCase = discoverProjectsUseCase,
       _desktopProjectDirectoryPickerService =
           desktopProjectDirectoryPickerService,
       _projectLauncherViewDataService = projectLauncherViewDataService,
       _readWorkbench = readWorkbench,
       _mutateWorkbench = mutateWorkbench,
       _readCurrentProject = readCurrentProject,
       _loadProject = loadProject,
       _resetToProjectlessWorkbench = resetToProjectlessWorkbench,
       _announce = announce,
       _readSettings = readSettings,
       _defaultProjectsRootPath = defaultProjectsRootPath,
       _settingsSearchRoots = settingsSearchRoots,
       _isMobileProjectRootLocked = isMobileProjectRootLocked;

  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final CreateProjectWorkspaceUseCase _createProjectWorkspaceUseCase;
  final DiscoverProjectsUseCase _discoverProjectsUseCase;
  final DesktopProjectDirectoryPickerService _desktopProjectDirectoryPickerService;
  final ProjectLauncherViewDataService _projectLauncherViewDataService;
  final WorkbenchViewData Function() _readWorkbench;
  final void Function(WorkbenchViewData Function(WorkbenchViewData current))
  _mutateWorkbench;
  final ProjectDescriptor? Function() _readCurrentProject;
  final Future<bool> Function(String rootPath) _loadProject;
  final void Function({required String status}) _resetToProjectlessWorkbench;
  final void Function(String message) _announce;
  final AppSettings? Function() _readSettings;
  final String _defaultProjectsRootPath;
  final List<String> _settingsSearchRoots;
  final bool _isMobileProjectRootLocked;

  Future<void> loadDefaultProject() async {
    // 中文注释: 默认项目恢复属于项目创建域入口，避免壳层自己理解“无项目时该怎么办”。
    final settings = _readSettings();
    if (settings == null) {
      return;
    }
    final defaultPath = settings.defaultProjectPath.trim();
    if (defaultPath.isEmpty) {
      _resetToProjectlessWorkbench(
        status: '请先创建项目，或在桌面端打开一个已有项目。',
      );
      await showLauncher(
        ProjectLauncherMode.create,
        status: '当前还没有有效项目。请先创建项目，或打开已有项目。',
        canDismiss: false,
      );
      return;
    }
    final loaded = await _loadProject(defaultPath);
    if (!loaded) {
      _resetToProjectlessWorkbench(
        status: '当前没有有效项目。请先创建项目，或打开已有项目。',
      );
      await showLauncher(
        ProjectLauncherMode.create,
        status: '未识别到有效项目：$defaultPath',
        canDismiss: false,
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
      _announce('移动端只允许在应用项目目录内创建项目。');
      return;
    }
    final selectedPath = await _desktopProjectDirectoryPickerService
        .pickProjectDirectory();
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      if (_readCurrentProject() == null) {
        await showLauncher(
          ProjectLauncherMode.create,
          status: '未选择目录。请创建项目，或重新选择已有项目目录。',
          canDismiss: false,
        );
      }
      return;
    }
    final normalizedPath = selectedPath.trim();
    final snapshot = await _loadProjectWorkspaceUseCase.execute(normalizedPath);
    if (snapshot == null) {
      if (_readCurrentProject() == null) {
        await showLauncher(
          ProjectLauncherMode.create,
          status: '所选目录不是有效项目。请选择项目根目录，或直接创建新项目。',
          canDismiss: false,
        );
      } else {
        _announce('所选目录不是有效项目。请选择包含项目配置的项目根目录。');
      }
      return;
    }
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: null,
        generationStatus: '正在打开项目...',
      ),
    );
    await _loadProject(snapshot.project.rootPath);
  }

  void onProjectLauncherDismissed() {
    // 中文注释: 弹层关闭只清理启动向导，不反向影响当前项目。
    if (_readCurrentProject() == null) {
      return;
    }
    _mutateWorkbench(
      (current) => current.copyWith(projectLauncher: null),
    );
  }

  Future<void> onProjectLauncherRefreshRequested() async {
    // 中文注释: 刷新项目列表时重新跑发现逻辑，但保留当前创建向导上下文。
    final launcher = _readWorkbench().projectLauncher;
    if (launcher == null) {
      return;
    }
    await showLauncher(
      launcher.mode,
      status: launcher.mode == ProjectLauncherMode.open
          ? '项目列表已刷新。'
          : launcher.status,
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
    await _loadProject(projectPath);
  }

  Future<void> onProjectCreationSubmitted(
    ProjectCreateRequestViewData request,
  ) async {
    // 中文注释: 项目创建先走 core 三段式 prepare，再决定是否需要补长任务运行基准。
    final cleanTitle = request.title.trim();
    final projectTypeId = request.projectTypeId.trim().isEmpty
        ? 'novel'
        : request.projectTypeId.trim();
    final storageStrategy = ProjectStorageStrategy.fromId(
      request.storageStrategyId,
    );
    final creationPlan = _createProjectWorkspaceUseCase.prepare(
      ProjectCreateRequest(
        title: cleanTitle,
        projectTypeId: projectTypeId,
        storageStrategy: storageStrategy,
        runtimeBaselineId: request.runtimeBaselineId.trim(),
      ),
    );
    if (!creationPlan.canCreate) {
      _mutateWorkbench(
        (current) => current.copyWith(
          projectLauncher: _projectLauncherViewDataService.build(
            mode: ProjectLauncherMode.create,
            projectsRootPath: _defaultProjectsRootPath,
            projects: const <JsonMap>[],
            status: '当前项目类型需要先选择长任务运行基准。',
            draftTitle: creationPlan.request.title,
            selectedProjectTypeId: creationPlan.request.projectTypeId,
            selectedStorageStrategy: creationPlan.request.storageStrategy,
            creationPhase: ProjectCreationPhase.runtimeBaseline,
            runtimeBaselineOptions: creationPlan.runtimeBaselineOptions,
            selectedRuntimeBaselineId: creationPlan.request.runtimeBaselineId,
            canDismiss: _readCurrentProject() != null,
            allowOpenExisting: !_isMobileProjectRootLocked,
          ),
        ),
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
          creationPhase: ProjectCreationPhase.basics,
          canDismiss: _readCurrentProject() != null,
          allowOpenExisting: !_isMobileProjectRootLocked,
        ),
      ),
    );
    try {
      final project = await _createProjectWorkspaceUseCase.executePrepared(
        projectsRootPath: _defaultProjectsRootPath,
        plan: creationPlan,
      );
      _mutateWorkbench((current) => current.copyWith(projectLauncher: null));
      await _loadProject(project.rootPath);
      _announce('已创建并打开新项目：${project.name}');
    } catch (error) {
      await showLauncher(
        ProjectLauncherMode.create,
        status: '创建项目失败：$error',
      );
    }
  }

  Future<void> showLauncher(
    ProjectLauncherMode mode, {
    String status = '',
    String draftTitle = '',
    String selectedProjectTypeId = 'novel',
    ProjectStorageStrategy selectedStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    ProjectCreationPhase creationPhase = ProjectCreationPhase.basics,
    List<ProjectRuntimeBaselineDefinition> runtimeBaselineOptions =
        const <ProjectRuntimeBaselineDefinition>[],
    String selectedRuntimeBaselineId = '',
    bool? canDismiss,
  }) async {
    // 中文注释: 项目创建与打开共用同一启动器数据源，避免两个入口各自拼装弹层。
    final projects = mode == ProjectLauncherMode.open
        ? await _discoverProjectsAcrossRoots()
        : const <JsonMap>[];
    _mutateWorkbench(
      (current) => current.copyWith(
        projectLauncher: _projectLauncherViewDataService.build(
          mode: mode,
          projectsRootPath: _defaultProjectsRootPath,
          projects: projects,
          status: status,
          draftTitle: draftTitle,
          selectedProjectTypeId: selectedProjectTypeId,
          selectedStorageStrategy: selectedStorageStrategy,
          creationPhase: creationPhase,
          runtimeBaselineOptions: runtimeBaselineOptions,
          selectedRuntimeBaselineId: selectedRuntimeBaselineId,
          canDismiss: canDismiss ?? _readCurrentProject() != null,
          allowOpenExisting: !_isMobileProjectRootLocked,
        ),
      ),
    );
  }

  Future<List<JsonMap>> _discoverProjectsAcrossRoots() async {
    // 中文注释: 项目发现按搜索根去重聚合，保留“默认目录外也可打开项目”的桌面能力。
    final roots = <String>[];
    void addRoot(String value) {
      final clean = value.trim();
      if (clean.isEmpty) {
        return;
      }
      final normalized = _normalizePathForCompare(clean);
      final exists = roots.any(
        (entry) => _normalizePathForCompare(entry) == normalized,
      );
      if (!exists) {
        roots.add(clean);
      }
    }

    addRoot(_defaultProjectsRootPath);
    for (final root in _settingsSearchRoots) {
      addRoot(root);
    }

    final projects = <JsonMap>[];
    final seenPaths = <String>{};
    for (final root in roots) {
      final discovered = await _discoverProjectsUseCase.execute(root);
      for (final project in discovered) {
        final path = _stringValue(project['path']);
        final normalized = _normalizePathForCompare(path);
        if (normalized.isEmpty || seenPaths.contains(normalized)) {
          continue;
        }
        seenPaths.add(normalized);
        projects.add(ValueReaders.deepCopyMap(project));
      }
    }
    projects.sort((left, right) {
      final leftTitle = _stringValue(left['title']);
      final rightTitle = _stringValue(right['title']);
      return leftTitle.compareTo(rightTitle);
    });
    return projects;
  }

  String _stringValue(Object? value, [String fallback = '']) {
    // 中文注释: 项目创建层只需要轻量文本归一化，避免把简单投影工具散落到调用方。
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _normalizePathForCompare(String value) {
    // 中文注释: 项目去重按统一大小写与分隔符规则比较，避免同一路径被重复列出。
    return value.trim().replaceAll('\\', '/').toLowerCase();
  }
}
