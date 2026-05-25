import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针专门验证第一种长任务模式在“信息不足补问”和“信息足够建计划”两条链路上是否可用。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_autopilot_probe',
    title: 'Seed Autopilot Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task mode 1 probe',
  );
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_seed_probe_',
  );
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
  );
  final modeRepository = ProjectModeGuidanceRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final transitionService = ModeGuidanceTransitionService();
  final promptBuilder = const LongTaskEntryPromptBuilderService();
  final useCase = GenerateDraftUseCase(
    projectWorkspacePort: bundle.projectWorkspacePort,
    llmGateway: bundle.createGateway(
      provider,
      networkSettings: const <String, Object?>{'proxy_mode': 'system'},
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
    loadAvailableAgents: (project) =>
        bundle.agentPackageCatalog.loadAgentPackages(project),
    loadAvailableAgentGroups: (project) =>
        bundle.agentGroupCatalog.loadAgentGroups(project),
  );

  final incompleteProject = await createProjectWorkspaceUseCase.execute(
    projectsRootPath: projectRoot.path,
    title: '模式一探针_信息不足',
    projectType: 'long_novel',
  );
  await _seedIncompleteState(
    repository: modeRepository,
    transitionService: transitionService,
    project: incompleteProject,
  );

  final completeProject = await createProjectWorkspaceUseCase.execute(
    projectsRootPath: projectRoot.path,
    title: '模式一探针_信息足够',
    projectType: 'long_novel',
  );
  await _seedCompleteState(
    repository: modeRepository,
    transitionService: transitionService,
    project: completeProject,
  );

  final reports = <String, Object?>{};
  reports['gap_probe'] = await runDraftProbeCase(
    useCase: useCase,
    project: incompleteProject,
    modelId: provider.modelId,
    prompt:
        '${promptBuilder.build(actionId: 'long_task.create_queue', project: _projectInfo(incompleteProject), payload: const <String, Object?>{'mode': 'seed_autopilot_novel'})}\n\n额外要求：如果信息仍不足，必须调用 present_user_options 提出最少 3 个补充选项，不要直接写总纲。',
    validator: _validateGapProbe,
  );
  reports['plan_probe'] = await runDraftProbeCase(
    useCase: useCase,
    project: completeProject,
    modelId: provider.modelId,
    prompt:
        '${promptBuilder.build(actionId: 'long_task.create_queue', project: _projectInfo(completeProject), payload: const <String, Object?>{'mode': 'seed_autopilot_novel'})}\n\n额外要求：必须先读取 tracking/modes/seed_autopilot_novel/guidance.md，再至少完成以下一个真实动作：写入 outline/总纲.md；或写入 chapter_outlines/章节任务清单.md；或创建不少于 3 个 chapter tasks。',
    validator: _validatePlanProbe,
  );

  final reportPath = File(
    '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_mode_probe_report.json',
  );
  await reportPath.parent.create(recursive: true);
  await reportPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(reports),
  );
  stdout.writeln('report: ${reportPath.path}');
  stdout.writeln(
    'gap_probe: ${reports['gap_probe'] is Map && (reports['gap_probe'] as Map)['ok'] == true ? 'PASS' : 'FAIL'}',
  );
  stdout.writeln(
    'plan_probe: ${reports['plan_probe'] is Map && (reports['plan_probe'] as Map)['ok'] == true ? 'PASS' : 'FAIL'}',
  );
}

Future<void> _seedIncompleteState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('seed_autopilot_novel');
  state = transitionService.answer(
    state,
    stageId: 'seed_scope',
    fieldKey: 'seed_scope',
    value: '只有一句灵感或一个核心卖点，还没有明确大纲。',
    label: '只有一句灵感',
    source: 'option',
  );
  await repository.save(project, state);
}

