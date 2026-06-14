import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_creation/application/controllers/project_creation_controller.dart';
import 'package:novel_agent_app/features/workbench/application/services/desktop_project_directory_picker_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_launcher_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_launcher_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('无默认项目时会进入创建启动器', () async {
    final harness = _ProjectCreationHarness(
      settings: const AppSettings(
        defaultProviderId: '',
        defaultAgentId: '',
        defaultModelId: '',
        defaultProjectPath: '',
        autoSaveDrafts: true,
        providers: <ProviderEndpointSettings>[],
      ),
    );

    await harness.controller.loadDefaultProject();

    final launcher = harness.workbench.projectLauncher;
    expect(launcher, isNotNull);
    expect(launcher!.mode, ProjectLauncherMode.create);
    expect(launcher.canDismiss, isFalse);
    expect(launcher.status, contains('当前还没有有效项目'));
    expect(harness.lastProjectlessStatus, contains('请先创建项目'));
  });

  test('长任务项目创建会按三段式推进并最终触发加载', () async {
    final harness = _ProjectCreationHarness();

    await harness.controller.onCreateProjectRequested();
    expect(
      harness.workbench.projectLauncher!.creationPhase,
      ProjectCreationPhase.projectType,
    );

    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '海城长篇',
        projectTypeId: 'long_novel',
        storageStrategyId: 'markdown_project_store',
      ),
    );
    expect(
      harness.workbench.projectLauncher!.creationPhase,
      ProjectCreationPhase.storageStrategy,
    );

    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '海城长篇',
        projectTypeId: 'long_novel',
        storageStrategyId: 'markdown_project_store',
      ),
    );
    final baselineLauncher = harness.workbench.projectLauncher;
    expect(
      baselineLauncher!.creationPhase,
      ProjectCreationPhase.runtimeBaseline,
    );
    expect(baselineLauncher.runtimeBaselineOptions, isNotEmpty);

    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '海城长篇',
        projectTypeId: 'long_novel',
        storageStrategyId: 'markdown_project_store',
        runtimeBaselineId: 'continuous_autonomous',
      ),
    );

    expect(harness.loadedProjectPaths, hasLength(1));
    expect(harness.loadedProjectPaths.single, 'D:/Projects/海城长篇');
    expect(harness.announcements.single, '已创建并打开新项目：海城长篇');
    expect(harness.workbench.projectLauncher, isNull);
  });

  test('创建向导可从运行基准阶段返回到存储策略阶段', () async {
    final harness = _ProjectCreationHarness();

    await harness.controller.onCreateProjectRequested();
    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '回退测试',
        projectTypeId: 'long_novel',
        storageStrategyId: 'markdown_project_store',
      ),
    );
    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '回退测试',
        projectTypeId: 'long_novel',
        storageStrategyId: 'markdown_project_store',
      ),
    );

    expect(
      harness.workbench.projectLauncher!.creationPhase,
      ProjectCreationPhase.runtimeBaseline,
    );

    await harness.controller.onProjectCreationBackRequested();

    final launcher = harness.workbench.projectLauncher;
    expect(launcher, isNotNull);
    expect(launcher!.creationPhase, ProjectCreationPhase.storageStrategy);
    expect(launcher.draftTitle, '回退测试');
    expect(launcher.selectedProjectTypeId, 'long_novel');
  });

  test('一般项目创建后会写入轻量 continuity 默认设置', () async {
    final harness = _ProjectCreationHarness();

    await harness.controller.onCreateProjectRequested();
    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '多世界续写',
        projectTypeId: 'novel',
        storageStrategyId: 'markdown_project_store',
        continuityInput: ProjectContinuityInputProfile(
          usesMultipleWorlds: true,
          usesBranchingRoutes: true,
          worldLabels: <String>['主世界', '镜像线'],
          notes: '主角跨世界保留部分记忆。',
        ),
      ),
    );
    await harness.controller.onProjectCreationSubmitted(
      const ProjectCreateRequestViewData(
        title: '多世界续写',
        projectTypeId: 'novel',
        storageStrategyId: 'markdown_project_store',
        continuityInput: ProjectContinuityInputProfile(
          usesMultipleWorlds: true,
          usesBranchingRoutes: true,
          worldLabels: <String>['主世界', '镜像线'],
          notes: '主角跨世界保留部分记忆。',
        ),
      ),
    );

    expect(harness.loadedProjectPaths.single, 'D:/Projects/多世界续写');
    final input = await harness.projectContinuityInputRepository.load(
      harness.currentProject!,
    );
    expect(input, isNotNull);
    expect(input!.usesMultipleWorlds, isTrue);
    expect(input.usesBranchingRoutes, isTrue);
    expect(input.worldLabels, <String>['主世界', '镜像线']);
    expect(input.notes, '主角跨世界保留部分记忆。');
  });
}

