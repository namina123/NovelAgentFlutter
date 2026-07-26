import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_result_factory.dart';

typedef ModeGuidancePlanInputLoader =
    Future<ModeGuidancePlanInput?> Function(
      ProjectDescriptor project, {
      required String modeId,
    });

typedef LongTaskWorkflowCreator =
    Future<JsonMap> Function(
      ProjectDescriptor project,
      String runtimeMode, {
      JsonMap options,
    });

class ProjectLongTaskToolExecutor {
  ProjectLongTaskToolExecutor({
    required ModeGuidancePlanInputLoader loadPlanInput,
    required LongTaskWorkflowCreator createLongTaskWorkflow,
    ProjectTypeCatalogService? projectTypeCatalogService,
    ModeGuidanceWorkspacePathService? workspacePathService,
    ProjectToolResultFactory? resultFactory,
  }) : _loadPlanInput = loadPlanInput,
       _createLongTaskWorkflow = createLongTaskWorkflow,
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory();

  final ModeGuidancePlanInputLoader _loadPlanInput;
  final LongTaskWorkflowCreator _createLongTaskWorkflow;
  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ModeGuidanceWorkspacePathService _workspacePathService;
  final ProjectToolResultFactory _resultFactory;

  Future<JsonMap> startLongTaskRun(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 会话工具只负责“按当前模式引导正式开跑”，不在这里重新发明规划链。
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      project.projectType,
    );
    if (normalizedProjectType != 'long_novel') {
      return _resultFactory.notExecuted(
        '只有长任务相关项目才允许启动长任务。',
        data: <String, Object?>{'project_type': normalizedProjectType},
      );
    }
    final modeId = _resolveModeId(project, arguments);
    if (modeId.isEmpty) {
      return _resultFactory.notExecuted(
        '当前无法判断要启动哪一种长任务模式，请提供 mode_id，或先为项目选定运行基准。',
      );
    }
    final guidancePath = _workspacePathService.summaryMarkdownPath(modeId);
    final planInput = await _loadPlanInput(project, modeId: modeId);
    if (planInput == null) {
      return _resultFactory.notExecuted(
        '当前模式还没有可用的引导状态，暂时不能启动长任务。',
        data: <String, Object?>{
          'mode_id': modeId,
          'guidance_path': guidancePath,
        },
      );
    }
    if (!planInput.isReady) {
      return _resultFactory.notExecuted(
        '当前灵感约束尚未收束完成，请先继续完善当前长任务模式。',
        data: <String, Object?>{
          'mode_id': modeId,
          'guidance_path': guidancePath,
          'runtime_baseline_id': planInput.runtimeBaselineId,
          'missing_fields': planInput.missingFields,
        },
      );
    }
    if (planInput.runtimeBaselineId.trim().isEmpty) {
      return _resultFactory.notExecuted(
        '当前模式不会生成长任务链，请先切回长任务相关模式。',
        data: <String, Object?>{
          'mode_id': modeId,
          'guidance_path': guidancePath,
        },
      );
    }
    final result = await _createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    if (!ValueReaders.boolValue(result['ok'], true)) {
      return _resultFactory.error(
        ValueReaders.stringValue(result['error'], '启动长任务失败。'),
        data: <String, Object?>{
          ...result,
          'mode_id': modeId,
          'guidance_path': guidancePath,
          'runtime_baseline_id': planInput.runtimeBaselineId,
        },
      );
    }
    final createdTaskCount = ValueReaders.objectList(
      result['created_tasks'],
    ).length;
    final message = createdTaskCount > 0
        ? '已启动长任务，共创建 $createdTaskCount 个任务。'
        : '已启动长任务。';
    return _resultFactory.success(
      message,
      data: <String, Object?>{
        ...result,
        'mode_id': modeId,
        'guidance_path': guidancePath,
        'runtime_baseline_id': planInput.runtimeBaselineId,
        'created_task_count': createdTaskCount,
      },
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
