import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';
import 'project_long_task_checkpoint_review_service.dart';

class ProjectLongTaskPostprocessResultService {
  ProjectLongTaskPostprocessResultService({
    required ProjectTaskRepository taskRepository,
    required ProjectLongTaskCheckpointReviewService checkpointReviewService,
    ChapterAtomicResultRecorderService? resultRecorderService,
    ReviewPathPolicyService? reviewPathPolicyService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewService = checkpointReviewService,
       _resultRecorderService =
           resultRecorderService ??
           ChapterAtomicResultRecorderService(
             stepStateService: ChapterAtomicStepStateService(),
             eventService: ChapterAtomicEventService(),
           ),
       _reviewPathPolicyService =
           reviewPathPolicyService ?? ReviewPathPolicyService();

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewService _checkpointReviewService;
  final ChapterAtomicResultRecorderService _resultRecorderService;
  final ReviewPathPolicyService _reviewPathPolicyService;

  Future<JsonMap> saveResult({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap execution,
    required DraftGenerationResult result,
    required List<JsonMap> memorySections,
  }) async {
    // 中文注释: 后处理结果的执行包更新、报告路径提取与检查点复盘落盘统一收在这里，避免 runtime 再长出第二套状态机。
    final executionUpdate = _resultRecorderService.recordPostprocessResult(
      execution,
      <String, Object?>{
        'id': '',
        'result_markdown': result.draftMarkdown,
        'error_summary': result.toolErrorSummary,
      },
      result.writtenPaths,
      _toolNames(result.executedTools),
    );
    final updatedExecution = ValueReaders.mapValue(
      executionUpdate['execution'],
    );
    final executionPath = ValueReaders.stringValue(
      updatedExecution['relative_path'],
      ValueReaders.stringValue(execution['relative_path']),
    );
    final changedPaths = <String>[];
    if (executionPath.trim().isNotEmpty) {
      await _taskRepository.saveRecord(
        project,
        executionPath,
        updatedExecution,
      );
      changedPaths.add(executionPath);
    }
    JsonMap checkpointReview = const <String, Object?>{};
    if (result.executedTools.isNotEmpty ||
        result.writtenPaths.isNotEmpty ||
        result.draftMarkdown.trim().isNotEmpty) {
      checkpointReview = await _checkpointReviewService.saveReview(
        project: project,
        task: task,
        result: <String, Object?>{
          'ok': true,
          'output_paths': result.writtenPaths,
          'changed_paths': result.changedPaths,
          'executed_tools': result.executedTools,
          'response': <String, Object?>{
            'content': result.draftMarkdown,
            'tool_calls': ValueReaders.deepCopyList(result.executedTools),
            'context_pack_summary': ValueReaders.stringValue(
              result.contextPack['summary'],
            ),
          },
        },
        memorySections: memorySections,
        execution: updatedExecution,
      );
      changedPaths.addAll(
        ValueReaders.stringList(checkpointReview['changed_paths']),
      );
    }
    return <String, Object?>{
      'ok': true,
      'execution': updatedExecution,
      'postprocess_review_report_path': _firstReviewMarkdownPath(
        result.writtenPaths,
      ),
      'postprocess_review_report_json_path': _firstReviewJsonPath(
        result.writtenPaths,
      ),
      'checkpoint_review': checkpointReview,
      'changed_paths': changedPaths,
    };
  }

  String _firstReviewMarkdownPath(List<String> paths) {
    for (final path in paths) {
      final markdownPath = _reviewPathPolicyService.reviewMarkdownPath(path);
      if (markdownPath.isNotEmpty) {
        return markdownPath;
      }
    }
    return '';
  }

  String _firstReviewJsonPath(List<String> paths) {
    for (final path in paths) {
      final jsonPath = _reviewPathPolicyService.reviewJsonPath(path);
      if (jsonPath.isNotEmpty) {
        return jsonPath;
      }
    }
    return '';
  }

  List<String> _toolNames(List<Object?> executedTools) {
    final result = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isNotEmpty && !result.contains(name)) {
        result.add(name);
      }
    }
    return result;
  }
}
