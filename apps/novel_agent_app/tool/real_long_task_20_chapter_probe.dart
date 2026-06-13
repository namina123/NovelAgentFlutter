import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main(List<String> arguments) async {
  // 中文注释: 这支探针专门从“创建长篇项目”开始，真实压一轮可配置章数的 mode 1 长任务链，用于排查检查点、后处理和持续推进是否会中途卡死。
  await ensureLocalRealProbeOptIn(probeName: 'real_long_task_20_chapter_probe');
  final repoRoot = resolveLocalProbeRepoRoot();
  final targetChapterCount = _chapterCountFromArgs(arguments);
  final checkpointInterval = _checkpointIntervalForChapterCount(
    targetChapterCount,
  );
  final provider = await _loadProvider(repoRoot);
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
  final runId = DateTime.now().toIso8601String().replaceAll(':', '-');
  final runArtifactDir = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_long_task_chapter_probe_runs${Platform.pathSeparator}${runId}_chapters_$targetChapterCount',
  );
  await runArtifactDir.create(recursive: true);
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

  final workspaceRoot = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_long_task_20_probe_workspace${Platform.pathSeparator}$runId',
  );
  await workspaceRoot.create(recursive: true);

  final report = <String, Object?>{
    'provider_id': provider.id,
    'model_id': provider.modelId,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace_root': workspaceRoot.path,
    'run_artifact_dir': runArtifactDir.path,
    'requested_chapter_count': targetChapterCount,
    'checkpoint_interval': checkpointInterval,
  };

  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: workspaceRoot.path,
      title: '$targetChapterCount章真实长任务探针',
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
        'chapter_count': targetChapterCount,
        'checkpoint_interval': checkpointInterval,
        'enable_chapter_word_constraints': true,
        'chapter_word_target': 2200,
        'chapter_word_min': 1600,
        'chapter_word_max': 2800,
        'sample_chapter_word_target': 1600,
        'sample_chapter_word_min': 1200,
        'sample_chapter_word_max': 2200,
      },
    );

    final stepLogs = <Object?>[];
    var completedChapterCount = 0;
    var postprocessCount = 0;
    var safetyCounter = 0;
    await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
      'project_root': project.rootPath,
      'phase': 'workflow_created',
      'chapter_file_count': completedChapterCount,
      'postprocess_count': postprocessCount,
      'safety_counter': safetyCounter,
      'last_step': const <String, Object?>{},
    });
    while (completedChapterCount < targetChapterCount && safetyCounter < 400) {
      safetyCounter += 1;
      final postprocessTask = await workflowRuntimeService
          .nextWorkflowPostprocessTask(project);
      if (postprocessTask.isNotEmpty) {
        final relativePath = ValueReaders.stringValue(
          postprocessTask['relative_path'],
        );
        final result = await workflowRuntimeService
            .runWorkflowTaskPostprocessOnce(
              project,
              settings,
              <String, Object?>{'relative_path': relativePath},
            );
        postprocessCount += 1;
        stepLogs.add(<String, Object?>{
          'kind': 'postprocess',
          'task_path': relativePath,
          'ok': ValueReaders.boolValue(result['ok']),
          'output_paths': ValueReaders.stringList(result['output_paths']),
          'tool_names': _resultToolNames(result),
        });
        final postprocessCheckpointReviewPath = ValueReaders.stringValue(
          ValueReaders.mapValue(result['checkpoint_review'])['relative_path'],
        );
        if (postprocessCheckpointReviewPath.trim().isNotEmpty) {
          await _applyContinuableCheckpointAction(
            workflowRuntimeService,
            project,
            postprocessCheckpointReviewPath,
          );
        }
        await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
          'project_root': project.rootPath,
          'phase': 'postprocess',
          'chapter_file_count': completedChapterCount,
          'postprocess_count': postprocessCount,
          'safety_counter': safetyCounter,
          'last_step': stepLogs.isEmpty
              ? const <String, Object?>{}
              : ValueReaders.mapValue(stepLogs.last),
        });
        continue;
      }

      final nextTask = await workflowRuntimeService.nextWorkflowTask(project);
      if (nextTask.isEmpty) {
        final resolved = await _resolveManualBlocker(
          workflowRuntimeService: workflowRuntimeService,
          taskRepository: taskRepository,
          project: project,
        );
        if (resolved) {
          stepLogs.add(const <String, Object?>{'kind': 'manual_resolution'});
          continue;
        }
        break;
      }

      final taskType = ValueReaders.stringValue(nextTask['task_type']);
      final taskPath = ValueReaders.stringValue(nextTask['relative_path']);
      if (taskType == 'checkpoint') {
        final transitioned = await taskRepository.transitionTask(
          project,
          <String, Object?>{'relative_path': taskPath},
          TaskRuntimeConstants.statusSucceeded,
          note: '探针自动确认检查点通过。',
        );
        stepLogs.add(<String, Object?>{
          'kind': 'checkpoint_confirm',
          'task_path': taskPath,
          'ok': ValueReaders.boolValue(transitioned['ok']),
        });
        await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
          'project_root': project.rootPath,
          'phase': 'checkpoint_confirm',
          'chapter_file_count': completedChapterCount,
          'postprocess_count': postprocessCount,
          'safety_counter': safetyCounter,
          'last_step': ValueReaders.mapValue(stepLogs.last),
        });
        continue;
      }

      final result = await workflowRuntimeService.runWorkflowTaskOnce(
        project,
        settings,
        <String, Object?>{'relative_path': taskPath},
      );
      final checkpointReviewPath = ValueReaders.stringValue(
        ValueReaders.mapValue(result['checkpoint_review'])['relative_path'],
      );
      if (checkpointReviewPath.trim().isNotEmpty) {
        await _applyContinuableCheckpointAction(
          workflowRuntimeService,
          project,
          checkpointReviewPath,
        );
      }
      final outputPaths = ValueReaders.stringList(result['output_paths']);
      stepLogs.add(<String, Object?>{
        'kind': 'task',
        'task_type': taskType,
        'task_path': taskPath,
        'ok': ValueReaders.boolValue(result['ok']),
        'output_paths': outputPaths,
        'checkpoint_review_path': checkpointReviewPath,
        'tool_summary': _toolSummary(result),
      });

      if (taskType == 'chapter' &&
          ValueReaders.stringValue(nextTask['chapter']).trim().isNotEmpty) {
        completedChapterCount = await _countChapterFiles(bundle, project);
      }
      await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
        'project_root': project.rootPath,
        'phase': 'task',
        'chapter_file_count': completedChapterCount,
        'postprocess_count': postprocessCount,
        'safety_counter': safetyCounter,
        'last_step': stepLogs.isEmpty
            ? const <String, Object?>{}
            : ValueReaders.mapValue(stepLogs.last),
      });
    }

    completedChapterCount = await _countChapterFiles(bundle, project);
    final tasks = await workflowRuntimeService.listWorkflowTasks(project);
    final projectFiles = await bundle.projectWorkspacePort.listEntries(
      project.rootPath,
    );
    final checkpointConfirmCount = stepLogs
        .where(
          (step) =>
              ValueReaders.stringValue(ValueReaders.mapValue(step)['kind']) ==
              'checkpoint_confirm',
        )
        .length;
    final manualResolutionCount = stepLogs
        .where(
          (step) =>
              ValueReaders.stringValue(ValueReaders.mapValue(step)['kind']) ==
              'manual_resolution',
        )
        .length;
    report.addAll(<String, Object?>{
      'ok': completedChapterCount >= targetChapterCount,
      'report_category': completedChapterCount >= targetChapterCount
          ? ProbeReportCategories.success
          : ProbeReportCategories.contentQualityFailure,
      'project_root': project.rootPath,
      'created_plan_path': ValueReaders.stringValue(created['plan_path']),
      'chapter_file_count': completedChapterCount,
      'postprocess_count': postprocessCount,
      'checkpoint_confirm_count': checkpointConfirmCount,
      'manual_resolution_count': manualResolutionCount,
      'safety_counter': safetyCounter,
      'task_status_counts': _taskStatusCounts(tasks),
      'chapter_paths': projectFiles
          .map((entry) => ValueReaders.stringValue(entry['relative_path']))
          .where((path) => path.startsWith('chapters/') && path.endsWith('.md'))
          .toList(growable: false),
      'all_project_files': projectFiles
          .map((entry) => ValueReaders.stringValue(entry['relative_path']))
          .toList(growable: false),
      'steps': stepLogs,
    });
    if (completedChapterCount < targetChapterCount) {
      report['error'] =
          '只生成到 $completedChapterCount 章，未达到 $targetChapterCount 章目标。';
    }
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
    report['report_category'] = classifyDraftProbeReportCategory(
      ok: false,
      errorSummary: '$error',
    );
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final runReportFile = File(
      '${runArtifactDir.path}${Platform.pathSeparator}report.json',
    );
    final latestReportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_long_task_20_probe_report.json',
    );
    report['run_report_path'] = runReportFile.path;
    report['latest_report_path'] = latestReportFile.path;
    final reportText = const JsonEncoder.withIndent('  ').convert(report);
    await runReportFile.parent.create(recursive: true);
    await runReportFile.writeAsString(reportText);
    await latestReportFile.parent.create(recursive: true);
    await latestReportFile.writeAsString(reportText);
    stdout.writeln('run_report: ${runReportFile.path}');
    stdout.writeln('report: ${latestReportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

Future<void> _writeProgressSnapshot(
  Directory runArtifactDir,
  String repoRoot,
  Map<String, Object?> snapshot,
) async {
  // 中文注释: 长链探针边跑边写进度，便于中断后直接定位卡在第几步，同时保留本次 run 的独立进度文件。
  final runFile = File(
    '${runArtifactDir.path}${Platform.pathSeparator}progress.json',
  );
  final latestFile = File(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_long_task_20_probe_progress.json',
  );
  final text = const JsonEncoder.withIndent('  ').convert(snapshot);
  await runFile.parent.create(recursive: true);
  await runFile.writeAsString(text);
  await latestFile.parent.create(recursive: true);
  await latestFile.writeAsString(text);
}

int _chapterCountFromArgs(List<String> arguments) {
  for (final argument in arguments) {
    final value = argument.trim();
    if (!value.startsWith('--chapter-count=')) {
      continue;
    }
    final parsed = int.tryParse(value.split('=').last.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 50);
    }
  }
  return 20;
}

