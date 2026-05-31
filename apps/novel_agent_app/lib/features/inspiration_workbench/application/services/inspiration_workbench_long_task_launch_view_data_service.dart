import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/inspiration_workbench_long_task_launch_view_data.dart';

class InspirationWorkbenchLongTaskLaunchViewDataService {
  InspirationWorkbenchLongTaskLaunchViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    ModeGuidancePlanInputBuilderService? planInputBuilderService,
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    ModeGuidanceWorkspacePathService? workspacePathService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _planInputBuilderService =
           planInputBuilderService ?? ModeGuidancePlanInputBuilderService(),
       _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ?? const RuntimeBaselineCatalogService(),
       _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ModeGuidancePlanInputBuilderService _planInputBuilderService;
  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final ModeGuidanceWorkspacePathService _workspacePathService;

  InspirationWorkbenchLongTaskLaunchViewData build({
    required String projectType,
    required ModeGuidanceState? state,
  }) {
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      projectType,
    );
    if (normalizedProjectType != 'long_novel' || state == null) {
      return InspirationWorkbenchLongTaskLaunchViewData.hidden();
    }
    final planInput = _planInputBuilderService.build(state);
    if (planInput.runtimeBaselineId.trim().isEmpty) {
      return InspirationWorkbenchLongTaskLaunchViewData.hidden();
    }
    final guidancePath = _workspacePathService.summaryMarkdownPath(state.modeId);
    final baseline = _runtimeBaselineCatalogService.byId(
      planInput.runtimeBaselineId,
    );
    final baselineTitle = baseline?.title ?? planInput.runtimeBaselineId;
    if (planInput.isReady) {
      return InspirationWorkbenchLongTaskLaunchViewData(
        isVisible: true,
        canLaunch: true,
        title: '已可启动长任务',
        description:
            '当前灵感与约束已收束完成，可直接生成“$baselineTitle”长任务链。引导摘要已写入 $guidancePath。',
        guidancePath: guidancePath,
        actionLabel: '启动长任务',
      );
    }
    return InspirationWorkbenchLongTaskLaunchViewData(
      isVisible: true,
      canLaunch: false,
      title: '这是长任务项目',
      description:
          '继续完成当前灵感阶段后，就可以直接生成“$baselineTitle”长任务链。对话引导摘要会持续写入 $guidancePath。',
      guidancePath: guidancePath,
      actionLabel: '继续完善后启动',
    );
  }
}
