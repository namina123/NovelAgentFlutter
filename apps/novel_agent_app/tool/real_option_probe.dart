import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main(List<String> arguments) async {
  // 中文注释: 这个探针脚本复用应用当前装配，专门排查真实模型链路里的 present_user_options 是否成功落成按钮。
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final settings = await bundle.settingsRepository.load();
  final provider = _resolveProvider(settings);
  if (provider == null) {
    stderr.writeln('没有找到可用 provider。');
    exitCode = 2;
    return;
  }

  final projectPath = settings.defaultProjectPath.trim();
  if (projectPath.isEmpty) {
    stderr.writeln('当前没有默认项目路径。');
    exitCode = 2;
    return;
  }

  final project = await bundle.projectRepository.openByPath(projectPath);
  if (project == null) {
    stderr.writeln('默认项目无效：$projectPath');
    exitCode = 2;
    return;
  }

  final modelProfileService = ModelExecutionProfileService();
  final executionProfile = modelProfileService.resolve(
    settings: settings,
    provider: provider,
  );
  final requestOptions = ValueReaders.mapValue(executionProfile['request_options']);
  final resolvedModelId = ValueReaders.stringValue(
    executionProfile['resolved_model_id'],
    settings.defaultModelId,
  );

  final workbenchState = ValueReaders.mapValue(
    settings.extraSettings['workbench_state'],
  );
  final activeDocumentPath = ValueReaders.stringValue(
    workbenchState['active_document_path'],
  );
  final activeDocumentBody =
      activeDocumentPath.trim().isEmpty
          ? ''
          : await bundle.projectWorkspacePort.readTextFile(
                project.rootPath,
                activeDocumentPath,
              ) ??
              '';

  final useCase = GenerateDraftUseCase(
    projectWorkspacePort: bundle.projectWorkspacePort,
    llmGateway: bundle.createGateway(
      provider,
      networkSettings: <String, Object?>{
        ...settings.networkSettings,
        'proxy_mode': 'system',
      },
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
    loadAvailableAgents: (currentProject) =>
        bundle.agentPackageCatalog.loadAgentPackages(currentProject),
    loadAvailableAgentGroups: (currentProject) =>
        bundle.agentGroupCatalog.loadAgentGroups(currentProject),
  );

  final prompt =
      arguments.isEmpty
          ? '我想做一个真实可写的智能开局。请先基于当前项目现状给我 3 个不同方向让我选择，每个方向一句标题加一句说明，不要直接写正文，必须使用 present_user_options。'
          : arguments.join(' ');

  stdout.writeln('=== Probe Start ===');
  stdout.writeln('project: ${project.rootPath}');
  stdout.writeln('provider: ${provider.id}');
  stdout.writeln('model: $resolvedModelId');
  stdout.writeln('activeDocumentPath: $activeDocumentPath');
  stdout.writeln('prompt: $prompt');

  final progressPhases = <String>[];
  final result = await useCase.execute(
    project: project,
    userPrompt: prompt,
    modelId: resolvedModelId,
    title: '选项工具探针',
    requestOptions: requestOptions,
    contextSettings: settings.contextSettings,
    modelProfile: ValueReaders.mapValue(executionProfile['runtime_profile']),
    activeDocumentPath: activeDocumentPath,
    activeDocumentBody: activeDocumentBody,
    onProgress: (progress) {
      progressPhases.add(progress.phase);
      if (progress.phase == 'tool_calls_ready') {
        final names = progress.pendingToolCalls
            .map((call) => ValueReaders.stringValue(call['name']))
            .where((name) => name.trim().isNotEmpty)
            .toList(growable: false);
        stdout.writeln('tool_calls_ready: ${names.join(', ')}');
      }
    },
  );

  stdout.writeln('waitingForUserChoice: ${result.waitingForUserChoice}');
  stdout.writeln('progressPhases: ${progressPhases.join(' -> ')}');
  stdout.writeln(
    'executedTools: ${result.executedTools.map((tool) => ValueReaders.stringValue(ValueReaders.mapValue(tool)['name'])).join(', ')}',
  );

  final readPathCounts = <String, int>{};
  for (final rawTool in result.executedTools) {
    final tool = ValueReaders.mapValue(rawTool);
    final name = ValueReaders.stringValue(tool['name']);
    if (name == 'read_project_file') {
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final toolResult = ValueReaders.mapValue(tool['result']);
      final relativePath = ValueReaders.stringValue(arguments['relative_path']);
      final nextCount = (readPathCounts[relativePath] ?? 0) + 1;
      readPathCounts[relativePath] = nextCount;
      stdout.writeln(
        'read_project_file[$nextCount]: ${nextCount == 1 ? 'first_read' : 'repeat_read'} | $relativePath',
      );
      stdout.writeln(
        'read_project_file.ok: ${ValueReaders.boolValue(toolResult['ok'], true)}',
      );
      continue;
    }
    if (name != 'present_user_options') {
      continue;
    }
    final toolResult = ValueReaders.mapValue(tool['result']);
    stdout.writeln('present_user_options.result.keys: ${toolResult.keys.join(', ')}');
    stdout.writeln(
      'present_user_options.question: ${ValueReaders.stringValue(toolResult['question'])}',
    );
    final options = ValueReaders.objectList(toolResult['options'])
        .map(ValueReaders.mapValue)
        .toList(growable: false);
    stdout.writeln('present_user_options.optionCount: ${options.length}');
    for (var index = 0; index < options.length && index < 3; index++) {
      final option = options[index];
      stdout.writeln(
        'option[$index]: label=${ValueReaders.stringValue(option['label'])} | prompt=${ValueReaders.stringValue(option['prompt'])}',
      );
    }
  }

  final sessionService = ConversationSessionStateService();
  final session = sessionService.createSession(
    sessionId: 'probe_session',
    title: 'probe',
    needsGoalSelection: false,
  );
  final state = sessionService.stateWithAssistantResult(session, result);
  stdout.writeln('pendingOptionsFromState: ${state.pendingOptions.length}');
  for (var index = 0; index < state.pendingOptions.length && index < 3; index++) {
    final option = state.pendingOptions[index];
    stdout.writeln(
      'state.option[$index]: label=${option.label} | prompt=${option.prompt}',
    );
  }
  stdout.writeln('read_summary:');
  for (final entry in readPathCounts.entries) {
    stdout.writeln(
      '- ${entry.value > 1 ? 'repeat' : 'unique'} | count=${entry.value} | path=${entry.key}',
    );
  }
  stdout.writeln('draftMarkdownPreview: ${result.draftMarkdown.substring(0, result.draftMarkdown.length > 120 ? 120 : result.draftMarkdown.length)}');
  stdout.writeln('=== Probe End ===');
}

ProviderEndpointSettings? _resolveProvider(AppSettings settings) {
  final providerId = ValueReaders.stringValue(
    ValueReaders.mapValue(settings.extraSettings['model_settings'])['provider_id'],
    settings.defaultProviderId,
  );
  for (final provider in settings.providers) {
    if (provider.id == providerId) {
      return provider;
    }
  }
  return settings.providers.isEmpty ? null : settings.providers.first;
}
