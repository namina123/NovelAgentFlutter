import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_semantic_review_repository.dart';
import '../storage/open_narrative_state_path_service.dart';
import '../storage/project_task_repository.dart';
import 'project_semantic_review_information_service.dart';

class ProjectWorkflowReviewRuntimeService {
  ProjectWorkflowReviewRuntimeService({
    required ProjectTaskRepository taskRepository,
    SemanticReviewRepository? reviewRepository,
    ProjectSemanticReviewInformationService? semanticReviewInformationService,
    ChapterDeliveryStateMachine? chapterDeliveryStateMachine,
    OpenNarrativeStatePathService? pathService,
    ReviewReportNormalizerService? reviewReportNormalizerService,
    ReviewPathPolicyService? reviewPathPolicyService,
    NarrativeSemanticReviewContractMapperService?
    semanticReviewContractMapperService,
    ReviewSummaryBuilderService? reviewSummaryBuilderService,
    ReviewRepairHandoffService? reviewRepairHandoffService,
  }) : _taskRepository = taskRepository,
       _reviewRepository =
           reviewRepository ??
           LocalSemanticReviewRepository(
             workspacePort: taskRepository.workspacePort,
           ),
       _chapterDeliveryStateMachine =
           chapterDeliveryStateMachine ?? const ChapterDeliveryStateMachine(),
       _semanticReviewInformationService =
           semanticReviewInformationService ??
           ProjectSemanticReviewInformationService(
             workspacePort: taskRepository.workspacePort,
           ),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _reviewReportNormalizerService =
           reviewReportNormalizerService ?? ReviewReportNormalizerService(),
       _reviewPathPolicyService =
           reviewPathPolicyService ?? ReviewPathPolicyService(),
       _semanticReviewContractMapperService =
           semanticReviewContractMapperService ??
           NarrativeSemanticReviewContractMapperService(),
       _reviewSummaryBuilderService =
           reviewSummaryBuilderService ?? const ReviewSummaryBuilderService(),
       _reviewRepairHandoffService =
           reviewRepairHandoffService ?? const ReviewRepairHandoffService();

  final ProjectTaskRepository _taskRepository;
  final SemanticReviewRepository _reviewRepository;
  final ChapterDeliveryStateMachine _chapterDeliveryStateMachine;
  final ProjectSemanticReviewInformationService
  _semanticReviewInformationService;
  final OpenNarrativeStatePathService _pathService;
  final ReviewReportNormalizerService _reviewReportNormalizerService;
  final ReviewPathPolicyService _reviewPathPolicyService;
  final NarrativeSemanticReviewContractMapperService
  _semanticReviewContractMapperService;
  final ReviewSummaryBuilderService _reviewSummaryBuilderService;
  final ReviewRepairHandoffService _reviewRepairHandoffService;

  Future<JsonMap> preflightReviewTask({
    required ProjectDescriptor project,
    required JsonMap task,
  }) async {
    if (!_isChapterGateReview(task)) {
      return const <String, Object?>{'ok': true, 'action': 'execute_review'};
    }
    final sourceTask = await _loadGateSourceTask(project, task);
    if (sourceTask.isEmpty) {
      return const <String, Object?>{'ok': true, 'action': 'execute_review'};
    }
    final deliveryState = await _sourceDeliveryState(project, sourceTask);
    if (deliveryState.chapterBodyDelivered) {
      return <String, Object?>{
        'ok': true,
        'action': 'execute_review',
        'source_task': sourceTask,
        'delivery_state': deliveryState.toJson(),
      };
    }
    final recoveryTask = await _findOrCreateRecoveryTask(
      project: project,
      reviewTask: task,
      sourceTask: sourceTask,
      deliveryState: deliveryState,
    );
    final rewired = await _rewireDependents(
      project,
      predecessorTaskId: ValueReaders.stringValue(task['id']),
      repairTaskId: ValueReaders.stringValue(recoveryTask['id']),
    );
    return <String, Object?>{
      'ok': true,
      'action': 'skip_review_create_recovery',
      'delivery_state': deliveryState.toJson(),
      'source_task': sourceTask,
      'recovery_task': recoveryTask,
      'rewired_tasks': rewired,
      'changed_paths': <Object?>[
        ValueReaders.stringValue(recoveryTask['relative_path']),
        ...rewired.map(
          (item) => ValueReaders.stringValue(item['relative_path']),
        ),
      ],
    };
  }

