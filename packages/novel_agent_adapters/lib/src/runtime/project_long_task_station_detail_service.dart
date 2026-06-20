import 'package:novel_agent_core/novel_agent_core.dart';

import '../projection/expression_constraint_status_projection.dart';
import '../projection/expression_constraint_status_projection_service.dart';
import '../projection/information_evidence_projection.dart';
import '../projection/information_evidence_projection_item.dart';
import '../projection/information_evidence_projection_service.dart';
import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_station_blocker_summary.dart';
import 'project_long_task_station_chain_item.dart';
import 'project_long_task_station_chain_summary.dart';
import 'project_long_task_station_detail.dart';
import 'project_long_task_station_item_summary.dart';
import 'project_long_task_station_narrative_summary.dart';

class ProjectLongTaskStationDetailService {
  static const String _continuityRoot = '.novel_agent/continuity/';
  static const String _ledgerRoot = '.novel_agent/continuity/ledgers/';
  static const String _claimsRoot = '.novel_agent/continuity/claims/';
  static const String _reviewsRoot = '.novel_agent/continuity/reviews/';
  static const String _deliveriesRoot = '.novel_agent/continuity/deliveries/';
  static const String _profileProposalsRoot =
      '.novel_agent/continuity/profile_proposals/';
  static const String _clarificationsRoot =
      '.novel_agent/continuity/clarifications/';
  static const String _informationRoot = '.novel_agent/information/';
  static const String _knowledgeCardsRoot =
      '.novel_agent/information/knowledge_cards/';
  static const String _designElementsRoot =
      '.novel_agent/information/design_elements/';
  static const String _researchNotesRoot =
      '.novel_agent/information/research_notes/';
  static const String _researchRequestsRoot =
      '.novel_agent/information/research_requests/';
  static const String _referenceWorksRoot =
      '.novel_agent/information/reference_works/';

  ProjectLongTaskStationDetailService({
    required ProjectTaskRepository taskRepository,
    required ProjectReviewReportService reviewReportService,
    TaskChainViewService? taskChainViewService,
    InformationEvidenceProjectionService? informationEvidenceProjectionService,
    ExpressionConstraintStatusProjectionService?
    expressionConstraintStatusProjectionService,
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
  }) : _taskRepository = taskRepository,
       _reviewReportService = reviewReportService,
       _taskChainViewService = taskChainViewService ?? TaskChainViewService(),
       _informationEvidenceProjectionService =
           informationEvidenceProjectionService ??
           const InformationEvidenceProjectionService(),
       _expressionConstraintStatusProjectionService =
           expressionConstraintStatusProjectionService ??
           const ExpressionConstraintStatusProjectionService(),
       _stopDiagnosisProjectionService =
           stopDiagnosisProjectionService ??
           const LongTaskStopDiagnosisProjectionService();

  final ProjectTaskRepository _taskRepository;
  final ProjectReviewReportService _reviewReportService;
  final TaskChainViewService _taskChainViewService;
  final InformationEvidenceProjectionService
  _informationEvidenceProjectionService;
  final ExpressionConstraintStatusProjectionService
  _expressionConstraintStatusProjectionService;
  final LongTaskStopDiagnosisProjectionService _stopDiagnosisProjectionService;

  Future<ProjectLongTaskStationDetail> loadForRun(RunInstance run) async {
    // 中文注释: 长任务总站详情只读项目内任务、审稿和运行记录，不在这里触发任何调度或状态迁移。
    final project = _projectFromReference(run.project);
    final tasks = await _taskRepository.listTasks(project);
    final runRecord = await _loadRunRecord(project, run.id);
    final activeTask = _resolveActiveTask(tasks, run, runRecord: runRecord);
    final chain = _resolveChain(tasks, activeTask: activeTask, run: run);
    final relatedTasks = _resolveRelatedTasks(
      allTasks: tasks,
      chain: chain,
      activeTask: activeTask,
    );
    final latestCheckpointReview = await _loadCheckpointSummary(
      project,
      relatedTasks,
      runRecord: runRecord,
    );
    final latestRepairTask = _resolveLatestRepairTask(relatedTasks);
    final latestReviewReport = await _loadReviewSummary(
      project,
      relatedTasks,
      latestRepairTask: latestRepairTask,
    );
    final narrativeSummary = await _loadNarrativeSummary(
      project,
      activeTask: activeTask,
      runRecord: runRecord,
      latestReviewReport: latestReviewReport,
    );
    return ProjectLongTaskStationDetail(
      activeTask: _taskSummary(activeTask),
      chain: chain,
      latestCheckpointReview: latestCheckpointReview,
      latestReviewReport: latestReviewReport,
      latestRepairTask: latestRepairTask,
      narrativeSummary: narrativeSummary,
      blocker: _buildBlocker(
        run,
        activeTask: activeTask,
        chain: chain,
        runRecord: runRecord,
        latestCheckpointReview: latestCheckpointReview,
        latestReviewReport: latestReviewReport,
        narrativeSummary: narrativeSummary,
      ),
    );
  }

  ProjectDescriptor _projectFromReference(RunProjectReference reference) {
    return ProjectDescriptor(
      id: reference.projectId,
      name: reference.title,
      rootPath: reference.rootPath,
      projectType: reference.projectTypeId,
      storageStrategy: reference.storageStrategy,
    );
  }

