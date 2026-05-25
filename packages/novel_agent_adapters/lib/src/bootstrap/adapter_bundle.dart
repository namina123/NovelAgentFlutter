import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../config/local_settings_repository.dart';
import '../packages/local_agent_group_catalog.dart';
import '../packages/local_agent_package_catalog.dart';
import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import '../packages/package_root_path_resolver.dart';
import '../providers/openai_llm_gateway.dart';
import '../runtime/local_long_task_run_registry.dart';
import '../runtime/long_task_heartbeat_scheduler.dart';
import '../runtime/long_task_supervisor.dart';
import '../storage/local_project_file_mutation_adapter.dart';
import '../storage/local_project_repository.dart';
import '../storage/local_project_workspace_port.dart';
import '../storage/delegating_project_content_repository.dart';
import '../storage/delegating_project_readable_projection_service.dart';
import '../storage/markdown_project_content_repository.dart';
import '../storage/markdown_project_readable_projection_service.dart';
import '../storage/project_tree_order_service.dart';
import '../storage/project_workspace_tool_host_adapter.dart';
import '../storage/sqlite_project_content_repository.dart';
import '../storage/sqlite_project_readable_projection_service.dart';
import '../tools/project_tool_dispatcher.dart';
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
    final longTaskSupervisor = LongTaskSupervisor(
      runRegistry: longTaskRunRegistry,
      heartbeatScheduler: longTaskHeartbeatScheduler,
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
    final agentPackageCatalog = LocalAgentPackageCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
    final agentGroupCatalog = LocalAgentGroupCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
    final skillGroupCatalog = LocalSkillGroupCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
    final skillPackageCatalog = LocalSkillPackageCatalog(
      packageRootPathResolver: packageRootPathResolver,
    );
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
      agentGroupCatalog: agentGroupCatalog,
      agentPackageCatalog: agentPackageCatalog,
      skillGroupCatalog: skillGroupCatalog,
      skillPackageCatalog: skillPackageCatalog,
      projectToolExecutionPort: ProjectToolDispatcher(
        hostPort: toolHostPort,
        skillGroupCatalog: skillGroupCatalog,
        skillPackageCatalog: skillPackageCatalog,
        treeOrderService: treeOrderService,
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
  final LocalAgentGroupCatalog agentGroupCatalog;
  final LocalAgentPackageCatalog agentPackageCatalog;
  final LocalSkillGroupCatalog skillGroupCatalog;
  final LocalSkillPackageCatalog skillPackageCatalog;

  LlmGateway createGateway(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: provider 到具体网关实现的映射由 adapter bundle 承担，宿主层只依赖核心协议。
    return OpenAiLlmGateway.fromProviderSettings(
      provider,
      networkSettings: networkSettings,
    );
  }
}
