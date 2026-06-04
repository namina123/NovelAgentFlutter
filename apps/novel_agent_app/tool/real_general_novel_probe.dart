import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

Future<void> main(List<String> arguments) async {
  await ensureLocalRealProbeOptIn(probeName: 'real_general_novel_probe');
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_general_novel_probe',
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_general_novel_probe',
    title: 'Real General Novel Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Shared local probe configuration for ordinary general novel validation.',
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
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_general_novel_probe_workspace${Platform.pathSeparator}${_safeTimestamp(runId)}',
  );
  await workspaceRoot.create(recursive: true);

  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  final projectTaskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final expressionConstraintProfileRepository =
      ExpressionConstraintProfileRepository(
        workspacePort: bundle.projectWorkspacePort,
      );
  final projectExpressionConstraintBindingRepository =
      ProjectExpressionConstraintBindingRepository(
        workspacePort: bundle.projectWorkspacePort,
      );
  final draftExecutionConstraintRuntimeService =
      ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
        workspacePort: bundle.projectWorkspacePort,
      );
  final conversationDraftRuntimeService = ProjectConversationDraftRuntimeService(
    workspacePort: bundle.projectWorkspacePort,
    hostPort: bundle.projectToolHostPort,
    taskRepository: projectTaskRepository,
  );
  final chapterLengthEvaluationService = ProjectChapterLengthEvaluationService(
    taskRepository: projectTaskRepository,
  );
  const expressionConstraintReviewProjectionService =
      ExpressionConstraintReviewProjectionService();
  final creativeRuleStackResolverService = CreativeRuleStackResolverService();
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
    'requested_chapter_count': chapterCount,
    'probe_kind': 'general_novel_manual_guidance_loop',
    'execution_path': 'ordinary_conversation_like',
    'expression_constraint_profile_ids': const <String>[
      'de_ai',
      'low_jargon_narration',
    ],
    'chapter_length_target': 2200,
    'chapter_length_min': 1900,
    'chapter_length_max': 2500,
    'foundation_files': _foundationFilePaths,
    'chapter_guides': _chapterGuides
        .take(chapterCount)
        .map((guide) => guide.toJson())
        .toList(growable: false),
    'note':
        'This probe intentionally follows the ordinary project conversation-like path rather than the long-task runtime path.',
  };

  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: workspaceRoot.path,
      title: '普通小说真实写作探针',
      projectType: 'novel',
    );
    report['project_root'] = project.rootPath;
    await _seedProject(bundle.projectWorkspacePort, project);
    await projectExpressionConstraintBindingRepository.saveBindings(
      project,
      const <ProjectExpressionConstraintBinding>[
        ProjectExpressionConstraintBinding(
          id: 'probe_de_ai_binding',
          profileId: 'de_ai',
          displayName: 'Probe de-AI',
          defaultForProject: true,
          targetStageIds: <String>['draft'],
          weight: 160,
        ),
        ProjectExpressionConstraintBinding(
          id: 'probe_low_jargon_binding',
          profileId: 'low_jargon_narration',
          displayName: 'Probe low jargon narration',
          defaultForProject: true,
          targetStageIds: <String>['draft'],
          weight: 140,
        ),
      ],
    );
    final loadedProfiles = await expressionConstraintProfileRepository
        .loadProfiles(project);
    report['loaded_expression_constraint_profile_ids'] = loadedProfiles
        .map((profile) => profile.id)
        .toList(growable: false);

    var successCount = 0;
    for (final guide in _chapterGuides.take(chapterCount)) {
      stdout.writeln('running ${guide.chapterLabel} ...');
      final executionConstraints =
          await draftExecutionConstraintRuntimeService.resolve(
            project,
            appliesTo: ConstraintBindingAppliesTo.writing,
            agentId: 'default_generalist',
            stageId: 'draft',
            legacyChapterLengthOptions: const <String, Object?>{
              'enable_chapter_word_constraints': true,
              'chapter_word_target': 2200,
              'chapter_word_min': 1900,
              'chapter_word_max': 2500,
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
        title: '${guide.chapterLabel}《${guide.title}》',
        sessionContext: _mergeSessionContext(
          ValueReaders.stringValue(executionConstraints['session_context_markdown']),
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
        title: '${guide.chapterLabel}《${guide.title}》',
      );
      final chapterTask = <String, Object?>{
        'id': 'ordinary_probe_${guide.chapterLabel}',
        'title': '写作${guide.chapterLabel}正文',
        'task_type': 'chapter',
        'output_paths': <Object?>[
          if (artifacts.outputPath.trim().isNotEmpty) artifacts.outputPath,
        ],
        'metadata': <String, Object?>{
          'stage': 'draft',
          'sort_order': guide.chapterNumber,
          ...ValueReaders.deepCopyMap(
            ValueReaders.mapValue(executionConstraints['chapter_length_metadata']),
          ),
        },
      };
      await projectTaskRepository.saveTask(project, chapterTask);
      final chapterLengthEvaluation = await chapterLengthEvaluationService
          .evaluate(
            project: project,
            task: chapterTask,
            result: result,
          );
      final creativeRuleStack = creativeRuleStackResolverService.resolve(
        expressionConstraintProfiles: ValueReaders.objectList(
          executionConstraints['expression_constraint_profiles'],
        ),
        projectExpressionConstraintBindings: ValueReaders.objectList(
          executionConstraints['project_expression_constraint_bindings'],
        ),
        stageId: 'draft',
      );
      final expressionConstraintReview =
          expressionConstraintReviewProjectionService
              .buildFromCreativeRuleStack(creativeRuleStack.toJson());
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
      final toolNames = result.executedTools
          .map(ValueReaders.mapValue)
          .map((tool) => ValueReaders.stringValue(tool['name']))
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: true);
      if (artifacts.chapterDelivery.isNotEmpty &&
          !toolNames.contains('submit_chapter_delivery')) {
        toolNames.add('submit_chapter_delivery');
      }
      final chapterReport = <String, Object?>{
        'ok':
            !_chapterHasBlockingFailure(
              result: result,
              artifacts: artifacts,
              productionObservation: productionObservation,
            ),
        'chapter_label': guide.chapterLabel,
        'chapter_title': guide.title,
        'guide_brief': guide.brief,
        'prompt': _chapterPrompt(guide),
        'expected_output_path': guide.chapterPath,
        'attempt': 1,
        'progress_phases': progressPhases,
        'output_paths': _collectOutputPaths(result, artifacts),
        'changed_paths': _collectChangedPaths(result, artifacts),
        'activation_report_path': artifacts.activationReportPath,
        'activation_report_summary': artifacts.activationReportSummary,
        'chapter_length_evaluation': chapterLengthEvaluation,
        'expression_constraint_review': expressionConstraintReview.toJson(),
        'chapter_delivery': ValueReaders.deepCopyMap(artifacts.chapterDelivery),
        'delivery_outcome': ValueReaders.stringValue(
          ValueReaders.mapValue(productionObservation['delivery'])['category'],
        ),
        'delivery_recovery_plan': _deliveryRecoveryPlan(
          artifacts.chapterDelivery,
          productionObservation,
        ),
        'production_observation': productionObservation,
        'tool_names': toolNames,
        'waiting_for_user_choice': result.waitingForUserChoice,
        'assistant_summary': result.draftMarkdown,
        'tool_error_summary': result.toolErrorSummary,
      };
      final reportKey =
          'chapter_${guide.chapterNumber.toString().padLeft(2, '0')}';
      report[reportKey] = chapterReport;
      if (ValueReaders.boolValue(chapterReport['ok'])) {
        successCount += 1;
      } else {
        report['error'] =
            '${guide.chapterLabel} 未通过 ordinary conversation probe 验证。';
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
    report['report_category'] = classifyDraftProbeReportCategory(
      ok: successCount == chapterCount,
      errorSummary: ValueReaders.stringValue(report['error']),
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
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_general_novel_probe_report.json',
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
  'styles/午夜频率风格.md',
  'outlines/story/总纲.md',
  'outlines/chapters/章节任务清单.md',
  'assets/characters/沈临川.md',
  'assets/characters/陈屿.md',
  'assets/world/第二层频道.md',
  'assets/foreshadows/姐姐失踪.foreshadow.md',
];

const List<_ChapterGuide> _chapterGuides = <_ChapterGuide>[
  _ChapterGuide(
    1,
    '第01章',
    '午夜热线',
    '建立女主沈临川、电台直播工作场景与“异常声音”引子；章节结尾必须抛出姐姐失踪相关的新异常证据。',
  ),
  _ChapterGuide(
    2,
    '第02章',
    '空号记录',
    '围绕空号热线与后台记录展开追查，推进女主与技术顾问陈屿的合作关系，留下一个无法用常识解释的技术矛盾。',
  ),
  _ChapterGuide(
    3,
    '第03章',
    '录音室门后的回声',
    '让女主第一次主动接近旧录音室异常点，明确“异常只能通过声音/电波被感知”的世界规则，并付出可感知代价。',
  ),
  _ChapterGuide(
    4,
    '第04章',
    '第二层频道',
    '把异常从单一热线扩展到更明确的“第二层频道”线索，剧情需要实质推进而不是原地解释。',
  ),
  _ChapterGuide(
    5,
    '第05章',
    '旧带里的名字',
    '借一份旧录音带或旧节目档案挖到姐姐留下的痕迹，让角色关系和过往事件更具体。',
  ),
  _ChapterGuide(
    6,
    '第06章',
    '错误的来电时间',
    '制造一次时间记录与现实不一致的异常，继续推进主线，并让沈临川做出更主动的行动决策。',
  ),
  _ChapterGuide(
    7,
    '第07章',
    '失真段',
    '让异常影响女主的听觉或身体状态，但不能只写症状，要推动她与陈屿的调查关系升级。',
  ),
  _ChapterGuide(
    8,
    '第08章',
    '台阶上的回拨',
    '安排一次危险的回拨或反向联络，让线索获得新信息，同时抛出更大的未知区域。',
  ),
  _ChapterGuide(
    9,
    '第09章',
    '她曾经听见什么',
    '把姐姐失踪前的关键经历补出一块拼图，让沈临川对“姐姐究竟遭遇了什么”形成阶段性判断。',
  ),
  _ChapterGuide(
    10,
    '第10章',
    '零秒通话',
    '完成一个阶段性钩子：真相更近一步，但代价与风险同步扩大，为后续继续写作留下清晰挂点。',
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
      '- 类型：都市异闻悬疑普通小说项目',
      '- 主角：沈临川，深夜电台《午夜热线》主播',
      '- 主线：追查姐姐失踪真相与“第二层频道”的来源',
      '- 规则：异常只能通过声音、电波、录音残响等媒介被感知',
      '- 写作要求：每章都必须有现场推进和清晰钩子',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/午夜频率风格.md',
    [
      '# 午夜频率风格',
      '',
      '- 冷色都市感，压迫感要稳定',
      '- 少解释，多现场',
      '- 对话要有人味，不要职业化评论腔',
      '- 允许悬疑留白，但不要空转吊胃口',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/story/总纲.md',
    [
      '# 总纲',
      '',
      '沈临川在午夜热线中接触到一条不属于现实层的第二道回声。',
      '她从零散来电、旧节目档案、失真的录音和姐姐留下的痕迹中，逐渐逼近“第二层频道”的真相。',
      '陈屿负责提供技术侧验证，但每推进一步，现实记录与声音证据都会出现新的错位。',
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
    'assets/characters/沈临川.md',
    [
      '# 沈临川',
      '',
      '- 职业：深夜电台主播',
      '- 核心驱动：查清姐姐失踪真相',
      '- 当前状态：对异常声音高度敏感，但仍努力保持职业镇定',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/陈屿.md',
    [
      '# 陈屿',
      '',
      '- 身份：技术顾问 / 旧识',
      '- 作用：帮助验证录音、通话记录和设备异常',
      '- 关系压力：对沈临川的执念与冒险冲动保持警惕',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/world/第二层频道.md',
    [
      '# 第二层频道',
      '',
      '- 只会通过声音、电波、录音残响等媒介被感知',
      '- 不能无代价获得全知信息',
      '- 每次有效接触都可能带来身体或认知层面的代价',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/foreshadows/姐姐失踪.foreshadow.md',
    [
      '# 姐姐失踪',
      '',
      '- 七个月前失踪',
      '- 离开前曾告诉沈临川“发现了一些东西，回来再说”',
      '- 相关线索只能从录音、来电、旧节目档案中慢慢拼接',
      '',
    ].join('\n'),
  );
}

String _chapterPrompt(_ChapterGuide guide) {
  return '''
你现在是在一个普通小说项目里逐章写作，而不是在长任务流水线上自动跑。
这是一次分散式用户使用场景，本轮只完成当前这一章。

## 本轮目标
- 写作章节：${guide.chapterLabel}《${guide.title}》
- 本章要求：${guide.brief}

## 操作要求
- 先读取项目关键文件，再动笔：`specs/project_spec.md`、`styles/午夜频率风格.md`、`outlines/story/总纲.md`、`outlines/chapters/章节任务清单.md`。
- 正文必须落盘到 `${guide.chapterPath}`。
- 完成正文后，再补一份 `${guide.summaryPath}`，用 4 到 8 条项目内连续性可用的摘要记录本章推进。
- 如果本章改变了角色状态、世界规则认知、伏笔状态或时间线，请同步更新对应 `assets/` 文件。
- `set_agent_tasks`、`call_sub_agent`、只读文件、只改状态文件，都不算本轮完成；本轮结束前必须实际写出 `${guide.chapterPath}`。

## 表达与风格
- 默认遵守项目已绑定的表达限制，尤其注意去 AI、压低分析腔。
- 不要用工整收束句和解释腔替代现场推进。
- 避免反复用 `——`、`不是……而是……`、近邻句换壳重说同一信息。

## 交付边界
- 优先使用 `submit_chapter_delivery` 做正式章节交付。
- 不要只在聊天里给我正文，不要把正文停留在回复里。
- 完成后只做简短说明：写了哪些文件、推进了什么。
''';
}

List<String> _pinnedPathsForChapter(_ChapterGuide guide) {
  final result = <String>[
    ..._foundationFilePaths,
    guide.chapterPath,
    guide.summaryPath,
  ];
  if (guide.chapterNumber > 1) {
    result.add('summaries/第${(guide.chapterNumber - 1).toString().padLeft(2, '0')}章.summary.md');
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

JsonMap _deliveryRecoveryPlan(
  JsonMap delivery,
  JsonMap productionObservation,
) {
  final deliverySignal = ValueReaders.mapValue(productionObservation['delivery']);
  final overall = ValueReaders.mapValue(productionObservation['overall']);
  final category = ValueReaders.stringValue(overall['category']);
  if (delivery.isEmpty) {
    return <String, Object?>{
      'primary_action': 'repair_required',
      'summary': '当前章节没有形成正式交付，下一轮应先补交或重写。',
      'outcome': 'missing_delivery',
      'reason_code': 'delivery_missing',
      'requires_user_decision': false,
      'should_auto_recover': false,
      'exhausted': false,
      'attempt_count': 0,
      'attempt_limit': 1,
      'fallback_actions': const <Object?>[],
      'context': const <String, Object?>{},
    };
  }
  if (category == 'repair') {
    return <String, Object?>{
      'primary_action': 'repair_required',
      'summary': '当前章节交付需要返工后再继续。',
      'outcome': ValueReaders.stringValue(deliverySignal['state']),
      'reason_code': ValueReaders.stringValue(deliverySignal['reason']),
      'requires_user_decision': false,
      'should_auto_recover': false,
      'exhausted': false,
      'attempt_count': 0,
      'attempt_limit': 1,
      'fallback_actions': const <Object?>[],
      'context': const <String, Object?>{},
    };
  }
  if (category == 'checkpoint_user') {
    return <String, Object?>{
      'primary_action': 'waiting_user_choice',
      'summary': '当前章节交付需要用户做真实选择后再继续。',
      'outcome': ValueReaders.stringValue(deliverySignal['state']),
      'reason_code': ValueReaders.stringValue(deliverySignal['reason']),
      'requires_user_decision': true,
      'should_auto_recover': false,
      'exhausted': false,
      'attempt_count': 0,
      'attempt_limit': 1,
      'fallback_actions': const <Object?>[],
      'context': const <String, Object?>{},
    };
  }
  if (category == 'manual_attention') {
    return <String, Object?>{
      'primary_action': 'manual_attention_required',
      'summary': '当前章节交付已进入人工处理范围。',
      'outcome': ValueReaders.stringValue(deliverySignal['state']),
      'reason_code': ValueReaders.stringValue(deliverySignal['reason']),
      'requires_user_decision': false,
      'should_auto_recover': false,
      'exhausted': false,
      'attempt_count': 0,
      'attempt_limit': 1,
      'fallback_actions': const <Object?>[],
      'context': const <String, Object?>{},
    };
  }
  return <String, Object?>{
    'primary_action': 'manual_attention_required',
    'summary': '当前任务没有需要恢复的章节交付失败。',
    'outcome': ValueReaders.stringValue(deliverySignal['state'], 'delivered'),
    'failure_kind': '',
    'reason_code': 'delivery_passed',
    'source_policy_id': 'default_chapter_delivery_recovery_policy',
    'requires_user_decision': false,
    'should_auto_recover': false,
    'exhausted': false,
    'attempt_count': 0,
    'attempt_limit': 1,
    'fallback_actions': const <Object?>[],
    'context': const <String, Object?>{},
  };
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

class _ChapterGuide {
  const _ChapterGuide(
    this.chapterNumber,
    this.chapterLabel,
    this.title,
    this.brief,
  );

  final int chapterNumber;
  final String chapterLabel;
  final String title;
  final String brief;

  String get chapterPath => 'chapters/$chapterLabel.md';
  String get summaryPath => 'summaries/$chapterLabel.summary.md';

  JsonMap toJson() {
    return <String, Object?>{
      'chapter_number': chapterNumber,
      'chapter_label': chapterLabel,
      'title': title,
      'brief': brief,
      'chapter_path': chapterPath,
      'summary_path': summaryPath,
    };
  }
}
