import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

Future<void> main() async {
  await ensureLocalRealProbeOptIn(
    probeName: 'real_information_evidence_ordinary_probe',
  );
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_information_evidence_ordinary_probe',
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_information_evidence_ordinary_probe',
    title: 'Real Information Evidence Ordinary Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description:
        'Small-budget real ordinary-project probe for information evidence discipline.',
    isDefault: true,
  );
  final settings = AppSettings(
    defaultProviderId: provider.id,
    defaultAgentId: 'default_generalist',
    defaultModelId: provider.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: false,
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
  final workspacePort = bundle.projectWorkspacePort;
  final projectRepository = bundle.projectRepository;
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: projectRepository,
    projectWorkspacePort: workspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  final taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
  final conversationRuntimeService = ProjectConversationDraftRuntimeService(
    workspacePort: workspacePort,
    hostPort: bundle.projectToolHostPort,
    taskRepository: taskRepository,
  );
  final pendingResearchActionService = ProjectPendingResearchActionService(
    workspacePort: workspacePort,
  );
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'real_information_evidence_ordinary_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);

  final report = <String, Object?>{
    'probe_name': 'real_information_evidence_ordinary_probe',
    'provider_id': provider.id,
    'model_id': provider.modelId,
    'probe_config_source': apiConfig.sourceLabel,
    'workspace_root': workspaceRoot.path,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'expected_categories': <String, Object?>{
      'open_network_project': ProbeReportCategories.success,
      'restricted_network_project': ProbeReportCategories.waitingUser,
    },
  };

  try {
    final openProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: workspaceRoot.path,
      title: '信息证据普通项目开放权限探针',
      projectType: 'novel',
    );
    await _seedProject(
      workspacePort,
      openProject,
      projectLabel: '开放权限项目',
      requiresHistoricalResearch: true,
    );
    final openContext = const HostInformationPermissionContext(
      allowNetwork: true,
      allowImportCollection: true,
      permissionMode: HostInformationPermissionModes.open,
      confirmationMode: HostInformationConfirmationModes.automatic,
      source: 'real_probe.open',
    );
    final openChapterReports = <JsonMap>[];
    for (final chapter in _openChapters) {
      final caseReport = await _runOrdinaryCase(
        bundle: bundle,
        settings: settings,
        provider: provider,
        conversationRuntimeService: conversationRuntimeService,
        pendingResearchActionService: pendingResearchActionService,
        project: openProject,
        hostContext: openContext,
        guide: chapter,
      );
      openChapterReports.add(caseReport);
    }
    final openProjectFiles = await workspacePort.listEntries(openProject.rootPath);
    final openCaseSummary = _summarizeOpenProjectCase(
      chapters: openChapterReports,
      projectFiles: openProjectFiles,
      projectRoot: openProject.rootPath,
    );
    report['open_network_project'] = openCaseSummary;

    final restrictedProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: workspaceRoot.path,
      title: '信息证据普通项目受限权限探针',
      projectType: 'novel',
    );
    await _seedProject(
      workspacePort,
      restrictedProject,
      projectLabel: '受限权限项目',
      requiresHistoricalResearch: true,
    );
    final restrictedContext = const HostInformationPermissionContext(
      allowNetwork: false,
      allowImportCollection: true,
      permissionMode: HostInformationPermissionModes.safe,
      confirmationMode:
          HostInformationConfirmationModes.userConfirmationRequired,
      source: 'real_probe.safe',
    );
    final restrictedCase = await _runOrdinaryCase(
      bundle: bundle,
      settings: settings,
      provider: provider,
      conversationRuntimeService: conversationRuntimeService,
      pendingResearchActionService: pendingResearchActionService,
      project: restrictedProject,
      hostContext: restrictedContext,
      guide: _restrictedChapter,
    );
    final restrictedCaseSummary = _summarizeRestrictedProjectCase(
      caseReport: restrictedCase,
      projectRoot: restrictedProject.rootPath,
    );
    report['restricted_network_project'] = restrictedCaseSummary;

    final overallOk =
        ValueReaders.boolValue(openCaseSummary['ok']) &&
        ValueReaders.boolValue(restrictedCaseSummary['ok']);
    report['ok'] = overallOk;
    report['report_category'] = overallOk
        ? ProbeReportCategories.success
        : ValueReaders.stringValue(
            restrictedCaseSummary['report_category'],
            ValueReaders.stringValue(openCaseSummary['report_category']),
          );
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
    report['report_category'] = classifyDraftProbeReportCategory(
      ok: false,
      errorSummary: '$error',
    );
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_information_evidence_ordinary_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

