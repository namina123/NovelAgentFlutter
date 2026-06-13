import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class ProjectLongTaskCheckpointReviewService {
  ProjectLongTaskCheckpointReviewService({
    required ProjectTaskRepository taskRepository,
    LongTaskCheckpointReviewService? checkpointReviewService,
    LongTaskCheckpointReviewMarkdownRenderer? markdownRenderer,
    LongTaskCheckpointSeverityService? checkpointSeverityService,
    LongTaskCheckpointActionContractService? checkpointActionContractService,
    LongTaskCheckpointReviewContractMapperService?
    checkpointReviewContractMapperService,
    ReviewSummaryBuilderService? reviewSummaryBuilderService,
    ReviewRepairHandoffService? reviewRepairHandoffService,
    ExpressionConstraintSurfaceRiskScanService?
    expressionConstraintSurfaceRiskScanService,
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
           LongTaskCheckpointActionContractService(),
       _checkpointReviewContractMapperService =
           checkpointReviewContractMapperService ??
           const LongTaskCheckpointReviewContractMapperService(),
       _reviewSummaryBuilderService =
           reviewSummaryBuilderService ?? const ReviewSummaryBuilderService(),
       _reviewRepairHandoffService =
           reviewRepairHandoffService ?? const ReviewRepairHandoffService(),
       _expressionConstraintSurfaceRiskScanService =
           expressionConstraintSurfaceRiskScanService ??
           const ExpressionConstraintSurfaceRiskScanService();

  final ProjectTaskRepository _taskRepository;
  final LongTaskCheckpointReviewService _checkpointReviewService;
  final LongTaskCheckpointReviewMarkdownRenderer _markdownRenderer;
  final LongTaskCheckpointSeverityService _checkpointSeverityService;
  final LongTaskCheckpointActionContractService
  _checkpointActionContractService;
  final LongTaskCheckpointReviewContractMapperService
  _checkpointReviewContractMapperService;
  final ReviewSummaryBuilderService _reviewSummaryBuilderService;
  final ReviewRepairHandoffService _reviewRepairHandoffService;
  final ExpressionConstraintSurfaceRiskScanService
  _expressionConstraintSurfaceRiskScanService;

  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    // 中文注释: 该服务把复盘合同补上项目文件摘录并落盘，供 GUI、CLI 与后续策略节点共用。
    final outputPaths = ValueReaders.stringList(result['output_paths']);
    final outputEvidence = await _outputEvidence(project, outputPaths);
    final resultForReview = _resultWithExpressionSurfaceReview(
      result: result,
      execution: execution,
      surfaceTexts: outputEvidence.surfaceTexts,
    );
    final review = _checkpointReviewService.buildReview(
      task: task,
      result: resultForReview,
      memorySections: memorySections,
      outputPaths: outputPaths,
      execution: execution,
    );
    review['output_excerpts'] = outputEvidence.excerpts;
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
    final authorityPolicy = ReviewAuthorityPolicy.longTask(
      metadata: <String, Object?>{
        'workflow_kind': 'long_task_checkpoint',
        'task_id': taskId,
        'task_path': ValueReaders.stringValue(task['relative_path']),
        'checkpoint_review_path': jsonPath,
      },
    );
    final sharedReviewContract = _checkpointReviewContractMapperService
        .mapReview(
          checkpointReview: review,
          createdAt: ValueReaders.stringValue(review['created_at']),
          metadata: <String, Object?>{
            'workflow_kind': 'long_task_checkpoint',
            'review_authority_policy': authorityPolicy.toJson(),
            'checkpoint_review_path': jsonPath,
            'checkpoint_review_markdown_path': markdownPath,
            'checkpoint_task_id': taskId,
            'checkpoint_task_path': ValueReaders.stringValue(
              task['relative_path'],
            ),
          },
        );
    final sharedReviewSummary = _reviewSummaryBuilderService.buildSummary(
      sharedReviewContract,
    );
    final sharedReviewRepairHandoff = _reviewRepairHandoffService
        .handoffFromReview(sharedReviewContract);
    review['review_authority_policy'] = authorityPolicy.toJson();
    review['review_contract'] = sharedReviewContract.toJson();
    review['review_summary'] = sharedReviewSummary.toJson();
    review['review_repair_handoff'] = sharedReviewRepairHandoff.toJson();
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

  JsonMap _resultWithExpressionSurfaceReview({
    required JsonMap result,
    required JsonMap execution,
    required List<String> surfaceTexts,
  }) {
    final surfaceReview = _expressionSurfaceReview(
      execution: execution,
      surfaceTexts: surfaceTexts,
    );
    if (surfaceReview.isEmpty) {
      return result;
    }
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(result),
      'expression_constraint_surface_review': surfaceReview.toJson(),
    };
  }

  ExpressionConstraintReviewProjection _expressionSurfaceReview({
    required JsonMap execution,
    required List<String> surfaceTexts,
  }) {
    final executionConstraints = ValueReaders.mapValue(
      execution['execution_constraints'],
    );
    if (executionConstraints.isEmpty || surfaceTexts.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    final bridge = WritingExecutionConstraintBridgeResult.fromJson(
      executionConstraints,
    );
    if (!bridge.expressionConstraintApplied ||
        bridge.projectExpressionConstraintBindings.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    return _expressionConstraintSurfaceRiskScanService.scan(
      profiles: bridge.expressionConstraintProfiles,
      bindings: bridge.projectExpressionConstraintBindings,
      texts: surfaceTexts,
    );
  }

  Future<_OutputEvidence> _outputEvidence(
    ProjectDescriptor project,
    List<String> outputPaths,
  ) async {
    final excerpts = <JsonMap>[];
    final surfaceTexts = <String>[];
    for (final path in outputPaths) {
      final content = await _taskRepository.readTextFile(project, path);
      final clean = (content ?? '').trim();
      if (clean.isEmpty) {
        continue;
      }
      surfaceTexts.add(clean);
      excerpts.add(<String, Object?>{
        'relative_path': path,
        'excerpt': clean.length <= 500
            ? clean
            : '${clean.substring(0, 500)}...',
      });
    }
    return _OutputEvidence(
      excerpts: List<JsonMap>.unmodifiable(excerpts),
      surfaceTexts: List<String>.unmodifiable(surfaceTexts),
    );
  }
}

class _OutputEvidence {
  const _OutputEvidence({required this.excerpts, required this.surfaceTexts});

  final List<JsonMap> excerpts;
  final List<String> surfaceTexts;
}
