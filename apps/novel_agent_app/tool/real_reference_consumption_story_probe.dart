import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main() async {
  await ensureLocalRealProbeOptIn(
    probeName: 'real_reference_consumption_story_probe',
  );
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_reference_consumption_story_probe',
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_reference_consumption_story_probe',
    title: 'Real Reference Consumption Story Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description:
        'Real probe for validating reference extraction asset consumption plus external research participation.',
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
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'real_reference_consumption_story_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);

  final report = <String, Object?>{
    'probe_name': 'real_reference_consumption_story_probe',
    'run_id': runId,
    'workspace_root': workspaceRoot.path,
    'probe_config_source': apiConfig.sourceLabel,
    'model_id': provider.modelId,
    'started_at': DateTime.now().toIso8601String(),
  };

  try {
    final project = await _createProject(bundle, workspaceRoot.path);
    report['project_root'] = project.rootPath;
    final expressionConstraintProfileRepository =
        ExpressionConstraintProfileRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectExpressionConstraintBindingRepository =
        ProjectExpressionConstraintBindingRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final probeExpressionBindings = defaultProbeExpressionBindings(
      idPrefix: 'reference_consumption_story_probe',
    );
    await projectExpressionConstraintBindingRepository.saveBindings(
      project,
      probeExpressionBindings,
    );
    final loadedExpressionConstraintProfiles =
        await expressionConstraintProfileRepository.loadProfiles(project);
    report['loaded_expression_constraint_profile_ids'] =
        loadedExpressionConstraintProfiles
            .map((profile) => profile.id)
            .toList(growable: false);
    report['expression_constraint_setup'] =
        buildProbeExpressionConstraintSetupReport(
          loadedProfiles: loadedExpressionConstraintProfiles,
          savedBindings: probeExpressionBindings,
        );

    final referenceSetup = await _mountFullSeriesReference(
      bundle: bundle,
      project: project,
      repoRoot: repoRoot,
    );
    report['reference_setup'] = referenceSetup;

    final researchSetup = await _seedCultivationResearch(
      bundle: bundle,
      project: project,
    );
    report['cultivation_research_setup'] = researchSetup;

    await _seedProjectFiles(
      workspacePort: bundle.projectWorkspacePort,
      project: project,
      referenceSetup: referenceSetup,
      researchSetup: researchSetup,
    );

    final storyResult = await _generateStory(
      bundle: bundle,
      settings: settings,
      provider: provider,
      project: project,
    );
    report['story_generation'] = storyResult;

    final projectionTexts = await _readProjectionTexts(
      workspacePort: bundle.projectWorkspacePort,
      project: project,
    );
    report['projection_paths_present'] = projectionTexts.keys.toList(
      growable: false,
    );
    report['projection_snippets'] = projectionTexts.map(
      (key, value) => MapEntry(key, _snippet(value)),
    );

    final storyPath = ValueReaders.stringValue(storyResult['output_path']);
    final storyMarkdown =
        await bundle.projectWorkspacePort.readTextFile(
          project.rootPath,
          storyPath,
        ) ??
        '';
    report['story_path'] = storyPath;
    report['story_preview'] = _snippet(storyMarkdown, maxChars: 3200);
    final activationSignals = await _readActivationSignals(
      workspacePort: bundle.projectWorkspacePort,
      project: project,
      storyResult: storyResult,
    );
    report['activation_signals'] = activationSignals;
    report['story_asset_signals'] = _storyAssetSignals(
      storyMarkdown: storyMarkdown,
      storyResult: storyResult,
      researchSetup: researchSetup,
      referenceSetup: referenceSetup,
      projectionTexts: projectionTexts,
    );
    _ensure(
      ValueReaders.boolValue(storyResult['ok']),
      '真实写作消费链未完成正式交付。',
    );
    _ensure(
      ValueReaders.intValue(activationSignals['selected_section_count']) > 0,
      'activation report 没有选入任何上下文 section。',
    );
    _ensure(
      ValueReaders.intValue(activationSignals['selected_with_source_refs']) > 0,
      'selected context sections 没有带入 source refs。',
    );
    _ensure(
      ValueReaders.intValue(activationSignals['selected_with_evidence_refs']) >
          0,
      'selected context sections 没有带入 evidence refs。',
    );
    _ensure(
      ValueReaders.intValue(
            activationSignals['selected_with_project_information_locator'],
          ) >
          0,
      'selected context sections 没有带入 project-information locator。',
    );
    report['ok'] = ValueReaders.boolValue(storyResult['ok']);
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_reference_consumption_story_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_reference_consumption_story_probe_report.md',
    );
    await markdownFile.writeAsString(_reportMarkdown(report));
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

Future<ProjectDescriptor> _createProject(
  AdapterBundle bundle,
  String projectsRootPath,
) {
  final useCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  return useCase.execute(
    projectsRootPath: projectsRootPath,
    title: '参考资产真实消费写作探针',
    projectType: 'novel',
  );
}

Future<Map<String, Object?>> _mountFullSeriesReference({
  required AdapterBundle bundle,
  required ProjectDescriptor project,
  required String repoRoot,
}) async {
  final substrateRoot = Directory(
    '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}reference_extraction${Platform.pathSeparator}substrate',
  )..createSync(recursive: true);
  final substrate = SqliteReferenceEvidenceSubstrate(
    substrateRootPath: substrateRoot.path,
  );
  final importService = ReferenceBundleImportService(substrate: substrate);
  final bundleRoot = _resolveReferenceBundleRoot(repoRoot);
  final importResult = await importService.importFromDirectory(bundleRoot);
  final mountService = ProjectReferenceExtractionMountService(
    workspacePort: bundle.projectWorkspacePort,
  );
  final projectionResult = await mountService.attachAndProjectIfRequested(
    project: project,
    substrate: substrate,
    request: const ProjectReferenceExtractionRequest(
      sourceFilePath: '',
      attachToProject: true,
      projectMountedEntries: true,
      explicitProjectionConfirmationGranted: true,
    ),
    packageId: importResult.packageId,
    packageVersionId: importResult.packageVersionId,
    displayName: '哈利波特第一卷真实提取资产',
    attachedAt: DateTime.now().toIso8601String(),
  );

  return <String, Object?>{
    'bundle_root': bundleRoot,
    'package_id': importResult.packageId,
    'package_version_id': importResult.packageVersionId,
    'imported_entry_count': importResult.importedEntryIds.length,
    'projection_status': projectionResult?.status ?? '',
    'knowledge_card_ids': projectionResult?.knowledgeCardIds ?? const <String>[],
    'design_element_ids':
        projectionResult?.designElementIds ?? const <String>[],
    'research_note_ids': projectionResult?.researchNoteIds ?? const <String>[],
    'reference_work_ids':
        projectionResult?.referenceWorkIds ?? const <String>[],
    'projection_paths':
        projectionResult?.generatedProjectionPaths ?? const <String>[],
  };
}

Future<Map<String, Object?>> _seedCultivationResearch({
  required AdapterBundle bundle,
  required ProjectDescriptor project,
}) async {
  final recordStore = SqliteProjectInformationRecordStore();
  final researchRepository = SqliteResearchNoteRepository(
    recordStore: recordStore,
  );
  final knowledgeRepository = SqliteKnowledgeCardRepository(
    recordStore: recordStore,
  );
  final projectionWriter = ProjectInformationProjectionWriterService(
    workspacePort: bundle.projectWorkspacePort,
    knowledgeCardRepository: knowledgeRepository,
    designElementRepository: SqliteDesignElementRepository(
      recordStore: recordStore,
    ),
    researchNoteRepository: researchRepository,
    referenceWorkRepository: SqliteReferenceWorkRepository(
      recordStore: recordStore,
    ),
  );
  final createdAt = DateTime.now().toIso8601String();
  final researchId = 'cultivation_research_note_001';
  final cardId = 'cultivation_knowledge_card_001';

  await researchRepository.appendResearchNote(
    project,
    ResearchNote(
      researchId: researchId,
      query: '道教内丹、气脉、符箓与天师传统的轻量写作知识卡',
      sourceKind: 'external_research',
      sourceUrlOrRef:
          'https://plato.stanford.edu/archives/fall2023/entries/daoism-religion/ | https://www.britannica.com/topic/Taoism/Basic-concepts-of-Taoism',
      citation:
          'Stanford Encyclopedia of Philosophy: Daoism - Religion; Encyclopaedia Britannica: Basic concepts of Taoism.',
      summary:
          '研究结果聚焦可安全用于轻松向跨界写作的通用概念：内丹重视精气神转化与身心修炼；气的调息与运行可表现为感知增强、心境稳定和少量日常巧技；符箓和天师传统更适合作为仪式化、驱邪化、秩序化的技法来源，不应直接写成无代价万能法术。',
      usableFacts: const <Object?>[
        <String, Object?>{
          'fact': '内丹修炼通常围绕精、气、神的调理与转化展开，更强调身心次第而非瞬间爆发。',
          'kind': 'cultivation_core',
        },
        <String, Object?>{
          'fact': '气的书写可落在呼吸、感知、宁神、体能恢复和细微操控，不必默认表现为大规模战斗光炮。',
          'kind': 'qi_usage',
        },
        <String, Object?>{
          'fact': '符箓与天师传统适合表现为驱邪、镇静、辟秽、结界和识别异常痕迹，强调仪式与秩序。',
          'kind': 'talisman_usage',
        },
        <String, Object?>{
          'fact': '若进入西式魔法校园，修仙知识更自然的消费方式是补足日常、观察、识别风险和处理执念，而不是完全替代原有魔法体系。',
          'kind': 'crossover_guideline',
        },
      ],
      creativeSuggestions: const <Object?>[
        <String, Object?>{'idea': '主角可把打坐、调息、画符当作宿舍日常，与霍格沃茨课程形成轻松反差。'},
        <String, Object?>{'idea': '解决原作意难平时，优先让修仙知识作用于观察、保命、安神和提前识别危险。'},
      ],
      uncertainty: '当前研究只提炼了适合写作消费的跨题材通用概念，没有展开宗派细分、历史争议和仪式细节。',
      licenseOrUsageNote: '仅作为 research note 与 project knowledge 使用，不直接复述来源原文。',
      createdBy: 'real_reference_consumption_story_probe',
      usagePolicy: const InformationUsagePolicy(
        usageMode: 'project_reference',
        citationRiskLevel: 'medium_risk',
        requiresConfirmation: false,
        allowsDerivativeUse: true,
        allowsDirectQuote: false,
      ),
      metadata: <String, Object?>{
        'created_at': createdAt,
        'source_urls': <String>[
          'https://plato.stanford.edu/archives/fall2023/entries/daoism-religion/',
          'https://www.britannica.com/topic/Taoism/Basic-concepts-of-Taoism',
        ],
      },
    ),
  );

  await knowledgeRepository.appendKnowledgeCard(
    project,
    ProjectKnowledgeCard(
      cardId: cardId,
      cardNamespace: 'crossover_cultivation',
      cardType: 'world_rule',
      title: '修仙知识在魔法校园中的轻量使用原则',
      summary: '把修仙知识写成轻量、可持续、偏日常和偏观察的能力层，而不是直接压扁原作世界观。',
      contentPayload: const <String, Object?>{
        'core_rules': <String>[
          '以调息、感知、安神、驱秽、识别异常为主。',
          '尽量把能力写成日常细节和问题解决手段，而不是大规模碾压。',
          '遇到原作悲剧节点时，可让主角凭提前感知、符箓安神或因果警觉做微调。',
          '保持霍格沃茨课程、师生关系和同级校园生活仍然是叙事主场。',
        ],
        'tone': 'light_daily_crossover',
      },
      sourceRefs: const <InformationSourceRef>[
        InformationSourceRef(
          sourceRef: NarrativeSourceRef(
            sourceType: 'project_research_note',
            sourceId: 'cultivation_research_note_001',
            label: '修仙研究笔记',
          ),
          sourceAuthority: 'research_note',
          roleAuthority: 'researcher',
          researchDepth: 'medium',
        ),
      ],
      evidenceRefs: const <NarrativeEvidenceRef>[
        NarrativeEvidenceRef(
          evidenceType: 'project_research_note',
          evidenceId: 'cultivation_research_note_001',
          sourceRef: NarrativeSourceRef(
            sourceType: 'project_research_note',
            sourceId: 'cultivation_research_note_001',
            label: '修仙研究笔记',
          ),
          summary: '该知识卡直接提炼自项目研究笔记中的跨题材使用原则。',
        ),
      ],
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.required,
        requiresExplicitSelection: false,
        preferredBudgetChars: 260,
      ),
      usagePolicy: const InformationUsagePolicy(
        usageMode: 'project_reference',
        citationRiskLevel: 'medium_risk',
        requiresConfirmation: false,
        allowsDerivativeUse: true,
        allowsDirectQuote: false,
      ),
      confidence: 0.79,
      lifecycleStatus: 'active',
      metadata: <String, Object?>{
        'created_at': createdAt,
        'activation_required': true,
        'activation_pinned': true,
        'preferred_budget_chars': 260,
      },
    ),
  );

  final projections = await projectionWriter.writeProjection(project);
  return <String, Object?>{
    'research_note_id': researchId,
    'knowledge_card_id': cardId,
    'projection_paths': projections
        .map((item) => item.relativePath)
        .toList(growable: false),
  };
}

