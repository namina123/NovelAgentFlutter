import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../config/local_settings_repository.dart';
import '../providers/openai_llm_gateway.dart';
import '../storage/local_project_file_mutation_adapter.dart';
import '../storage/local_project_repository.dart';
import '../storage/local_project_workspace_port.dart';
import '../storage/project_workspace_tool_host_adapter.dart';
import '../tools/project_tool_dispatcher.dart';
import 'desktop_app_paths_provider.dart';

class AdapterBundle {
  const AdapterBundle({
    required this.settingsRootPath,
    required this.settingsSearchRoots,
    required this.defaultProjectRootPath,
    required this.settingsRepository,
    required this.projectRepository,
    required this.projectWorkspacePort,
    required this.projectToolExecutionPort,
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
    final projectWorkspacePort = LocalProjectWorkspacePort();
    final toolHostPort = ProjectWorkspaceToolHostAdapter(
      workspacePort: projectWorkspacePort,
      fileMutationAdapter: LocalProjectFileMutationAdapter(),
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
      projectWorkspacePort: projectWorkspacePort,
      projectToolExecutionPort: ProjectToolDispatcher(hostPort: toolHostPort),
    );
  }

  final String settingsRootPath;
  final List<String> settingsSearchRoots;
  final String defaultProjectRootPath;
  final SettingsRepository settingsRepository;
  final ProjectRepository projectRepository;
  final ProjectWorkspacePort projectWorkspacePort;
  final ToolExecutionPort projectToolExecutionPort;

  LlmGateway createGateway(ProviderEndpointSettings provider) {
    // 中文注释: provider 到具体网关实现的映射由 adapter bundle 承担，宿主层只依赖核心协议。
    return OpenAiLlmGateway.fromProviderSettings(provider);
  }
}
