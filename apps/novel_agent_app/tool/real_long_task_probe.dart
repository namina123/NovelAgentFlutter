import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 该探针用 temp/novel_agent_settings.json 的自定义提供商真实跑一段 mode 1 长任务主链，重点核对样章门槛、正文落盘、角色状态与技能调用。
  final repoRoot = _resolveRepoRoot();
  final settingsFile = File(
    '$repoRoot${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
  );
  if (!await settingsFile.exists()) {
    stderr.writeln('缺少 temp/novel_agent_settings.json');
    exitCode = 2;
    return;
  }
  final provider = await _loadProvider(settingsFile);
  final settings = AppSettings(
    defaultProviderId: provider.id,
    defaultAgentId: 'default_generalist',
    defaultModelId: provider.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[provider],
    networkSettings: const <String, Object?>{'proxy_mode': 'system'},
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': provider.id,
        'model_id': provider.modelId,
        'stream_mode': 'stream',
        'api_mode': 'chat',
      },
    },
  );

  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
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
  final buildPlanInputUseCase = BuildModeGuidancePlanInputUseCase(
    statePort: modeRepository,
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
    'novel_agent_real_long_task_probe_',
  );
  final report = <String, Object?>{
    'provider_id': provider.id,
    'model_id': provider.modelId,
    'started_at': DateTime.now().toIso8601String(),
  };
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: '真实长任务探针',
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
    final created = await workflowRuntimeService.createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: <String, Object?>{
        ...planInput.options,
        'chapter_count': 3,
        'checkpoint_interval': 2,
        'enable_chapter_word_constraints': true,
        'chapter_word_target': 1800,
        'chapter_word_min': 1400,
        'chapter_word_max': 2200,
        'sample_chapter_word_target': 1400,
        'sample_chapter_word_min': 1000,
        'sample_chapter_word_max': 1800,
      },
    );
    final tasksAfterCreate = await workflowRuntimeService.listWorkflowTasks(
      project,
    );
    report['created_plan_path'] = ValueReaders.stringValue(
      created['plan_path'],
    );
    report['created_task_count'] = tasksAfterCreate.length;
    report['created_task_output_paths'] = tasksAfterCreate
        .map(
          (task) => <String, Object?>{
            'id': ValueReaders.stringValue(task['id']),
            'task_type': ValueReaders.stringValue(task['task_type']),
            'stage': ValueReaders.stringValue(
              ValueReaders.mapValue(task['metadata'])['stage'],
            ),
            'output_paths': ValueReaders.stringList(task['output_paths']),
          },
        )
        .toList(growable: false);

    final planningTask = tasksAfterCreate.firstWhere(
      (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
    );
    final planningResult = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(
          planningTask['relative_path'],
        ),
      },
    );
    final planningTaskAfter = await taskRepository.loadTask(
      project,
      <String, Object?>{'id': ValueReaders.stringValue(planningTask['id'])},
    );
    final planningCheckpointReviewPath = ValueReaders.stringValue(
      ValueReaders.mapValue(
        planningResult['checkpoint_review'],
      )['relative_path'],
    );
    final planningToolSummary = _toolSummary(planningResult);
    await workflowRuntimeService.applyCheckpointReviewAction(
      project,
      planningCheckpointReviewPath,
      'continue_long_task',
    );
    final outlineCheckpoint = await _findTaskByStage(
      workflowRuntimeService,
      project,
      stage: 'checkpoint',
      titleContains: '总纲',
    );
    await taskRepository.transitionTask(
      project,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(
          outlineCheckpoint['relative_path'],
        ),
      },
      TaskRuntimeConstants.statusSucceeded,
      note: '真实探针确认规划检查点通过。',
    );

    final sampleTask = await _findTaskByStage(
      workflowRuntimeService,
      project,
      stage: 'sample',
    );
    final samplePrepared = await workflowRuntimeService
        .prepareWorkflowTaskExecution(
          project,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              sampleTask['relative_path'],
            ),
          },
          modelProfile: <String, Object?>{
            'id': provider.id,
            'base_url': provider.baseUrl,
            'model_id': provider.modelId,
          },
        );
    final sampleResult = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(sampleTask['relative_path']),
      },
    );
    final sampleTaskAfter = await taskRepository.loadTask(
      project,
      <String, Object?>{'id': ValueReaders.stringValue(sampleTask['id'])},
    );
    final sampleCheckpointReviewPath = ValueReaders.stringValue(
      ValueReaders.mapValue(sampleResult['checkpoint_review'])['relative_path'],
    );
    final samplePostprocess = await workflowRuntimeService
        .runWorkflowTaskPostprocessOnce(project, settings, <String, Object?>{
          'relative_path': ValueReaders.stringValue(
            sampleTask['relative_path'],
          ),
        });
    await workflowRuntimeService.applyCheckpointReviewAction(
      project,
      sampleCheckpointReviewPath,
      'continue_long_task',
    );
    final sampleCheckpoint = await _findTaskByStage(
      workflowRuntimeService,
      project,
      stage: 'checkpoint',
      titleContains: '样章',
    );
    await taskRepository.transitionTask(
      project,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(
          sampleCheckpoint['relative_path'],
        ),
      },
      TaskRuntimeConstants.statusSucceeded,
      note: '真实探针确认样章检查点通过。',
    );

    final chapterTwoTask = await _findTask(
      workflowRuntimeService,
      project,
      (task) =>
          ValueReaders.stringValue(task['task_type']) == 'chapter' &&
          ValueReaders.stringValue(
                ValueReaders.mapValue(task['metadata'])['stage'],
              ) ==
              'draft' &&
          ValueReaders.stringValue(task['chapter']) == '第02章',
    );
    final chapterTwoResult = await workflowRuntimeService.runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(
          chapterTwoTask['relative_path'],
        ),
      },
    );
    final chapterTwoTaskAfter = await taskRepository.loadTask(
      project,
      <String, Object?>{'id': ValueReaders.stringValue(chapterTwoTask['id'])},
    );
    final chapterTwoPostprocess = await workflowRuntimeService
        .runWorkflowTaskPostprocessOnce(project, settings, <String, Object?>{
          'relative_path': ValueReaders.stringValue(
            chapterTwoTask['relative_path'],
          ),
        });

    final samplePrompt = ValueReaders.stringValue(
      ValueReaders.mapValue(
        samplePrepared['execution'],
      )['prompt_preview_markdown'],
    );
    final projectFiles = await bundle.projectWorkspacePort.listEntries(
      project.rootPath,
    );
    report.addAll(<String, Object?>{
      'ok': true,
      'project_root': project.rootPath,
      'planning': <String, Object?>{
        'ok': ValueReaders.boolValue(planningResult['ok']),
        'status_after_step': ValueReaders.stringValue(
          planningTaskAfter['status'],
        ),
        'changed_paths': ValueReaders.stringList(
          planningResult['changed_paths'],
        ),
        'tool_summary': planningToolSummary,
        'checkpoint_review_path': planningCheckpointReviewPath,
      },
      'sample': <String, Object?>{
        'ok': ValueReaders.boolValue(sampleResult['ok']),
        'status_after_step': ValueReaders.stringValue(
          sampleTaskAfter['status'],
        ),
        'output_paths': ValueReaders.stringList(sampleResult['output_paths']),
        'tool_summary': _toolSummary(sampleResult),
        'postprocess_output_paths': ValueReaders.stringList(
          samplePostprocess['output_paths'],
        ),
        'postprocess_tools': _resultToolNames(samplePostprocess),
        'checkpoint_review_path': sampleCheckpointReviewPath,
        'prompt_has_word_target': samplePrompt.contains('目标约 1400 字'),
      },
      'chapter_02': <String, Object?>{
        'ok': ValueReaders.boolValue(chapterTwoResult['ok']),
        'status_after_step': ValueReaders.stringValue(
          chapterTwoTaskAfter['status'],
        ),
        'output_paths': ValueReaders.stringList(
          chapterTwoResult['output_paths'],
        ),
        'tool_summary': _toolSummary(chapterTwoResult),
        'postprocess_output_paths': ValueReaders.stringList(
          chapterTwoPostprocess['output_paths'],
        ),
        'postprocess_tools': _resultToolNames(chapterTwoPostprocess),
      },
      'character_state_written': projectFiles.any(
        (entry) => ValueReaders.stringValue(
          entry['relative_path'],
        ).startsWith('characters/'),
      ),
      'chapter_file_written': projectFiles.any(
        (entry) => ValueReaders.stringValue(
          entry['relative_path'],
        ).startsWith('chapters/'),
      ),
      'summary_file_written': projectFiles.any(
        (entry) => ValueReaders.stringValue(
          entry['relative_path'],
        ).startsWith('summaries/'),
      ),
      'all_project_files': projectFiles
          .map((entry) => ValueReaders.stringValue(entry['relative_path']))
          .toList(growable: false),
    });
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_long_task_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

