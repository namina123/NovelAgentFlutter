import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_review_repair_task_service.dart';

class ProjectLongTaskChapterGateService {
  ProjectLongTaskChapterGateService({
    required ProjectTaskRepository taskRepository,
    required ProjectReviewReportService reviewReportService,
    required ProjectLongTaskReviewRepairTaskService reviewRepairTaskService,
    LongTaskChapterGatePolicyService? chapterGatePolicyService,
  }) : _taskRepository = taskRepository,
       _reviewReportService = reviewReportService,
       _reviewRepairTaskService = reviewRepairTaskService,
       _chapterGatePolicyService =
           chapterGatePolicyService ?? const LongTaskChapterGatePolicyService();

  final ProjectTaskRepository _taskRepository;
  final ProjectReviewReportService _reviewReportService;
  final ProjectLongTaskReviewRepairTaskService _reviewRepairTaskService;
  final LongTaskChapterGatePolicyService _chapterGatePolicyService;

  Future<JsonMap> applyReviewOutcome({
    required ProjectDescriptor project,
    required JsonMap task,
  }) async {
    // 中文注释: 章级闸门编排只负责“审稿结果 -> 是否派生返工 -> 是否改挂下游依赖”。
    final metadata = ValueReaders.mapValue(task['metadata']);
    final runtimeBaselineId = _chapterGatePolicyService
        .runtimeBaselineIdForTask(task);
    if (ValueReaders.stringValue(task['task_type']) != 'review' ||
        ValueReaders.stringValue(metadata['origin']) != 'chapter_gate_review' ||
        runtimeBaselineId != 'chapter_collaboration_autorun') {
      return const <String, Object?>{
        'ok': true,
        'action': 'noop',
        'changed_paths': <Object?>[],
      };
    }
    final reviewReportPath = _resolveReviewReportPath(task, metadata);
    if (reviewReportPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Chapter gate review report path is missing.',
        'action': 'missing_review_report',
        'changed_paths': const <Object?>[],
      };
    }
    final loaded = await _reviewReportService.loadReport(
      project,
      reviewReportPath,
    );
    if (!ValueReaders.boolValue(loaded['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          loaded['error'],
          'Chapter gate review report not found.',
        ),
        'action': 'missing_review_report',
        'review_report_path': reviewReportPath,
        'changed_paths': const <Object?>[],
      };
    }
    final decision = _chapterGatePolicyService.reviewOutcomeDecision(
      ValueReaders.mapValue(loaded['report']),
      runtimeBaselineId: runtimeBaselineId,
    );
    if (ValueReaders.stringValue(decision['action']) != 'create_repair_task') {
      return <String, Object?>{
        'ok': true,
        'action': ValueReaders.stringValue(decision['action'], 'pass_gate'),
        'gate_decision': decision,
        'gate_disposition': ValueReaders.stringValue(decision['disposition']),
        'gate_reason': ValueReaders.stringValue(decision['reason']),
        'blocks_auto_advance': ValueReaders.boolValue(
          decision['blocks_auto_advance'],
        ),
        'manual_attention_required': ValueReaders.boolValue(
          decision['manual_attention_required'],
        ),
        'review_report_path': ValueReaders.stringValue(loaded['markdown_path']),
        'changed_paths': const <Object?>[],
      };
    }
    final created = await _reviewRepairTaskService.createTask(
      project: project,
      task: task,
      reviewReportPath: ValueReaders.stringValue(loaded['markdown_path']),
    );
    if (!ValueReaders.boolValue(created['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          created['error'],
          'Failed to create chapter gate repair task.',
        ),
        'action': 'create_repair_task',
        'gate_decision': decision,
        'review_report_path': ValueReaders.stringValue(loaded['markdown_path']),
        'changed_paths': ValueReaders.objectList(created['changed_paths']),
      };
    }
    final repairTask = ValueReaders.mapValue(created['task']);
    if (repairTask.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Chapter gate repair task is empty.',
        'action': 'create_repair_task',
        'gate_decision': decision,
        'review_report_path': ValueReaders.stringValue(loaded['markdown_path']),
        'changed_paths': ValueReaders.objectList(created['changed_paths']),
      };
    }
    final rewired = await _rewireDependents(
      project,
      predecessorTaskId: ValueReaders.stringValue(task['id']),
      repairTaskId: ValueReaders.stringValue(repairTask['id']),
    );
    return <String, Object?>{
      'ok': true,
      'action': 'create_repair_task',
      'gate_decision': decision,
      'gate_disposition': ValueReaders.stringValue(decision['disposition']),
      'gate_reason': ValueReaders.stringValue(decision['reason']),
      'blocks_auto_advance': ValueReaders.boolValue(
        decision['blocks_auto_advance'],
      ),
      'manual_attention_required': ValueReaders.boolValue(
        decision['manual_attention_required'],
      ),
      'review_report_path': ValueReaders.stringValue(loaded['markdown_path']),
      'repair_task': repairTask,
      'rewired_tasks': rewired,
      'changed_paths': <Object?>[
        ...ValueReaders.objectList(created['changed_paths']),
        ...rewired.map(
          (item) => ValueReaders.stringValue(item['relative_path']),
        ),
      ],
    };
  }

  String _resolveReviewReportPath(JsonMap task, JsonMap metadata) {
    final metadataPath = ValueReaders.stringValue(
      metadata['review_report_path'],
    ).trim();
    if (metadataPath.isNotEmpty) {
      return metadataPath;
    }
    for (final path in ValueReaders.stringList(task['output_paths'])) {
      final clean = path.trim().replaceAll('\\', '/');
      if (clean.startsWith('reviews/') &&
          (clean.toLowerCase().endsWith('.md') ||
              clean.toLowerCase().endsWith('.json'))) {
        return clean;
      }
    }
    return '';
  }

  Future<List<JsonMap>> _rewireDependents(
    ProjectDescriptor project, {
    required String predecessorTaskId,
    required String repairTaskId,
  }) async {
    final tasks = await _taskRepository.listTasks(project);
    final updated = <JsonMap>[];
    for (final task in tasks) {
      final taskId = ValueReaders.stringValue(task['id']);
      if (taskId.isEmpty ||
          taskId == predecessorTaskId ||
          taskId == repairTaskId) {
        continue;
      }
      final dependsOn = ValueReaders.stringList(task['depends_on']);
      if (!dependsOn.contains(predecessorTaskId)) {
        continue;
      }
      final nextDependsOn = <String>[];
      for (final dependency in dependsOn) {
        final candidate = dependency == predecessorTaskId
            ? repairTaskId
            : dependency;
        if (candidate.isNotEmpty && !nextDependsOn.contains(candidate)) {
          nextDependsOn.add(candidate);
        }
      }
      final saved = await _taskRepository.saveTask(
        project,
        ValueReaders.deepCopyMap(task)..['depends_on'] = nextDependsOn,
      );
      updated.add(saved);
    }
    return updated;
  }
}
