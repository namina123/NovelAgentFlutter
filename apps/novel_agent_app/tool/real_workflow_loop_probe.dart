import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';

Future<void> main(List<String> arguments) async {
  // 中文注释: 该探针复制真实项目到隔离副本，并用指定 provider 跑一次 workflow next，专门排查“同一轮是否重复读取同一路径”。
  await ensureLocalRealProbeOptIn(probeName: 'real_workflow_loop_probe');
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final sourceProjectPath = arguments.isEmpty
      ? localSettings.defaultProjectPath.trim()
      : arguments.first;
  if (sourceProjectPath.trim().isEmpty) {
    stderr.writeln('请传入源项目路径，或先在本地设置中配置 defaultProjectPath。');
    exitCode = 2;
    return;
  }
  final sourceProjectDirectory = Directory(sourceProjectPath);
  if (!await sourceProjectDirectory.exists()) {
    stderr.writeln('源项目不存在: $sourceProjectPath');
    exitCode = 2;
    return;
  }

  final apiConfig = await loadLocalProbeApiConfig(
    probeName: 'real_workflow_loop_probe',
    requireRealProbeOptIn: false,
    allowLegacyTestApi: false,
    allowTempSettingsFallback: false,
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_workflow_loop_probe',
    title: 'Real Workflow Loop Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Shared local probe configuration for workflow loop probe.',
    isDefault: true,
  );
  final settings = AppSettings(
    defaultProviderId: provider.id,
    defaultAgentId: 'default_generalist',
    defaultModelId: provider.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: true,
    providers: <ProviderEndpointSettings>[provider],
    networkSettings: localSettings.networkSettings.isEmpty
        ? const <String, Object?>{'proxy_mode': 'system'}
        : localSettings.networkSettings,
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': provider.id,
        'model_id': provider.modelId,
        'stream_mode': 'stream',
        'api_mode': 'chat',
      },
    },
  );

  final reportRoot = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_workflow_loop_probe',
  );
  await reportRoot.create(recursive: true);
  final probeRoot = Directory(
    '${reportRoot.path}${Platform.pathSeparator}${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}',
  );
  await probeRoot.create(recursive: true);
  final copiedProjectPath =
      '${probeRoot.path}${Platform.pathSeparator}project_copy';
  await _copyDirectory(sourceProjectDirectory, Directory(copiedProjectPath));

  final project = await bundle.projectRepository.openByPath(copiedProjectPath);
  if (project == null) {
    stderr.writeln('复制后的项目无法打开: $copiedProjectPath');
    exitCode = 2;
    return;
  }
  final workflowRuntimeService = ProjectWorkflowRuntimeService(
    taskRepository: ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    ),
    promptTemplateService: ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    ),
    generateDraftUseCaseFactory: (resolvedProvider, networkSettings) {
      return GenerateDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
        llmGateway: bundle.createGateway(
          resolvedProvider,
          networkSettings: networkSettings,
        ),
        toolExecutionPort: bundle.projectToolExecutionPort,
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        projectPromptContract: ProjectPromptContract(),
        hostPlatform: HostPlatform.windows,
        loadAvailableAgents: (currentProject) =>
            bundle.agentPackageCatalog.loadAgentPackages(currentProject),
        loadAvailableAgentGroups: (currentProject) =>
            bundle.agentGroupCatalog.loadAgentGroups(currentProject),
      );
    },
  );

  final nextTask = await workflowRuntimeService.nextWorkflowTask(project);
  stdout.writeln('project_copy: ${project.rootPath}');
  stdout.writeln('next_task: ${ValueReaders.stringValue(nextTask['title'])}');
  stdout.writeln(
    'next_task_path: ${ValueReaders.stringValue(nextTask['relative_path'])}',
  );
  if (nextTask.isEmpty) {
    stdout.writeln('当前没有可运行任务。');
    return;
  }

  final result = await workflowRuntimeService.runNextWorkflowTaskOnce(
    project,
    settings,
  );
  final executedTools = ValueReaders.objectList(
    result['executed_tools'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  final readPathCounts = <String, int>{};
  final toolNameCounts = <String, int>{};
  for (final tool in executedTools) {
    final toolName = ValueReaders.stringValue(tool['name']);
    toolNameCounts[toolName] = (toolNameCounts[toolName] ?? 0) + 1;
    if (toolName != 'read_project_file') {
      continue;
    }
    final relativePath = ValueReaders.stringValue(
      ValueReaders.mapValue(tool['arguments'])['relative_path'],
    );
    readPathCounts[relativePath] = (readPathCounts[relativePath] ?? 0) + 1;
  }

  stdout.writeln('ok: ${ValueReaders.boolValue(result['ok'])}');
  stdout.writeln(
    'changed_paths: ${ValueReaders.stringList(result['changed_paths']).join(', ')}',
  );
  stdout.writeln(
    'output_paths: ${ValueReaders.stringList(result['output_paths']).join(', ')}',
  );
  stdout.writeln('tool_counts: ${jsonEncode(toolNameCounts)}');
  stdout.writeln('read_path_counts: ${jsonEncode(readPathCounts)}');
  stdout.writeln('read_path_summary:');
  for (final entry in readPathCounts.entries) {
    stdout.writeln(
      '- ${entry.value > 1 ? 'repeat' : 'unique'} | count=${entry.value} | path=${entry.key}',
    );
  }
  final readSeen = <String, int>{};
  for (final tool in executedTools) {
    final toolName = ValueReaders.stringValue(tool['name']);
    final arguments = ValueReaders.mapValue(tool['arguments']);
    final relativePath = ValueReaders.stringValue(arguments['relative_path']);
    if (toolName == 'read_project_file') {
      final nextCount = (readSeen[relativePath] ?? 0) + 1;
      readSeen[relativePath] = nextCount;
      stdout.writeln(
        'tool=$toolName read_index=$nextCount mark=${nextCount == 1 ? 'first_read' : 'repeat_read'} path=$relativePath',
      );
      continue;
    }
    stdout.writeln('tool=$toolName path=$relativePath');
  }
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  // 中文注释: 真实项目必须复制到隔离副本再跑探针，避免 run-next 直接污染用户工作目录。
  await target.create(recursive: true);
  await for (final entity in source.list(
    recursive: false,
    followLinks: false,
  )) {
    final nextPath =
        '${target.path}${Platform.pathSeparator}${entity.uri.pathSegments.last}';
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(nextPath));
      continue;
    }
    if (entity is File) {
      await entity.copy(nextPath);
    }
  }
}