String _resolveRepoRoot() {
  // 中文注释: 真实探针既可能从 apps/novel_agent_app 执行，也可能从仓库根执行，这里统一向上定位仓库根。
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final candidate = File(
      '${current.path}${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
    );
    if (candidate.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

Map<String, Object?> _toolSummary(JsonMap result) {
  // 中文注释: 探针只保留工具摘要与重复读取标记，避免把整份响应体打印得太肥。
  final executedTools = ValueReaders.objectList(
    result['executed_tools'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  final toolNameCounts = <String, int>{};
  final readPathCounts = <String, int>{};
  final skillLoads = <Object?>[];
  for (final tool in executedTools) {
    final name = ValueReaders.stringValue(tool['name']);
    toolNameCounts[name] = (toolNameCounts[name] ?? 0) + 1;
    if (name == 'load_agent_skill') {
      final arguments = ValueReaders.mapValue(tool['arguments']);
      skillLoads.add(<String, Object?>{
        'skill_id': ValueReaders.stringValue(arguments['skill_id']),
        'query': ValueReaders.stringValue(arguments['query']),
      });
    }
    if (name != 'read_project_file') {
      continue;
    }
    final path = ValueReaders.stringValue(
      ValueReaders.mapValue(tool['arguments'])['relative_path'],
    );
    readPathCounts[path] = (readPathCounts[path] ?? 0) + 1;
  }
  return <String, Object?>{
    'tool_name_counts': toolNameCounts,
    'skill_loads': skillLoads,
    'read_path_counts': readPathCounts,
    'read_path_marks': readPathCounts.entries
        .map(
          (entry) => <String, Object?>{
            'path': entry.key,
            'count': entry.value,
            'mark': entry.value > 1 ? 'repeat_read' : 'first_read',
          },
        )
        .toList(growable: false),
  };
}

List<String> _resultToolNames(JsonMap result) {
  final explicit = ValueReaders.stringList(result['tool_names']);
  if (explicit.isNotEmpty) {
    return explicit;
  }
  return ValueReaders.objectList(result['executed_tools'])
      .map(
        (tool) => ValueReaders.stringValue(ValueReaders.mapValue(tool)['name']),
      )
      .toList(growable: false);
}

Future<JsonMap> _findTaskByStage(
  ProjectWorkflowRuntimeService workflowRuntimeService,
  ProjectDescriptor project, {
  required String stage,
  String titleContains = '',
}) {
  return _findTask(
    workflowRuntimeService,
    project,
    (task) =>
        ValueReaders.stringValue(
              ValueReaders.mapValue(task['metadata'])['stage'],
            ) ==
            stage &&
        (titleContains.trim().isEmpty ||
            ValueReaders.stringValue(task['title']).contains(titleContains)),
  );
}

Future<JsonMap> _findTask(
  ProjectWorkflowRuntimeService workflowRuntimeService,
  ProjectDescriptor project,
  bool Function(JsonMap task) predicate,
) async {
  final tasks = await workflowRuntimeService.listWorkflowTasks(project);
  for (final task in tasks) {
    if (predicate(task)) {
      return task;
    }
  }
  throw StateError('未找到符合条件的任务。');
}

Future<ProviderEndpointSettings> _loadProvider(File settingsFile) async {
  // 中文注释: 这里直接读取 temp 设置中的默认 provider，避免把用户主配置和临时探针配置混在一起。
  final root = ValueReaders.mapValue(
    jsonDecode(await settingsFile.readAsString()),
  );
  final rawProviders = ValueReaders.objectList(
    root['providers'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  if (rawProviders.isEmpty) {
    throw StateError('temp/novel_agent_settings.json 缺少 providers。');
  }
  final selected = rawProviders.firstWhere(
    (provider) => ValueReaders.boolValue(provider['is_default']),
    orElse: () => rawProviders.first,
  );
  return ProviderEndpointSettings(
    id: ValueReaders.stringValue(selected['id'], 'local-openai'),
    title: ValueReaders.stringValue(selected['title'], '本地 OpenAI Compatible'),
    protocol: ValueReaders.stringValue(
      selected['protocol'],
      'openai_compatible',
    ),
    baseUrl: ValueReaders.stringValue(selected['base_url']),
    apiKey: ValueReaders.stringValue(selected['api_key']),
    modelId: ValueReaders.stringValue(
      selected['model_id'],
      'deepseek-v4-flash',
    ),
    description: ValueReaders.stringValue(selected['description']),
    isDefault: true,
  );
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
      'value': '都市异闻悬疑长篇。女主沈临川是电台夜班主播，能在午夜热线里听见现实裂缝后的第二层声音。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '都市压迫感、悬疑递进与情绪钩子稳定推进。',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '所有异常都必须通过“电波残响”被感知，角色不能无代价全知。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '沈临川要查清姐姐失踪真相，并确认午夜热线里的声音到底来自谁。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '中文商业小说风格，克制、利落、少分析腔，重现场压力。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '先总纲后样章，再连续推进；关键转折与跨卷变化需要人工确认。',
      'label': '托管边界',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以启动长任务。',
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