Future<void> _seedProject(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project, {
  required String projectLabel,
  required bool requiresHistoricalResearch,
}) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    [
      '# 项目规格',
      '',
      '- 项目：$projectLabel',
      '- 类型：历史都市悬疑小说',
      '- 主线：1930年代上海电台主播调查一串真实历史线索中的异常回声。',
      '- 写作纪律：凡涉及 1930 年代上海真实地标、报刊、交通、时间制度或机构资料，必须先形成 research request / research note，再落正文；不能直接编造成长期设定。',
      '- 本轮探针目标：验证信息证据纪律闭环，不追求长篇完整性。',
      if (requiresHistoricalResearch)
        '- 强制资料点：章节内至少有一处需要核查真实历史背景的细节。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/历史临场风格.md',
    [
      '# 历史临场风格',
      '',
      '- 现场感优先，不要分析腔。',
      '- 需要外部资料时，先 research note，再落正文。',
      '- 资料不足时宁可保留缺口，也不要假装知道。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/story/总纲.md',
    [
      '# 总纲',
      '',
      '女主黎音在 1930 年代上海经营午夜电台节目，调查一串与旧报馆、法租界路名、电车路线和码头公告相关的异常回声。',
      '她每次逼近真相，都必须确认哪些细节属于真实史料，哪些只是戏剧化推断。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/黎音.md',
    [
      '# 黎音',
      '',
      '- 职业：深夜电台播音员',
      '- 核心驱动：确认哥哥失踪前留下的历史线索是否真实存在。',
      '- 当前原则：遇到真实史料缺口时，先补资料，再推进判断。',
      '',
    ].join('\n'),
  );
}

Future<JsonMap> _runOrdinaryCase({
  required AdapterBundle bundle,
  required AppSettings settings,
  required ProviderEndpointSettings provider,
  required ProjectConversationDraftRuntimeService conversationRuntimeService,
  required ProjectPendingResearchActionService pendingResearchActionService,
  required ProjectDescriptor project,
  required HostInformationPermissionContext hostContext,
  required _OrdinaryChapterGuide guide,
}) async {
  final preparation = await conversationRuntimeService.prepareDraftRun(
    project,
    taskType: 'chapter',
    pinnedRelativePaths: const <String>[
      'specs/project_spec.md',
      'styles/历史临场风格.md',
      'outlines/story/总纲.md',
      'assets/characters/黎音.md',
    ],
  );
  final useCase = _createGenerateDraftUseCase(
    bundle: bundle,
    provider: provider,
    networkSettings: settings.networkSettings,
    hostContext: hostContext,
  );
  final progressPhases = <String>[];
  final result = await useCase.execute(
    project: project,
    userPrompt: guide.prompt,
    modelId: provider.modelId,
    title: guide.title,
    sessionContext: _mergeSessionContext(
      preparation.sessionContextMarkdown,
      guide.additionalContext,
    ),
    requestOptions: const <String, Object?>{'stream': true},
    contextSettings: settings.contextSettings,
    modelProfile: settings.extraSettings,
    exposedToolIds: preparation.exposedToolIds,
    onProgress: (progress) {
      progressPhases.add(progress.phase);
    },
  );
  ProjectConversationDraftRuntimeArtifacts artifacts =
      const ProjectConversationDraftRuntimeArtifacts();
  var finalizationError = '';
  try {
    artifacts = await conversationRuntimeService.finalizeDraftRun(
      project: project,
      preparation: preparation,
      result: result,
      title: guide.title,
    );
  } catch (error) {
    finalizationError = '$error';
  }
  final combinedChangedPaths = <String>{
    ...result.changedPaths,
    ...artifacts.changedPaths,
  }.toList(growable: false);
  final pendingRequests = await pendingResearchActionService.list(project);
  final informationProbe = buildInformationProbeAssessment(
    probeLabel: guide.id,
    activationReport: preparation.activationReport,
    changedPaths: combinedChangedPaths,
    toolNames: result.executedTools
        .map(ValueReaders.mapValue)
        .map((tool) => ValueReaders.stringValue(tool['name']))
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false),
  );
  final delivery = artifacts.chapterDelivery;
  final deliveryAccepted =
      ValueReaders.stringValue(delivery['delivery_state']) == 'delivered' &&
      ValueReaders.stringValue(delivery['sidecar_state']) == 'accepted';
  final evidenceObserved =
      combinedChangedPaths.any(
        (path) => path.replaceAll('\\', '/').contains('/research_requests/'),
      ) ||
      combinedChangedPaths.any(
        (path) => path.replaceAll('\\', '/').contains('/research_notes/'),
      ) ||
      pendingRequests.isNotEmpty;
  return <String, Object?>{
    'id': guide.id,
    'title': guide.title,
    'host_context': hostContext.toJson(),
    'prompt': guide.prompt,
    'ok': deliveryAccepted || evidenceObserved,
    'run_completed': true,
    'progress_phases': progressPhases,
    'output_path': artifacts.outputPath,
    'chapter_delivery': ValueReaders.deepCopyMap(delivery),
    'information_status': artifacts.informationStatus,
    'information_summary': artifacts.informationSummary,
    'information_changed_paths': artifacts.informationChangedPaths,
    'changed_paths': combinedChangedPaths,
    'pending_research_requests': pendingRequests,
    'waiting_for_user_choice': result.waitingForUserChoice,
    'tool_error_summary': result.toolErrorSummary,
    'finalization_error': finalizationError,
    'formal_delivery_ok': deliveryAccepted,
    'draft_markdown': result.draftMarkdown,
    'executed_tools': result.executedTools,
    'writing_execution_result': artifacts.writingExecutionResult,
    'information_probe': informationProbe,
  };
}

