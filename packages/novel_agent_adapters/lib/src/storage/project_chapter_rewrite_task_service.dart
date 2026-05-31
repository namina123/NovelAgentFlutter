import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_task_repository.dart';

class ProjectChapterRewriteTaskService {
  ProjectChapterRewriteTaskService({
    required ProjectTaskRepository taskRepository,
    ChapterRewriteTaskFactoryService? taskFactoryService,
  }) : _taskRepository = taskRepository,
       _taskFactoryService =
           taskFactoryService ?? ChapterRewriteTaskFactoryService();

  final ProjectTaskRepository _taskRepository;
  final ChapterRewriteTaskFactoryService _taskFactoryService;

  Future<JsonMap> createRevisionTaskFromPlan(
    ProjectDescriptor project,
    ChapterRewritePlan plan, {
    String analysisPath = '',
  }) async {
    // 中文注释: 这里专门负责把重写计划物化成 revision 任务文件，GUI/CLI 都不需要再手拼任务 JSON。
    final task = _taskFactoryService.revisionTaskFromPlan(
      plan,
      analysisPath: analysisPath,
    );
    if (task == null || task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前计划不会直接生成修订任务。',
      };
    }
    final saved = await _taskRepository.saveTask(project, task);
    return <String, Object?>{
      'ok': true,
      'relative_path': ValueReaders.stringValue(saved['relative_path']),
      'task': saved,
      'task_arguments': task,
    };
  }

  Future<JsonMap> createRevisionTaskFromSuggestions(
    ProjectDescriptor project,
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions, {
    String analysisPath = '',
  }) async {
    // 中文注释: 选择建议直接转任务时，也统一走同一仓储入口保存。
    final task = _taskFactoryService.revisionTaskFromSuggestions(
      result,
      suggestions,
      analysisPath: analysisPath,
    );
    if (task == null || task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前建议集合不能直接生成修订任务。',
      };
    }
    final saved = await _taskRepository.saveTask(project, task);
    return <String, Object?>{
      'ok': true,
      'relative_path': ValueReaders.stringValue(saved['relative_path']),
      'task': saved,
      'task_arguments': task,
    };
  }
}
