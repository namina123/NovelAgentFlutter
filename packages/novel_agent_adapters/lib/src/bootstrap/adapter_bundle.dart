import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../config/local_settings_repository.dart';
import '../packages/agent_catalog_overlay_repository.dart';
import '../packages/agent_group_catalog_overlay_repository.dart';
import '../packages/builtin_starter_agent_group_registration_service.dart';
import '../packages/local_agent_group_catalog.dart';
import '../packages/local_agent_package_catalog.dart';
import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import '../packages/package_root_path_resolver.dart';
import '../providers/gateway_factory_resolver.dart';
import '../runtime/local_long_task_run_registry.dart';
import '../runtime/long_task_heartbeat_scheduler.dart';
import '../runtime/long_task_supervisor.dart';
import '../runtime/long_task_watchdog.dart';
import '../storage/local_project_file_mutation_adapter.dart';
import '../storage/local_project_repository.dart';
import '../storage/local_project_workspace_port.dart';
import '../storage/delegating_project_content_repository.dart';
import '../storage/delegating_project_readable_projection_service.dart';
import '../storage/markdown_project_content_repository.dart';
import '../storage/markdown_project_readable_projection_service.dart';
import '../storage/project_tree_order_service.dart';
import '../storage/project_workspace_tool_host_adapter.dart';
import '../storage/project_mode_guidance_repository.dart';
import '../storage/project_agent_group_binding_repository.dart';
import '../storage/project_agent_skill_loadout_repository.dart';
import '../storage/project_prompt_template_service.dart';
import '../storage/project_task_repository.dart';
import '../storage/sqlite_project_content_repository.dart';
import '../storage/sqlite_project_readable_projection_service.dart';
import '../tools/project_agent_skill_runtime_loadout_service.dart';
import '../tools/project_tool_dispatcher.dart';
import '../workflow/project_workflow_runtime_service.dart';
import 'desktop_app_paths_provider.dart';
import 'workspace_root_locator.dart';

class AdapterBundle {
  const AdapterBundle({
    required this.settingsRootPath,
    required this.settingsSearchRoots,
    required this.defaultProjectRootPath,
    required this.settingsRepository,
    required this.projectRepository,
    required this.projectContentRepository,
    required this.projectReadableProjectionService,
    required this.projectWorkspacePort,
    required this.projectToolHostPort,
    required this.projectToolExecutionPort,
    required this.longTaskRunRegistry,
    required this.longTaskSupervisor,
    required this.longTaskWatchdog,
    required this.agentCatalogOverlayRepository,
    required this.agentGroupCatalogOverlayRepository,
    required this.projectAgentGroupBindingRepository,
    required this.agentGroupCatalog,
    required this.agentPackageCatalog,
    required this.skillGroupCatalog,
    required this.skillPackageCatalog,
  });