Future<void> _seedProjectFiles({
  required ProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
  required Map<String, Object?> referenceSetup,
  required Map<String, Object?> researchSetup,
}) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    [
      '# 项目规格',
      '',
      '- 目标：验证正式 reference extraction 结果、项目知识卡与外部 research note 能否共同参与真实写作。',
      '- 题材：哈利波特同人，整体偏轻松向，允许剧情偏移但不得无视原作核心关系与校园节奏。',
      '- 主角：来自地球的中国人；地球原本无法修炼，但主角偶然获得修仙功法；前世作为天师老死后穿越到哈利波特世界，转生成中国人，与哈利同级进入霍格沃兹。',
      '- 消费纪律：必须优先使用项目内 reference 投影、knowledge card 与 research note；不得把外部研究直接当成长引用抄入正文。',
      '- 修仙能力使用方式：偏日常、偏观察、偏安神和解决问题，避免一上来碾压整个魔法体系。',
      '- 剧情目标：处理原作中的意难平，并让剧情偏移来自主角的真实介入，不要只写成口头宣言。',
      '',
      '## 已挂载参考',
      '',
      '- 整书参考资料包：${ValueReaders.stringValue(referenceSetup['package_id'])}@${ValueReaders.stringValue(referenceSetup['package_version_id'])}',
      '- 修仙研究笔记：${ValueReaders.stringValue(researchSetup['research_note_id'])}',
      '- 修仙知识卡：${ValueReaders.stringValue(researchSetup['knowledge_card_id'])}',
      '',
    ].join('\n'),
  );

  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/story/写作任务.md',
    [
      '# 写作任务',
      '',
      '请写一篇偏轻松向的同人故事，重点不是面面俱到，而是让“已有参考资产真的参与了写作”。',
      '',
      '硬约束：',
      '- 主角来自地球中国，前世为天师，晚年才偶得修仙功法，死后转生到哈利波特世界。',
      '- 主角与哈利同级入学，在霍格沃兹展开校园生活。',
      '- 修仙知识必须以项目 research / knowledge 资产为准，主要用于调息、感知、安神、驱秽、识别异常和解决校园问题。',
      '- 需要处理原作意难平，并写出由此造成的剧情偏移。',
      '- 故事里应自然出现至少三类参考影响：哈利波特原作角色/校园资产、修仙 research note、修仙 knowledge card。',
      '- 避免直接照抄原作句子；要写成新的派生剧情。',
      '',
      '推荐关注的原作资产：',
      '- 霍格沃茨是校园生活主场，主角不要把魔法学校写成背景板。',
      '- 哈利、罗恩、赫敏是核心三人组，主角的加入应是增量而不是替换。',
      '- 海格、女贞路、对角巷、从麻瓜到魔法世界的边界感、轻微反讽和日常幽默都是有价值的参考。',
      '',
    ].join('\n'),
  );

  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/轻松校园跨界风格.md',
    [
      '# 轻松校园跨界风格',
      '',
      '- 校园细节要自然，人物互动要有少年气和一点机灵感。',
      '- 修仙知识优先写成生活化手段，例如清心、感知、安神、护符、驱秽、小范围化解危机。',
      '- 允许轻微幽默和文化反差，但不要玩梗过度。',
      '- 原作人物的情感基调和关系张力要保留，不要只剩设定拼盘。',
      '',
    ].join('\n'),
  );
}

