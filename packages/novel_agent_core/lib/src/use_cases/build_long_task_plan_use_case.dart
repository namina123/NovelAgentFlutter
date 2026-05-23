import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../workflow/long_task_plan_changed_paths_service.dart';
import '../workflow/long_task_plan_markdown_renderer.dart';
import '../workflow/long_task_plan_record_service.dart';
import '../workflow/long_task_task_factory_service.dart';

class BuildLongTaskPlanUseCase {
  BuildLongTaskPlanUseCase({
    required LongTaskTaskFactoryService taskFactoryService,
    required LongTaskPlanRecordService planRecordService,
    required LongTaskPlanChangedPathsService changedPathsService,
    required LongTaskPlanMarkdownRenderer markdownRenderer,
  }) : _taskFactoryService = taskFactoryService,
       _planRecordService = planRecordService,
       _changedPathsService = changedPathsService,
       _markdownRenderer = markdownRenderer;

  final LongTaskTaskFactoryService _taskFactoryService;
  final LongTaskPlanRecordService _planRecordService;
  final LongTaskPlanChangedPathsService _changedPathsService;
  final LongTaskPlanMarkdownRenderer _markdownRenderer;

  JsonMap execute(
    String mode,
    String planId, {
    JsonMap options = const <String, Object?>{},
    String createdAt = '',
    String planPath = 'tracking/long_task/plan.json',
    String planMarkdownPath = 'tracking/long_task/plan.md',
  }) {
    // 中文注释: 这个用例把长任务计划创建串成一个共享入口，宿主不再各自手拼计划文件内容。
    final tasks = _taskFactoryService.buildTasks(
      mode,
      planId,
      options: options,
      createdAt: createdAt,
    );
    final summaries = tasks
        .map<JsonMap>(
          (task) => <String, Object?>{
            'id': task['id'],
            'title': task['title'],
            'task_type': task['task_type'],
            'status': task['status'],
            'sort_order': ValueReaders.intValue(
              ValueReaders.mapValue(task['metadata'])['sort_order'],
            ),
            'depends_on': task['depends_on'],
            'output_paths': task['output_paths'],
            'relative_path': task['relative_path'],
          },
        )
        .toList(growable: false);
    final plan = _planRecordService.planRecord(
      planId,
      mode,
      options: options,
      createdTasks: summaries,
      createdAt: createdAt,
    );
    final markdown = _markdownRenderer.renderMarkdown(plan);
    return <String, Object?>{
      'ok': true,
      'plan': plan,
      'tasks': tasks,
      'markdown': markdown,
      'changed_paths': _changedPathsService.changedPaths(
        planPath,
        planMarkdownPath,
        summaries,
      ),
    };
  }
}
