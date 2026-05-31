import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main(List<String> arguments) async {
  // 中文注释: 这个探针脚本专门验证真实 OpenAI 兼容提供商在不同模型下的工具调用链是否稳定可用。
  final requestedModels = arguments
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final models = requestedModels.isEmpty
      ? const <String>['qwen3.5-plus', 'kimi-k2.5', 'minimax-m2.5']
      : requestedModels;

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
  if (provider.protocol.trim() != 'openai_compatible') {
    stderr.writeln('当前 provider 不是 openai_compatible：${provider.protocol}');
    exitCode = 2;
    return;
  }
  if (provider.apiKey.trim().isEmpty || provider.baseUrl.trim().isEmpty) {
    stderr.writeln('当前 provider 缺少 apiKey 或 baseUrl。');
    exitCode = 2;
    return;
  }

  final sourceProjectPath = settings.defaultProjectPath.trim();
  if (sourceProjectPath.isEmpty) {
    stderr.writeln('当前没有默认项目路径。');
    exitCode = 2;
    return;
  }
  final sourceProject = await bundle.projectRepository.openByPath(
    sourceProjectPath,
  );
  if (sourceProject == null) {
    stderr.writeln('默认项目无效：$sourceProjectPath');
    exitCode = 2;
    return;
  }

  final reportRoot = await _prepareReportRoot();
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  final modelProfileService = ModelExecutionProfileService();
  final executionProfile = modelProfileService.resolve(
    settings: settings,
    provider: provider,
  );
  final hostPlatform = _currentHostPlatform();
  GenerateDraftUseCase useCaseFactory({
    required ProjectDescriptor project,
    required ProviderEndpointSettings provider,
  }) {
    return GenerateDraftUseCase(
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
      hostPlatform: hostPlatform,
      loadAvailableAgents: (currentProject) =>
          bundle.agentPackageCatalog.loadAgentPackages(currentProject),
      loadAvailableAgentGroups: (currentProject) =>
          bundle.agentGroupCatalog.loadAgentGroups(currentProject),
    );
  }

  final probeCases = <_ProbeCase>[
    _ProbeCase(
      id: 'options_chain',
      prompt:
          '你必须先调用 read_project_file 读取 chapters/compat_probe_source.md，再基于其中的世界观和基调给我 3 个不同方向的可点击选项。不要直接写正文，必须调用 present_user_options。',
      validate: _validateOptionsProbe,
    ),
    _ProbeCase(
      id: 'edit_chain',
      prompt:
          '你必须先读取 chapters/compat_probe_edit.md，然后把其中的 OLD_TOKEN 替换为 NEW_TOKEN_314，优先使用 edit_project_file。完成后只回复 EDIT_OK。',
      validate: _validateEditProbe,
    ),
  ];

  final modelReports = <Object?>[];
  stdout.writeln('=== Real OpenAI-Compatible Probe Start ===');
  stdout.writeln('provider: ${provider.id}');
  stdout.writeln('baseUrl: ${provider.baseUrl}');
  stdout.writeln('project: ${sourceProject.rootPath}');
  stdout.writeln('models: ${models.join(', ')}');

  for (final modelId in models) {
    stdout.writeln('\n--- Model: $modelId ---');
    final project = await _prepareModelProject(
      createProjectWorkspaceUseCase: createProjectWorkspaceUseCase,
      reportRoot: reportRoot,
      modelId: modelId,
    );
    await _seedFixtures(bundle.projectWorkspacePort, project);
    final useCase = useCaseFactory(project: project, provider: provider);
    final caseReports = <Object?>[];
    var modelOk = true;
    for (final probeCase in probeCases) {
      stdout.writeln('running ${probeCase.id} ...');
      final caseReport = await _runProbeCase(
        project: project,
        useCase: useCase,
        modelId: modelId,
        probeCase: probeCase,
        requestOptions: <String, Object?>{
          ...ValueReaders.mapValue(executionProfile['request_options']),
          'stream': true,
        },
        contextSettings: settings.contextSettings,
        modelProfile: ValueReaders.mapValue(
          executionProfile['runtime_profile'],
        ),
      );
      caseReports.add(caseReport);
      final ok = ValueReaders.boolValue(caseReport['ok']);
      modelOk = modelOk && ok;
      stdout.writeln(
        '${ok ? 'PASS' : 'FAIL'} ${probeCase.id} | ${ValueReaders.stringValue(caseReport['summary'])}',
      );
    }
    modelReports.add(<String, Object?>{
      'model_id': modelId,
      'ok': modelOk,
      'project_copy_path': project.rootPath,
      'cases': caseReports,
    });
  }

  final reportPath = await _writeReport(
    reportRoot: reportRoot,
    provider: provider,
    sourceProject: sourceProject,
    models: models,
    modelReports: modelReports,
  );
  final failedCount = modelReports
      .map(ValueReaders.mapValue)
      .where((entry) => !ValueReaders.boolValue(entry['ok']))
      .length;
  stdout.writeln('\nreport: $reportPath');
  stdout.writeln('failed_models: $failedCount');
  stdout.writeln('=== Real OpenAI-Compatible Probe End ===');
  if (failedCount > 0) {
    exitCode = 1;
  }
}