Future<Map<String, Object?>> _generateStory({
  required AdapterBundle bundle,
  required AppSettings settings,
  required ProviderEndpointSettings provider,
  required ProjectDescriptor project,
}) async {
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final conversationRuntimeService = ProjectConversationDraftRuntimeService(
    workspacePort: bundle.projectWorkspacePort,
    hostPort: bundle.projectToolHostPort,
    taskRepository: taskRepository,
  );
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

  final preparation = await conversationRuntimeService.prepareDraftRun(
    project,
    taskType: 'chapter',
    pinnedRelativePaths: const <String>[
      'specs/project_spec.md',
      'outlines/story/写作任务.md',
      'styles/轻松校园跨界风格.md',
      'knowledge/项目知识摘要.md',
      'knowledge/设计元素摘要.md',
      'research/资料研究摘要.md',
      'references/引用作品边界.md',
    ],
  );
  final deliveryOnlyToolIds = preparation.exposedToolIds
      .where(
        (toolId) => toolId == NarrativeDomainToolNames.submitChapterDelivery,
      )
      .toList(growable: false);
  final progressPhases = <String>[];
  final result = await useCase.execute(
    project: project,
    userPrompt: _storyPrompt,
    modelId: resolvedModelId,
    title: '第一章《天师新生》',
    sessionContext: [
      '系统说明：当前上下文已经预载入项目规格、哈利波特参考摘要、引用边界、修仙研究摘要与知识卡摘要。',
      '请不要继续读取项目文件、列目录、加载技能或停在计划说明；直接写正文，并在末轮调用 submit_chapter_delivery 正式交付。',
      preparation.sessionContextMarkdown,
    ].join('\n\n'),
    requestOptions: requestOptions,
    contextSettings: settings.contextSettings,
    modelProfile: runtimeProfile,
    exposedToolIds: deliveryOnlyToolIds,
    onProgress: (progress) {
      progressPhases.add(progress.phase);
    },
  );
  final artifacts = await conversationRuntimeService.finalizeDraftRun(
    project: project,
    preparation: preparation,
    result: result,
    title: '第一章《天师新生》',
  );
  return <String, Object?>{
    'ok': !result.waitingForUserChoice && !result.stoppedByToolError,
    'progress_phases': progressPhases,
    'executed_tools': result.executedTools,
    'waiting_for_user_choice': result.waitingForUserChoice,
    'stopped_by_tool_error': result.stoppedByToolError,
    'tool_error_summary': result.toolErrorSummary,
    'output_path': artifacts.outputPath,
    'activation_report_path': artifacts.activationReportPath,
    'activation_report_summary': artifacts.activationReportSummary,
    'chapter_delivery': artifacts.chapterDelivery,
    'information_status': artifacts.informationStatus,
    'information_summary': artifacts.informationSummary,
    'information_changed_paths': artifacts.informationChangedPaths,
    'changed_paths': artifacts.changedPaths,
    'session_context_markdown_preview': _snippet(
      preparation.sessionContextMarkdown,
      maxChars: 3200,
    ),
    'session_context_signals': <String, Object?>{
      'contains_source_refs_marker':
          preparation.sessionContextMarkdown.contains('source_refs:'),
      'contains_evidence_refs_marker':
          preparation.sessionContextMarkdown.contains('evidence_refs:'),
      'contains_project_information_locator':
          preparation.sessionContextMarkdown.contains('project-information://'),
    },
  };
}