  Future<JsonMap> persistSemanticReviewArtifacts({
    required ProjectDescriptor project,
    required JsonMap task,
    required List<Object?> executedTools,
  }) async {
    final reviews = _semanticReviewsFromExecutedTools(executedTools);
    if (reviews.isEmpty) {
      return const <String, Object?>{
        'ok': true,
        'review_ids': <Object?>[],
        'output_paths': <Object?>[],
        'changed_paths': <Object?>[],
      };
    }
    final changedPaths = <String>[];
    for (final review in reviews) {
      await _reviewRepository.appendReview(project, review);
      changedPaths.add(_pathService.reviewPath(review.reviewId));
    }
    changedPaths.add(_pathService.reviewsIndexPath());

    final primaryReview = reviews.last;
    final authorityPolicy = const ReviewAuthorityPolicy.standardProject();
    final reportPaths = _reportPaths(task);
    final markdownPath = reportPaths.$1;
    final jsonPath = reportPaths.$2;
    final reportCreatedAt = DateTime.now().toIso8601String();
    final semanticReviewContract = _semanticReviewContractMapperService
        .mapReview(
          review: primaryReview,
          reviewType: ValueReaders.stringValue(
            ValueReaders.mapValue(task['metadata'])['review_type'],
            ReviewTypeConstants.general,
          ),
          sourcePaths: ValueReaders.stringList(task['source_paths']),
          targetPaths: ValueReaders.stringList(task['output_paths']),
          reportPaths: <String>[
            if (markdownPath.isNotEmpty) markdownPath,
            if (jsonPath.isNotEmpty) jsonPath,
          ],
          createdAt: reportCreatedAt,
          metadata: <String, Object?>{
            'workflow_kind': 'workflow_task',
            'review_authority_policy': authorityPolicy.toJson(),
            'review_task_id': ValueReaders.stringValue(task['id']),
            'review_task_path': ValueReaders.stringValue(task['relative_path']),
          },
        );
    final semanticReviewSummary = _reviewSummaryBuilderService.buildSummary(
      semanticReviewContract,
    );
    final semanticReviewRepairHandoff = _reviewRepairHandoffService
        .handoffFromReview(semanticReviewContract);
    final report = _semanticReviewAsReport(task, primaryReview);
    final normalizedReport =
        _reviewReportNormalizerService.normalizeReport(
          report,
          generatedId: primaryReview.reviewId,
          createdAt: reportCreatedAt,
        )..addAll(<String, Object?>{
          'review_authority_policy': authorityPolicy.toJson(),
          'review_contract': semanticReviewContract.toJson(),
          'review_summary': semanticReviewSummary.toJson(),
          'review_repair_handoff': semanticReviewRepairHandoff.toJson(),
        });
    if (jsonPath.isNotEmpty) {
      await _taskRepository.saveRecord(project, jsonPath, normalizedReport);
      changedPaths.add(jsonPath);
    }
    if (markdownPath.isNotEmpty) {
      await _taskRepository.writeTextFile(
        project,
        markdownPath,
        _reviewReportMarkdown(normalizedReport),
      );
      changedPaths.add(markdownPath);
    }
    final informationArtifacts = await _semanticReviewInformationService
        .persist(project: project, reviews: reviews);
    changedPaths.addAll(
      ValueReaders.stringList(informationArtifacts['changed_paths']),
    );
    return <String, Object?>{
      'ok': true,
      'review_ids': reviews
          .map((item) => item.reviewId)
          .toList(growable: false),
      'primary_review_id': primaryReview.reviewId,
      'primary_review': primaryReview.toJson(),
      'report': normalizedReport,
      'report_markdown_path': markdownPath,
      'report_json_path': jsonPath,
      'semantic_review_authority_policy': authorityPolicy.toJson(),
      'semantic_review_contract': semanticReviewContract.toJson(),
      'semantic_review_summary': semanticReviewSummary.toJson(),
      'semantic_review_repair_handoff': semanticReviewRepairHandoff.toJson(),
      'output_paths': <Object?>[
        if (markdownPath.isNotEmpty) markdownPath,
        if (jsonPath.isNotEmpty) jsonPath,
        ...ValueReaders.stringList(informationArtifacts['output_paths']),
      ],
      'analysis_information': informationArtifacts,
      'changed_paths': changedPaths,
    };
  }