  factory AdapterBundle.standard({
    String? workingDirectoryPath,
    String? settingsRootPath,
    List<String> settingsSearchRoots = const <String>[],
    String? defaultProjectRootPath,
    bool allowConfiguredProjectPathOverride = true,
    Map<String, String>? environment,
  }) {
    // 中文注释: 标准装配入口集中构建本地适配器，同时把设置目录与默认项目目录彻底分开。
    final desktopAppPaths = DesktopAppPathsProvider(
      environment: environment,
    ).resolve(workingDirectoryPath: workingDirectoryPath);
    final resolvedSettingsRootPath = Directory(
      settingsRootPath?.trim().isNotEmpty == true
          ? settingsRootPath!
          : desktopAppPaths.settingsRootPath,
    ).absolute.path;
    final resolvedDefaultProjectRootPath = Directory(
      defaultProjectRootPath?.trim().isNotEmpty == true
          ? defaultProjectRootPath!
          : desktopAppPaths.defaultProjectRootPath,
    ).absolute.path;
    Directory(resolvedSettingsRootPath).createSync(recursive: true);
    Directory(resolvedDefaultProjectRootPath).createSync(recursive: true);
    final treeOrderService = ProjectTreeOrderService();
    final projectWorkspacePort = LocalProjectWorkspacePort(
      treeOrderService: treeOrderService,
    );
    final projectContentRepository = DelegatingProjectContentRepository(
      markdownRepository: MarkdownProjectContentRepository(
        projectWorkspacePort: projectWorkspacePort,
      ),
      sqliteRepository: SqliteProjectContentRepository(
        projectWorkspacePort: projectWorkspacePort,
      ),
    );
    final projectReadableProjectionService =
        DelegatingProjectReadableProjectionService(
          markdownService: MarkdownProjectReadableProjectionService(
            projectWorkspacePort: projectWorkspacePort,
          ),
          sqliteService: SqliteProjectReadableProjectionService(
            projectWorkspacePort: projectWorkspacePort,
          ),
        );
    final longTaskRunRegistry = LocalLongTaskRunRegistry(
      settingsRootPath: resolvedSettingsRootPath,
    );
    final longTaskHeartbeatScheduler = LongTaskHeartbeatScheduler(
      runRegistry: longTaskRunRegistry,
      runtimeBaselineCatalogService: const RuntimeBaselineCatalogService(),
    );
    final longTaskWatchdog = LongTaskWatchdog(
      runRegistry: longTaskRunRegistry,
      heartbeatScheduler: longTaskHeartbeatScheduler,
    );
    final longTaskSupervisor = LongTaskSupervisor(
      runRegistry: longTaskRunRegistry,
      watchdogDispatchPort: longTaskWatchdog,
    );
    final toolHostPort = ProjectWorkspaceToolHostAdapter(
      workspacePort: projectWorkspacePort,
      fileMutationAdapter: LocalProjectFileMutationAdapter(),
    );
    final workspaceRootPath = const WorkspaceRootLocator().locate(
      startPath: workingDirectoryPath,
    );
    final packageRootPathResolver = PackageRootPathResolver(
      workspaceRootPath: workspaceRootPath,
    );
    final agentCatalogOverlayRepository = AgentCatalogOverlayRepository(
      settingsRootPath: resolvedSettingsRootPath,
    );
    final agentGroupCatalogOverlayRepository =
        AgentGroupCatalogOverlayRepository(
          settingsRootPath: resolvedSettingsRootPath,
        );
    final projectAgentGroupBindingRepository =
        ProjectAgentGroupBindingRepository(workspacePort: projectWorkspacePort);
    final agentPackageCatalog = LocalAgentPackageCatalog(
      packageRootPathResolver: packageRootPathResolver,
      overlayRepository: agentCatalogOverlayRepository,
    );
    final agentGroupCatalog = LocalAgentGroupCatalog(
      packageRootPathResolver: packageRootPathResolver,
      overlayRepository: agentGroupCatalogOverlayRepository,
      starterGroupRegistrationService:
          BuiltinStarterAgentGroupRegistrationService(),
    );
    final skillGroupCatalog = LocalSkillGroupCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
    final skillPackageCatalog = LocalSkillPackageCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
    final modeGuidanceRepository = ProjectModeGuidanceRepository(
      workspacePort: projectWorkspacePort,
    );
    final buildModeGuidancePlanInputUseCase = BuildModeGuidancePlanInputUseCase(
      statePort: modeGuidanceRepository,
    );
    final workflowRuntimeService = ProjectWorkflowRuntimeService(
      taskRepository: ProjectTaskRepository(
        workspacePort: projectWorkspacePort,
      ),
      promptTemplateService: ProjectPromptTemplateService(
        workspacePort: projectWorkspacePort,
      ),
      generateDraftUseCaseFactory: (_, __) {
        throw UnsupportedError(
          'AdapterBundle internal workflow runtime service is only used for start_long_task_run tool creation.',
        );
      },
    );
    final projectAgentSkillLoadoutRepository =
        ProjectAgentSkillLoadoutRepository(workspacePort: projectWorkspacePort);
    final resolvedSettingsSearchRoots = <String>[
      resolvedSettingsRootPath,
      ...desktopAppPaths.settingsSearchRoots,
      ...settingsSearchRoots,
    ].where((path) => path.trim().isNotEmpty).toSet().toList(growable: false);
    return AdapterBundle(
      settingsRootPath: resolvedSettingsRootPath,
      settingsSearchRoots: resolvedSettingsSearchRoots,
      defaultProjectRootPath: resolvedDefaultProjectRootPath,
      settingsRepository: LocalSettingsRepository(
        settingsSearchRoots: resolvedSettingsSearchRoots,
        defaultProjectRootPath: resolvedDefaultProjectRootPath,
        allowConfiguredProjectPathOverride: allowConfiguredProjectPathOverride,
        environment: environment,
      ),
      projectRepository: LocalProjectRepository(),
      projectContentRepository: projectContentRepository,
      projectReadableProjectionService: projectReadableProjectionService,
      projectWorkspacePort: projectWorkspacePort,
      projectToolHostPort: toolHostPort,
      longTaskRunRegistry: longTaskRunRegistry,
      longTaskSupervisor: longTaskSupervisor,
      longTaskWatchdog: longTaskWatchdog,
      agentCatalogOverlayRepository: agentCatalogOverlayRepository,
      agentGroupCatalogOverlayRepository: agentGroupCatalogOverlayRepository,
      projectAgentGroupBindingRepository: projectAgentGroupBindingRepository,
      agentGroupCatalog: agentGroupCatalog,
      agentPackageCatalog: agentPackageCatalog,
      skillGroupCatalog: skillGroupCatalog,
      skillPackageCatalog: skillPackageCatalog,
      projectToolExecutionPort: ProjectToolDispatcher(
        hostPort: toolHostPort,
        skillGroupCatalog: skillGroupCatalog,
        skillPackageCatalog: skillPackageCatalog,
        treeOrderService: treeOrderService,
        buildModeGuidancePlanInputUseCase: buildModeGuidancePlanInputUseCase,
        workflowRuntimeService: workflowRuntimeService,
        agentSkillRuntimeLoadoutService: ProjectAgentSkillRuntimeLoadoutService(
          loadoutRepository: projectAgentSkillLoadoutRepository,
        ),
      ),
    );
  }