int _checkpointIntervalForChapterCount(int chapterCount) {
  if (chapterCount <= 10) {
    return 3;
  }
  if (chapterCount <= 20) {
    return 5;
  }
  return 7;
}

Future<ProviderEndpointSettings> _loadProvider(String repoRoot) async {
  // 中文注释: 真实探针统一读取 local/probe_api.txt 或环境变量指定文件，不再私吃 temp/test_api 配置。
  final config = await loadLocalProbeApiConfig(
    probeName: 'real_long_task_20_chapter_probe',
    allowLegacyTestApi: false,
    allowTempSettingsFallback: false,
    repoRootOverride: repoRoot,
  );
  return ProviderEndpointSettings(
    id: 'real_long_task_20_chapter_probe',
    title: 'Real Long Task 20 Chapter Probe',
    protocol: 'openai_compatible',
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    modelId: config.modelId,
    description: 'Shared local probe configuration for the 20 chapter probe.',
    isDefault: true,
  );
}

Future<bool> _resolveManualBlocker({
  required ProjectWorkflowRuntimeService workflowRuntimeService,
  required ProjectTaskRepository taskRepository,
  required ProjectDescriptor project,
}) async {
  // 中文注释: 阻塞解析只处理“用户确认就能继续”的节点，不擅自篡改返工链或失败任务。
  final tasks = await workflowRuntimeService.listWorkflowTasks(project);
  for (final task in tasks) {
    if (ValueReaders.stringValue(task['status']) !=
        TaskRuntimeConstants.statusWaitingUser) {
      continue;
    }
    final taskType = ValueReaders.stringValue(task['task_type']);
    final taskPath = ValueReaders.stringValue(task['relative_path']);
    if (taskType == 'checkpoint' && taskPath.trim().isNotEmpty) {
      await taskRepository.transitionTask(
        project,
        <String, Object?>{'relative_path': taskPath},
        TaskRuntimeConstants.statusSucceeded,
        note: '探针自动确认检查点通过。',
      );
      return true;
    }
    final checkpointReviewPath = ValueReaders.stringValue(
      task['checkpoint_review_path'],
    ).trim();
    if (checkpointReviewPath.isNotEmpty) {
      return _applyContinuableCheckpointAction(
        workflowRuntimeService,
        project,
        checkpointReviewPath,
      );
    }
  }
  return false;
}