Future<JsonMap> _runProbeCase({
  required ProjectDescriptor project,
  required GenerateDraftUseCase useCase,
  required String modelId,
  required _ProbeCase probeCase,
  required JsonMap requestOptions,
  required JsonMap contextSettings,
  required JsonMap modelProfile,
}) async {
  // 中文注释: 单个真实探针用统一包装执行，方便把过程、结果和失败原因一起固化到报告里。
  final progressPhases = <String>[];
  final startedAt = DateTime.now().toIso8601String();
  try {
    final result = await useCase.execute(
      project: project,
      userPrompt: probeCase.prompt,
      modelId: modelId,
      title: 'OpenAI Compat Probe ${probeCase.id}',
      requestOptions: requestOptions,
      contextSettings: contextSettings,
      modelProfile: modelProfile,
      onProgress: (progress) {
        progressPhases.add(progress.phase);
      },
    );
    final validation = await probeCase.validate(project, result);
    return <String, Object?>{
      'case_id': probeCase.id,
      'ok': ValueReaders.boolValue(validation['ok']),
      'summary': ValueReaders.stringValue(validation['summary']),
      'detail': ValueReaders.deepCopyMap(validation),
      'progress_phases': progressPhases,
      'executed_tools': result.executedTools
          .map(ValueReaders.mapValue)
          .map((tool) => ValueReaders.stringValue(tool['name']))
          .toList(growable: false),
      'waiting_for_user_choice': result.waitingForUserChoice,
      'draft_markdown': result.draftMarkdown,
      'reasoning_content': result.reasoningContent,
      'started_at': startedAt,
      'finished_at': DateTime.now().toIso8601String(),
    };
  } catch (error, stackTrace) {
    return <String, Object?>{
      'case_id': probeCase.id,
      'ok': false,
      'summary': '$error',
      'stack_trace': '$stackTrace',
      'progress_phases': progressPhases,
      'started_at': startedAt,
      'finished_at': DateTime.now().toIso8601String(),
    };
  }
}

Future<JsonMap> _validateOptionsProbe(
  ProjectDescriptor project,
  DraftGenerationResult result,
) async {
  // 中文注释: 选项探针重点看真实按钮链是否成立，而不是单纯看模型最后吐了什么文字。
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .toList(growable: false);
  final sessionService = ConversationSessionStateService();
  final session = sessionService.createSession(
    sessionId: 'probe_options_session',
    title: 'probe',
    needsGoalSelection: false,
  );
  final state = sessionService.stateWithAssistantResult(session, result);
  final hasRead = toolNames.contains('read_project_file');
  final hasOptions = toolNames.contains('present_user_options');
  final optionCount = state.pendingOptions.length;
  final ok =
      result.waitingForUserChoice && hasOptions && optionCount >= 2 && hasRead;
  return <String, Object?>{
    'ok': ok,
    'summary':
        'waiting=${result.waitingForUserChoice}, read=$hasRead, options=$hasOptions, pending=$optionCount',
    'pending_option_labels': state.pendingOptions
        .map((option) => option.label)
        .toList(growable: false),
  };
}