Future<Map<String, Object?>> _readActivationSignals({
  required ProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
  required Map<String, Object?> storyResult,
}) async {
  final activationReportPath = ValueReaders.stringValue(
    storyResult['activation_report_path'],
  );
  if (activationReportPath.trim().isEmpty) {
    return const <String, Object?>{};
  }
  final raw = await workspacePort.readTextFile(project.rootPath, activationReportPath);
  if ((raw ?? '').trim().isEmpty) {
    return <String, Object?>{
      'activation_report_path': activationReportPath,
      'selected_section_count': 0,
    };
  }
  final decoded = jsonDecode(raw!);
  final root = _activationReportRoot(ValueReaders.mapValue(decoded));
  final selectedSections = _readSelectedActivationSections(root);
  final materializedSections = selectedSections
      .where(_isMaterializedActivationSection)
      .toList(growable: false);
  final selectedWithSourceRefs = materializedSections
      .where(
        _activationSectionHasSourceRefs,
      )
      .toList(growable: false);
  final selectedWithEvidenceRefs = materializedSections
      .where(
        _activationSectionHasEvidenceRefs,
      )
      .toList(growable: false);
  final selectedWithLocator = materializedSections
      .where(
        _activationSectionHasProjectInformationLocator,
      )
      .toList(growable: false);
  return <String, Object?>{
    'activation_report_path': activationReportPath,
    'reported_selected_section_count': selectedSections.length,
    'selected_section_count': materializedSections.length,
    'selected_item_count_from_items': ValueReaders.mapList(root['items'])
        .where(_isSelectedActivationSection)
        .length,
    'selected_with_source_refs': selectedWithSourceRefs.length,
    'selected_with_evidence_refs': selectedWithEvidenceRefs.length,
    'selected_with_project_information_locator': selectedWithLocator.length,
    'selected_section_samples': materializedSections.take(6).map((item) {
      final metadata = ValueReaders.mapValue(item['metadata']);
      return <String, Object?>{
        'title': ValueReaders.stringValue(item['title']),
        'source': ValueReaders.stringValue(item['source']),
        'target_path': ValueReaders.stringValue(item['target_path']),
        'included_chars': ValueReaders.intValue(item['included_chars']),
        'source_of_truth_locator': ValueReaders.stringValue(
          metadata['source_of_truth_locator'],
          ValueReaders.stringValue(item['source_of_truth_locator']),
        ),
        'source_display': ValueReaders.stringValue(
          metadata['source_display'],
          ValueReaders.stringValue(item['source_display']),
        ),
        'source_refs_count': ValueReaders.mapList(
          metadata['source_refs'],
        ).isNotEmpty
            ? ValueReaders.mapList(metadata['source_refs']).length
            : ValueReaders.mapList(item['source_refs']).length,
        'evidence_refs_count': ValueReaders.mapList(
          metadata['evidence_refs'],
        ).isNotEmpty
            ? ValueReaders.mapList(metadata['evidence_refs']).length
            : ValueReaders.mapList(item['evidence_refs']).length,
        'selected': ValueReaders.boolValue(item['selected'], true),
      };
    }).toList(growable: false),
  };
}

