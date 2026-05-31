import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectLongTaskCheckpointReviewService {
  ProjectLongTaskCheckpointReviewService({
    required ProjectTaskRepository taskRepository,
    LongTaskCheckpointReviewService? checkpointReviewService,
    LongTaskCheckpointReviewMarkdownRenderer? markdownRenderer,
    LongTaskCheckpointSeverityService? checkpointSeverityService,
    LongTaskCheckpointActionContractService? checkpointActionContractService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewService =
           checkpointReviewService ??
           LongTaskCheckpointReviewService(
             taskSummaryService: LongTaskTaskSummaryService(),
           ),
       _markdownRenderer =
           markdownRenderer ?? const LongTaskCheckpointReviewMarkdownRenderer(),
       _checkpointSeverityService =
           checkpointSeverityService ?? LongTaskCheckpointSeverityService(),
       _checkpointActionContractService =
           checkpointActionContractService ??
           LongTaskCheckpointActionContractService();

  final ProjectTaskRepository _taskRepository;
  final LongTaskCheckpointReviewService _checkpointReviewService;
  final LongTaskCheckpointReviewMarkdownRenderer _markdownRenderer;
  final LongTaskCheckpointSeverityService _checkpointSeverityService;
  final LongTaskCheckpointActionContractService
  _checkpointActionContractService;

  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    // 中文注释: 该服务把复盘合同补上项目文件摘录并落盘，供 GUI、CLI 与后续策略节点共用。
    final outputPaths = _mergedPaths(
      ValueReaders.stringList(task['output_paths']),
      ValueReaders.stringList(result['output_paths']),
    );
    final review = _checkpointReviewService.buildReview(
      task: task,
      result: result,
      memorySections: memorySections,
      outputPaths: outputPaths,
      execution: execution,
    );
    review['output_excerpts'] = await _outputExcerpts(project, outputPaths);
    final taskId = ValueReaders.stringValue(task['id'], 'task');
    final safeTaskId = taskId.replaceAll(RegExp(r'[^a-zA-Z0-9_\\-]+'), '_');
    final basePath =
        'tracking/checkpoint_reviews/$safeTaskId.${DateTime.now().microsecondsSinceEpoch}';
    final jsonPath = '$basePath.json';
    final markdownPath = '$basePath.md';
    review['json_path'] = jsonPath;
    review['markdown_path'] = markdownPath;
    final severity = _checkpointSeverityService.assess(review);
    review['severity'] = ValueReaders.stringValue(severity['severity']);
    review['severity_label'] = ValueReaders.stringValue(
      severity['severity_label'],
    );
    review['severity_reasons'] = ValueReaders.stringList(severity['reasons']);
    final actionPackage = _checkpointActionContractService.buildPackage(
      review,
      checkpointReviewPath: jsonPath,
    );
    review['suggested_actions'] = ValueReaders.mapList(
      actionPackage['actions'],
    );
    review['action_summary'] = ValueReaders.stringValue(
      actionPackage['action_summary'],
    );
    review['recommended_action_id'] = ValueReaders.stringValue(
      actionPackage['recommended_action_id'],
    );
    review['disposition'] = ValueReaders.mapValue(actionPackage['disposition']);
    review['continuation_disposition'] = ValueReaders.stringValue(
      ValueReaders.mapValue(actionPackage['disposition'])['disposition'],
    );
    review['continuation_reason'] = ValueReaders.stringValue(
      ValueReaders.mapValue(actionPackage['disposition'])['reason'],
    );
    await _taskRepository.saveRecord(project, jsonPath, review);
    await _taskRepository.writeTextFile(
      project,
      markdownPath,
      _markdownRenderer.renderMarkdown(review),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': jsonPath,
      'markdown_path': markdownPath,
      'review': review,
      'changed_paths': <Object?>[jsonPath, markdownPath],
    };
  }

  Future<List<JsonMap>> _outputExcerpts(
    ProjectDescriptor project,
    List<String> outputPaths,
  ) async {
    final excerpts = <JsonMap>[];
    for (final path in outputPaths) {
      final content = await _taskRepository.readTextFile(project, path);
      final clean = (content ?? '').trim();
      if (clean.isEmpty) {
        continue;
      }
      excerpts.add(<String, Object?>{
        'relative_path': path,
        'excerpt': clean.length <= 500
            ? clean
            : '${clean.substring(0, 500)}...',
      });
    }
    return excerpts;
  }

  List<String> _mergedPaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }
}
