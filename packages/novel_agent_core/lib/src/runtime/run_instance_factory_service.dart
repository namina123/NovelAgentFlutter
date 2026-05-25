import '../project/project_descriptor.dart';
import 'long_task_run_status.dart';
import 'run_instance.dart';
import 'run_project_reference.dart';
import 'runtime_baseline.dart';

class RunInstanceFactoryService {
  const RunInstanceFactoryService();

  RunInstance createLongTaskInstance({
    required String runId,
    required ProjectDescriptor project,
    required RuntimeBaseline runtimeBaseline,
    required String modeId,
    required String workflowStrategyId,
    LongTaskRunStatus initialStatus = LongTaskRunStatus.draftingGuidance,
    DateTime? now,
  }) {
    // 中文注释: 运行实例的创建统一收口在这里，确保“全局运行对象”总是带着项目引用和运行基线一起出生。
    final createdAt = now ?? DateTime.now();
    return RunInstance(
      id: runId,
      project: RunProjectReference.fromProject(project),
      runtimeBaselineId: runtimeBaseline.id,
      modeId: modeId.trim(),
      workflowStrategyId: workflowStrategyId.trim(),
      status: initialStatus,
      createdAt: createdAt,
      updatedAt: createdAt,
      startedAt: initialStatus == LongTaskRunStatus.running ? createdAt : null,
    );
  }
}
