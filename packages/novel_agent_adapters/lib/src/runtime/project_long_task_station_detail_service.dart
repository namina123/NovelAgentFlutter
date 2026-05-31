import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_review_report_service.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_station_blocker_summary.dart';
import 'project_long_task_station_chain_item.dart';
import 'project_long_task_station_chain_summary.dart';
import 'project_long_task_station_detail.dart';
import 'project_long_task_station_item_summary.dart';

class ProjectLongTaskStationDetailService {
  ProjectLongTaskStationDetailService({
    required ProjectTaskRepository taskRepository,
    required ProjectReviewReportService reviewReportService,
    TaskChainViewService? taskChainViewService,
  }) : _taskRepository = taskRepository,
       _reviewReportService = reviewReportService,
       _taskChainViewService = taskChainViewService ?? TaskChainViewService();

  final ProjectTaskRepository _taskRepository;
  final ProjectReviewReportService _reviewReportService;
  final TaskChainViewService _taskChainViewService;

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
    return ProjectLongTaskStationDetail(
      activeTask: _taskSummary(activeTask),
      chain: chain,
      latestCheckpointReview: latestCheckpointReview,
      latestReviewReport: latestReviewReport,
      latestRepairTask: latestRepairTask,
      blocker: _buildBlocker(
        run,
        activeTask: activeTask,
        chain: chain,
        runRecord: runRecord,
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

  Future<JsonMap> _loadRunRecord(ProjectDescriptor project, String runId) async {
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
    final lastTaskId = ValueReaders.stringValue(runRecord['last_task_id']).trim();
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
    if (nextRunnableTitle.trim().isNotEmpty && nextRunnableTitle.trim() != '无') {
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
      subtitle: subtitleParts.where((item) => item.trim().isNotEmpty).join(' · '),
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
    yield ValueReaders.stringValue(task['followup_request_checkpoint_review_path']);
    yield ValueReaders.stringValue(metadata['followup_request_checkpoint_review_path']);
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
        ValueReaders.stringValue(metadata['review_report_path']).trim().isNotEmpty ||
        ValueReaders.stringValue(task['review_report_path']).trim().isNotEmpty ||
        ValueReaders.stringValue(task['chapter_gate_review_report_path'])
            .trim()
            .isNotEmpty ||
        ValueReaders.stringValue(metadata['origin_checkpoint_review_path'])
            .trim()
            .isNotEmpty;
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
      subtitle: subtitleParts.where((item) => item.trim().isNotEmpty).join(' · '),
      summary: summary.trim(),
    );
  }

  ProjectLongTaskStationBlockerSummary _buildBlocker(
    RunInstance run, {
    required JsonMap activeTask,
    required ProjectLongTaskStationChainSummary? chain,
    required JsonMap runRecord,
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
    final blockingCheckpointTitles = chain?.blockingCheckpointTitles ?? const <String>[];
    if (blockingCheckpointTitles.isNotEmpty) {
      detailLines.add('阻塞检查点：${blockingCheckpointTitles.join('、')}');
    }
    return ProjectLongTaskStationBlockerSummary(
      code: code,
      note: _blockerNote(code),
      detail: detailLines.join('\n').trim(),
      controlSummary: _blockerControlSummary(code),
      blockingCheckpointTitles: blockingCheckpointTitles,
      runRecordPath: ValueReaders.stringValue(runRecord['relative_path']),
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
    final recordStopReason = ValueReaders.stringValue(runRecord['stop_reason']).trim();
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
      case 'waiting_gate':
        return '建议先跳到任务中心处理检查点或关口动作。';
      case 'failed':
      case 'step_failed':
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