Future<bool> _applyContinuableCheckpointAction(
  ProjectWorkflowRuntimeService workflowRuntimeService,
  ProjectDescriptor project,
  String checkpointReviewPath,
) async {
  // 中文注释: 真实用户确认链优先走共享检查点动作合同，只自动执行“继续/确认”两类无分叉动作。
  final actionPackage = await workflowRuntimeService
      .buildCheckpointReviewActionPackage(project, checkpointReviewPath);
  for (final actionId in const <String>[
    'confirm_checkpoint_continue',
    'continue_long_task',
  ]) {
    for (final action in ValueReaders.mapList(actionPackage['actions'])) {
      if (ValueReaders.stringValue(action['id']) == actionId &&
          ValueReaders.boolValue(action['enabled'])) {
        final result = await workflowRuntimeService.applyCheckpointReviewAction(
          project,
          checkpointReviewPath,
          actionId,
        );
        return ValueReaders.boolValue(result['ok']);
      }
    }
  }
  return false;
}

Future<int> _countChapterFiles(
  AdapterBundle bundle,
  ProjectDescriptor project,
) async {
  final entries = await bundle.projectWorkspacePort.listEntries(
    project.rootPath,
  );
  return entries
      .map((entry) => ValueReaders.stringValue(entry['relative_path']))
      .where((path) => path.startsWith('chapters/') && path.endsWith('.md'))
      .length;
}

