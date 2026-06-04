import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_session_projection_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 该探针只验证 opening/group/start 工具链闭环，不去重写真实 AI 探针职责。
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_group_opening_probe_',
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
  final planInputUseCase = BuildModeGuidancePlanInputUseCase(
    statePort: modeRepository,
  );
  final workflowRuntimeService = ProjectWorkflowRuntimeService(
    taskRepository: ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    ),
    promptTemplateService: ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    ),
    generateDraftUseCaseFactory: (_, networkSettings) {
      throw UnsupportedError('AG-08 opening probe does not run model drafting.');
    },
  );
  final longTaskExecutor = ProjectLongTaskToolExecutor(
    loadPlanInput: (project, {required modeId}) =>
        planInputUseCase.execute(project, modeId: modeId),
    createLongTaskWorkflow: workflowRuntimeService.createLongTaskWorkflow,
  );
  final projectionService = ProjectOpeningSessionProjectionService(
    loadAgentPackages: bundle.agentPackageCatalog.loadAgentPackages,
    loadAgentGroups: bundle.agentGroupCatalog.loadAgentGroups,
    loadProjectAgentGroupSelections:
        bundle.projectAgentGroupBindingRepository.loadSelections,
  );

  try {
    final novelProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'AG08_普通小说',
      projectType: 'novel',
    );
    final seedProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'AG08_灵感长篇',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    final fullOutlineProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'AG08_全纲长篇',
      projectType: 'long_novel',
      runtimeBaselineId: 'chapter_collaboration_autorun',
    );
    final deconstructionProject = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'AG08_拆书项目',
      projectType: 'book_deconstruction',
    );

    await bundle.projectAgentGroupBindingRepository.saveSelections(
      seedProject,
      const <ProjectAgentGroupSelection>[
        ProjectAgentGroupSelection(
          groupId: 'starter_long_novel_seed_generalist',
          displayName: '默认长任务灵感开局',
          selectedByDefault: true,
        ),
      ],
    );
    await _seedReadySeedState(modeRepository, seedProject);
    await _seedReadyFullOutlineState(modeRepository, fullOutlineProject);

    final novelProjection = await projectionService.build(
      project: novelProject,
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
      sessionGoalModeId: SessionRecordConstants.modeSmartOpening,
    );
    final seedProjection = await projectionService.build(
      project: seedProject,
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
        runtimeMode: 'long_task_project',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: await modeRepository.load(
        seedProject,
        modeId: 'seed_autopilot_novel',
      ),
    );
    final fullOutlineProjection = await projectionService.build(
      project: fullOutlineProject,
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
        runtimeMode: 'long_task_project',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: await modeRepository.load(
        fullOutlineProject,
        modeId: 'full_outline_consensus',
      ),
    );
    final deconstructionProjection = await projectionService.build(
      project: deconstructionProject,
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'book_deconstruction',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
      freeTextIntent: '请先帮我整理这本书的结构与资产。',
    );

    final seedStartResult = await longTaskExecutor.startLongTaskRun(
      seedProject,
      const <String, Object?>{},
    );
    final fullOutlineStartResult = await longTaskExecutor.startLongTaskRun(
      fullOutlineProject,
      const <String, Object?>{},
    );

    final seedSelections = await bundle.projectAgentGroupBindingRepository
        .loadSelections(seedProject);
    final novelSelections = await bundle.projectAgentGroupBindingRepository
        .loadSelections(novelProject);
    final report = <String, Object?>{
      'novel_opening': _buildInteractiveProjectionReport(
        projection: novelProjection,
        expectedGroupId: 'starter_novel_generalist',
        expectedSupportedGroupId: 'starter_novel_generalist',
      ),
      'seed_opening': _buildLongTaskProjectionReport(
        projection: seedProjection,
        expectedGroupId: 'starter_long_novel_seed_generalist',
        expectedUnsupportedGroupId: 'starter_long_novel_full_outline_generalist',
        startResult: seedStartResult,
      ),
      'full_outline_opening': _buildLongTaskProjectionReport(
        projection: fullOutlineProjection,
        expectedGroupId: 'starter_long_novel_full_outline_generalist',
        expectedUnsupportedGroupId: 'starter_long_novel_seed_generalist',
        startResult: fullOutlineStartResult,
      ),
      'book_deconstruction_opening': _buildInteractiveProjectionReport(
        projection: deconstructionProjection,
        expectedGroupId: 'starter_book_deconstruction_generalist',
        expectedSupportedGroupId: 'starter_book_deconstruction_generalist',
      ),
      'project_binding_isolation': <String, Object?>{
        'ok': seedSelections.length == 1 && novelSelections.isEmpty,
        'seed_selection_count': seedSelections.length,
        'novel_selection_count': novelSelections.length,
        'seed_binding_file_exists': File(
          '${seedProject.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}project_agent_groups.json',
        ).existsSync(),
        'novel_binding_file_exists': File(
          '${novelProject.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}project_agent_groups.json',
        ).existsSync(),
      },
    };
    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}agent_group_opening_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final ok = report.values.every((value) {
      final map = ValueReaders.mapValue(value);
      return ValueReaders.boolValue(map['ok']);
    });
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(ok ? 'PASS' : 'FAIL');
  } finally {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

Map<String, Object?> _buildInteractiveProjectionReport({
  required OpeningSessionProjection projection,
  required String expectedGroupId,
  required String expectedSupportedGroupId,
}) {
  final supportedGroupIds = projection.supportedGroups
      .map((group) => group.groupId)
      .toList(growable: false);
  final actionIds = projection.orchestration.suggestedActions
      .map((item) => item.commandId)
      .toList(growable: false);
  final ok =
      projection.currentGroupId == expectedGroupId &&
      supportedGroupIds.contains(expectedSupportedGroupId) &&
      projection.orchestration.readiness.canStartInteractiveSession &&
      actionIds.contains('opening.start_interactive_session');
  return <String, Object?>{
    'ok': ok,
    'current_group_id': projection.currentGroupId,
    'supported_group_ids': supportedGroupIds,
    'unsupported_group_ids': projection.unsupportedGroups
        .map((group) => group.groupId)
        .toList(growable: false),
    'action_ids': actionIds,
  };
}

Map<String, Object?> _buildLongTaskProjectionReport({
  required OpeningSessionProjection projection,
  required String expectedGroupId,
  required String expectedUnsupportedGroupId,
  required JsonMap startResult,
}) {
  final supportedGroupIds = projection.supportedGroups
      .map((group) => group.groupId)
      .toList(growable: false);
  final unsupportedGroupIds = projection.unsupportedGroups
      .map((group) => group.groupId)
      .toList(growable: false);
  final actionIds = projection.orchestration.suggestedActions
      .map((item) => item.commandId)
      .toList(growable: false);
  final createdPaths = ValueReaders.stringList(startResult['changed_paths']);
  final ok =
      projection.currentGroupId == expectedGroupId &&
      supportedGroupIds.contains(expectedGroupId) &&
      unsupportedGroupIds.contains(expectedUnsupportedGroupId) &&
      projection.orchestration.readiness.canStartLongTask &&
      actionIds.contains('opening.start_long_task_run') &&
      ValueReaders.boolValue(startResult['ok']) &&
      createdPaths.any((path) => path.startsWith('tasks/'));
  return <String, Object?>{
    'ok': ok,
    'current_group_id': projection.currentGroupId,
    'supported_group_ids': supportedGroupIds,
    'unsupported_group_ids': unsupportedGroupIds,
    'action_ids': actionIds,
    'start_result': startResult,
  };
}

Future<void> _seedReadySeedState(
  ProjectModeGuidanceRepository repository,
  ProjectDescriptor project,
) async {
  final transitionService = ModeGuidanceTransitionService();
  var state = transitionService.initialize('seed_autopilot_novel');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'seed_scope',
      'field': 'seed_scope',
      'value': '主角从矿牢归来复仇，并逐步掀翻帝国誓约秩序。',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '持续升级、权谋翻盘、真相层层揭开。',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '皇室、教廷与七大公国共同维持誓约统治。',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '复仇翻案，并夺回家族守护权。',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '商业长篇，节奏紧，避免空泛抒情。',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '跨卷大转折先确认，其余默认托管推进。',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '可以开始生成可恢复长任务链。',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      source: 'probe',
    );
  }
  await repository.save(project, state);
}

