import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tool/probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证第二种长任务模式在“信息不足补问”和“信息足够先建纲”两条链路上的稳定性。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'full_outline_probe',
    title: 'Full Outline Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task mode 2 probe',
  );
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_full_outline_probe_',
  );
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
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
    title: '模式二探针_信息不足',
    projectType: 'long_novel',
    runtimeBaselineId: 'continuous_autonomous',
  );
  await _seedIncompleteState(
    repository: modeRepository,
    transitionService: transitionService,
    project: incompleteProject,
  );

  final completeProject = await createProjectWorkspaceUseCase.execute(
    projectsRootPath: projectRoot.path,
    title: '模式二探针_信息足够',
    projectType: 'long_novel',
    runtimeBaselineId: 'continuous_autonomous',
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
        '${promptBuilder.build(actionId: 'long_task.create_queue', project: _projectInfo(incompleteProject), payload: const <String, Object?>{'mode': 'full_outline_consensus'})}\n\n额外要求：如果全书信息仍不足，必须调用 present_user_options 提出至少 3 个补充方向，不要直接写总纲。',
    validator: _validateGapProbe,
  );
  reports['plan_probe'] = await runDraftProbeCase(
    useCase: useCase,
    project: completeProject,
    modelId: provider.modelId,
    prompt:
        '${promptBuilder.build(actionId: 'long_task.create_queue', project: _projectInfo(completeProject), payload: const <String, Object?>{'mode': 'full_outline_consensus'})}\n\n额外要求：必须先读取 tracking/modes/full_outline_consensus/guidance.md，再至少完成以下一个真实动作：写入 outline/总纲.md；或写入 volume_outlines/卷纲.md；或创建不少于 3 个 chapter tasks。',
    validator: _validatePlanProbe,
  );

  final reportPath = File(
    '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}full_outline_mode_probe_report.json',
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
  var state = transitionService.initialize('full_outline_consensus');
  state = transitionService.answer(
    state,
    stageId: 'book_premise',
    fieldKey: 'book_premise',
    value: '一个失势宗门后人被迫回京卷入新朝开国后的权力清洗。',
    label: '故事总前提',
    source: 'free_text',
  );
  await repository.save(project, state);
}

Future<void> _seedCompleteState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('full_outline_consensus');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'book_premise',
      'field': 'book_premise',
      'value': '一个衰败帝国边境的私生公主被迫回京争位。她必须在皇储之争、边军失控和异族南下之间，建立自己的政治联盟并重新定义帝国秩序。',
    },
    <String, String>{
      'stage': 'main_arc',
      'field': 'main_arc',
      'value':
          '主线围绕“回京入局、收拢边军、拆解诸侯联盟、最终夺权重建秩序”四个阶段推进。核心冲突是主角如何在既要掌权又不愿沦为旧秩序复制品之间作出选择。',
    },
    <String, String>{
      'stage': 'volume_map',
      'field': 'volume_map',
      'value':
          '第一卷回京入局，建立初始盟友与敌对格局；第二卷边军反噬，主角必须回到边境稳住旧部；第三卷诸侯裂盟，主角主动引爆朝局；第四卷王座清算，主角与最大政敌公开对决。',
    },
    <String, String>{
      'stage': 'ending_commitment',
      'field': 'ending_commitment',
      'value': '结局必须让主角掌权，但她会在情感与信任关系上付出巨大代价，最终建立一种比旧帝国更冷硬却更诚实的新秩序。',
    },
    <String, String>{
      'stage': 'style_and_boundaries',
      'field': 'style_and_boundaries',
      'value': '文风要干净克制、偏商业长篇，强调政治博弈和局势逆转，避免空转抒情与套路打脸。',
    },
    <String, String>{
      'stage': 'consensus_confirm',
      'field': 'consensus_confirm',
      'value': '当前全书共识已经足够，可以开始生成总纲、卷纲和执行队列。',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      source: 'free_text',
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
        ).contains('tracking/modes/full_outline_consensus/guidance.md'),
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
        return path.contains('full_outline_consensus_overview.md') ||
            path.contains('full_outline_consensus_volumes.md') ||
            path.contains('full_outline_consensus_constraints.md') ||
            path.contains('full_outline_consensus_style.md') ||
            path.contains('full_outline_consensus_core_roles.md');
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
        ).contains('tracking/modes/full_outline_consensus/guidance.md'),
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
        return path.contains('full_outline_consensus_overview.md') ||
            path.contains('full_outline_consensus_volumes.md') ||
            path.contains('full_outline_consensus_constraints.md') ||
            path.contains('full_outline_consensus_style.md') ||
            path.contains('full_outline_consensus_core_roles.md');
      });
  final hasPlanningOutput =
      result.writtenPaths.any((path) => path.startsWith('outline/')) ||
      result.writtenPaths.any((path) => path.startsWith('volume_outlines/')) ||
      result.changedPaths.any((path) => path.startsWith('tasks/')) ||
      toolNames.contains('set_agent_tasks') ||
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