Map<String, Object?> _activationReportRoot(Map<String, Object?> root) {
  if (ValueReaders.mapList(root['selected_context_sections']).isNotEmpty ||
      ValueReaders.mapList(root['items']).isNotEmpty) {
    return root;
  }
  final nestedReport = ValueReaders.mapValue(root['report']);
  if (ValueReaders.mapList(nestedReport['selected_context_sections']).isNotEmpty ||
      ValueReaders.mapList(nestedReport['items']).isNotEmpty) {
    return nestedReport;
  }
  return root;
}

List<Map<String, Object?>> _readSelectedActivationSections(
  Map<String, Object?> root,
) {
  final selectedSections = ValueReaders.mapList(root['selected_context_sections'])
      .map(ValueReaders.mapValue)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (selectedSections.isNotEmpty) {
    return selectedSections;
  }
  return ValueReaders.mapList(root['items'])
      .where(_isSelectedActivationSection)
      .toList(growable: false);
}

bool _isSelectedActivationSection(Map<String, Object?> item) {
  return ValueReaders.boolValue(item['selected']);
}

bool _isMaterializedActivationSection(Map<String, Object?> item) {
  if (!_isSelectedActivationSection(item)) {
    return false;
  }
  if (ValueReaders.intValue(item['included_chars']) > 0) {
    return true;
  }
  return ValueReaders.stringValue(item['selected_text']).trim().isNotEmpty;
}

