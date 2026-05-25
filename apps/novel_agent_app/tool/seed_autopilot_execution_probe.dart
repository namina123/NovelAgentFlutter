import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证“模式引导 -> 计划输入 -> 工作流执行单步”整条共享运行链是否真正吃到长期约束。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_execution_probe',
    title: 'Seed Execution Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task execution probe',
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
    'novel_agent_seed_execution_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '模式一执行探针',
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
    final created = await workflowRuntimeService.createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    final planningTask = await workflowRuntimeService.nextWorkflowTask(project);
    final planningSelector = <String, Object?>{
      'relative_path': ValueReaders.stringValue(planningTask['relative_path']),
    };
    final preparedPlanning = await workflowRuntimeService
        .prepareWorkflowTaskExecution(
          project,
          planningSelector,
          modelProfile: <String, Object?>{
            'id': provider.id,
            'base_url': provider.baseUrl,
            'model_id': provider.modelId,
          },
        );
    final runOnce = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      planningSelector,
    );
    final chapterTask =
        (await workflowRuntimeService.listWorkflowTasks(project)).firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
          orElse: () => const <String, Object?>{},
        );
    final chapterSelector = <String, Object?>{
      'relative_path': ValueReaders.stringValue(chapterTask['relative_path']),
    };
    final preparedChapter = await workflowRuntimeService
        .prepareWorkflowTaskExecution(
          project,
          chapterSelector,
          modelProfile: <String, Object?>{
            'id': provider.id,
            'base_url': provider.baseUrl,
            'model_id': provider.modelId,
          },
        );
    final planningSectionTitles = _sectionTitles(preparedPlanning);
    final chapterSectionTitles = _sectionTitles(preparedChapter);
    final changedPaths = ValueReaders.stringList(runOnce['changed_paths']);
    final checkpointReview = ValueReaders.mapValue(
      runOnce['checkpoint_review'],
    );
    final checkpointReviewPath = ValueReaders.stringValue(
      checkpointReview['relative_path'],
    );
    final checkpointReviewMarkdownPath = ValueReaders.stringValue(
      checkpointReview['markdown_path'],
    );
    final checkpointReviewJsonText = checkpointReviewPath.trim().isEmpty
        ? ''
        : (await bundle.projectWorkspacePort.readTextFile(
                project.rootPath,
                checkpointReviewPath,
              ) ??
              '');
    final checkpointReviewMarkdown = checkpointReviewMarkdownPath.trim().isEmpty
        ? ''
        : (await bundle.projectWorkspacePort.readTextFile(
                project.rootPath,
                checkpointReviewMarkdownPath,
              ) ??
              '');
    final executedToolNames = ValueReaders.objectList(runOnce['executed_tools'])
        .map(
          (tool) =>
              ValueReaders.stringValue(ValueReaders.mapValue(tool)['name']),
        )
        .toList(growable: false);
    final sectionOk =
        planningSectionTitles.contains('长期约束') &&
        planningSectionTitles.contains('风格锚点') &&
        planningSectionTitles.contains('世界硬约束') &&
        planningSectionTitles.contains('角色/身份锚点') &&
        chapterSectionTitles.contains('长期约束') &&
        chapterSectionTitles.contains('任务指定来源') &&
        chapterSectionTitles.contains('风格锚点') &&
        chapterSectionTitles.contains('世界硬约束') &&
        chapterSectionTitles.contains('角色/身份锚点');
    final checkpointReviewOk =
        checkpointReviewPath.startsWith('tracking/checkpoint_reviews/') &&
        checkpointReviewMarkdownPath.endsWith('.md') &&
        checkpointReviewJsonText.contains('drift_watch_items') &&
        checkpointReviewMarkdown.contains('漂移警戒') &&
        checkpointReviewMarkdown.contains('下一步建议');
    final writeOk =
        changedPaths.any((path) => path.startsWith('outline/')) ||
        changedPaths.any((path) => path.startsWith('chapter_outlines/')) ||
        changedPaths.any((path) => path.startsWith('tasks/'));
    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(created['ok']) &&
          ValueReaders.boolValue(preparedPlanning['ok']) &&
          ValueReaders.boolValue(preparedChapter['ok']) &&
          ValueReaders.boolValue(runOnce['ok']) &&
          sectionOk &&
          checkpointReviewOk &&
          writeOk,
      'planning_section_titles': planningSectionTitles,
      'chapter_section_titles': chapterSectionTitles,
      'executed_tool_names': executedToolNames,
      'changed_paths': changedPaths,
      'created_plan_path': ValueReaders.stringValue(created['plan_path']),
      'planning_task': planningTask,
      'chapter_task': chapterTask,
      'prepared_planning_ok': ValueReaders.boolValue(preparedPlanning['ok']),
      'prepared_chapter_ok': ValueReaders.boolValue(preparedChapter['ok']),
      'run_once_ok': ValueReaders.boolValue(runOnce['ok']),
      'section_ok': sectionOk,
      'checkpoint_review_ok': checkpointReviewOk,
      'checkpoint_review_path': checkpointReviewPath,
      'checkpoint_review_markdown_path': checkpointReviewMarkdownPath,
      'write_ok': writeOk,
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_execution_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_execution_probe: PASS'
          : 'seed_autopilot_execution_probe: FAIL',
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
      'value': '黑暗奇幻权谋长篇。主角林夜家族覆灭后，被流放北境矿牢，多年后带着读取誓约裂痕的能力返回帝都复仇翻案。',
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
      'value': '帝国以誓约维持统治，所有高位者受誓约束缚；主角只能看见裂痕，不能直接改写誓约。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '复仇翻案，并夺回北境守护权，重写帝国把誓约当作奴役工具的秩序。',
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
      'value': '允许先生成总纲、分卷结构和前 12 章章纲，但跨卷大转折与最终结局方向需要先回到用户确认。',
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

List<String> _sectionTitles(JsonMap preparedResult) {
  final execution = ValueReaders.mapValue(preparedResult['execution']);
  final contextPack = ValueReaders.mapValue(execution['context_pack']);
  return ValueReaders.objectList(contextPack['sections'])
      .map(
        (section) =>
            ValueReaders.stringValue(ValueReaders.mapValue(section)['title']),
      )
      .toList(growable: false);
}