class _ProjectCreationHarness {
  _ProjectCreationHarness({this.settings})
    : _workspacePort = _InMemoryProjectWorkspacePort(),
      _manifestCodecService = ProjectManifestCodecService(),
      workbench = WorkbenchViewData.initial() {
    projectContinuityInputRepository = ProjectContinuityInputRepository(
      workspacePort: _workspacePort,
    );
    final projectGeneralContinuitySetupService =
        ProjectGeneralContinuitySetupService(
          continuityRepository: ProjectContinuityRepository(
            workspacePort: _workspacePort,
          ),
          inputRepository: projectContinuityInputRepository,
        );
    final projectRepository = _FakeProjectRepository(
      workspacePort: _workspacePort,
      manifestCodecService: _manifestCodecService,
    );
    controller = ProjectCreationController(
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: projectRepository,
        projectWorkspacePort: _workspacePort,
      ),
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: projectRepository,
        projectWorkspacePort: _workspacePort,
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      ),
      desktopProjectDirectoryPickerService: _FakeDirectoryPickerService(),
      projectLauncherViewDataService: ProjectLauncherViewDataService(),
      readWorkbench: () => workbench,
      mutateWorkbench: (updater) {
        workbench = updater(workbench);
      },
      readCurrentProject: () => currentProject,
      loadProject: (rootPath) async {
        loadedProjectPaths.add(rootPath);
        currentProject = await projectRepository.openByPath(rootPath);
        workbench = workbench.copyWith(projectLauncher: null);
        return true;
      },
      resetToProjectlessWorkbench: ({required String status}) {
        lastProjectlessStatus = status;
        currentProject = null;
      },
      announce: announcements.add,
      readSettings: () => settings,
      projectGeneralContinuitySetupService:
          projectGeneralContinuitySetupService,
      defaultProjectsRootPath: 'D:/Projects',
      isMobileProjectRootLocked: false,
    );
  }

  final _InMemoryProjectWorkspacePort _workspacePort;
  final ProjectManifestCodecService _manifestCodecService;
  final AppSettings? settings;
  final List<String> announcements = <String>[];
  final List<String> loadedProjectPaths = <String>[];
  late final ProjectContinuityInputRepository projectContinuityInputRepository;

  late final ProjectCreationController controller;
  late WorkbenchViewData workbench;
  String lastProjectlessStatus = '';
  ProjectDescriptor? currentProject;
}

class _FakeDirectoryPickerService extends DesktopProjectDirectoryPickerService {
  @override
  Future<String?> pickProjectDirectory() async => null;
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    required _InMemoryProjectWorkspacePort workspacePort,
    required ProjectManifestCodecService manifestCodecService,
  }) : _workspacePort = workspacePort,
       _manifestCodecService = manifestCodecService;

  final _InMemoryProjectWorkspacePort _workspacePort;
  final ProjectManifestCodecService _manifestCodecService;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    final manifestContent = _workspacePort.readStoredTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (manifestContent == null) {
      return null;
    }
    final projectName = rootPath
        .split('/')
        .where((part) => part.isNotEmpty)
        .last;
    final manifest = _manifestCodecService.parse(
      manifestContent,
      fallbackTitle: projectName,
    );
    return ProjectDescriptor(
      id: projectName,
      name: manifest.title,
      rootPath: rootPath,
      projectType: manifest.projectType,
      storageStrategy: manifest.storageStrategy,
      runtimeBaselineId: manifest.runtimeBaselineId,
    );
  }
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

  String? readStoredTextFile(String rootPath, String relativePath) {
    return _files[_key(rootPath, relativePath)];
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return readStoredTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[_key(rootPath, relativePath)] = content;
  }
}

class _FakeProjectContentRepository implements ProjectContentRepository {
  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}

class _FakeProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}