JsonMap _summarizeOpenProjectCase({
  required List<JsonMap> chapters,
  required List<JsonMap> projectFiles,
  required String projectRoot,
}) {
  final openChapterUsedResearch = chapters.any(_chapterHasExecutedResearch);
  final explicitNoInfoNeeded = chapters.any(_chapterHasExplicitNoInfoNeeded);
  final ranAllCases = chapters.every(
    (chapter) => ValueReaders.boolValue(chapter['run_completed']),
  );
  final reportCategory =
      ranAllCases && (openChapterUsedResearch || explicitNoInfoNeeded)
      ? ProbeReportCategories.success
      : ProbeReportCategories.informationQualityFailure;
  return <String, Object?>{
    'ok': reportCategory == ProbeReportCategories.success,
    'report_category': reportCategory,
    'project_root': projectRoot,
    'chapter_count': chapters.length,
    'chapters': chapters,
    'used_research': openChapterUsedResearch,
    'explicit_no_info_needed': explicitNoInfoNeeded,
    'all_project_files': projectFiles
        .map((entry) => ValueReaders.stringValue(entry['relative_path']))
        .toList(growable: false),
    'summary':
        openChapterUsedResearch
            ? '开放权限普通项目已观察到自动资料研究。'
            : explicitNoInfoNeeded
            ? '开放权限普通项目未触发研究，但模型给出了明确的无需外部资料说明。'
            : '开放权限普通项目没有观察到自动资料研究，也没有明确的无需外部资料说明。',
  };
}

JsonMap _summarizeRestrictedProjectCase({
  required JsonMap caseReport,
  required String projectRoot,
}) {
  final informationStatus = ValueReaders.stringValue(
    caseReport['information_status'],
  );
  final pendingRequests = ValueReaders.mapList(
    caseReport['pending_research_requests'],
  );
  final hasAwaitingConfirmation = pendingRequests.any(
    (entry) =>
        ValueReaders.stringValue(
          ValueReaders.mapValue(entry)['request_state'],
        ) ==
        ProjectPendingResearchRequestStates.awaitingUserConfirmation,
  );
  final waitingUser =
      informationStatus == 'waiting_confirmation' || hasAwaitingConfirmation;
  return <String, Object?>{
    'ok': waitingUser,
    'report_category': waitingUser
        ? ProbeReportCategories.waitingUser
        : ProbeReportCategories.informationQualityFailure,
    'project_root': projectRoot,
    'case': caseReport,
    'summary': waitingUser
        ? '受限权限普通项目已进入 pending confirmation。'
        : '受限权限普通项目未观察到 pending confirmation。',
  };
}

GenerateDraftUseCase _createGenerateDraftUseCase({
  required AdapterBundle bundle,
  required ProviderEndpointSettings provider,
  required JsonMap networkSettings,
  required HostInformationPermissionContext hostContext,
}) {
  final basePort = bundle.projectToolExecutionPort;
  final scopedToolPort = basePort is ProjectToolDispatcher
      ? basePort.scopedWithHostInformationPermissionContext(hostContext)
      : basePort;
  return GenerateDraftUseCase(
    projectWorkspacePort: bundle.projectWorkspacePort,
    llmGateway: bundle.createGateway(
      provider,
      networkSettings: networkSettings,
    ),
    toolExecutionPort: scopedToolPort,
    contextAssemblerService: ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    ),
    projectPromptContract: ProjectPromptContract(),
    hostPlatform: _currentHostPlatform(),
    loadAvailableAgents: (project) =>
        bundle.agentPackageCatalog.loadAgentPackages(project),
    loadAvailableAgentGroups: (project) =>
        bundle.agentGroupCatalog.loadAgentGroups(project),
  );
}