Future<void> _seedReadyFullOutlineState(
  ProjectModeGuidanceRepository repository,
  ProjectDescriptor project,
) async {
  final transitionService = ModeGuidanceTransitionService();
  var state = transitionService.initialize('full_outline_consensus');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'book_premise',
      'field': 'book_premise',
      'value': '失势公主回京争位，并在边军失控与诸侯裂盟间建立新秩序。',
    },
    <String, String>{
      'stage': 'main_arc',
      'field': 'main_arc',
      'value': '回京入局、收拢边军、拆解诸侯联盟、最终夺权重建秩序。',
    },
    <String, String>{
      'stage': 'volume_map',
      'field': 'volume_map',
      'value': '四卷结构，逐卷升级局势与代价。',
    },
    <String, String>{
      'stage': 'ending_commitment',
      'field': 'ending_commitment',
      'value': '结局掌权，但要付出情感与信任代价。',
    },
    <String, String>{
      'stage': 'style_and_boundaries',
      'field': 'style_and_boundaries',
      'value': '克制、紧凑、偏商业长篇，重政治博弈。',
    },
    <String, String>{
      'stage': 'consensus_confirm',
      'field': 'consensus_confirm',
      'value': '当前共识足够，可以开始生成总纲与执行队列。',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      source: 'probe',
    );
  }
  await repository.save(project, state);
}
