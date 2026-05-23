import '../common/json_types.dart';
import '../workflow/long_task_batch_option_service.dart';
import '../workflow/long_task_scheduler_markdown_renderer.dart';
import '../workflow/long_task_scheduler_tick_plan_service.dart';

class BuildLongTaskSchedulerSnapshotUseCase {
  BuildLongTaskSchedulerSnapshotUseCase({
    required LongTaskSchedulerTickPlanService schedulerTickPlanService,
    required LongTaskBatchOptionService batchOptionService,
    required LongTaskSchedulerMarkdownRenderer schedulerMarkdownRenderer,
  }) : _schedulerTickPlanService = schedulerTickPlanService,
       _batchOptionService = batchOptionService,
       _schedulerMarkdownRenderer = schedulerMarkdownRenderer;

  final LongTaskSchedulerTickPlanService _schedulerTickPlanService;
  final LongTaskBatchOptionService _batchOptionService;
  final LongTaskSchedulerMarkdownRenderer _schedulerMarkdownRenderer;

  JsonMap execute(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 这个用例把调度 tick、批次收紧参数和 Markdown 摘要打包成一份宿主快照。
    final schedulerPlan = _schedulerTickPlanService.schedulerTickPlan(
      record,
      tasks,
      options: options,
    );
    final batchPlan = schedulerPlan['batch_plan'] is Map<String, Object?>
        ? schedulerPlan['batch_plan'] as Map<String, Object?>
        : const <String, Object?>{};
    return <String, Object?>{
      'ok': true,
      'scheduler_plan': schedulerPlan,
      'batch_limited_options': _batchOptionService.batchLimitedOptions(
        batchPlan,
        options: options,
      ),
      'markdown': _schedulerMarkdownRenderer.renderMarkdown(schedulerPlan),
    };
  }
}