  final String settingsRootPath;
  final List<String> settingsSearchRoots;
  final String defaultProjectRootPath;
  final SettingsRepository settingsRepository;
  final ProjectRepository projectRepository;
  final ProjectContentRepository projectContentRepository;
  final ProjectReadableProjectionService projectReadableProjectionService;
  final ProjectWorkspacePort projectWorkspacePort;
  final ProjectToolHostPort projectToolHostPort;
  final ToolExecutionPort projectToolExecutionPort;
  final LongTaskRunRegistry longTaskRunRegistry;
  final LongTaskSupervisor longTaskSupervisor;
  final LongTaskWatchdog longTaskWatchdog;
  final AgentCatalogOverlayRepository agentCatalogOverlayRepository;
  final AgentGroupCatalogOverlayRepository agentGroupCatalogOverlayRepository;
  final ProjectAgentGroupBindingRepository projectAgentGroupBindingRepository;
  final LocalAgentGroupCatalog agentGroupCatalog;
  final LocalAgentPackageCatalog agentPackageCatalog;
  final LocalSkillGroupCatalog skillGroupCatalog;
  final LocalSkillPackageCatalog skillPackageCatalog;

  LlmGateway createGateway(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: bundle 这里只负责装配，不再自己决定哪种协议对应哪种网关实现。
    return GatewayFactoryResolver().resolve(
      provider,
      networkSettings: networkSettings,
    );
  }
}
