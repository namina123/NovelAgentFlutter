import 'project_descriptor.dart';
import 'project_type_transition_plan.dart';
import 'project_type_transition_policy.dart';
import 'project_type_transition_request.dart';

class ProjectTypeTransitionPreparationService {
  const ProjectTypeTransitionPreparationService({
    ProjectTypeTransitionPolicy? projectTypeTransitionPolicy,
  }) : _projectTypeTransitionPolicy =
           projectTypeTransitionPolicy ?? const ProjectTypeTransitionPolicy();

  final ProjectTypeTransitionPolicy _projectTypeTransitionPolicy;

  ProjectTypeTransitionPlan prepare({
    required ProjectDescriptor project,
    required String targetProjectTypeId,
    String runtimeBaselineId = '',
    bool hasActiveLongTaskRun = false,
  }) {
    // 中文注释: 准备阶段只读取现有项目事实并转换成计划对象，不触碰任何文件写入或状态改写。
    return _projectTypeTransitionPolicy.plan(
      ProjectTypeTransitionRequest(
        sourceProjectTypeId: project.projectType,
        targetProjectTypeId: targetProjectTypeId,
        storageStrategy: project.storageStrategy,
        currentRuntimeBaselineId: runtimeBaselineId.trim().isEmpty
            ? project.runtimeBaselineId
            : runtimeBaselineId,
        hasActiveLongTaskRun: hasActiveLongTaskRun,
      ),
    );
  }
}