Map<String, Object?> _taskStatusCounts(List<JsonMap> tasks) {
  final counts = <String, int>{};
  for (final task in tasks) {
    final status = ValueReaders.stringValue(task['status'], 'unknown');
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

Map<String, Object?> _toolSummary(JsonMap result) {
  // 中文注释: 长链探针只保留工具摘要和重复读取痕迹，避免报告爆炸。
  final executedTools = ValueReaders.objectList(
    result['executed_tools'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  final toolNameCounts = <String, int>{};
  final readPathCounts = <String, int>{};
  for (final tool in executedTools) {
    final name = ValueReaders.stringValue(tool['name']);
    toolNameCounts[name] = (toolNameCounts[name] ?? 0) + 1;
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
      'value': '都市异闻悬疑长篇。女主沈临川是夜班电台主播，能从午夜热线里听见不属于现实层的第二道回声。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '悬疑递进、都市压迫感与角色情绪线稳定并行，保证章节钩子。 ',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '所有异常都要经过电波残响才可被感知，任何超常认知都必须付出现实代价。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '沈临川要查清姐姐失踪真相，并确认午夜热线里的另一层声音究竟来自谁。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '中文商业悬疑风格，干净、利落、少分析腔，保留现场感和节奏推进。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '允许连续推进，总纲与样章确认后自动写到 20 章，每 5 章设一个检查点。',
      'label': '托管边界',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '以上信息已确认，可以启动长任务。',
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
