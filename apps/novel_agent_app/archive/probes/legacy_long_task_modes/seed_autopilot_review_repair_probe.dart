import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tool/probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针专注验证“review task -> review report -> repair task”共享返工链，避免把前置 checkpoint 波动混进同一条验证。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_review_repair_probe',
    title: 'Seed Review Repair Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task review repair probe',
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
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final reviewReportService = ProjectReviewReportService(
    workspacePort: bundle.projectWorkspacePort,
    taskRepository: taskRepository,
  );
  final workflowRuntimeService = ProjectWorkflowRuntimeService(
    taskRepository: taskRepository,
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
    'novel_agent_seed_review_repair_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '审稿返工探针',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await bundle.projectWorkspacePort.writeTextFile(
      project.rootPath,
      'chapters/ch01.md',
      '''
# 第01章 归来者

林夜在北境矿牢里度过了八年。他记得自己十四岁被流放，如今却被旁人称作二十岁。
他从未离开北境，却在同一段回忆里提到自己曾在帝都地下黑市躲藏三年。
誓约体系要求所有高位者以鲜血立誓，文本前段说誓约无法伪造，后段又写一名小吏可以随手仿造帝国誓书。
''',
    );
    final reviewTaskCreated = await reviewReportService
        .createReviewTask(project, const <String, Object?>{
          'source_path': 'chapters/ch01.md',
          'review_type': 'continuity',
          'title': '连续性检查：第01章归来者',
        });
    final reviewTask = ValueReaders.mapValue(reviewTaskCreated['task']);
    final reviewSelector = <String, Object?>{
      'relative_path': ValueReaders.stringValue(reviewTask['relative_path']),
    };
    final reviewRun = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      reviewSelector,
    );
    final repairTaskResult = await workflowRuntimeService
        .createWorkflowReviewRepairTask(project, reviewSelector);
    final repairTask = ValueReaders.mapValue(repairTaskResult['task']);
    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(reviewTaskCreated['ok']) &&
          ValueReaders.boolValue(reviewRun['ok']) &&
          ValueReaders.boolValue(repairTaskResult['ok']) &&
          ValueReaders.stringValue(repairTask['task_type']) == 'revision',
      'review_task_path': ValueReaders.stringValue(reviewTask['relative_path']),
      'repair_task_path': ValueReaders.stringValue(repairTask['relative_path']),
      'repair_review_report_path': ValueReaders.stringValue(
        ValueReaders.mapValue(repairTask['metadata'])['review_report_path'],
      ),
      'review_run_changed_paths': ValueReaders.stringList(
        reviewRun['changed_paths'],
      ),
      'repair_result': repairTaskResult,
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_review_repair_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_review_repair_probe: PASS'
          : 'seed_autopilot_review_repair_probe: FAIL',
    );
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

