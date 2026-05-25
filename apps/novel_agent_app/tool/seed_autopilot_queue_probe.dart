import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证受控长任务队列运行后，长任务运行记录步骤里会挂上检查点复盘引用。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_queue_probe',
    title: 'Seed Queue Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task queue probe',
  );
  final settings = AppSettings(
    defaultProviderId: provider.id,
    defaultAgentId: '',
    defaultModelId: provider.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[provider],
    networkSettings: const <String, Object?>{'proxy_mode': 'system'},
  );
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
  );
  final modeRepository = ProjectModeGuidanceRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final buildPlanInputUseCase = BuildModeGuidancePlanInputUseCase(
    statePort: modeRepository,
  );
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
        loadAvailableAgents: (project) =>
            bundle.agentPackageCatalog.loadAgentPackages(project),
        loadAvailableAgentGroups: (project) =>
            bundle.agentGroupCatalog.loadAgentGroups(project),
      );
    },
  );
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_seed_queue_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '模式一队列探针',
      projectType: 'long_novel',
    );
    await _seedReadyState(
      repository: modeRepository,
      transitionService: ModeGuidanceTransitionService(),
      project: project,
    );
    final planInput = await buildPlanInputUseCase.execute(
      project,
      modeId: 'seed_autopilot_novel',
    );
    if (planInput == null || !planInput.isReady) {
      throw StateError('模式一计划输入未准备完成。');
    }
    await workflowRuntimeService.createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    final queueRun = await workflowRuntimeService.runWorkflowTaskQueue(
      project,
      settings,
      options: const <String, Object?>{
        'max_steps': 1,
        'stop_on_user_checkpoint': true,
      },
    );
    final longTaskRecord = ValueReaders.mapValue(queueRun['long_task_record']);
    final steps = ValueReaders.mapList(longTaskRecord['steps']);
    final firstStep = steps.isEmpty ? const <String, Object?>{} : steps.first;
    final checkpointReviewPath = ValueReaders.stringValue(
      firstStep['checkpoint_review_path'],
    );
    final longTaskRunPath = ValueReaders.stringValue(
      queueRun['long_task_run_path'],
    );
    final longTaskRunJsonText = longTaskRunPath.trim().isEmpty
        ? ''
        : (await bundle.projectWorkspacePort.readTextFile(
                project.rootPath,
                longTaskRunPath,
              ) ??
              '');
    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(queueRun['ok']) &&
          steps.isNotEmpty &&
          checkpointReviewPath.startsWith('tracking/checkpoint_reviews/') &&
          longTaskRunJsonText.contains(checkpointReviewPath),
      'stop_reason': ValueReaders.stringValue(queueRun['stop_reason']),
      'steps_count': steps.length,
      'checkpoint_review_path': checkpointReviewPath,
      'long_task_run_path': longTaskRunPath,
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_queue_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_queue_probe: PASS'
          : 'seed_autopilot_queue_probe: FAIL',
    );
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

Future<void> _seedReadyState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('seed_autopilot_novel');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'seed_scope',
      'field': 'seed_scope',
      'value': '黑暗奇幻权谋长篇。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '高压权谋、阶层压迫与连续逆转。',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '帝国以誓约维持统治，主角不能直接改写誓约。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '复仇翻案，并夺回北境守护权。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '干净利落，偏商业长篇。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许先生成总纲和章纲，跨卷大转折需要人工确认。',
      'label': '托管边界',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以开始生成可恢复长任务链。',
      'label': '确认启动',
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
