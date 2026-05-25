import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/bootstrap/cli_bootstrap.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 该探针验证 CLI 是否能消费新的 checkpoint / revision 共享动作合同，并应用其中的真实动作。
  final apiConfig = await _loadProbeApiConfig();
  final provider = ProviderEndpointSettings(
    id: 'cli_resolution_probe',
    title: 'CLI Resolution Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: apiConfig.modelId,
    description: 'CLI resolution probe',
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
  final bootstrap = CliBootstrap();
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_cli_resolution_probe_',
  );
  final report = <String, Object?>{};
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'CLI收口动作探针',
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
    await taskRepository.saveTask(project, <String, Object?>{
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
      'relative_path': 'tasks/task_001.json',
    });

    final runChapter = await _runWithRetry<JsonMap>(() {
      return workflowRuntimeService.runWorkflowTaskOnce(
        project,
        settings,
        const <String, Object?>{'id': 'task_001'},
      );
    });
    final checkpointReviewPath = ValueReaders.stringValue(
      ValueReaders.mapValue(runChapter['checkpoint_review'])['relative_path'],
    );
    final checkpointActionsExit = await bootstrap.run(<String>[
      'workflow',
      'checkpoint-actions',
      '--review',
      checkpointReviewPath,
      '--project',
      project.rootPath,
    ]);
    final applyCheckpointExit = await bootstrap.run(<String>[
      'workflow',
      'apply-checkpoint-action',
      '--review',
      checkpointReviewPath,
      '--command',
      'create_followup_review_tasks',
      '--project',
      project.rootPath,
    ]);

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
    }
  ],
  "suggestions": [
    "修复后重新做一轮连续性检查，确认章节设定一致。"
  ]
}
''',
    );
    await taskRepository.saveTask(project, <String, Object?>{
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
        'checkpoint_review_path': checkpointReviewPath,
        'checkpoint_review_id': 'checkpoint_source',
      },
      'relative_path': 'tasks/review_task_ch01.json',
    });
    final createdRepair = await workflowRuntimeService
        .createWorkflowReviewRepairTask(project, const <String, Object?>{
          'id': 'review_task_ch01',
        });
    final revisionTaskPath = ValueReaders.stringValue(
      ValueReaders.mapValue(createdRepair['task'])['relative_path'],
    );
    await _runWithRetry<JsonMap>(() {
      return workflowRuntimeService.runWorkflowTaskOnce(
        project,
        settings,
        <String, Object?>{'relative_path': revisionTaskPath},
      );
    });
    await _runWithRetry<JsonMap>(() {
      return workflowRuntimeService.runWorkflowTaskPostprocessOnce(
        project,
        settings,
        <String, Object?>{'relative_path': revisionTaskPath},
      );
    });
    final revisionResolutionExit = await bootstrap.run(<String>[
      'workflow',
      'revision-resolution',
      '--task',
      revisionTaskPath,
      '--project',
      project.rootPath,
    ]);
    final applyRevisionResolutionExit = await bootstrap.run(<String>[
      'workflow',
      'apply-revision-resolution',
      '--task',
      revisionTaskPath,
      '--command',
      'create_followup_review_tasks',
      '--project',
      project.rootPath,
    ]);

    final tasks = await taskRepository.listTasks(project);
    final reviewTaskCount = tasks.where((task) {
      return ValueReaders.stringValue(task['task_type']) == 'review';
    }).length;
    report.addAll(<String, Object?>{
      'ok':
          checkpointActionsExit == 0 &&
          applyCheckpointExit == 0 &&
          revisionResolutionExit == 0 &&
          applyRevisionResolutionExit == 0 &&
          reviewTaskCount >= 2,
      'checkpoint_review_path': checkpointReviewPath,
      'revision_task_path': revisionTaskPath,
      'checkpoint_actions_exit': checkpointActionsExit,
      'apply_checkpoint_exit': applyCheckpointExit,
      'revision_resolution_exit': revisionResolutionExit,
      'apply_revision_resolution_exit': applyRevisionResolutionExit,
      'review_task_count': reviewTaskCount,
    });
  } finally {
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}workflow_resolution_cli_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(
      ValueReaders.boolValue(report['ok'])
          ? 'workflow_resolution_cli_probe: PASS'
          : 'workflow_resolution_cli_probe: FAIL',
    );
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

Future<_ProbeApiConfig> _loadProbeApiConfig() async {
  final file = File(
    '${Directory.current.parent.parent.path}${Platform.pathSeparator}test_api.txt',
  );
  final lines = await file.readAsLines();
  final cleanLines = lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (cleanLines.length < 3) {
    throw StateError('test_api.txt 至少需要 baseUrl、apiKey、modelId 三行。');
  }
  return _ProbeApiConfig(
    baseUrl: cleanLines[0],
    apiKey: cleanLines[1],
    modelId: cleanLines[2],
  );
}

Future<T> _runWithRetry<T>(
  Future<T> Function() action, {
  int attempts = 2,
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;
  for (var index = 0; index < attempts; index += 1) {
    try {
      return await action();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (!_isRetryableTransportError(error) || index + 1 >= attempts) {
        break;
      }
    }
  }
  throw lastError ?? lastStackTrace ?? StateError('unknown probe error');
}

bool _isRetryableTransportError(Object error) {
  if (error is HttpException || error is SocketException) {
    return true;
  }
  final message = '$error'.toLowerCase();
  return message.contains('connection closed') ||
      message.contains('connection terminated') ||
      message.contains('connection reset');
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
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '高压权谋、连续逆转与长期压迫中的向上反击。',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '誓约体系无法被真正伪造，只能伪造外观或利用裂痕。',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '林夜要推翻冤案并夺回对北境命运的发言权。',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '干净利落，偏商业长篇，尽量减少说明腔。',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许补规划与修订，但重大方向仍需回到用户确认。',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以开始生成可恢复长任务链。',
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

class _ProbeApiConfig {
  const _ProbeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  final String baseUrl;
  final String apiKey;
  final String modelId;
}
