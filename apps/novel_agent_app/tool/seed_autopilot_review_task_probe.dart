import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证“真实执行 -> 检查点复盘 -> 物化审稿任务”是否能跑通共享 runtime 链路。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_review_task_probe',
    title: 'Seed Review Task Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task checkpoint review task probe',
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
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
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
    'novel_agent_seed_review_task_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '模式一审稿任务探针',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
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
    final planningTask = await workflowRuntimeService.nextWorkflowTask(project);
    await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(
          planningTask['relative_path'],
        ),
      },
    );
    final chapterTask =
        (await workflowRuntimeService.listWorkflowTasks(project)).firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
          orElse: () => const <String, Object?>{},
        );
    if (chapterTask.isEmpty) {
      throw StateError('未生成 chapter 任务。');
    }
    final chapterSelector = <String, Object?>{
      'relative_path': ValueReaders.stringValue(chapterTask['relative_path']),
    };
    final runChapter = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      chapterSelector,
    );
    final created = await workflowRuntimeService.createCheckpointReviewTasks(
      project,
      chapterSelector,
    );
    final reviewTasks = ValueReaders.mapList(created['tasks']);
    final checkpointReviewPath = ValueReaders.stringValue(
      created['checkpoint_review_path'],
    );
    final allTasks = await workflowRuntimeService.listWorkflowTasks(project);
    final suggestionTasks = allTasks
        .where((task) {
          if (ValueReaders.stringValue(task['task_type']) != 'review') {
            return false;
          }
          final metadata = ValueReaders.mapValue(task['metadata']);
          return ValueReaders.stringValue(metadata['origin']) ==
              'checkpoint_review_suggestion';
        })
        .toList(growable: false);
    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(runChapter['ok']) &&
          ValueReaders.boolValue(created['ok']) &&
          checkpointReviewPath.startsWith('tracking/checkpoint_reviews/') &&
          reviewTasks.isNotEmpty &&
          suggestionTasks.isNotEmpty,
      'checkpoint_review_path': checkpointReviewPath,
      'review_task_count': reviewTasks.length,
      'suggestion_task_count': suggestionTasks.length,
      'review_task_paths': reviewTasks
          .map((task) => ValueReaders.stringValue(task['relative_path']))
          .toList(growable: false),
      'review_task_titles': reviewTasks
          .map((task) => ValueReaders.stringValue(task['title']))
          .toList(growable: false),
      'run_chapter_changed_paths': ValueReaders.stringList(
        runChapter['changed_paths'],
      ),
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_review_task_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_review_task_probe: PASS'
          : 'seed_autopilot_review_task_probe: FAIL',
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
      'value': '黑暗奇幻权谋长篇。主角林夜被流放多年后重返帝都复仇翻案。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '高压权谋、连续逆转与阶层压迫下的上升反击。',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '帝国以誓约体系维持秩序，主角只能识别裂痕，不能直接改写誓约。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '主角要复仇翻案，并夺回北境秩序的话语权。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '干净利落，偏商业长篇。每章都要有钩子、情报推进或权力逆转。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许先生成总纲、章纲和样章，但跨卷大转折与结局方向需要先回到用户确认。',
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
