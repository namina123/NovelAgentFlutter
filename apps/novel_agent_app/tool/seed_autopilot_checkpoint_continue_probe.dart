import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: 该探针验证 mode 1 的 checkpoint review 不只是能停住，还能通过共享动作继续主链或确认显式检查点。
  final apiConfig = await loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'seed_checkpoint_continue_probe',
    title: 'Seed Checkpoint Continue Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'Long task checkpoint continue probe',
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
    'novel_agent_seed_checkpoint_continue_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '模式一检查点继续探针',
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
      'outline/总纲.md',
      '# 总纲\n\n第一卷：主角归京翻案，誓约裂痕逐渐显露。\n',
    );
    await bundle.projectWorkspacePort.writeTextFile(
      project.rootPath,
      'chapter_outlines/章节任务清单.md',
      '# 章节任务清单\n\n第01章：归来者抵达帝都外围，发现旧案线索。\n',
    );
    await taskRepository.saveTask(project, const <String, Object?>{
      'id': 'task_001',
      'title': '样章：第01章',
      'task_type': 'chapter',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusQueued,
      'chapter': '第01章',
      'goal': '按已确认规格、总纲和章纲生成本章正式正文。',
      'brief': '样章测试',
      'depends_on': <Object?>[],
      'source_paths': <Object?>[
        'specs/project_spec.md',
        'outline/总纲.md',
        'chapter_outlines/章节任务清单.md',
        'tracking/modes/seed_autopilot_novel/guidance.md',
        'styles/seed_autopilot_style.md',
      ],
      'output_paths': <Object?>['drafts/第01章_seed_to_full.md'],
      'metadata': <String, Object?>{
        'plan_id': 'plan_test',
        'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'sort_order': 1,
        'stage': 'sample',
        'generated_by': 'LongTaskPlanner',
        'persistent_context_paths': <Object?>[
          'tracking/modes/seed_autopilot_novel/guidance.md',
          'styles/seed_autopilot_style.md',
        ],
      },
      'tool_hint': '先读取长期约束。',
      'created_at': '2026-05-25T00:00:00Z',
      'updated_at': '2026-05-25T00:00:00Z',
      'history': <Object?>[
        <String, Object?>{
          'status': TaskRuntimeConstants.statusQueued,
          'note': 'created',
          'created_at': '2026-05-25T00:00:00Z',
        },
      ],
      'relative_path': 'tasks/task_001.json',
    });

    final runOnce = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      const <String, Object?>{'id': 'task_001'},
    );
    final checkpointReviewPath = ValueReaders.stringValue(
      ValueReaders.mapValue(runOnce['checkpoint_review'])['relative_path'],
    );
    final checkpointReview = await taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    await taskRepository.saveRecord(
      project,
      checkpointReviewPath,
      <String, Object?>{
        ...checkpointReview,
        'severity': 'low',
        'severity_label': '低风险',
        'severity_reasons': <Object?>['探针覆盖继续主链动作。'],
      },
    );
    final chapterPackage = await workflowRuntimeService
        .buildCheckpointReviewActionPackage(project, checkpointReviewPath);
    final continueResult = await workflowRuntimeService
        .applyCheckpointReviewAction(
          project,
          checkpointReviewPath,
          'continue_long_task',
        );
    final continuedTask = await taskRepository.loadTask(
      project,
      const <String, Object?>{'id': 'task_001'},
    );

    await taskRepository.saveTask(project, const <String, Object?>{
      'id': 'checkpoint_001',
      'title': '检查点：第一卷样章确认',
      'task_type': 'checkpoint',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusWaitingUser,
      'chapter': '第01章',
      'goal': '确认样章阶段当前可继续主链。',
      'brief': '显式检查点',
      'depends_on': <Object?>['task_001'],
      'source_paths': <Object?>[
        'tracking/modes/seed_autopilot_novel/guidance.md',
        'drafts/第01章_seed_to_full.md',
      ],
      'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
      'metadata': <String, Object?>{
        'plan_id': 'plan_test',
        'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'sort_order': 2,
        'stage': 'checkpoint',
        'manual_checkpoint': true,
      },
      'relative_path': 'tasks/checkpoint_001.json',
    });
    const explicitCheckpointReviewPath =
        'tracking/checkpoint_reviews/checkpoint_001.json';
    await taskRepository.saveRecord(
      project,
      explicitCheckpointReviewPath,
      const <String, Object?>{
        'id': 'checkpoint_review_explicit_001',
        'task': <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点：第一卷样章确认',
          'task_type': 'checkpoint',
          'relative_path': 'tasks/checkpoint_001.json',
        },
        'task_type': 'checkpoint',
        'stage': 'checkpoint',
        'result_ok': true,
        'severity': 'low',
        'severity_label': '低风险',
        'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
        'confirmation_focus': <Object?>['确认当前检查点可以继续。'],
        'drift_watch_items': <Object?>[],
        'persistent_context_paths': <Object?>[
          'tracking/modes/seed_autopilot_novel/guidance.md',
        ],
      },
    );
    final checkpointPackage = await workflowRuntimeService
        .buildCheckpointReviewActionPackage(
          project,
          explicitCheckpointReviewPath,
        );
    final confirmResult = await workflowRuntimeService
        .applyCheckpointReviewAction(
          project,
          explicitCheckpointReviewPath,
          'confirm_checkpoint_continue',
        );
    final confirmedTask = await taskRepository.loadTask(
      project,
      const <String, Object?>{'id': 'checkpoint_001'},
    );

    report.addAll(<String, Object?>{
      'ok':
          ValueReaders.boolValue(runOnce['ok']) &&
          ValueReaders.mapList(chapterPackage['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) == 'continue_long_task' &&
                ValueReaders.boolValue(item['enabled']),
          ) &&
          ValueReaders.boolValue(continueResult['ok']) &&
          ValueReaders.stringValue(continuedTask['status']) ==
              TaskRuntimeConstants.statusSucceeded &&
          ValueReaders.mapList(checkpointPackage['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'confirm_checkpoint_continue' &&
                ValueReaders.boolValue(item['enabled']),
          ) &&
          ValueReaders.boolValue(confirmResult['ok']) &&
          ValueReaders.stringValue(confirmedTask['status']) ==
              TaskRuntimeConstants.statusSucceeded,
      'chapter_checkpoint_review_path': checkpointReviewPath,
      'chapter_action_summary': ValueReaders.stringValue(
        chapterPackage['action_summary'],
      ),
      'chapter_recommended_action_id': ValueReaders.stringValue(
        chapterPackage['recommended_action_id'],
      ),
      'continued_task_status': ValueReaders.stringValue(
        continuedTask['status'],
      ),
      'confirmed_checkpoint_status': ValueReaders.stringValue(
        confirmedTask['status'],
      ),
      'explicit_checkpoint_review_path': explicitCheckpointReviewPath,
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}seed_autopilot_checkpoint_continue_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'seed_autopilot_checkpoint_continue_probe: PASS'
          : 'seed_autopilot_checkpoint_continue_probe: FAIL',
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