bool _chapterHasExecutedResearch(JsonMap chapter) {
  final informationStatus = ValueReaders.stringValue(
    chapter['information_status'],
  );
  if (informationStatus == 'executed_research') {
    return true;
  }
  final changedPaths = ValueReaders.stringList(chapter['changed_paths']);
  return changedPaths.any(
    (path) => path.replaceAll('\\', '/').contains('/research_notes/'),
  );
}

bool _chapterHasExplicitNoInfoNeeded(JsonMap chapter) {
  final summary = ValueReaders.stringValue(chapter['information_summary']);
  final markdown = ValueReaders.stringValue(chapter['draft_markdown']);
  for (final candidate in <String>[
    summary,
    markdown,
  ]) {
    final text = candidate.trim();
    if (text.contains('无需外部资料') ||
        text.contains('不需要外部资料') ||
        text.contains('无需联网资料') ||
        text.toLowerCase().contains('no external research needed')) {
      return true;
    }
  }
  return false;
}

String _mergeSessionContext(String base, String extra) {
  final parts = <String>[];
  if (base.trim().isNotEmpty) {
    parts.add(base.trim());
  }
  if (extra.trim().isNotEmpty) {
    parts.add(extra.trim());
  }
  return parts.join('\n\n');
}

HostPlatform _currentHostPlatform() {
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

const List<_OrdinaryChapterGuide> _openChapters = <_OrdinaryChapterGuide>[
  _OrdinaryChapterGuide(
    id: 'open_chapter_01',
    title: '第01章《先查法租界电车线》',
    prompt: '''
你现在是在普通小说项目里逐章写作，本轮必须完成正式章节交付。

本章目标：
- 写一章 1932 年上海法租界夜间追查戏。
- 女主必须核查一个真实历史细节：法租界附近电车线路、报馆作息或旧码头公告规则。
- 这类细节不能直接编造，必须先调用 `request_external_research` 形成 research request / research note，再写进正文。

强约束：
- 如果你判断确实不需要外部资料，必须在最终简短说明里明确写出“无需外部资料”的原因。
- 如果你需要外部资料，就先研究，再正文交付。
- 不要只做计划、不要只读文件、不要把正文留在回复里。
- 正文完成后用 `submit_chapter_delivery` 正式交付。
''',
    additionalContext: '本章重点是观察开放权限下是否会自动执行外部资料研究。',
  ),
  _OrdinaryChapterGuide(
    id: 'open_chapter_02',
    title: '第02章《旧报纸上的时间差》',
    prompt: '''
继续普通项目第二章写作。

本章目标：
- 围绕一张旧报纸上的时间记录展开追查。
- 至少要核查一个真实历史背景：1930年代上海夜间报纸发行、法租界路名、旧电台播报时间制度三者之一。
- 这类信息如果要入正文，先调用 `request_external_research`，不要直接猜。

交付要求：
- 必须完成正式章节正文和 `submit_chapter_delivery`。
- 如果最终仍认为无需外部资料，要在简短说明里明确解释为什么这章可以不查。
''',
    additionalContext: '第二章用于补足 2 章开放权限普通项目验收。',
  ),
];

const _OrdinaryChapterGuide _restrictedChapter = _OrdinaryChapterGuide(
  id: 'restricted_chapter_01',
  title: '第01章《先别假装知道》',
  prompt: '''
你现在是在普通小说项目里逐章写作，本轮优先遵守资料纪律。

本章目标：
- 写一章 1930年代上海夜间调查戏。
- 这章必须先确认一个真实历史背景：旧电车运行、夜间报馆刊印、法租界街区名称或轮渡告示规则。
- 对这类外部事实，不要直接编造；请先调用 `request_external_research`。

重要：
- 当前环境可能不会直接允许联网研究；如果工具返回需要确认，就保留 pending，不要假装已经研究完成。
- 不要为了强行完稿而跳过 research request。
''',
  additionalContext: '这一章用于验证受限权限下是否稳定进入 pending confirmation。',
);

class _OrdinaryChapterGuide {
  const _OrdinaryChapterGuide({
    required this.id,
    required this.title,
    required this.prompt,
    required this.additionalContext,
  });

  final String id;
  final String title;
  final String prompt;
  final String additionalContext;
}