  Future<JsonMap> _loadRunRecord(
    ProjectDescriptor project,
    String runId,
  ) async {
    // 中文注释: 全局运行实例和项目内长任务运行记录之间通过 run id 对齐，找不到时再回退最近记录。
    final records = await _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/long_task_runs/',
      limit: 200,
    );
    for (final record in records) {
      if (ValueReaders.stringValue(record['id']) == runId.trim()) {
        return record;
      }
    }
    return records.isEmpty ? const <String, Object?>{} : records.first;
  }

  JsonMap _resolveActiveTask(
    List<JsonMap> tasks,
    RunInstance run, {
    required JsonMap runRecord,
  }) {
    final activeTaskId = run.activeTaskId.trim();
    final activeTaskTitle = run.activeTaskTitle.trim();
    final lastTaskId = ValueReaders.stringValue(
      runRecord['last_task_id'],
    ).trim();
    for (final task in tasks) {
      if (_matchesTaskIdentity(task, activeTaskId) ||
          _matchesTaskIdentity(task, lastTaskId)) {
        return task;
      }
    }
    if (activeTaskTitle.isNotEmpty) {
      for (final task in tasks) {
        if (ValueReaders.stringValue(task['title']).trim() == activeTaskTitle) {
          return task;
        }
      }
    }
    return const <String, Object?>{};
  }

  bool _matchesTaskIdentity(JsonMap task, String identity) {
    final cleanIdentity = identity.trim();
    if (cleanIdentity.isEmpty) {
      return false;
    }
    return ValueReaders.stringValue(task['id']).trim() == cleanIdentity ||
        ValueReaders.stringValue(task['relative_path']).trim() == cleanIdentity;
  }

  ProjectLongTaskStationChainSummary? _resolveChain(
    List<JsonMap> tasks, {
    required JsonMap activeTask,
    required RunInstance run,
  }) {
    final chainView = _taskChainViewService.buildView(tasks);
    final chains = ValueReaders.mapList(chainView['chains']);
    if (chains.isEmpty) {
      return null;
    }
    JsonMap selectedChain = const <String, Object?>{};
    final activePlanId = ValueReaders.stringValue(
      ValueReaders.mapValue(activeTask['metadata'])['plan_id'],
    ).trim();
    if (activePlanId.isNotEmpty) {
      for (final chain in chains) {
        if (ValueReaders.stringValue(chain['plan_id']).trim() == activePlanId) {
          selectedChain = chain;
          break;
        }
      }
    }
    if (selectedChain.isEmpty && run.activeTaskId.trim().isNotEmpty) {
      for (final chain in chains) {
        for (final node in ValueReaders.mapList(chain['nodes'])) {
          if (_matchesChainNode(node, run.activeTaskId)) {
            selectedChain = chain;
            break;
          }
        }
        if (selectedChain.isNotEmpty) {
          break;
        }
      }
    }
    if (selectedChain.isEmpty && run.activeTaskTitle.trim().isNotEmpty) {
      for (final chain in chains) {
        for (final node in ValueReaders.mapList(chain['nodes'])) {
          if (ValueReaders.stringValue(node['title']).trim() ==
              run.activeTaskTitle.trim()) {
            selectedChain = chain;
            break;
          }
        }
        if (selectedChain.isNotEmpty) {
          break;
        }
      }
    }
    if (selectedChain.isEmpty) {
      selectedChain = chains.first;
    }
    final nextRunnableId = ValueReaders.stringValue(
      selectedChain['next_runnable_id'],
    ).trim();
    final blockingCheckpointTitles = ValueReaders.stringList(
      selectedChain['blocking_checkpoints'],
    );
    final items = ValueReaders.mapList(selectedChain['nodes'])
        .map(
          (node) => ProjectLongTaskStationChainItem(
            id: ValueReaders.stringValue(node['id']),
            title: ValueReaders.stringValue(node['title'], '未命名任务'),
            relativePath: ValueReaders.stringValue(node['relative_path']),
            status: ValueReaders.stringValue(node['status']),
            taskType: ValueReaders.stringValue(node['task_type']),
            sortOrder: ValueReaders.intValue(node['sort_order']),
            isActive: _matchesChainNode(node, run.activeTaskId),
            isNextRunnable:
                ValueReaders.stringValue(node['id']).trim() == nextRunnableId,
            isBlockingCheckpoint:
                ValueReaders.boolValue(node['manual_checkpoint']) &&
                ValueReaders.stringValue(node['status']) ==
                    TaskRuntimeConstants.statusWaitingUser,
          ),
        )
        .toList(growable: false);
    final mode = ValueReaders.stringValue(selectedChain['mode']).trim();
    final subtitleParts = <String>[
      mode.isEmpty ? '未标注模式' : mode,
      '节点 ${items.length}',
    ];
    final nextRunnableTitle = ValueReaders.stringValue(
      selectedChain['next_runnable_title'],
      '无',
    );
    if (nextRunnableTitle.trim().isNotEmpty &&
        nextRunnableTitle.trim() != '无') {
      subtitleParts.add('下一步 $nextRunnableTitle');
    }
    return ProjectLongTaskStationChainSummary(
      title: ValueReaders.stringValue(selectedChain['title'], '当前任务链'),
      subtitle: subtitleParts.join(' · '),
      nextRunnableTitle: nextRunnableTitle,
      blockingCheckpointTitles: blockingCheckpointTitles,
      items: items,
    );
  }

  bool _matchesChainNode(JsonMap node, String identity) {
    final cleanIdentity = identity.trim();
    if (cleanIdentity.isEmpty) {
      return false;
    }
    return ValueReaders.stringValue(node['id']).trim() == cleanIdentity ||
        ValueReaders.stringValue(node['relative_path']).trim() == cleanIdentity;
  }

  List<JsonMap> _resolveRelatedTasks({
    required List<JsonMap> allTasks,
    required ProjectLongTaskStationChainSummary? chain,
    required JsonMap activeTask,
  }) {
    // 中文注释: 总站优先围绕当前链路看最近 checkpoint/review/repair，避免不同计划的旧任务互相串味。
    final byPath = <String, JsonMap>{};
    for (final task in allTasks) {
      final path = ValueReaders.stringValue(task['relative_path']).trim();
      if (path.isNotEmpty) {
        byPath[path] = task;
      }
    }
    final byId = <String, JsonMap>{};
    for (final task in allTasks) {
      final id = ValueReaders.stringValue(task['id']).trim();
      if (id.isNotEmpty) {
        byId[id] = task;
      }
    }
    final result = <JsonMap>[];
    if (chain != null) {
      for (final item in chain.items) {
        final task =
            byPath[item.relativePath] ??
            byId[item.id] ??
            const <String, Object?>{};
        if (task.isNotEmpty) {
          result.add(task);
        }
      }
    }
    if (activeTask.isNotEmpty &&
        !result.any(
          (task) =>
              ValueReaders.stringValue(task['relative_path']) ==
              ValueReaders.stringValue(activeTask['relative_path']),
        )) {
      result.add(activeTask);
    }
    if (result.isEmpty) {
      result.addAll(allTasks);
    }
    result.sort(_compareTasksByUpdatedAtDesc);
    return result;
  }

  int _compareTasksByUpdatedAtDesc(JsonMap left, JsonMap right) {
    final leftUpdated = ValueReaders.stringValue(
      left['updated_at'],
      ValueReaders.stringValue(left['created_at']),
    );
    final rightUpdated = ValueReaders.stringValue(
      right['updated_at'],
      ValueReaders.stringValue(right['created_at']),
    );
    return rightUpdated.compareTo(leftUpdated);
  }

  Future<ProjectLongTaskStationItemSummary?> _loadCheckpointSummary(
    ProjectDescriptor project,
    List<JsonMap> tasks, {
    required JsonMap runRecord,
  }) async {
    final paths = <String>[
      ValueReaders.stringValue(runRecord['last_checkpoint_review_path']),
      ...tasks.expand(_checkpointReviewCandidatesForTask),
    ];
    final checkpointPath = _firstNonEmptyDistinct(paths);
    if (checkpointPath.isEmpty) {
      return null;
    }
    final record = await _taskRepository.loadRecord(project, checkpointPath);
    if (record.isEmpty) {
      return null;
    }
    final summary = ValueReaders.stringValue(
      record['action_summary'],
      ValueReaders.stringValue(record['summary']),
    );
    final subtitleParts = <String>[
      ValueReaders.stringValue(record['severity'], '未标注严重度'),
    ];
    final continuation = ValueReaders.stringValue(
      record['continuation_disposition'],
    ).trim();
    if (continuation.isNotEmpty) {
      subtitleParts.add(continuation);
    }
    return ProjectLongTaskStationItemSummary(
      id: ValueReaders.stringValue(record['id'], checkpointPath),
      title: ValueReaders.stringValue(record['title'], '最近检查点复盘'),
      relativePath: checkpointPath,
      status: ValueReaders.stringValue(record['severity']),
      subtitle: subtitleParts
          .where((item) => item.trim().isNotEmpty)
          .join(' · '),
      summary: summary.trim(),
    );
  }

  Iterable<String> _checkpointReviewCandidatesForTask(JsonMap task) sync* {
    final metadata = ValueReaders.mapValue(task['metadata']);
    yield ValueReaders.stringValue(task['checkpoint_review_path']);
    yield ValueReaders.stringValue(task['postprocess_checkpoint_review_path']);
    yield ValueReaders.stringValue(task['continued_checkpoint_review_path']);
    yield ValueReaders.stringValue(task['confirmed_checkpoint_review_path']);
    yield ValueReaders.stringValue(metadata['checkpoint_review_path']);
    yield ValueReaders.stringValue(metadata['origin_checkpoint_review_path']);
    yield ValueReaders.stringValue(
      task['followup_request_checkpoint_review_path'],
    );
    yield ValueReaders.stringValue(
      metadata['followup_request_checkpoint_review_path'],
    );
  }

  Future<ProjectLongTaskStationItemSummary?> _loadReviewSummary(
    ProjectDescriptor project,
    List<JsonMap> tasks, {
    required ProjectLongTaskStationItemSummary? latestRepairTask,
  }) async {
    final repairPath = latestRepairTask?.relativePath ?? '';
    final reviewCandidates = <String>[
      if (repairPath.isNotEmpty)
        ...tasks
            .where(
              (task) =>
                  ValueReaders.stringValue(task['relative_path']) == repairPath,
            )
            .expand(_reviewReportCandidatesForTask),
      ...tasks.expand(_reviewReportCandidatesForTask),
    ];
    final reviewPath = _firstNonEmptyDistinct(reviewCandidates);
    if (reviewPath.isEmpty) {
      return null;
    }
    final loaded = await _reviewReportService.loadReport(project, reviewPath);
    if (!ValueReaders.boolValue(loaded['ok'])) {
      return null;
    }
    final report = ValueReaders.mapValue(loaded['report']);
    return ProjectLongTaskStationItemSummary(
      id: ValueReaders.stringValue(report['id'], reviewPath),
      title: ValueReaders.stringValue(report['title'], '最近审稿报告'),
      relativePath: ValueReaders.stringValue(
        loaded['markdown_path'],
        reviewPath,
      ),
      status: ValueReaders.stringValue(report['review_type']),
      subtitle: ValueReaders.stringValue(
        report['scope'],
        ValueReaders.stringValue(report['review_type']),
      ),
      summary: ValueReaders.stringValue(
        report['summary'],
        ValueReaders.stringValue(loaded['markdown_body']),
      ).trim(),
    );
  }

  Future<ProjectLongTaskStationNarrativeSummary?> _loadNarrativeSummary(
    ProjectDescriptor project, {
    required JsonMap activeTask,
    required JsonMap runRecord,
    required ProjectLongTaskStationItemSummary? latestReviewReport,
  }) async {
    final metadata = ValueReaders.mapValue(activeTask['metadata']);
    final executionPath = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(activeTask['atomic_execution_path']),
      ValueReaders.stringValue(metadata['atomic_execution_path']),
    ]);
    final execution = executionPath.isEmpty
        ? const <String, Object?>{}
        : await _taskRepository.loadRecord(project, executionPath);
    final lastStep = _latestRunStep(runRecord);
    final checkpointReviewPath = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(runRecord['last_checkpoint_review_path']),
      ..._checkpointReviewCandidatesForTask(activeTask),
    ]);
    final checkpointReviewRecord = checkpointReviewPath.isEmpty
        ? const <String, Object?>{}
        : await _taskRepository.loadRecord(project, checkpointReviewPath);
    final activationPath = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(execution['activation_report_path']),
      ValueReaders.stringValue(activeTask['activation_report_path']),
      ValueReaders.stringValue(metadata['activation_report_path']),
      ValueReaders.stringValue(runRecord['last_activation_report_path']),
      ValueReaders.stringValue(lastStep['activation_report_path']),
    ]);
    final activationSummary = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(execution['activation_report_summary']),
      ValueReaders.stringValue(activeTask['activation_report_summary']),
      ValueReaders.stringValue(metadata['activation_report_summary']),
      ValueReaders.stringValue(lastStep['activation_report_summary']),
    ]);
    final deliveryState = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(execution['chapter_delivery_state']),
      ValueReaders.stringValue(activeTask['chapter_delivery_state']),
      ValueReaders.stringValue(metadata['chapter_delivery_state']),
      ValueReaders.stringValue(runRecord['last_chapter_delivery_state']),
      ValueReaders.stringValue(lastStep['chapter_delivery_state']),
    ]);
    final deliveryPath = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(execution['chapter_delivery_path']),
      ValueReaders.stringValue(activeTask['chapter_delivery_path']),
      ValueReaders.stringValue(metadata['chapter_delivery_path']),
      ValueReaders.stringValue(runRecord['last_chapter_delivery_path']),
      ValueReaders.stringValue(lastStep['chapter_delivery_path']),
    ]);
    final activation = _narrativeItem(
      title: 'Activation',
      status: 'activation',
      relativePath: activationPath,
      subtitle: activationPath.isEmpty ? '上下文激活摘要' : '上下文激活报告',
      summary: activationSummary,
    );
    final deliverySubtitleParts = <String>[];
    if (deliveryState.isNotEmpty) {
      deliverySubtitleParts.add(deliveryState);
    }
    if (deliveryPath.isNotEmpty) {
      deliverySubtitleParts.add(deliveryPath);
    }
    final delivery = _narrativeItem(
      title: 'Delivery',
      status: deliveryState,
      relativePath: deliveryPath,
      subtitle: deliverySubtitleParts.join(' · '),
      summary: deliveryState,
    );
    final review = latestReviewReport == null
        ? null
        : ProjectLongTaskStationItemSummary(
            id: latestReviewReport.id,
            title: 'Review',
            relativePath: latestReviewReport.relativePath,
            status: latestReviewReport.status,
            subtitle: latestReviewReport.subtitle,
            summary: latestReviewReport.summary,
          );
    final changedPaths = <String>[
      ...ValueReaders.stringList(execution['changed_paths']),
      ...ValueReaders.stringList(runRecord['last_changed_paths']),
      ...ValueReaders.stringList(lastStep['changed_paths']),
    ];
    final informationChangedPaths = <String>[
      ...ValueReaders.stringList(runRecord['last_information_changed_paths']),
      ...ValueReaders.stringList(lastStep['information_changed_paths']),
      ...ValueReaders.stringList(
        checkpointReviewRecord['information_changed_paths'],
      ),
      ...ValueReaders.stringList(
        ValueReaders.mapValue(
          checkpointReviewRecord['information_signal'],
        )['changed_paths'],
      ),
    ];
    final continuity = _continuityItem(_continuityCounts(changedPaths));
    final currentExpressionConstraint = _expressionConstraintItem(
      _expressionConstraintProjectionFromSources(
        execution: execution,
        runRecord: runRecord,
        lastStep: lastStep,
      ),
      relativePath: executionPath,
      chapterPath: deliveryPath,
      title: '表达限制',
    );
    final recentExpressionConstraintItems = _recentExpressionConstraintItems(
      runRecord,
    );
    final projectionItems = _projectionItems(changedPaths);
    final permissionItems = await _permissionItems(project, changedPaths);
    final informationPermissionRecords = await _informationPermissionRecords(
      project,
      informationChangedPaths,
    );
    final informationProjection = _informationProjection(
      changedPaths: informationChangedPaths,
      summary: _firstNonEmptyDistinct(<String>[
        ValueReaders.stringValue(runRecord['last_information_summary']),
        ValueReaders.stringValue(lastStep['information_summary']),
        ValueReaders.stringValue(checkpointReviewRecord['information_summary']),
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            checkpointReviewRecord['information_signal'],
          )['summary'],
        ),
      ]),
      riskCategory: _firstNonEmptyDistinct(<String>[
        ValueReaders.stringValue(runRecord['last_information_risk_category']),
        ValueReaders.stringValue(lastStep['information_risk_category']),
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            checkpointReviewRecord['information_signal'],
          )['category'],
        ),
      ]),
      permissionRecords: informationPermissionRecords,
    );
    final summary = ProjectLongTaskStationNarrativeSummary(
      activation: activation,
      delivery: delivery,
      review: review,
      continuity: continuity,
      information: _informationItem(informationProjection),
      expressionConstraint: currentExpressionConstraint,
      projectionItems: projectionItems,
      permissionItems: permissionItems,
      informationProjectionItems: _summaryItemsFromProjectionItems(
        informationProjection.projectionItems,
      ),
      informationPermissionItems: _summaryItemsFromProjectionItems(
        informationProjection.userActionItems,
      ),
      recentExpressionConstraintItems: recentExpressionConstraintItems,
    );
    return summary.hasContent ? summary : null;
  }

  JsonMap _latestRunStep(JsonMap runRecord) {
    final steps = ValueReaders.mapList(runRecord['steps']);
    if (steps.isEmpty) {
      return const <String, Object?>{};
    }
    return steps.last;
  }

  ProjectLongTaskStationItemSummary? _narrativeItem({
    required String title,
    required String status,
    required String relativePath,
    required String subtitle,
    required String summary,
  }) {
    if (relativePath.trim().isEmpty && summary.trim().isEmpty) {
      return null;
    }
    final resolvedSubtitle = subtitle.trim().isEmpty ? title : subtitle.trim();
    final resolvedSummary = summary.trim().isEmpty
        ? resolvedSubtitle
        : summary.trim();
    return ProjectLongTaskStationItemSummary(
      id: relativePath.trim().isEmpty ? title : relativePath.trim(),
      title: title,
      relativePath: relativePath.trim(),
      status: status.trim(),
      subtitle: resolvedSubtitle,
      summary: resolvedSummary,
    );
  }

  ExpressionConstraintStatusProjection
  _expressionConstraintProjectionFromSources({
    required JsonMap execution,
    required JsonMap runRecord,
    required JsonMap lastStep,
  }) {
    for (final source in <JsonMap>[
      ValueReaders.mapValue(execution['writing_execution_result']),
      ValueReaders.mapValue(runRecord['last_writing_execution_result']),
      ValueReaders.mapValue(lastStep['writing_execution_result']),
    ]) {
      if (source.isEmpty) {
        continue;
      }
      final projection = _expressionConstraintStatusProjectionService
          .fromWritingExecutionResult(source);
      if (projection.present) {
        return projection;
      }
    }
    return const ExpressionConstraintStatusProjection();
  }

  ProjectLongTaskStationItemSummary? _expressionConstraintItem(
    ExpressionConstraintStatusProjection projection, {
    required String relativePath,
    required String chapterPath,
    required String title,
  }) {
    if (!projection.present) {
      return null;
    }
    final subtitleParts = <String>[
      if (projection.statusLabel.trim().isNotEmpty) projection.statusLabel,
      if (projection.policyMode.trim().isNotEmpty) projection.policyMode,
      if (chapterPath.trim().isNotEmpty) chapterPath.trim(),
    ];
    final resolvedPath = relativePath.trim().isNotEmpty
        ? relativePath.trim()
        : chapterPath.trim();
    return ProjectLongTaskStationItemSummary(
      id: resolvedPath.isEmpty ? title : resolvedPath,
      title: title,
      relativePath: resolvedPath,
      status: projection.status,
      subtitle: subtitleParts.join(' · '),
      summary: projection.summary,
    );
  }

  List<ProjectLongTaskStationItemSummary> _recentExpressionConstraintItems(
    JsonMap runRecord,
  ) {
    final items = <ProjectLongTaskStationItemSummary>[];
    final seenPaths = <String>{};
    for (final step in ValueReaders.mapList(runRecord['steps']).reversed) {
      final writingExecutionResult = ValueReaders.mapValue(
        step['writing_execution_result'],
      );
      if (writingExecutionResult.isEmpty) {
        continue;
      }
      final projection = _expressionConstraintStatusProjectionService
          .fromWritingExecutionResult(writingExecutionResult);
      if (!projection.present) {
        continue;
      }
      final chapterPath = ValueReaders.stringValue(
        step['chapter_delivery_path'],
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              writingExecutionResult['delivery'],
            )['metadata'],
          )['chapter_path'],
        ),
      ).trim();
      final identity = chapterPath.isEmpty
          ? ValueReaders.stringValue(step['task_id']).trim()
          : chapterPath;
      if (identity.isEmpty || !seenPaths.add(identity)) {
        continue;
      }
      final title = chapterPath.isEmpty
          ? '最近章节表达限制'
          : '表达限制：${chapterPath.split('/').last}';
      final item = _expressionConstraintItem(
        projection,
        relativePath: identity,
        chapterPath: chapterPath,
        title: title,
      );
      if (item != null) {
        items.add(item);
      }
      if (items.length >= 3) {
        break;
      }
    }
    return List<ProjectLongTaskStationItemSummary>.unmodifiable(items);
  }

  List<ProjectLongTaskStationItemSummary> _projectionItems(
    List<String> changedPaths,
  ) {
    final normalizedPaths = _normalizedChangedPaths(changedPaths);
    final items = <ProjectLongTaskStationItemSummary>[];

    void addProjection({
      required String title,
      required String relativePath,
      required String summary,
    }) {
      if (!normalizedPaths.contains(relativePath)) {
        return;
      }
      items.add(
        ProjectLongTaskStationItemSummary(
          id: relativePath,
          title: title,
          relativePath: relativePath,
          status: 'projection',
          subtitle: 'Readable projection',
          summary: summary,
        ),
      );
    }

    addProjection(
      title: '叙事状态规则',
      relativePath: NarrativeStateProjectionDocument.rulesRelativePath,
      summary: '打开当前叙事规则投影。',
    );
    addProjection(
      title: '最近状态变化',
      relativePath: NarrativeStateProjectionDocument.recentChangesRelativePath,
      summary: '打开最近 claims 与 ledger 变化投影。',
    );
    addProjection(
      title: '项目约束摘要',
      relativePath:
          NarrativeStateProjectionDocument.constraintSummaryRelativePath,
      summary: '打开当前项目约束投影。',
    );
    addProjection(
      title: '语义复核摘要',
      relativePath:
          NarrativeStateProjectionDocument.semanticReviewSummaryRelativePath,
      summary: '打开当前语义复核投影。',
    );
    return items;
  }

  InformationEvidenceProjection _informationProjection({
    required List<String> changedPaths,
    required String summary,
    required String riskCategory,
    required List<JsonMap> permissionRecords,
  }) {
    return _informationEvidenceProjectionService
        .fromWorkflowInformationContract(<String, Object?>{
          ..._informationCounts(changedPaths),
          'present': changedPaths.isNotEmpty || summary.trim().isNotEmpty,
          'summary': summary.trim(),
          'risk_category': riskCategory.trim(),
          'projection_paths': _informationProjectionPaths(changedPaths),
        }, permissionRecords: permissionRecords);
  }

  ProjectLongTaskStationItemSummary? _informationItem(
    InformationEvidenceProjection projection,
  ) {
    if (!projection.hasContent) {
      return null;
    }
    return ProjectLongTaskStationItemSummary(
      id: 'information_summary',
      title: '资料状态',
      relativePath: '',
      status: projection.status,
      subtitle: projection.subtitle,
      summary: projection.summary,
    );
  }

  List<String> _informationProjectionPaths(List<String> changedPaths) {
    final normalizedPaths = _normalizedChangedPaths(changedPaths);
    final paths = <String>[
      if (normalizedPaths.contains(
        InformationProjectionDocument.knowledgeSummaryRelativePath,
      ))
        InformationProjectionDocument.knowledgeSummaryRelativePath,
      if (normalizedPaths.contains(
        InformationProjectionDocument.designSummaryRelativePath,
      ))
        InformationProjectionDocument.designSummaryRelativePath,
      if (normalizedPaths.contains(
        InformationProjectionDocument.researchSummaryRelativePath,
      ))
        InformationProjectionDocument.researchSummaryRelativePath,
      if (normalizedPaths.contains(
        InformationProjectionDocument.referenceBoundaryRelativePath,
      ))
        InformationProjectionDocument.referenceBoundaryRelativePath,
    ];
    if (paths.isNotEmpty) {
      return paths;
    }
    return const <String>[];
  }

  List<ProjectLongTaskStationItemSummary> _summaryItemsFromProjectionItems(
    List<InformationEvidenceProjectionItem> items,
  ) {
    return items
        .map(
          (item) => ProjectLongTaskStationItemSummary(
            id: item.id,
            title: item.title,
            relativePath: item.relativePath,
            status: item.status,
            subtitle: item.subtitle,
            summary: item.summary,
          ),
        )
        .toList(growable: false);
  }

  JsonMap _informationCounts(List<String> changedPaths) {
    final normalizedPaths = _normalizedChangedPaths(changedPaths);
    var knowledge = 0;
    var design = 0;
    var research = 0;
    var reference = 0;
    for (final normalized in normalizedPaths) {
      if (normalized.startsWith(_knowledgeCardsRoot) &&
          _isHiddenJsonRecordPath(normalized)) {
        knowledge += 1;
      } else if (normalized.startsWith(_designElementsRoot) &&
          _isHiddenJsonRecordPath(normalized)) {
        design += 1;
      } else if (normalized.startsWith(_researchNotesRoot) &&
          _isHiddenJsonRecordPath(normalized)) {
        research += 1;
      } else if (normalized.startsWith(_referenceWorksRoot) &&
          _isHiddenJsonRecordPath(normalized)) {
        reference += 1;
      }
    }
    return <String, Object?>{
      'knowledge_count': knowledge,
      'design_count': design,
      'research_count': research,
      'reference_count': reference,
    };
  }

  Future<List<JsonMap>> _informationPermissionRecords(
    ProjectDescriptor project,
    List<String> changedPaths,
  ) async {
    final paths = _normalizedChangedPaths(
      changedPaths,
    ).where(_isInformationPermissionRecordPath).toList(growable: false)..sort();
    final records = <JsonMap>[];
    for (final path in paths) {
      final record = await _taskRepository.loadRecord(project, path);
      if (record.isEmpty) {
        continue;
      }
      records.add(<String, Object?>{'relative_path': path, 'record': record});
    }
    return records;
  }

  Set<String> _normalizedChangedPaths(List<String> changedPaths) {
    final normalizedPaths = <String>{};
    for (final rawPath in changedPaths) {
      final normalized = rawPath.replaceAll('\\', '/').trim();
      if (normalized.isNotEmpty) {
        normalizedPaths.add(normalized);
      }
    }
    return normalizedPaths;
  }

  Future<List<ProjectLongTaskStationItemSummary>> _permissionItems(
    ProjectDescriptor project,
    List<String> changedPaths,
  ) async {
    final paths = _normalizedChangedPaths(
      changedPaths,
    ).where(_isPermissionRecordPath).toList(growable: false)..sort();
    final items = <ProjectLongTaskStationItemSummary>[];
    for (final path in paths) {
      final record = await _taskRepository.loadRecord(project, path);
      items.add(_permissionItem(path, record));
    }
    return items;
  }

  bool _isPermissionRecordPath(String path) {
    if (!path.endsWith('.json') || path.endsWith('/index.json')) {
      return false;
    }
    return path.startsWith(_profileProposalsRoot) ||
        path.startsWith(_clarificationsRoot);
  }

  bool _isInformationPermissionRecordPath(String path) {
    if (!_isHiddenJsonRecordPath(path) || !path.startsWith(_informationRoot)) {
      return false;
    }
    return path.startsWith(_knowledgeCardsRoot) ||
        path.startsWith(_designElementsRoot) ||
        path.startsWith(_researchRequestsRoot) ||
        path.startsWith(_referenceWorksRoot);
  }

  bool _isHiddenJsonRecordPath(String path) {
    return path.endsWith('.json') && !path.endsWith('/index.json');
  }

  ProjectLongTaskStationItemSummary _permissionItem(
    String relativePath,
    JsonMap record,
  ) {
    if (relativePath.startsWith(_clarificationsRoot)) {
      return _clarificationPermissionItem(relativePath, record);
    }
    return _profileProposalPermissionItem(relativePath, record);
  }

  ProjectLongTaskStationItemSummary _profileProposalPermissionItem(
    String relativePath,
    JsonMap record,
  ) {
    final proposal = ValueReaders.mapValue(record['proposal']);
    final proposalId = ValueReaders.stringValue(
      proposal['proposal_id'],
      relativePath,
    );
    final permissionDecision = ValueReaders.mapValue(
      record['permission_decision'],
    );
    final reason = _firstNonEmptyDistinct(<String>[
      ValueReaders.stringValue(proposal['reason']),
      ValueReaders.stringValue(permissionDecision['reason']),
    ]);
    final subtitle = _permissionSubtitle(
      record,
      fallback: ValueReaders.boolValue(proposal['requires_user_confirmation'])
          ? '需要确认'
          : '提案待处理',
    );
    return ProjectLongTaskStationItemSummary(
      id: relativePath,
      title: 'Profile Proposal',
      relativePath: relativePath,
      status: ValueReaders.stringValue(record['outcome_status'], 'proposed'),
      subtitle: '$subtitle · $proposalId',
      summary: reason.isEmpty ? 'Profile proposal 等待用户查看。' : reason,
    );
  }

  ProjectLongTaskStationItemSummary _clarificationPermissionItem(
    String relativePath,
    JsonMap record,
  ) {
    final clarification = ValueReaders.mapValue(
      record['clarification_request'],
    );
    final question = ValueReaders.stringValue(clarification['question']).trim();
    final optionCount = ValueReaders.mapList(clarification['options']).length;
    final blocking = ValueReaders.boolValue(clarification['blocking'], true);
    final subtitle = _permissionSubtitle(
      record,
      fallback: blocking ? '阻塞确认' : '非阻塞确认',
    );
    final parts = <String>[subtitle, if (optionCount > 0) '选项 $optionCount'];
    return ProjectLongTaskStationItemSummary(
      id: relativePath,
      title: 'Clarification',
      relativePath: relativePath,
      status: ValueReaders.stringValue(
        record['outcome_status'],
        DomainToolOutcomeStatuses.needsUserConfirmation,
      ),
      subtitle: parts.join(' · '),
      summary: question.isEmpty ? '等待用户确认补充信息。' : question,
    );
  }

  String _permissionSubtitle(JsonMap record, {required String fallback}) {
    final outcomeStatus = ValueReaders.stringValue(record['outcome_status']);
    final permissionDecision = ValueReaders.mapValue(
      record['permission_decision'],
    );
    final disposition = ValueReaders.stringValue(
      permissionDecision['disposition'],
    );
    final parts = <String>[
      if (outcomeStatus.trim().isNotEmpty) outcomeStatus.trim(),
      if (disposition.trim().isNotEmpty) disposition.trim(),
    ];
    return parts.isEmpty ? fallback : parts.join(' · ');
  }

  JsonMap _continuityCounts(List<String> changedPaths) {
    final normalizedPaths = _normalizedChangedPaths(changedPaths);
    var ledger = 0;
    var claims = 0;
    var reviews = 0;
    var deliveries = 0;
    for (final normalized in normalizedPaths) {
      if (!normalized.startsWith(_continuityRoot)) {
        continue;
      }
      if (normalized.startsWith(_ledgerRoot)) {
        ledger += 1;
      } else if (normalized.startsWith(_claimsRoot)) {
        claims += 1;
      } else if (normalized.startsWith(_reviewsRoot)) {
        reviews += 1;
      } else if (normalized.startsWith(_deliveriesRoot)) {
        deliveries += 1;
      }
    }
    final total = ledger + claims + reviews + deliveries;
    return <String, Object?>{
      'total': total,
      'ledger': ledger,
      'claims': claims,
      'reviews': reviews,
      'deliveries': deliveries,
    };
  }

  ProjectLongTaskStationItemSummary? _continuityItem(JsonMap counts) {
    final total = ValueReaders.intValue(counts['total']);
    if (total <= 0) {
      return null;
    }
    final parts = <String>[];
    final ledger = ValueReaders.intValue(counts['ledger']);
    final claims = ValueReaders.intValue(counts['claims']);
    final reviews = ValueReaders.intValue(counts['reviews']);
    final deliveries = ValueReaders.intValue(counts['deliveries']);
    if (ledger > 0) {
      parts.add('ledger $ledger');
    }
    if (claims > 0) {
      parts.add('claims $claims');
    }
    if (reviews > 0) {
      parts.add('reviews $reviews');
    }
    if (deliveries > 0) {
      parts.add('deliveries $deliveries');
    }
    return ProjectLongTaskStationItemSummary(
      id: 'continuity_counts',
      title: 'Continuity',
      relativePath: '',
      status: 'continuity',
      subtitle: '更新 $total 项',
      summary: parts.isEmpty ? '更新 $total 项' : parts.join(' | '),
    );
  }

  Iterable<String> _reviewReportCandidatesForTask(JsonMap task) sync* {
    final metadata = ValueReaders.mapValue(task['metadata']);
    yield ValueReaders.stringValue(task['chapter_gate_review_report_path']);
    yield ValueReaders.stringValue(task['postprocess_review_report_path']);
    yield ValueReaders.stringValue(task['review_report_path']);
    yield ValueReaders.stringValue(metadata['review_report_path']);
  }

  ProjectLongTaskStationItemSummary? _resolveLatestRepairTask(
    List<JsonMap> tasks,
  ) {
    for (final task in tasks) {
      if (!_isRepairTask(task)) {
        continue;
      }
      return _taskSummary(task);
    }
    return null;
  }

  bool _isRepairTask(JsonMap task) {
    if (ValueReaders.stringValue(task['task_type']).trim() != 'revision') {
      return false;
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    return ValueReaders.stringValue(metadata['origin']).trim() ==
            'review_report' ||
        ValueReaders.stringValue(
          metadata['review_report_path'],
        ).trim().isNotEmpty ||
        ValueReaders.stringValue(
          task['review_report_path'],
        ).trim().isNotEmpty ||
        ValueReaders.stringValue(
          task['chapter_gate_review_report_path'],
        ).trim().isNotEmpty ||
        ValueReaders.stringValue(
          metadata['origin_checkpoint_review_path'],
        ).trim().isNotEmpty;
  }

  ProjectLongTaskStationItemSummary? _taskSummary(JsonMap task) {
    if (task.isEmpty) {
      return null;
    }
    final sourcePaths = ValueReaders.stringList(task['source_paths']);
    final chapter = ValueReaders.stringValue(task['chapter']).trim();
    final subtitleParts = <String>[
      ValueReaders.stringValue(task['task_type'], 'task'),
      if (chapter.isNotEmpty) chapter,
      if (sourcePaths.isNotEmpty) sourcePaths.first,
    ];
    final summary = ValueReaders.stringValue(
      task['brief'],
      ValueReaders.stringValue(task['goal']),
    );
    return ProjectLongTaskStationItemSummary(
      id: ValueReaders.stringValue(
        task['id'],
        ValueReaders.stringValue(task['relative_path']),
      ),
      title: ValueReaders.stringValue(task['title'], '未命名任务'),
      relativePath: ValueReaders.stringValue(task['relative_path']),
      status: ValueReaders.stringValue(task['status']),
      subtitle: subtitleParts
          .where((item) => item.trim().isNotEmpty)
          .join(' · '),
      summary: summary.trim(),
    );
  }

  ProjectLongTaskStationBlockerSummary _buildBlocker(
    RunInstance run, {
    required JsonMap activeTask,
    required ProjectLongTaskStationChainSummary? chain,
    required JsonMap runRecord,
    required ProjectLongTaskStationItemSummary? latestCheckpointReview,
    required ProjectLongTaskStationItemSummary? latestReviewReport,
    required ProjectLongTaskStationNarrativeSummary? narrativeSummary,
  }) {
    final code = _resolvedBlockerCode(
      run: run,
      activeTask: activeTask,
      runRecord: runRecord,
      chain: chain,
    );
    final detailLines = <String>[];
    final stopNote = ValueReaders.stringValue(runRecord['stop_note']).trim();
    if (stopNote.isNotEmpty) {
      detailLines.add(stopNote);
    }
    if (run.note.trim().isNotEmpty &&
        !detailLines.any((line) => line == run.note.trim())) {
      detailLines.add(run.note.trim());
    }
    if (activeTask.isNotEmpty) {
      detailLines.add(
        '当前任务：${ValueReaders.stringValue(activeTask['title'], '未命名任务')}'
        '（${ValueReaders.stringValue(activeTask['status'], '待办')}）',
      );
    }
    final blockingCheckpointTitles =
        chain?.blockingCheckpointTitles ?? const <String>[];
    if (blockingCheckpointTitles.isNotEmpty) {
      detailLines.add('阻塞检查点：${blockingCheckpointTitles.join('、')}');
    }
    final diagnosis = _stopDiagnosisProjectionService.project(
      stopOutcome: _stopOutcomeForRun(run, runRecord: runRecord),
      recoveryState: _recoveryStateForRun(run, runRecord: runRecord),
      legacyReason: code,
      runStatus: run.status.id,
      note: _firstNonEmptyDistinct(<String>[
        ValueReaders.stringValue(runRecord['stop_note']),
        run.note,
      ]),
      reviewSummary: _firstNonEmptyDistinct(<String>[
        latestReviewReport?.summary ?? '',
        latestCheckpointReview?.summary ?? '',
        narrativeSummary?.review?.summary ?? '',
      ]),
      informationSummary: _firstNonEmptyDistinct(<String>[
        narrativeSummary?.information?.summary ?? '',
        ValueReaders.stringValue(runRecord['last_information_summary']),
      ]),
      detail: detailLines.join('\n').trim(),
      metadata: <String, Object?>{
        'source': 'project_long_task_station_detail',
        'run_record_path': ValueReaders.stringValue(runRecord['relative_path']),
      },
    );
    return ProjectLongTaskStationBlockerSummary(
      code: code,
      category: diagnosis.category,
      label: diagnosis.label,
      note: diagnosis.summary.isEmpty ? _blockerNote(code) : diagnosis.summary,
      detail: diagnosis.detail,
      controlSummary: _blockerControlSummary(code),
      blockingCheckpointTitles: blockingCheckpointTitles,
      runRecordPath: ValueReaders.stringValue(runRecord['relative_path']),
    );
  }

  LongTaskStopOutcome _stopOutcomeForRun(
    RunInstance run, {
    required JsonMap runRecord,
  }) {
    if (run.stopOutcome.present) {
      return run.stopOutcome;
    }
    final recordOutcome = LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(runRecord['stop_outcome']),
    );
    if (recordOutcome.present) {
      return recordOutcome;
    }
    return LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(
        ValueReaders.mapValue(runRecord['last_recovery_state'])['stop_outcome'],
      ),
    );
  }

  LongTaskRecoveryState _recoveryStateForRun(
    RunInstance run, {
    required JsonMap runRecord,
  }) {
    if (run.recoveryState.present) {
      return run.recoveryState;
    }
    return LongTaskRecoveryState.fromJson(
      ValueReaders.mapValue(runRecord['last_recovery_state']),
    );
  }

  String _resolvedBlockerCode({
    required RunInstance run,
    required JsonMap activeTask,
    required JsonMap runRecord,
    required ProjectLongTaskStationChainSummary? chain,
  }) {
    final runStopReason = run.stopReason.trim();
    if (runStopReason.isNotEmpty) {
      return runStopReason;
    }
    final recordStopReason = ValueReaders.stringValue(
      runRecord['stop_reason'],
    ).trim();
    if (recordStopReason.isNotEmpty) {
      return recordStopReason;
    }
    final activeStatus = ValueReaders.stringValue(activeTask['status']).trim();
    if (activeStatus == TaskRuntimeConstants.statusWaitingUser) {
      return 'waiting_user';
    }
    if (activeStatus == TaskRuntimeConstants.statusFailed) {
      return 'failed';
    }
    if ((chain?.blockingCheckpointTitles.isNotEmpty ?? false)) {
      return 'waiting_gate';
    }
    return '';
  }

  String _blockerNote(String code) {
    switch (code.trim()) {
      case 'waiting_user':
      case 'waiting_user_checkpoint':
      case 'waiting_gate':
        return '当前运行已经停在需要确认或复核的节点。';
      case 'failed':
      case 'step_failed':
        return '当前运行链有失败节点，需要先修复或重试。';
      case 'blocked_dependencies':
        return '当前任务依赖还没有放行，暂时无法继续推进。';
      case 'manual_pause':
      case 'paused':
        return '当前运行被暂停，恢复前不会继续推进。';
      default:
        return code.trim().isEmpty ? '当前没有明显阻塞。' : '当前运行存在待处理阻塞。';
    }
  }

  String _blockerControlSummary(String code) {
    switch (code.trim()) {
      case 'waiting_user':
      case 'waiting_user_checkpoint':
        return '建议先跳到任务中心处理检查点或关口动作。';
      case 'waiting_gate':
        return '建议先查看当前关口或复核结果，再决定是否继续推进。';
      case 'failed':
      case 'step_failed':
      case 'failed_task':
      case 'delivery_repair_required':
      case 'information_repair_required':
        return '建议先查看返工链或失败任务，再决定重试或修订。';
      case 'manual_pause':
      case 'paused':
        return '可以直接在总站恢复，或先回工作台检查项目状态。';
      case 'blocked_dependencies':
        return '建议先查看当前链路上的前置节点完成情况。';
      default:
        return '可以先打开项目，再进入相关中心继续处理。';
    }
  }

  String _firstNonEmptyDistinct(Iterable<String> values) {
    final seen = <String>{};
    for (final rawValue in values) {
      final clean = rawValue.trim();
      if (clean.isEmpty || !seen.add(clean)) {
        continue;
      }
      return clean;
    }
    return '';
  }
}