bool _activationSectionHasSourceRefs(Map<String, Object?> item) {
  final metadata = ValueReaders.mapValue(item['metadata']);
  return ValueReaders.mapList(item['source_refs']).isNotEmpty ||
      ValueReaders.mapList(metadata['source_refs']).isNotEmpty;
}

bool _activationSectionHasEvidenceRefs(Map<String, Object?> item) {
  final metadata = ValueReaders.mapValue(item['metadata']);
  return ValueReaders.mapList(item['evidence_refs']).isNotEmpty ||
      ValueReaders.mapList(metadata['evidence_refs']).isNotEmpty;
}

bool _activationSectionHasProjectInformationLocator(Map<String, Object?> item) {
  final metadata = ValueReaders.mapValue(item['metadata']);
  return ValueReaders.stringValue(
            item['source_of_truth_locator'],
          ).startsWith('project-information://') ||
      ValueReaders.stringValue(
        item['target_path'],
      ).startsWith('project-information://') ||
      ValueReaders.stringValue(
        metadata['source_of_truth_locator'],
      ).startsWith('project-information://');
}

Future<Map<String, String>> _readProjectionTexts({
  required ProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
}) async {
  final result = <String, String>{};
  for (final path in const <String>[
    'knowledge/项目知识摘要.md',
    'knowledge/设计元素摘要.md',
    'research/资料研究摘要.md',
    'references/引用作品边界.md',
  ]) {
    final text = await workspacePort.readTextFile(project.rootPath, path) ?? '';
    if (text.trim().isNotEmpty) {
      result[path] = text;
    }
  }
  return result;
}

