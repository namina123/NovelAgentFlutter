import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/inspiration_workbench_long_task_launch_result.dart';

class InspirationWorkbenchLongTaskLauncherService {
  InspirationWorkbenchLongTaskLauncherService({
    required BuildModeGuidancePlanInputUseCase buildModeGuidancePlanInputUseCase,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
  }) : _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _workflowRuntimeService = workflowRuntimeService;

  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;

  Future<InspirationWorkbenchLongTaskLaunchResult> launch(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    final planInput = await _buildModeGuidancePlanInputUseCase.execute(
      project,
      modeId: modeId.trim(),
    );
    if (planInput == null) {
      return const InspirationWorkbenchLongTaskLaunchResult(
        ok: false,
        message: '当前模式还没有可用的引导状态，暂时不能启动长任务。',
      );
    }
    if (!planInput.isReady) {
      return const InspirationWorkbenchLongTaskLaunchResult(
        ok: false,
        message: '当前灵感约束尚未收束完成，暂时还不能启动长任务。',
      );
    }
    if (planInput.runtimeBaselineId.trim().isEmpty) {
      return const InspirationWorkbenchLongTaskLaunchResult(
        ok: false,
        message: '当前模式不会生成长任务链，请先切回长任务相关模式。',
      );
    }
    final result = await _workflowRuntimeService.createLongTaskWorkflow(
      project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    final createdTaskCount = ValueReaders.objectList(
      result['created_tasks'],
    ).length;
    return InspirationWorkbenchLongTaskLaunchResult(
      ok: ValueReaders.boolValue(result['ok'], true),
      message: createdTaskCount > 0
          ? '长任务队列已生成，共创建 $createdTaskCount 个任务。'
          : '长任务队列已生成。',
    );
  }
}
