import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/primary_action_view_data.dart';
import '../models/opening_session_projection.dart';

class WorkbenchOpeningLaunchBridgeService {
  WorkbenchOpeningLaunchBridgeService({
    required BuildModeGuidancePlanInputUseCase buildModeGuidancePlanInputUseCase,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
    LongTaskOpeningPromptBuilderService? longTaskOpeningPromptBuilderService,
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _workflowRuntimeService = workflowRuntimeService,
       _longTaskOpeningPromptBuilderService =
           longTaskOpeningPromptBuilderService ??
           const LongTaskOpeningPromptBuilderService(),
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final LongTaskOpeningPromptBuilderService _longTaskOpeningPromptBuilderService;
  final ProjectTypeCatalogService _projectTypeCatalogService;

  PrimaryActionViewData? resolveLongTaskLaunchTarget(
    OpeningSessionProjection? projection,
  ) {
    if (projection == null || projection.orchestration.suggestedActions.isEmpty) {
      return null;
    }
    final action = projection.orchestration.suggestedActions.first;
    return PrimaryActionViewData(
      id: action.id,
      title: action.title,
      description: action.description,
      commandId: action.commandId,
      payload: action.payload,
    );
  }

  String buildLongTaskEntryPrompt({
    required ProjectDescriptor project,
    required OpeningSessionProjection? projection,
    required String activeDocumentPath,
    required String activeDocumentExcerpt,
  }) {
    // 中文注释: 开局按钮统一在这里生成提示词，控制器只负责转发和发送，避免各入口重复拼装开局文案。
    final readiness = projection?.orchestration.readiness;
    final suggestedAction = resolveLongTaskLaunchTarget(projection);
    return _longTaskOpeningPromptBuilderService.build(
      project: <String, Object?>{
        'title': project.name,
        'project_type': _projectTypeCatalogService.normalize(
          project.projectType,
        ),
        'root_path': project.rootPath,
        'runtime_baseline_id': project.runtimeBaselineId,
      },
      currentGroupDisplayName: projection?.currentGroupDisplayName ?? '',
      canStartLongTask: readiness?.canStartLongTask ?? false,
      missingRequirementTitles: readiness == null
          ? const <String>[]
          : readiness.missingRequirements
              .map((item) => item.title.trim())
              .where((title) => title.isNotEmpty)
              .toList(growable: false),
      effectiveModeId: effectiveLongTaskModeId(projection),
      suggestedActionTitle: suggestedAction?.title ?? '',
      suggestedActionDescription: suggestedAction?.description ?? '',
      activeDocumentPath: activeDocumentPath,
      activeDocumentExcerpt: activeDocumentExcerpt,
    );
  }

  String effectiveLongTaskModeId(OpeningSessionProjection? projection) {
    if (projection == null) {
      return '';
    }
    final activeModeId = projection
        .orchestration
        .state
        .modeGuidanceState
        ?.modeId
        .trim();
    if (activeModeId != null && activeModeId.isNotEmpty) {
      return activeModeId;
    }
    final readinessModeId = projection.orchestration.readiness.effectiveModeId
        .trim();
    if (readinessModeId.isNotEmpty) {
      return readinessModeId;
    }
    return projection.orchestration.state.intent.modeId.trim();
  }

  Future<JsonMap> createWorkflowFromModeGuidance(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    // 中文注释: 模式引导收束后统一从这里创建正式长任务队列，避免 controller 和灵感工作台各自拼建链逻辑。
    final planInput = await _buildModeGuidancePlanInputUseCase.execute(
      project,
      modeId: modeId.trim(),
    );
    if (planInput == null) {
      return const <String, Object?>{
        'ok': false,
        'message': '当前还没有可用的模式状态，请先完成模式引导。',
      };
    }
    if (!planInput.isReady) {
      return const <String, Object?>{
        'ok': false,
        'message': '当前模式信息尚未收束完成，请先完成当前阶段。',
      };
    }
    final result = await _workflowRuntimeService.createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    return <String, Object?>{
      ...result,
      'plan_input': <String, Object?>{
        'runtime_mode': planInput.runtimeMode,
        'runtime_baseline_id': planInput.runtimeBaselineId,
        'options': planInput.options,
      },
    };
  }

  Future<JsonMap> launchLongTaskFromModeGuidance(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    // 中文注释: 灵感工作台的“启动长任务”也必须先沿着同一份模式引导合同收束，再生成正式任务链。
    final creation = await createWorkflowFromModeGuidance(
      project,
      modeId: modeId,
    );
    if (!ValueReaders.boolValue(creation['ok'], true)) {
      return creation;
    }
    final createdTaskCount = ValueReaders.objectList(
      creation['created_tasks'],
    ).length;
    return <String, Object?>{
      ...creation,
      'message': createdTaskCount > 0
          ? '长任务队列已生成，共创建 $createdTaskCount 个任务。'
          : '长任务队列已生成。',
    };
  }

  Future<JsonMap> startLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings, {
    required JsonMap arguments,
  }) async {
    // 中文注释: opening 的正式启动需要先确保 workflow 已就位，再统一进入受控队列运行。
    final existingTasks = await _workflowRuntimeService.listWorkflowTasks(
      project,
    );
    if (existingTasks.isEmpty) {
      final creation = await createWorkflowFromModeGuidance(
        project,
        modeId: _resolveModeId(project, arguments),
      );
      if (!ValueReaders.boolValue(creation['ok'], true)) {
        return creation;
      }
    }
    return _workflowRuntimeService.runWorkflowTaskQueue(
      project,
      settings,
      options: <String, Object?>{
        'entry_reason': 'opening_start_long_task_run',
        'mode_id': _resolveModeId(project, arguments),
      },
    );
  }

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) {
    return _workflowRuntimeService.runWorkflowTaskQueue(
      project,
      settings,
      options: options,
      agent: agent,
    );
  }

  String _resolveModeId(ProjectDescriptor project, JsonMap arguments) {
    for (final key in const <String>['mode_id', 'mode', 'guidance_mode_id']) {
      final value = ValueReaders.stringValue(arguments[key]).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    switch (project.runtimeBaselineId.trim()) {
      case 'continuous_autonomous':
        return 'seed_autopilot_novel';
      case 'chapter_collaboration_autorun':
        return 'full_outline_consensus';
      default:
        return '';
    }
  }
}