Map<String, Object?> _storyAssetSignals({
  required String storyMarkdown,
  required Map<String, Object?> storyResult,
  required Map<String, Object?> researchSetup,
  required Map<String, Object?> referenceSetup,
  required Map<String, String> projectionTexts,
}) {
  final lower = storyMarkdown.toLowerCase();
  final executedToolNames =
      ValueReaders.objectList(storyResult['executed_tools'])
          .map(ValueReaders.mapValue)
          .map((item) => ValueReaders.stringValue(item['name']))
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
  return <String, Object?>{
    'mentions_hogwarts':
        storyMarkdown.contains('霍格沃') || lower.contains('hogwarts'),
    'mentions_harry': storyMarkdown.contains('哈利') || lower.contains('harry'),
    'mentions_ron_or_hermione':
        storyMarkdown.contains('罗恩') ||
        storyMarkdown.contains('赫敏') ||
        lower.contains('ron') ||
        lower.contains('hermione'),
    'mentions_hagrid_or_diagon':
        storyMarkdown.contains('海格') ||
        storyMarkdown.contains('对角巷') ||
        lower.contains('hagrid') ||
        lower.contains('diagon'),
    'mentions_cultivation_terms':
        storyMarkdown.contains('调息') ||
        storyMarkdown.contains('符') ||
        storyMarkdown.contains('天师') ||
        storyMarkdown.contains('气') ||
        storyMarkdown.contains('清心'),
    'used_information_tools': executedToolNames,
    'reference_projection_paths': referenceSetup['projection_paths'],
    'research_projection_paths': researchSetup['projection_paths'],
    'projection_texts_loaded': projectionTexts.keys.toList(growable: false),
  };
}

