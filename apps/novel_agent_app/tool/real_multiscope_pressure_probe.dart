import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main(List<String> arguments) async {
  await ensureLocalRealProbeOptIn(probeName: 'real_multiscope_pressure_probe');
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_multiscope_pressure_probe',
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_multiscope_pressure_probe',
    title: 'Real Multiscope Pressure Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description:
        'Shared local probe configuration for multiscope continuity pressure validation.',
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
  final chapterCount = _chapterCountFromArgs(arguments);
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_multiscope_pressure_probe_workspace${Platform.pathSeparator}${_safeTimestamp(runId)}',
  );
  await workspaceRoot.create(recursive: true);

  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final constraintRuntimeService =
      ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
        workspacePort: bundle.projectWorkspacePort,
      );
  final conversationDraftRuntimeService = ProjectConversationDraftRuntimeService(
    workspacePort: bundle.projectWorkspacePort,
    hostPort: bundle.projectToolHostPort,
    taskRepository: taskRepository,
  );
  const narrativeSupervisorRiskPolicyService =
      NarrativeSupervisorRiskPolicyService();
  final modelProfileService = ModelExecutionProfileService();
  final executionProfile = modelProfileService.resolve(
    settings: settings,
    provider: provider,
  );
  final resolvedModelId = ValueReaders.stringValue(
    executionProfile['resolved_model_id'],
    provider.modelId,
  );
  final requestOptions = ValueReaders.mapValue(
    executionProfile['request_options'],
  );
  final runtimeProfile = ValueReaders.mapValue(
    executionProfile['runtime_profile'],
  );
  final useCase = GenerateDraftUseCase(
    projectWorkspacePort: bundle.projectWorkspacePort,
    llmGateway: bundle.createGateway(
      provider,
      networkSettings: settings.networkSettings,
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
    hostPlatform: _currentHostPlatform(),
    loadAvailableAgents: (project) =>
        bundle.agentPackageCatalog.loadAgentPackages(project),
    loadAvailableAgentGroups: (project) =>
        bundle.agentGroupCatalog.loadAgentGroups(project),
  );

  final report = <String, Object?>{
    'provider_id': provider.id,
    'model_id': resolvedModelId,
    'base_url': provider.baseUrl,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace_root': workspaceRoot.path,
    'project_type': 'novel',
    'probe_kind': 'multiscope_pressure_manual_guidance_loop',
    'execution_path': 'ordinary_conversation_like',
    'requested_chapter_count': chapterCount,
    'stress_axes': const <String>[
      'scope_switch',
      'memory_carry_over',
      'relationship_drift',
      'world_rule_cost',
    ],
    'foundation_files': _foundationFilePaths,
    'chapter_guides': _chapterGuides
        .take(chapterCount)
        .map((guide) => guide.toJson())
        .toList(growable: false),
  };

  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: workspaceRoot.path,
      title: '多舞台压力真实写作探针',
      projectType: 'novel',
    );
    report['project_root'] = project.rootPath;
    await _seedProject(bundle.projectWorkspacePort, project);

    var successCount = 0;
    for (final guide in _chapterGuides.take(chapterCount)) {
      stdout.writeln('running ${guide.chapterLabel} ...');
      final runtimeTitle = guide.chapterLabel;
      final executionConstraints = await constraintRuntimeService.resolve(
        project,
        appliesTo: ConstraintBindingAppliesTo.writing,
        agentId: 'default_generalist',
        stageId: 'draft',
        legacyChapterLengthOptions: const <String, Object?>{
          'enable_chapter_word_constraints': true,
          'chapter_word_target': 2400,
          'chapter_word_min': 1800,
          'chapter_word_max': 2800,
        },
      );
      final preparation = await conversationDraftRuntimeService.prepareDraftRun(
        project,
        taskType: 'chapter',
        pinnedRelativePaths: _pinnedPathsForChapter(guide),
      );
      final progressPhases = <String>[];
      final result = await useCase.execute(
        project: project,
        userPrompt: _chapterPrompt(guide),
        modelId: resolvedModelId,
        title: runtimeTitle,
        sessionContext: _mergeSessionContext(
          ValueReaders.stringValue(
            executionConstraints['session_context_markdown'],
          ),
          preparation.sessionContextMarkdown,
        ),
        requestOptions: requestOptions,
        contextSettings: settings.contextSettings,
        modelProfile: runtimeProfile,
        exposedToolIds: preparation.exposedToolIds,
        expressionConstraintProfiles: ValueReaders.objectList(
          executionConstraints['expression_constraint_profiles'],
        ),
        projectExpressionConstraintBindings: ValueReaders.objectList(
          executionConstraints['project_expression_constraint_bindings'],
        ),
        onProgress: (progress) {
          progressPhases.add(progress.phase);
        },
      );
      final artifacts = await conversationDraftRuntimeService.finalizeDraftRun(
        project: project,
        preparation: preparation,
        result: result,
        title: runtimeTitle,
      );
      final outputPaths = _collectOutputPaths(result, artifacts);
      final changedPaths = _collectChangedPaths(result, artifacts);
      final productionObservation = narrativeSupervisorRiskPolicyService.assess(
        result: <String, Object?>{
          'executed_tools': result.executedTools,
          'response': <String, Object?>{
            'waiting_for_user_choice': result.waitingForUserChoice,
          },
        },
        execution: <String, Object?>{
          'chapter_delivery': artifacts.chapterDelivery,
          'chapter_delivery_state': ValueReaders.stringValue(
            artifacts.chapterDelivery['delivery_state'],
          ),
        },
      );
      final blockingFailure = _chapterHasBlockingFailure(
        result: result,
        artifacts: artifacts,
        productionObservation: productionObservation,
      );
      final summaryWritten =
          changedPaths.contains(guide.summaryPath) ||
          outputPaths.contains(guide.summaryPath);
      final stateWritebackSatisfied =
          guide.requiredStatePaths.isEmpty ||
          changedPaths.any(guide.requiredStatePaths.contains);
      final summary = _buildChapterSummary(
        blockingFailure: blockingFailure,
        summaryWritten: summaryWritten,
        stateWritebackSatisfied: stateWritebackSatisfied,
        requiredStatePaths: guide.requiredStatePaths,
      );
      final ok = !blockingFailure && summaryWritten && stateWritebackSatisfied;
      final reportCategory = ok
          ? ProbeReportCategories.success
          : (blockingFailure
                ? classifyDraftProbeReportCategory(
                    ok: false,
                    result: result,
                    validation: <String, Object?>{
                      'summary': summary,
                      'waiting_for_user_choice': result.waitingForUserChoice,
                    },
                  )
                : ProbeReportCategories.contentQualityFailure);
      final chapterReport = <String, Object?>{
        'ok': ok,
        'report_category': reportCategory,
        'summary': summary,
        'chapter_label': guide.chapterLabel,
        'chapter_title': guide.title,
        'guide_brief': guide.brief,
        'stress_focus': guide.stressFocus,
        'required_state_paths': guide.requiredStatePaths,
        'progress_phases': progressPhases,
        'output_paths': outputPaths,
        'changed_paths': changedPaths,
        'activation_report_path': artifacts.activationReportPath,
        'activation_report_summary': artifacts.activationReportSummary,
        'chapter_delivery': ValueReaders.deepCopyMap(artifacts.chapterDelivery),
        'production_observation': productionObservation,
        'tool_names': _collectToolNames(result, artifacts),
        'waiting_for_user_choice': result.waitingForUserChoice,
        'tool_error_summary': result.toolErrorSummary,
        'assistant_summary': result.draftMarkdown,
      };
      final reportKey =
          'chapter_${guide.chapterNumber.toString().padLeft(2, '0')}';
      report[reportKey] = chapterReport;
      if (ok) {
        successCount += 1;
      } else {
        report['error'] = '${guide.chapterLabel} 未通过 multiscope pressure probe 验证。';
        report['failed_chapter'] = reportKey;
        report['report_category'] = chapterReport['report_category'];
        break;
      }
    }

    final projectFiles = await bundle.projectWorkspacePort.listEntries(
      project.rootPath,
    );
    report['all_project_files'] = projectFiles
        .map((entry) => ValueReaders.stringValue(entry['relative_path']))
        .toList(growable: false);
    report['ok'] = successCount == chapterCount;
    report['report_category'] = ValueReaders.stringValue(
      report['report_category'],
      classifyDraftProbeReportCategory(
        ok: successCount == chapterCount,
        errorSummary: ValueReaders.stringValue(report['error']),
      ),
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
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_multiscope_pressure_probe_report.json',
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

const List<String> _foundationFilePaths = <String>[
  'specs/project_spec.md',
  'styles/折返站风格.md',
  'outlines/story/总纲.md',
  'outlines/chapters/章节任务清单.md',
  'assets/characters/闻栖.md',
  'assets/characters/周既明.md',
  'assets/world/舞台切换规则.md',
  'assets/state/记忆残留账本.md',
  'assets/foreshadows/回站权限.foreshadow.md',
];

const List<_PressureChapterGuide> _chapterGuides = <_PressureChapterGuide>[
  _PressureChapterGuide(
    1,
    '第01章',
    '雨城折返',
    '主角闻栖第一次从本体世界被抛进“雨城舞台”，只有她保留上一站记忆；必须写出世界切换的即时代价。',
    'scope_switch + first memory carry-over',
    <String>['assets/state/记忆残留账本.md'],
  ),
  _PressureChapterGuide(
    2,
    '第02章',
    '无名站台',
    '闻栖回到本体世界后发现部分关系被重置，但她手里留下了别站台带回来的证据；必须推进她与周既明的关系错位。',
    'relationship_drift + evidence persistence',
    <String>[
      'assets/state/记忆残留账本.md',
      'assets/characters/周既明.md',
    ],
  ),
  _PressureChapterGuide(
    3,
    '第03章',
    '镜厅借名',
    '第三舞台里同一角色以不同身份出现，闻栖必须识别“同人不同位”的连续性压力，而不是把它写成简单重复。',
    'identity drift across scopes',
    <String>[
      'assets/world/舞台切换规则.md',
      'assets/characters/闻栖.md',
    ],
  ),
  _PressureChapterGuide(
    4,
    '第04章',
    '回站门槛',
    '回到主线世界时，前面三次切换的代价要叠加兑现，并抛出下一阶段必须面对的权限门槛。',
    'stacked cost + forward hook',
    <String>[
      'assets/state/记忆残留账本.md',
      'assets/foreshadows/回站权限.foreshadow.md',
    ],
  ),
];

Future<void> _seedProject(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    [
      '# 项目规格',
      '',
      '- 类型：多舞台切换悬疑普通小说项目',
      '- 主角：闻栖，意外卷入“折返站”系统的档案修复员',
      '- 主线：搞清楚不同舞台之间的折返规则，并追查谁在篡改她的记忆与身份记录',
      '- 压力点：世界切换、部分记忆保留、关系重置、同角色异身份、回站代价叠加',
      '- 注意：以上只是项目输入压力，不是程序类型；一切都应通过正常写作、状态更新和章节交付承接',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/折返站风格.md',
    [
      '# 折返站风格',
      '',
      '- 节奏利落，现场先行',
      '- 世界切换时重点写角色体感、认知落差与人际错位',
      '- 少讲设定，多让设定在行动代价里显形',
      '- 不要把连续性压力写成抽象说明书',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/story/总纲.md',
    [
      '# 总纲',
      '',
      '闻栖在修复一批离奇丢失的旧档案时，被拖入名为“折返站”的多舞台系统。',
      '每次切换舞台，只有她会保留上一站的部分记忆，而其他人、关系和身份记录都会发生偏移。',
      '她必须在不断错位的世界里追查篡改源头，同时承担每次回站都会叠加的代价。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/chapters/章节任务清单.md',
    [
      '# 章节任务清单',
      '',
      for (final guide in _chapterGuides)
        '- ${guide.chapterLabel}《${guide.title}》：${guide.brief}',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/闻栖.md',
    [
      '# 闻栖',
      '',
      '- 身份：档案修复员',
      '- 优势：记忆抓取能力强，能从细节中识别错位',
      '- 风险：每次回站都会让她更难区分“现在”与“上一站”',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/周既明.md',
    [
      '# 周既明',
      '',
      '- 身份：本体世界的调查搭档',
      '- 变量：在不同舞台里可能以不同职业或关系身份出现',
      '- 当前要求：不能把他写成完全陌生人，也不能直接当成稳定不变的单版本角色',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/world/舞台切换规则.md',
    [
      '# 舞台切换规则',
      '',
      '- 每次切换都会重排局部身份、关系和环境细节',
      '- 只有闻栖会保留部分连续记忆',
      '- 带回证据需要支付代价，不能无损跨站搬运所有信息',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/state/记忆残留账本.md',
    [
      '# 记忆残留账本',
      '',
      '- 用来记录闻栖带回主线世界的残留记忆、代价与错位证据',
      '- 每次出现新残留，都必须简明补记',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/foreshadows/回站权限.foreshadow.md',
    [
      '# 回站权限',
      '',
      '- 目前只知道回站次数越多，权限门槛越高',
      '- 真正的触发条件与代价还未完全明确',
      '',
    ].join('\n'),
  );
}

String _chapterPrompt(_PressureChapterGuide guide) {
  return '''
你现在是在普通项目对话式写作链里逐章推进，不是在题材专用工作流里跑。
这次的复杂输入只是用户给定的叙事压力：多舞台切换、部分记忆保留、关系错位和回站代价。不要把这些当成程序类型标签。

## 本轮目标
- 写作章节：${guide.chapterLabel}《${guide.title}》
- 本章要求：${guide.brief}
- 本章压力焦点：${guide.stressFocus}

## 必做动作
- 先读取关键文件：`specs/project_spec.md`、`styles/折返站风格.md`、`outlines/story/总纲.md`、`outlines/chapters/章节任务清单.md`、`assets/world/舞台切换规则.md`、`assets/state/记忆残留账本.md`。
- 正文必须落盘到 `${guide.chapterPath}`。
- 完成正文后，再写 `${guide.summaryPath}`，用 4 到 8 条连续性摘要记录本章发生了什么、哪些状态被带到了下一章。
- `${guide.summaryPath}` 是唯一允许的 summary 路径。不要额外创建带书名号、带“连续性摘要”、带章节标题扩展名的变体 summary 文件。
- 本章如果发生世界规则理解变化、记忆残留新增、关系错位更新或权限门槛推进，必须直接修改这些已有文件中的至少一个：${guide.requiredStatePaths.join('、')}。
- 如果 `${guide.summaryPath}` 没有写出，或者上面列出的状态文件一个都没更新，就不要结束本轮，也不要先提交完成。
- 先把正文、summary、状态文件都写好，再做正式 `submit_chapter_delivery`。
- 不要调用 `call_sub_agent`、`create_chapter_task`、`mark_task_status`、`summarize_context`。这不是分派任务回合，而是你自己直接完成本章与相关文件更新。
- 只读、只计划、只在聊天里给正文，都不算完成。

## 表达要求
- 继续遵守项目约束，压低分析腔。
- 多写现场冲突与代价兑现，不要把复杂性偷换成抽象解释。

## 交付要求
- 优先使用 `submit_chapter_delivery` 做正式章节交付。
- 不要把正文停留在回复里。
- 完成后只简短说明：写了哪些文件、推进了什么状态。
''';
}

List<String> _pinnedPathsForChapter(_PressureChapterGuide guide) {
  final result = <String>[
    ..._foundationFilePaths,
    guide.chapterPath,
    guide.summaryPath,
  ];
  if (guide.chapterNumber > 1) {
    result.add(
      'summaries/第${(guide.chapterNumber - 1).toString().padLeft(2, '0')}章.summary.md',
    );
  }
  return result;
}

List<String> _collectOutputPaths(
  DraftGenerationResult result,
  ProjectConversationDraftRuntimeArtifacts artifacts,
) {
  final paths = <String>[
    ...result.writtenPaths,
    if (artifacts.outputPath.trim().isNotEmpty) artifacts.outputPath,
  ];
  return paths.toSet().toList(growable: false);
}

List<String> _collectChangedPaths(
  DraftGenerationResult result,
  ProjectConversationDraftRuntimeArtifacts artifacts,
) {
  final paths = <String>[
    ...result.changedPaths,
    ...artifacts.changedPaths,
  ];
  return paths.toSet().toList(growable: false);
}

List<String> _collectToolNames(
  DraftGenerationResult result,
  ProjectConversationDraftRuntimeArtifacts artifacts,
) {
  final names = result.executedTools
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: true);
  if (artifacts.chapterDelivery.isNotEmpty &&
      !names.contains('submit_chapter_delivery')) {
    names.add('submit_chapter_delivery');
  }
  return names;
}

bool _chapterHasBlockingFailure({
  required DraftGenerationResult result,
  required ProjectConversationDraftRuntimeArtifacts artifacts,
  required JsonMap productionObservation,
}) {
  if (result.waitingForUserChoice) {
    return true;
  }
  if (artifacts.outputPath.trim().isEmpty || artifacts.chapterDelivery.isEmpty) {
    return true;
  }
  final overallCategory = ValueReaders.stringValue(
    ValueReaders.mapValue(productionObservation['overall'])['category'],
  );
  if (overallCategory != 'accept') {
    return true;
  }
  if (result.stoppedByToolError && !_hasRecoveredFormalDelivery(artifacts)) {
    return true;
  }
  return false;
}

bool _hasRecoveredFormalDelivery(ProjectConversationDraftRuntimeArtifacts artifacts) {
  final delivery = artifacts.chapterDelivery;
  if (delivery.isEmpty) {
    return false;
  }
  final stateResult = ValueReaders.mapValue(delivery['state_result']);
  return ValueReaders.stringValue(delivery['delivery_state']) == 'delivered' &&
      ValueReaders.stringValue(delivery['sidecar_state']) == 'accepted' &&
      ValueReaders.boolValue(stateResult['chapter_body_delivered']) &&
      ValueReaders.boolValue(stateResult['submission_accepted']);
}

String _buildChapterSummary({
  required bool blockingFailure,
  required bool summaryWritten,
  required bool stateWritebackSatisfied,
  required List<String> requiredStatePaths,
}) {
  if (blockingFailure) {
    return 'formal chapter delivery or output contract failed';
  }
  if (!summaryWritten) {
    return 'chapter summary file was not written';
  }
  if (!stateWritebackSatisfied) {
    return 'pressure state writeback missing for ${requiredStatePaths.join(', ')}';
  }
  return 'ok';
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

int _chapterCountFromArgs(List<String> arguments) {
  for (final argument in arguments) {
    final value = argument.trim();
    if (!value.startsWith('--chapter-count=')) {
      continue;
    }
    final parsed = int.tryParse(value.split('=').last.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, _chapterGuides.length);
    }
  }
  return _chapterGuides.length;
}

String _safeTimestamp(String value) {
  return value.replaceAll(':', '-').replaceAll('.', '-');
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

class _PressureChapterGuide {
  const _PressureChapterGuide(
    this.chapterNumber,
    this.chapterLabel,
    this.title,
    this.brief,
    this.stressFocus,
    this.requiredStatePaths,
  );

  final int chapterNumber;
  final String chapterLabel;
  final String title;
  final String brief;
  final String stressFocus;
  final List<String> requiredStatePaths;

  String get chapterPath => 'chapters/$chapterLabel.md';
  String get summaryPath => 'summaries/$chapterLabel.summary.md';

  JsonMap toJson() {
    return <String, Object?>{
      'chapter_number': chapterNumber,
      'chapter_label': chapterLabel,
      'title': title,
      'brief': brief,
      'stress_focus': stressFocus,
      'required_state_paths': requiredStatePaths,
      'chapter_path': chapterPath,
      'summary_path': summaryPath,
    };
  }
}