Future<JsonMap> _validateEditProbe(
  ProjectDescriptor project,
  DraftGenerationResult result,
) async {
  // 中文注释: 修改探针重点看 edit_project_file 是否真实执行且结果确实落到隔离副本里。
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .toList(growable: false);
  final file = File(
    '${project.rootPath}${Platform.pathSeparator}drafts${Platform.pathSeparator}compat_probe_edit.md',
  );
  final content = await file.readAsString();
  final hasEdit = toolNames.contains('edit_project_file');
  final updated = content.contains('NEW_TOKEN_314');
  final repliedOk = result.draftMarkdown.trim().contains('EDIT_OK');
  final ok = hasEdit && updated && repliedOk;
  return <String, Object?>{
    'ok': ok,
    'summary': 'edit=$hasEdit, updated=$updated, reply=$repliedOk',
    'file_content_preview': content,
  };
}

Future<Directory> _prepareReportRoot() async {
  // 中文注释: 真实兼容探针放到独立 artifacts 根，方便和纯工具探针报告区分。
  final root = Directory('artifacts/real_model_probes');
  await root.create(recursive: true);
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final reportRoot = Directory('${root.path}/probe_$timestamp');
  await reportRoot.create(recursive: true);
  return reportRoot;
}

Future<ProjectDescriptor> _prepareModelProject({
  required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
  required Directory reportRoot,
  required String modelId,
}) async {
  // 中文注释: 每个模型各自用一份最小项目骨架，避免默认项目上下文过重掩盖真实兼容层行为。
  final safeModelId = modelId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final projectsRoot = Directory('${reportRoot.path}/$safeModelId/workspaces');
  await projectsRoot.create(recursive: true);
  return createProjectWorkspaceUseCase.execute(
    projectsRootPath: projectsRoot.path,
    title: 'Compat Probe $safeModelId',
    projectType: 'novel',
  );
}

Future<void> _seedFixtures(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
) async {
  // 中文注释: 真实模型探针统一补齐可预测的夹具文件，减少结果受用户项目当前内容漂移影响。
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/compat_probe_source.md',
    [
      '# Compat Probe Source',
      '世界基调：冷色科幻悬疑。',
      '线索重点：BetaKey42 line lives here.',
      '主角状态：记忆残缺，但行动果断。',
      '冲突方向：逃亡、调查、伪装身份。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/compat_probe_edit.md',
    [
      '# Compat Edit File',
      'PLACEHOLDER=OLD_TOKEN',
      'STATUS=READY',
      '',
    ].join('\n'),
  );
}

Future<String> _writeReport({
  required Directory reportRoot,
  required ProviderEndpointSettings provider,
  required ProjectDescriptor sourceProject,
  required List<String> models,
  required List<Object?> modelReports,
}) async {
  // 中文注释: 报告里保留 provider、模型和逐 case 结果，方便之后换网关或换模型横向对照。
  final report = <String, Object?>{
    'created_at': DateTime.now().toIso8601String(),
    'provider_id': provider.id,
    'provider_title': provider.title,
    'provider_protocol': provider.protocol,
    'provider_base_url': provider.baseUrl,
    'source_project_path': sourceProject.rootPath,
    'models': models,
    'model_reports': modelReports,
  };
  final reportPath = '${reportRoot.path}${Platform.pathSeparator}report.json';
  await File(
    reportPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  return reportPath;
}

HostPlatform _currentHostPlatform() {
  // 中文注释: 工具暴露过滤层依赖宿主平台，这里在探针脚本里显式对齐应用 bootstrap 的平台判定。
  if (Platform.isWindows) {
    return HostPlatform.windows;
  }
  if (Platform.isLinux) {
    return HostPlatform.linux;
  }
  if (Platform.isMacOS) {
    return HostPlatform.macos;
  }
  if (Platform.isAndroid) {
    return HostPlatform.android;
  }
  if (Platform.isIOS) {
    return HostPlatform.ios;
  }
  return HostPlatform.unknown;
}

ProviderEndpointSettings? _resolveProvider(AppSettings settings) {
  final providerId = ValueReaders.stringValue(
    ValueReaders.mapValue(
      settings.extraSettings['model_settings'],
    )['provider_id'],
    settings.defaultProviderId,
  );
  for (final provider in settings.providers) {
    if (provider.id == providerId) {
      return provider;
    }
  }
  return settings.providers.isEmpty ? null : settings.providers.first;
}

class _ProbeCase {
  const _ProbeCase({
    required this.id,
    required this.prompt,
    required this.validate,
  });

  final String id;
  final String prompt;
  final Future<JsonMap> Function(
    ProjectDescriptor project,
    DraftGenerationResult result,
  )
  validate;
}

