import '../common/json_types.dart';
import '../workflow/long_task_revision_plan_service.dart';

class BuildLongTaskRevisionPlanUseCase {
  BuildLongTaskRevisionPlanUseCase({
    required LongTaskRevisionPlanService revisionPlanService,
  }) : _revisionPlanService = revisionPlanService;

  final LongTaskRevisionPlanService _revisionPlanService;

  JsonMap execute(
    JsonMap record,
    List<Object?> tasks,
    String command, {
    JsonMap arguments = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 这个用例把长任务修订命令收束到统一入口，GUI 和 CLI 可共用同一修订合同。
    return _revisionPlanService.buildRevisionPlan(
      record,
      tasks,
      command,
      arguments: arguments,
      createdAt: createdAt,
    );
  }
}
