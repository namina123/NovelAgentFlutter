import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectReviewRepairTaskContractService {
  ProjectReviewRepairTaskContractService({
    ReviewRepairHandoffService? reviewRepairHandoffService,
    ReviewPathPolicyService? reviewPathPolicyService,
  }) : _reviewRepairHandoffService =
           reviewRepairHandoffService ?? const ReviewRepairHandoffService(),
       _reviewPathPolicyService =
           reviewPathPolicyService ?? ReviewPathPolicyService();

  final ReviewRepairHandoffService _reviewRepairHandoffService;
  final ReviewPathPolicyService _reviewPathPolicyService;

  JsonMap buildWorkflowRevisionTask({
    required ReviewContract reviewContract,
    required RepairHandoffDecision repairHandoff,
    required String reviewReportPath,
    required String workflowMode,
    required JsonMap sourceTaskMetadata,
    required String sourceTaskId,
    required String sourceTaskPath,
    List<String> inheritedDependsOn = const <String>[],
  }) {
    final request =
        repairHandoff.repairRequest ??
        const RepairRequest(
          requestId: '',
          sourceReviewId: '',
          sourceReviewType: '',
          sourceDisposition: '',
          repairBrief: '',
        );
    final baseTask = _reviewRepairHandoffService.buildRepairTask(request);
    final contextPaths = _mergePaths(<String>[
      ...baseTask.contextPaths,
      ...request.evidencePaths,
      ...reviewContract.evidencePaths,
    ], _reportReferencePaths(reviewReportPath));
    final targetPaths = _mergePaths(
      baseTask.targetPaths,
      reviewContract.basis.targetPaths,
    );
    final dependsOn = _mergePaths(inheritedDependsOn, <String>[sourceTaskId]);
    return <String, Object?>{
      'id': baseTask.taskId,
      'title': baseTask.title,
      'task_type': 'revision',
      'chapter': _chapterScope(reviewContract),
      'goal': baseTask.goal,
      'brief': _briefFromRepairTask(
        reviewContract: reviewContract,
        repairRequest: request,
      ),
      'mode': workflowMode.trim().isEmpty
          ? TaskRuntimeConstants.modeSingleChapterAtomic
          : workflowMode.trim(),
      'status': TaskRuntimeConstants.statusQueued,
      'depends_on': dependsOn,
      'source_paths': contextPaths,
      'output_paths': targetPaths,
      'metadata': <String, Object?>{
        ...baseTask.metadata,
        ...request.metadata,
        'origin': 'review_repair_handoff',
        'review_contract': reviewContract.toJson(),
        'review_summary': ReviewSummaryBuilderService()
            .buildSummary(reviewContract)
            .toJson(),
        'review_repair_handoff': repairHandoff.toJson(),
        'review_report_path': reviewReportPath,
        'review_id': reviewContract.reviewId,
        'review_type': reviewContract.reviewType,
        'runtime_baseline_id': ValueReaders.stringValue(
          sourceTaskMetadata['runtime_baseline_id'],
        ),
        'workflow_mode': workflowMode,
        'persistent_context_paths': ValueReaders.stringList(
          sourceTaskMetadata['persistent_context_paths'],
        ),
        'origin_review_task_id': sourceTaskId,
        'origin_review_task_path': sourceTaskPath,
        'origin_checkpoint_review_path': ValueReaders.stringValue(
          sourceTaskMetadata['checkpoint_review_path'],
        ),
        'origin_checkpoint_review_id': ValueReaders.stringValue(
          sourceTaskMetadata['checkpoint_review_id'],
        ),
      },
      'tool_hint':
          '这是正式审稿返修任务。先读取 review_contract、review_repair_handoff、审稿报告与目标文件，只修阻塞问题；修完后重新提交正式交付或复核，不要并行扩写其他任务。',
    };
  }

  List<String> _reportReferencePaths(String reviewReportPath) {
    final markdownPath = _reviewPathPolicyService.reviewMarkdownPath(
      reviewReportPath,
    );
    final jsonPath = _reviewPathPolicyService.reviewJsonPath(reviewReportPath);
    return <String>[
      if (markdownPath.isNotEmpty) markdownPath,
      if (jsonPath.isNotEmpty && jsonPath != markdownPath) jsonPath,
    ];
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      final clean = item.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  String _chapterScope(ReviewContract reviewContract) {
    final summary = reviewContract.basis.summary.trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    if (reviewContract.basis.targetPaths.isNotEmpty) {
      return reviewContract.basis.targetPaths.first;
    }
    if (reviewContract.basis.sourcePaths.isNotEmpty) {
      return reviewContract.basis.sourcePaths.first;
    }
    return reviewContract.reviewType;
  }

  String _briefFromRepairTask({
    required ReviewContract reviewContract,
    required RepairRequest repairRequest,
  }) {
    return '${reviewContract.reviewType}'
        '｜disposition=${reviewContract.recommendedDisposition}'
        '｜findings=${repairRequest.findingIds.length}'
        '。修复时优先读取共享 review_contract / repair_handoff，再回看审稿报告原文。';
  }
}