Future<void> _seedCompleteState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('seed_autopilot_novel');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'seed_scope',
      'field': 'seed_scope',
      'value':
          '题材是黑暗奇幻权谋。主角林夜曾是边境公爵之子，家族在政变夜被灭门，他被流放到北境矿牢。多年后他意外掌握能读取誓约裂痕的能力，决定回到帝都，一边伪装成誓约修补师，一边追查当年政变真相，最终掀翻由皇室、教廷和七大公国共同维持的秩序。',
      'label': '已有题材设定',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value':
          '核心承诺是高压权谋、阶层压迫与连续逆转。读者需要持续看到主角在更高层级的政治缝隙中反杀、更换盟友与对手、并逐步揭开帝国誓约体系背后的真相。',
      'label': '权谋悬压',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value':
          '帝国以“誓约”维持统治。皇室、教廷、七大公国、北境军团与地下商盟是五个核心阵营。所有高位者都被誓约束缚，违背誓约会导致力量反噬、血脉污染或领地崩坏。主角的能力能看见誓约裂痕，但不能直接修改誓约，只能借局势诱发连锁崩解。',
      'label': '奇幻秩序',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '主角第一驱动力是复仇与翻案，但更深层目标是夺回家族被剥夺的北境守护权，并重写帝国把誓约当作奴役工具的秩序。',
      'label': '复仇翻盘',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '文风要求干净、利落、偏商业长篇。每章都要有明确钩子、情报推进或权力逆转，避免空泛抒情和大段设定灌输。',
      'label': '干净利落',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许智能体先生成总纲、分卷结构和前 12 章章纲，但跨卷大转折、核心反派身份和最终结局方向需要先回到用户确认。',
      'label': '先纲后文',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以开始生成可恢复长任务链。',
      'label': '开始托管',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      label: item['label']!,
      source: 'option',
    );
  }
  await repository.save(project, state);
}

Future<Map<String, Object?>> _validateGapProbe(
  DraftGenerationResult result,
) async {
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((item) => ValueReaders.stringValue(item['name']))
      .toList(growable: false);
  final readGuidance = result.executedTools
      .map(ValueReaders.mapValue)
      .where(
        (item) => ValueReaders.stringValue(item['name']) == 'read_project_file',
      )
      .any(
        (item) => ValueReaders.stringValue(
          ValueReaders.mapValue(item['arguments'])['relative_path'],
        ).contains('tracking/modes/seed_autopilot_novel/guidance.md'),
      );
  final readProjectedAsset = result.executedTools
      .map(ValueReaders.mapValue)
      .where(
        (item) => ValueReaders.stringValue(item['name']) == 'read_project_file',
      )
      .any((item) {
        final path = ValueReaders.stringValue(
          ValueReaders.mapValue(item['arguments'])['relative_path'],
        );
        return path.contains('seed_autopilot_seed.md') ||
            path.contains('seed_autopilot_constraints.md') ||
            path.contains('seed_autopilot_world_anchor.md') ||
            path.contains('seed_autopilot_protagonist.md') ||
            path.contains('seed_autopilot_style.md');
      });
  final ok =
      (readGuidance || readProjectedAsset) &&
      toolNames.contains('present_user_options') &&
      result.waitingForUserChoice;
  return <String, Object?>{
    'ok': ok,
    'summary':
        'read_guidance=$readGuidance read_projected=$readProjectedAsset options=${toolNames.contains('present_user_options')} waiting=${result.waitingForUserChoice}',
  };
}

Future<Map<String, Object?>> _validatePlanProbe(
  DraftGenerationResult result,
) async {
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((item) => ValueReaders.stringValue(item['name']))
      .toList(growable: false);
  final readGuidance = result.executedTools
      .map(ValueReaders.mapValue)
      .where(
        (item) => ValueReaders.stringValue(item['name']) == 'read_project_file',
      )
      .any(
        (item) => ValueReaders.stringValue(
          ValueReaders.mapValue(item['arguments'])['relative_path'],
        ).contains('tracking/modes/seed_autopilot_novel/guidance.md'),
      );
  final readProjectedAsset = result.executedTools
      .map(ValueReaders.mapValue)
      .where(
        (item) => ValueReaders.stringValue(item['name']) == 'read_project_file',
      )
      .any((item) {
        final path = ValueReaders.stringValue(
          ValueReaders.mapValue(item['arguments'])['relative_path'],
        );
        return path.contains('seed_autopilot_seed.md') ||
            path.contains('seed_autopilot_constraints.md') ||
            path.contains('seed_autopilot_world_anchor.md') ||
            path.contains('seed_autopilot_protagonist.md') ||
            path.contains('seed_autopilot_style.md');
      });
  final hasPlanningOutput =
      result.writtenPaths.any((path) => path.startsWith('outline/')) ||
      result.writtenPaths.any((path) => path.startsWith('chapter_outlines/')) ||
      result.changedPaths.any((path) => path.startsWith('tasks/')) ||
      toolNames.contains('create_chapter_task');
  final ok = (readGuidance || readProjectedAsset) && hasPlanningOutput;
  return <String, Object?>{
    'ok': ok,
    'summary':
        'read_guidance=$readGuidance read_projected=$readProjectedAsset planning_output=$hasPlanningOutput written=${result.writtenPaths.length}',
  };
}

Map<String, Object?> _projectInfo(ProjectDescriptor project) {
  return <String, Object?>{
    'id': project.id,
    'title': project.name,
    'path': project.rootPath,
    'project_type': project.projectType,
  };
}
