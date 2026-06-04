import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tool/probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证 mode 1 的返工链在 revision 后处理后，能真实生成收口动作并继续物化后续审稿任务。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_revision_resolution_probe',
    title: 'Seed Revision Resolution Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task revision resolution probe',
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
  final modeRepository = ProjectModeGuidanceRepository(
    workspacePort: bundle.projectWorkspacePort,
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
    'novel_agent_seed_revision_resolution_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '模式一修订收口探针',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await _seedReadyState(
      repository: modeRepository,
      transitionService: ModeGuidanceTransitionService(),
      project: project,
    );
    await bundle.projectWorkspacePort.writeTextFile(
      project.rootPath,
      'chapters/ch01.md',
      '''
# 第01章 归来者

林夜被流放时只有十四岁，如今众人却说他刚满二十。
同一章后文又写他已经二十四岁，并且在帝都黑市潜伏了整整三年。
誓约体系前文说无法伪造，后文却让一个小吏随手仿造帝国誓书。
''',
    );
    await bundle.projectWorkspacePort.writeTextFile(
      project.rootPath,
      'reviews/continuity/ch01.md',
      '''
# 连续性检查：第01章

- 范围：chapters/ch01.md
- 关联文件：chapters/ch01.md

## 主要问题

- 年龄前后矛盾：开头写二十岁，后文写二十四岁。
- 经历时间矛盾：写成“从未离开北境”却又说在帝都黑市潜伏三年。
- 世界规则矛盾：前文说誓约无法伪造，后文却说小吏可随手仿造。
''',
    );
    await bundle.projectWorkspacePort.writeTextFile(
      project.rootPath,
      'reviews/continuity/ch01.json',
      '''
{
  "id": "review_ch01",
  "title": "连续性检查：第01章",
  "review_type": "continuity",
  "scope": "chapters/ch01.md",
  "summary": "第01章存在年龄、经历时间与誓约规则三处连续性矛盾。",
  "source_paths": ["chapters/ch01.md"],
  "issues": [
    {
      "title": "年龄前后矛盾",
      "suggestion": "统一为一个年龄，并与流放时长匹配。",
      "source_path": "chapters/ch01.md"
    },
    {
      "title": "经历时间矛盾",
      "suggestion": "删除帝都黑市潜伏三年的说法，或改成通过他人口述获知帝都情况。",
      "source_path": "chapters/ch01.md"
    },
    {
      "title": "誓约规则矛盾",
      "suggestion": "改成小吏只能伪造外观，无法伪造真正生效的誓约。",
      "source_path": "chapters/ch01.md"
    }
  ],
  "suggestions": [
    "修复后重新做一轮连续性检查，确认章节设定一致。"
  ]
}
''',
    );
    await taskRepository.saveTask(project, const <String, Object?>{
      'id': 'review_task_ch01',
      'title': '连续性检查：第01章',
      'task_type': 'review',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': 'waiting_user',
      'source_paths': <Object?>[
        'chapters/ch01.md',
        'tracking/modes/seed_autopilot_novel/guidance.md',
      ],
      'output_paths': <Object?>[
        'reviews/continuity/ch01.md',
        'reviews/continuity/ch01.json',
      ],
      'metadata': <String, Object?>{
        'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'persistent_context_paths': <Object?>[
          'tracking/modes/seed_autopilot_novel/guidance.md',
        ],
        'review_report_path': 'reviews/continuity/ch01.md',
        'checkpoint_review_path': 'tracking/checkpoint_reviews/source.json',
        'checkpoint_review_id': 'checkpoint_source',
      },
      'relative_path': 'tasks/review_task_ch01.json',
    });
    await taskRepository.saveRecord(
      project,
      'tracking/checkpoint_reviews/source.json',
      const <String, Object?>{
        'id': 'checkpoint_source',
        'task_type': 'chapter',
        'stage': 'sample',
        'output_paths': <Object?>['chapters/ch01.md'],
        'drift_watch_items': <Object?>['确认世界规则与样章文风不继续漂移。'],
      },
    );
    final createdRepair = await workflowRuntimeService
        .createWorkflowReviewRepairTask(project, const <String, Object?>{
          'id': 'review_task_ch01',
        });
    final revisionTask = ValueReaders.mapValue(createdRepair['task']);
    final revisionSelector = <String, Object?>{
      'relative_path': ValueReaders.stringValue(revisionTask['relative_path']),
    };
    final runRevision = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      revisionSelector,
    );
    final postprocess = await workflowRuntimeService
        .runWorkflowTaskPostprocessOnce(project, settings, revisionSelector);
    final resolution = await workflowRuntimeService.buildRevisionResolution(
      project,
      revisionSelector,
    );
    final followup = await workflowRuntimeService.applyRevisionResolutionAction(
      project,
      revisionSelector,
      'create_followup_review_tasks',
    );
    final reloadedTask = await taskRepository.loadTask(
      project,
      revisionSelector,
    );
    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(createdRepair['ok']) &&
          ValueReaders.boolValue(runRevision['ok']) &&
          ValueReaders.boolValue(postprocess['ok']) &&
          ValueReaders.boolValue(resolution['ok']) &&
          ValueReaders.boolValue(followup['ok']) &&
          ValueReaders.mapList(followup['tasks']).isNotEmpty &&
          ValueReaders.mapList(resolution['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) == 'return_to_checkpoint',
          ) &&
          ValueReaders.stringValue(
            resolution['checkpoint_review_path'],
          ).startsWith('tracking/checkpoint_reviews/') &&
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              reloadedTask['metadata'],
            )['origin_checkpoint_review_path'],
          ).startsWith('tracking/checkpoint_reviews/'),
      'revision_task_path': ValueReaders.stringValue(
        revisionTask['relative_path'],
      ),
      'resolution_stage': ValueReaders.stringValue(resolution['stage']),
      'resolution_action_summary': ValueReaders.stringValue(
        resolution['action_summary'],
      ),
      'resolution_checkpoint_review_path': ValueReaders.stringValue(
        resolution['checkpoint_review_path'],
      ),
      'followup_task_count': ValueReaders.mapList(followup['tasks']).length,
      'followup_changed_paths': ValueReaders.stringList(
        followup['changed_paths'],
      ),
      'origin_checkpoint_review_path': ValueReaders.stringValue(
        ValueReaders.mapValue(
          reloadedTask['metadata'],
        )['origin_checkpoint_review_path'],
      ),
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_revision_resolution_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_revision_resolution_probe: PASS'
          : 'seed_autopilot_revision_resolution_probe: FAIL',
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
      'value': '黑暗奇幻权谋长篇。主角林夜在誓约帝国中翻案复仇。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '高压权谋、连续逆转与长期压迫中的向上反击。',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '誓约体系无法被真正伪造，只能伪造外观或利用裂痕。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '林夜要推翻冤案并夺回对北境命运的发言权。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '干净利落，偏商业长篇，尽量减少说明腔。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许补规划与修订，但重大方向仍需回到用户确认。',
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