String _snippet(String text, {int maxChars = 1200}) {
  final normalized = text.replaceAll('\r\n', '\n').trim();
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return '${normalized.substring(0, maxChars)}...';
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

String _resolveReferenceBundleRoot(String repoRoot) {
  final override = Platform.environment['REFERENCE_CONSUMPTION_BUNDLE_ROOT'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }
  final volumeOne =
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_real_probe_workspace${Platform.pathSeparator}hp_volume1_rerun_20260608${Platform.pathSeparator}bundle';
  if (Directory(volumeOne).existsSync()) {
    return volumeOne;
  }
  return '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_real_probe_workspace${Platform.pathSeparator}hp_full_series_bulk_v1${Platform.pathSeparator}bundle';
}

String _reportMarkdown(Map<String, Object?> report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final storyGeneration = ValueReaders.mapValue(report['story_generation']);
  final assetSignals = ValueReaders.mapValue(report['story_asset_signals']);
  final lines = <String>[
    '# 参考资产真实消费写作探针报告',
    '',
    '- 结果：${ok ? 'PASS' : 'FAIL'}',
    '- 工作区：${ValueReaders.stringValue(report['workspace_root'])}',
    '- 项目目录：${ValueReaders.stringValue(report['project_root'])}',
    '- 模型：${ValueReaders.stringValue(report['model_id'])}',
    '- 故事输出：${ValueReaders.stringValue(report['story_path'])}',
    '- 等待用户确认：${ValueReaders.boolValue(storyGeneration['waiting_for_user_choice'])}',
    '- 工具错误：${ValueReaders.boolValue(storyGeneration['stopped_by_tool_error'])}',
    '- 参考资产消费信号：',
    '  - 霍格沃茨：${ValueReaders.boolValue(assetSignals['mentions_hogwarts'])}',
    '  - 哈利：${ValueReaders.boolValue(assetSignals['mentions_harry'])}',
    '  - 罗恩/赫敏：${ValueReaders.boolValue(assetSignals['mentions_ron_or_hermione'])}',
    '  - 海格/对角巷：${ValueReaders.boolValue(assetSignals['mentions_hagrid_or_diagon'])}',
    '  - 修仙术语：${ValueReaders.boolValue(assetSignals['mentions_cultivation_terms'])}',
    '',
  ];
  if (!ok) {
    lines.add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  return '${lines.join('\n')}\n';
}

HostPlatform _currentHostPlatform() {
  if (Platform.isWindows) {
    return HostPlatform.windows;
  }
  if (Platform.isMacOS) {
    return HostPlatform.macos;
  }
  if (Platform.isLinux) {
    return HostPlatform.linux;
  }
  return HostPlatform.unknown;
}

const String _storyPrompt = '''
请直接完成一章轻松向同人正文，并通过正式章节交付工具交付。

必须满足：
1. 主角来自地球中国，前世为天师，老死前偶得修仙功法，死后转生到哈利波特世界，现与哈利同级入学。
2. 正文要明显保留霍格沃茨校园感，不能只写成外挂碾压。
3. 修仙知识优先写成调息、感知、安神、护符、驱秽、识别异常和日常问题解决。
4. 至少自然处理一个原作意难平的前置苗头，例如提前察觉某个角色的情绪创伤、危险征兆或校园中的被忽视问题，并让剧情出现细小偏移。
5. 必须显得你确实参考了项目里的哈利波特资料摘要、引用边界、研究摘要和修仙知识卡，而不是裸写。
6. 避免直接照抄原作句子。
7. 不要继续规划、解释、列清单，也不要请求更多文件；当前上下文已经足够。

写法要求：
- 轻松、自然、有校园日常和人物互动。
- 允许少量幽默。
- 重点写“主角如何把修仙知识和魔法校园现实结合起来”。
- 完成正文后，必须调用 submit_chapter_delivery 正式交付。
''';