  JsonMap attachReviewArtifacts(JsonMap execution, JsonMap artifacts) {
    final next = ValueReaders.deepCopyMap(execution);
    final reviewIds = ValueReaders.stringList(artifacts['review_ids']);
    if (reviewIds.isNotEmpty) {
      next['semantic_review_ids'] = reviewIds;
      next['primary_semantic_review_id'] = ValueReaders.stringValue(
        artifacts['primary_review_id'],
      );
      next['semantic_review_report_path'] = ValueReaders.stringValue(
        artifacts['report_markdown_path'],
      );
      next['semantic_review_report_json_path'] = ValueReaders.stringValue(
        artifacts['report_json_path'],
      );
      next['semantic_review'] = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(artifacts['primary_review']),
      );
      next['semantic_review_authority_policy'] = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(artifacts['semantic_review_authority_policy']),
      );
      next['semantic_review_contract'] = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(artifacts['semantic_review_contract']),
      );
      next['semantic_review_summary'] = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(artifacts['semantic_review_summary']),
      );
      next['semantic_review_repair_handoff'] = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(artifacts['semantic_review_repair_handoff']),
      );
    }
    final analysisInformation = ValueReaders.mapValue(
      artifacts['analysis_information'],
    );
    if (analysisInformation.isNotEmpty) {
      next['analysis_information'] = ValueReaders.deepCopyMap(
        analysisInformation,
      );
      next['analysis_information_changed_paths'] = ValueReaders.stringList(
        analysisInformation['changed_paths'],
      );
    }
    return next;
  }

  bool _isChapterGateReview(JsonMap task) {
    return ValueReaders.stringValue(task['task_type']) == 'review' &&
        ValueReaders.stringValue(
              ValueReaders.mapValue(task['metadata'])['origin'],
            ) ==
            'chapter_gate_review';
  }

  Future<JsonMap> _loadGateSourceTask(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final sourceTaskId = ValueReaders.stringValue(
      metadata['gate_source_task_id'],
      ValueReaders.stringList(task['depends_on']).isEmpty
          ? ''
          : ValueReaders.stringList(task['depends_on']).first,
    ).trim();
    if (sourceTaskId.isEmpty) {
      return <String, Object?>{};
    }
    return _taskRepository.loadTask(project, <String, Object?>{
      'id': sourceTaskId,
    });
  }

  Future<ChapterDeliveryStateResult> _sourceDeliveryState(
    ProjectDescriptor project,
    JsonMap sourceTask,
  ) async {
    final outputPaths = ValueReaders.stringList(sourceTask['output_paths']);
    final chapterPath = outputPaths.isEmpty ? '' : outputPaths.first;
    final content = chapterPath.isEmpty
        ? ''
        : (await _taskRepository.readTextFile(project, chapterPath) ?? '');
    return _chapterDeliveryStateMachine.evaluate(
      ChapterDeliveryStateRequest(
        deliveryId:
            'review-preflight:${ValueReaders.stringValue(sourceTask['id'])}',
        chapterPath: chapterPath,
        resolvedChapterPath: chapterPath,
        chapterContent: content,
        title: ValueReaders.stringValue(sourceTask['title']),
        writeSucceeded: true,
      ),
    );
  }

  Future<JsonMap> _findOrCreateRecoveryTask({
    required ProjectDescriptor project,
    required JsonMap reviewTask,
    required JsonMap sourceTask,
    required ChapterDeliveryStateResult deliveryState,
  }) async {
    final existing = await _findExistingRecoveryTask(
      project,
      ValueReaders.stringValue(sourceTask['id']),
    );
    if (existing.isNotEmpty) {
      return existing;
    }
    final sourceMetadata = ValueReaders.mapValue(sourceTask['metadata']);
    final outputPaths = ValueReaders.stringList(sourceTask['output_paths']);
    final now = DateTime.now().toIso8601String();
    final recoveryTask = <String, Object?>{
      'schema_version': 1,
      'id':
          '${ValueReaders.stringValue(sourceTask['id'], 'chapter')}_delivery_recovery',
      'title':
          '恢复章节交付：${ValueReaders.stringValue(sourceTask['title'], '未命名章节')}',
      'task_type': 'revision',
      'mode': ValueReaders.stringValue(
        sourceTask['mode'],
        TaskRuntimeConstants.modeSingleChapterAtomic,
      ),
      'status': TaskRuntimeConstants.statusQueued,
      'chapter': ValueReaders.stringValue(sourceTask['chapter']),
      'goal':
          '只修复当前章节交付缺口并重新提交正式章节交付。当前检测状态：${deliveryState.state}。不要扩写下一章、不要改总纲、不要并行处理其他任务。',
      'brief':
          '恢复当前失败章节交付｜state=${deliveryState.state}｜reason=${deliveryState.reason}',
      'depends_on': <Object?>[
        if (ValueReaders.stringValue(sourceTask['id']).trim().isNotEmpty)
          ValueReaders.stringValue(sourceTask['id']),
      ],
      'source_paths': _mergePaths(
        ValueReaders.stringList(sourceTask['source_paths']),
        <String>[
          ...outputPaths,
          ValueReaders.stringValue(sourceTask['atomic_execution_path']),
          ...ValueReaders.stringList(
            sourceMetadata['persistent_context_paths'],
          ),
        ],
      ),
      'output_paths': outputPaths,
      'metadata': <String, Object?>{
        'origin': 'chapter_gate_missing_output_recovery',
        'runtime_baseline_id': ValueReaders.stringValue(
          sourceMetadata['runtime_baseline_id'],
        ),
        'workflow_mode': ValueReaders.stringValue(sourceTask['mode']),
        'persistent_context_paths': ValueReaders.stringList(
          sourceMetadata['persistent_context_paths'],
        ),
        'gate_source_task_id': ValueReaders.stringValue(sourceTask['id']),
        'gate_source_task_path': ValueReaders.stringValue(
          sourceTask['relative_path'],
        ),
        'gate_review_task_id': ValueReaders.stringValue(reviewTask['id']),
        'gate_review_task_path': ValueReaders.stringValue(
          reviewTask['relative_path'],
        ),
        'delivery_state': deliveryState.state,
        'delivery_reason': deliveryState.reason,
        'recovery_target': 'chapter_delivery',
      },
      'tool_hint':
          '这是缺正文/坏正文优先 recovery 任务。先读取原章节目标和已有产物，只修当前失败目标；正文达到要求后用 submit_chapter_delivery 重新交付，不要扩展到下一章或无关修订。',
      'created_at': now,
      'updated_at': now,
      'history': <Object?>[
        <String, Object?>{
          'status': TaskRuntimeConstants.statusQueued,
          'note':
              'Chapter delivery recovery task generated before semantic review.',
          'created_at': now,
        },
      ],
    };
    return _taskRepository.saveTask(project, recoveryTask);
  }

  Future<JsonMap> _findExistingRecoveryTask(
    ProjectDescriptor project,
    String sourceTaskId,
  ) async {
    final tasks = await _taskRepository.listTasks(project);
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['task_type']) != 'revision') {
        continue;
      }
      final metadata = ValueReaders.mapValue(task['metadata']);
      if (ValueReaders.stringValue(metadata['origin']) !=
          'chapter_gate_missing_output_recovery') {
        continue;
      }
      if (ValueReaders.stringValue(metadata['gate_source_task_id']) ==
          sourceTaskId) {
        return task;
      }
    }
    return <String, Object?>{};
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

  List<NarrativeSemanticReview> _semanticReviewsFromExecutedTools(
    List<Object?> executedTools,
  ) {
    final result = <NarrativeSemanticReview>[];
    for (final rawTool in executedTools) {
      _collectSemanticReviewsFromTool(
        ValueReaders.mapValue(rawTool),
        into: result,
      );
    }
    return result;
  }

  void _collectSemanticReviewsFromTool(
    JsonMap tool, {
    required List<NarrativeSemanticReview> into,
  }) {
    final name = ValueReaders.stringValue(tool['name']).trim();
    if (name == 'submit_semantic_review') {
      final payload = ValueReaders.mapValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(tool['result'])['domain_outcome'],
        )['outcome_payload'],
      );
      final reviewJson = ValueReaders.mapValue(payload['review']);
      if (reviewJson.isNotEmpty) {
        into.add(NarrativeSemanticReview.fromJson(reviewJson));
      }
      return;
    }
    if (name != 'call_sub_agent') {
      return;
    }
    final nestedTools = ValueReaders.objectList(
      ValueReaders.mapValue(tool['result'])['tool_calls'],
    );
    for (final nestedTool in nestedTools) {
      _collectSemanticReviewsFromTool(
        ValueReaders.mapValue(nestedTool),
        into: into,
      );
    }
  }

  (String, String) _reportPaths(JsonMap task) {
    String markdownPath = '';
    String jsonPath = '';
    for (final path in ValueReaders.stringList(task['output_paths'])) {
      final normalized = path.trim().replaceAll('\\', '/');
      if (markdownPath.isEmpty) {
        markdownPath = _reviewPathPolicyService.reviewMarkdownPath(normalized);
      }
      if (jsonPath.isEmpty) {
        jsonPath = _reviewPathPolicyService.reviewJsonPath(normalized);
      }
    }
    return (markdownPath, jsonPath);
  }

  JsonMap _semanticReviewAsReport(
    JsonMap task,
    NarrativeSemanticReview review,
  ) {
    final reviewType = ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['review_type'],
      ReviewTypeConstants.general,
    );
    final issues = review.findings
        .where(
          (finding) =>
              finding.severity == SemanticReviewSeverity.blocking ||
              finding.severity == SemanticReviewSeverity.high ||
              finding.severity == SemanticReviewSeverity.medium,
        )
        .map(
          (finding) => <String, Object?>{
            'title': finding.summary,
            'severity': _reportSeverity(finding.severity),
            'detail': finding.unableToLocateEvidence
                ? finding.unlocatableReason
                : '',
            'suggestion': finding.suggestedAction,
          },
        )
        .toList(growable: false);
    final suggestions = review.findings
        .where(
          (finding) =>
              finding.severity == SemanticReviewSeverity.low ||
              finding.severity == SemanticReviewSeverity.info,
        )
        .map((finding) => finding.summary)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    return <String, Object?>{
      'id': review.reviewId,
      'review_type': reviewType,
      'title': ValueReaders.stringValue(task['title'], '语义复核'),
      'scope': ValueReaders.stringValue(
        task['chapter'],
        ValueReaders.stringValue(task['title']),
      ),
      'summary': review.summary,
      'issues': issues,
      'suggestions': suggestions,
      'source_paths': ValueReaders.stringList(task['source_paths']),
      'metadata': <String, Object?>{
        'semantic_review_id': review.reviewId,
        'recommended_disposition': review.recommendedDisposition.id,
      },
    };
  }

  String _reviewReportMarkdown(JsonMap report) {
    final lines = <String>[
      '# ${ValueReaders.stringValue(report['title'], '语义复核')}',
      '',
      '- 范围：${ValueReaders.stringValue(report['scope'], '当前范围')}',
      '- 类型：${ValueReaders.stringValue(report['review_type'], ReviewTypeConstants.general)}',
      '',
      '## 摘要',
      ValueReaders.stringValue(report['summary']),
    ];
    final issues = ValueReaders.mapList(report['issues']);
    if (issues.isNotEmpty) {
      lines
        ..add('')
        ..add('## Issues');
      for (final issue in issues) {
        lines.add(
          '- [${ValueReaders.stringValue(issue['severity'], 'normal')}] ${ValueReaders.stringValue(issue['title'])}',
        );
        final suggestion = ValueReaders.stringValue(issue['suggestion']);
        if (suggestion.trim().isNotEmpty) {
          lines.add('  - 建议：$suggestion');
        }
      }
    }
    final suggestions = ValueReaders.stringList(report['suggestions']);
    if (suggestions.isNotEmpty) {
      lines
        ..add('')
        ..add('## Suggestions');
      for (final item in suggestions) {
        lines.add('- $item');
      }
    }
    return lines.join('\n');
  }

  String _reportSeverity(SemanticReviewSeverity severity) {
    switch (severity) {
      case SemanticReviewSeverity.blocking:
        return 'critical';
      case SemanticReviewSeverity.high:
        return 'high';
      case SemanticReviewSeverity.medium:
        return 'medium';
      case SemanticReviewSeverity.low:
        return 'low';
      case SemanticReviewSeverity.info:
        return 'normal';
    }
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
}
