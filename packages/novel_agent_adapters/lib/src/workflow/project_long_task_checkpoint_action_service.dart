import 'package:novel_agent_core/novel_agent_core.dart';

import '../runtime/long_task_supervisor.dart';
import '../runtime/project_long_task_run_registry_sync_service.dart';
import '../storage/project_mode_guidance_repository.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_checkpoint_review_task_service.dart';
import 'project_long_task_checkpoint_revision_followup_service.dart';
import 'project_mode_guidance_revisit_service.dart';

class ProjectLongTaskCheckpointActionService {
  ProjectLongTaskCheckpointActionService({
    required ProjectTaskRepository taskRepository,
    required ProjectLongTaskCheckpointReviewTaskService
    checkpointReviewTaskService,
    ProjectLongTaskCheckpointRevisionFollowupService?
    checkpointRevisionFollowupService,
    ProjectModeGuidanceRepository? modeGuidanceRepository,
    ProjectModeGuidanceRevisitService? modeGuidanceRevisitService,
    LongTaskCheckpointSeverityService? checkpointSeverityService,
    LongTaskCheckpointActionContractService? checkpointActionContractService,
    LongTaskRunLifecycleService? runLifecycleService,
    LongTaskSupervisor? longTaskSupervisor,
    ProjectLongTaskRunRegistrySyncService? longTaskRunRegistrySyncService,
  }) : _taskRepository = taskRepository,
       _checkpointReviewTaskService = checkpointReviewTaskService,
       _checkpointRevisionFollowupService =
           checkpointRevisionFollowupService ??
           ProjectLongTaskCheckpointRevisionFollowupService(
             taskRepository: taskRepository,
             checkpointReviewTaskService: checkpointReviewTaskService,
           ),
       _modeGuidanceRevisitService =
           modeGuidanceRevisitService ??
           ProjectModeGuidanceRevisitService(
             taskRepository: taskRepository,
             repository:
                 modeGuidanceRepository ??
                 ProjectModeGuidanceRepository(
                   workspacePort: taskRepository.workspacePort,
                 ),
           ),
       _checkpointSeverityService =
           checkpointSeverityService ?? LongTaskCheckpointSeverityService(),
       _checkpointActionContractService =
           checkpointActionContractService ??
           LongTaskCheckpointActionContractService(),
       _runLifecycleService =
           runLifecycleService ?? LongTaskRunLifecycleService(),
       _longTaskRunRegistrySyncService =
           longTaskRunRegistrySyncService ??
           (longTaskSupervisor == null
               ? null
               : ProjectLongTaskRunRegistrySyncService(
                   supervisor: longTaskSupervisor,
                   taskRepository: taskRepository,
                 ));

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;
  final ProjectLongTaskCheckpointRevisionFollowupService
  _checkpointRevisionFollowupService;
  final ProjectModeGuidanceRevisitService _modeGuidanceRevisitService;
  final LongTaskCheckpointSeverityService _checkpointSeverityService;
  final LongTaskCheckpointActionContractService
  _checkpointActionContractService;
  final LongTaskRunLifecycleService _runLifecycleService;
  final ProjectLongTaskRunRegistrySyncService? _longTaskRunRegistrySyncService;

  Future<JsonMap> buildActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    // 中文注释: 项目态入口负责加载 checkpoint review，并为旧记录补算严重度与动作合同。
    final review = await _taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    if (review.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review not found.',
        'actions': const <Object?>[],
      };
    }
    final severity = _checkpointSeverityService.assess(review);
    final resolvedSeverity = ValueReaders.stringValue(
      review['severity'],
      ValueReaders.stringValue(severity['severity']),
    );
    final resolvedSeverityLabel = ValueReaders.stringValue(
      review['severity_label'],
      ValueReaders.stringValue(severity['severity_label']),
    );
    final sourceTask = await _loadSourceTask(project, review);
    final actionPackage = _guardCheckpointContinuationActions(
      _guardRepeatedFollowupReviewCreation(
        _checkpointActionContractService.buildPackage(<String, Object?>{
          ...review,
          'severity': resolvedSeverity,
          'severity_label': resolvedSeverityLabel,
        }, checkpointReviewPath: checkpointReviewPath),
        sourceTask: sourceTask,
        checkpointReviewPath: checkpointReviewPath,
      ),
      sourceTask: sourceTask,
      checkpointReviewPath: checkpointReviewPath,
    );
    return <String, Object?>{
      'ok': true,
      'checkpoint_review_path': checkpointReviewPath,
      'severity': resolvedSeverity,
      'severity_label': resolvedSeverityLabel,
      'severity_reasons': ValueReaders.stringList(
        review['severity_reasons'].runtimeType == List
            ? review['severity_reasons']
            : severity['reasons'],
      ),
      'review': review,
      ...actionPackage,
    };
  }

  Future<JsonMap> buildGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) {
    // 中文注释: 长期约束回看包是只读动作，不应复用 applyAction 的副作用入口。
    return _modeGuidanceRevisitService.buildPackage(
      project,
      checkpointReviewPath,
    );
  }

  Future<JsonMap> applyAction(
    ProjectDescriptor project,
    String checkpointReviewPath,
    String command,
  ) async {
    // 中文注释: checkpoint 动作在这里统一落到真实项目语义，保证 GUI/CLI 与长任务宿主共用同一条入口。
    final review = await _taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    if (review.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review not found.',
      };
    }
    final taskSummary = ValueReaders.mapValue(review['task']);
    final task = await _taskRepository.loadTask(project, <String, Object?>{
      'relative_path': ValueReaders.stringValue(taskSummary['relative_path']),
      'task_id': ValueReaders.stringValue(taskSummary['id']),
    });
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Source task for checkpoint review not found.',
      };
    }
    final resolved = _resolvedReviewPackage(
      review,
      checkpointReviewPath: checkpointReviewPath,
      sourceTask: task,
    );
    final cleanCommand = command.trim().toLowerCase();
    if (<String>{
          'continue_long_task',
          'confirm_checkpoint_continue',
        }.contains(cleanCommand) &&
        !_canApplyCheckpointContinuation(task)) {
      return <String, Object?>{
        'ok': false,
        'error':
            'Checkpoint action is disabled because the source task still blocks progress.',
        'checkpoint_review_path': checkpointReviewPath,
      };
    }
    final action = _findEnabledAction(resolved.package, cleanCommand);
    if (action.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint action is disabled in current review state.',
        'checkpoint_review_path': checkpointReviewPath,
      };
    }
    if (cleanCommand == 'create_followup_review_tasks') {
      final created = await _checkpointReviewTaskService.createTasks(
        project: project,
        task: task,
        checkpointReview: review,
        rewireDependents: false,
      );
      final markedTask = await _markFollowupReviewCreationApplied(
        project: project,
        sourceTask: task,
        checkpointReviewPath: checkpointReviewPath,
        created: created,
      );
      return <String, Object?>{
        ...created,
        'checkpoint_review_path': checkpointReviewPath,
        if (markedTask.isNotEmpty) 'source_task': markedTask,
        'changed_paths': <String>[
          ...ValueReaders.stringList(created['changed_paths']),
          ValueReaders.stringValue(markedTask['relative_path']),
        ].where((path) => path.trim().isNotEmpty).toList(growable: false),
      };
    }
    if (cleanCommand == 'request_revision_followup') {
      return _checkpointRevisionFollowupService.requestFollowup(
        project: project,
        task: task,
        checkpointReview: review,
        checkpointReviewPath: checkpointReviewPath,
      );
    }
    if (cleanCommand == 'continue_long_task') {
      final transitioned = await _taskRepository.transitionTask(
        project,
        _taskSelector(task),
        TaskRuntimeConstants.statusSucceeded,
        note: '用户确认当前检查点产物可继续主链。',
        extra: <String, Object?>{
          'continued_checkpoint_review_path': checkpointReviewPath,
        },
      );
      final unlockedCheckpoints = await _confirmImmediateCheckpointDependents(
        project: project,
        sourceTask: task,
        checkpointReviewPath: checkpointReviewPath,
      );
      final resumedRuns =
          await _resumePausedRunsWaitingForCheckpointConfirmation(
            project: project,
            sourceTask: task,
            checkpointReviewPath: checkpointReviewPath,
          );
      return <String, Object?>{
        ...transitioned,
        'checkpoint_review_path': checkpointReviewPath,
        'unlocked_checkpoint_tasks': unlockedCheckpoints,
        'unlocked_checkpoint_task_ids': unlockedCheckpoints
            .map((item) => ValueReaders.stringValue(item['id']))
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: false),
        'unlocked_checkpoint_paths': unlockedCheckpoints
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((path) => path.trim().isNotEmpty)
            .toList(growable: false),
        'resumed_long_task_runs': resumedRuns,
        'resumed_long_task_run_paths': resumedRuns
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((path) => path.trim().isNotEmpty)
            .toList(growable: false),
        'changed_paths': <String>[
          ValueReaders.stringValue(transitioned['relative_path']),
          ...unlockedCheckpoints.map(
            (item) => ValueReaders.stringValue(item['relative_path']),
          ),
          ...resumedRuns.map(
            (item) => ValueReaders.stringValue(item['relative_path']),
          ),
        ].where((path) => path.trim().isNotEmpty).toList(growable: false),
      };
    }
    if (cleanCommand == 'confirm_checkpoint_continue') {
      final transitioned = await _taskRepository.transitionTask(
        project,
        _taskSelector(task),
        TaskRuntimeConstants.statusSucceeded,
        note: '用户确认显式 checkpoint，允许长任务继续调度。',
        extra: <String, Object?>{
          'confirmed_checkpoint_review_path': checkpointReviewPath,
        },
      );
      final resumedRuns =
          await _resumePausedRunsWaitingForCheckpointConfirmation(
            project: project,
            sourceTask: task,
            checkpointReviewPath: checkpointReviewPath,
          );
      return <String, Object?>{
        ...transitioned,
        'checkpoint_review_path': checkpointReviewPath,
        'resumed_long_task_runs': resumedRuns,
        'resumed_long_task_run_paths': resumedRuns
            .map((item) => ValueReaders.stringValue(item['relative_path']))
            .where((path) => path.trim().isNotEmpty)
            .toList(growable: false),
        'changed_paths': <String>[
          ValueReaders.stringValue(transitioned['relative_path']),
          ...resumedRuns.map(
            (item) => ValueReaders.stringValue(item['relative_path']),
          ),
        ].where((path) => path.trim().isNotEmpty).toList(growable: false),
      };
    }
    if (cleanCommand == 'revisit_mode_guidance') {
      return _modeGuidanceRevisitService.buildPackage(
        project,
        checkpointReviewPath,
      );
    }
    return <String, Object?>{
      'ok': false,
      'error': 'Checkpoint action is not materialized yet.',
      'checkpoint_review_path': checkpointReviewPath,
    };
  }

  _ResolvedCheckpointReviewPackage _resolvedReviewPackage(
    JsonMap review, {
    required String checkpointReviewPath,
    required JsonMap sourceTask,
  }) {
    final severity = _checkpointSeverityService.assess(review);
    final resolvedSeverity = ValueReaders.stringValue(
      review['severity'],
      ValueReaders.stringValue(severity['severity']),
    );
    final resolvedSeverityLabel = ValueReaders.stringValue(
      review['severity_label'],
      ValueReaders.stringValue(severity['severity_label']),
    );
    return _ResolvedCheckpointReviewPackage(
      package: _guardCheckpointContinuationActions(
        _guardRepeatedFollowupReviewCreation(
          _checkpointActionContractService.buildPackage(<String, Object?>{
            ...review,
            'severity': resolvedSeverity,
            'severity_label': resolvedSeverityLabel,
          }, checkpointReviewPath: checkpointReviewPath),
          sourceTask: sourceTask,
          checkpointReviewPath: checkpointReviewPath,
        ),
        sourceTask: sourceTask,
        checkpointReviewPath: checkpointReviewPath,
      ),
    );
  }

  JsonMap _findEnabledAction(JsonMap package, String actionId) {
    for (final rawAction in ValueReaders.mapList(package['actions'])) {
      if (ValueReaders.stringValue(rawAction['id']) == actionId &&
          ValueReaders.boolValue(rawAction['enabled'])) {
        return rawAction;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _taskSelector(JsonMap task) {
    final result = <String, Object?>{};
    final relativePath = ValueReaders.stringValue(task['relative_path']).trim();
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (relativePath.isNotEmpty) {
      result['relative_path'] = relativePath;
    }
    if (taskId.isNotEmpty) {
      result['task_id'] = taskId;
    }
    return result;
  }

  Future<JsonMap> _loadSourceTask(
    ProjectDescriptor project,
    JsonMap review,
  ) async {
    final taskSummary = ValueReaders.mapValue(review['task']);
    return _taskRepository.loadTask(project, <String, Object?>{
      'relative_path': ValueReaders.stringValue(taskSummary['relative_path']),
      'task_id': ValueReaders.stringValue(taskSummary['id']),
    });
  }

  JsonMap _guardCheckpointContinuationActions(
    JsonMap package, {
    required JsonMap sourceTask,
    String checkpointReviewPath = '',
  }) {
    final cleanCheckpointReviewPath = checkpointReviewPath.trim();
    final continuationAlreadyApplied =
        cleanCheckpointReviewPath.isNotEmpty &&
        _wasContinuationAlreadyApplied(
          sourceTask,
          checkpointReviewPath: cleanCheckpointReviewPath,
        );
    if (_canApplyCheckpointContinuation(sourceTask) &&
        !continuationAlreadyApplied) {
      return package;
    }
    final actions = ValueReaders.mapList(package['actions'])
        .map((action) {
          final actionId = ValueReaders.stringValue(action['id']).trim();
          if (!<String>{
            'continue_long_task',
            'confirm_checkpoint_continue',
          }.contains(actionId)) {
            return action;
          }
          return <String, Object?>{
            ...action,
            'enabled': false,
            'disabled_reason': continuationAlreadyApplied
                ? 'checkpoint_action_already_applied'
                : 'source_task_blocks_progress',
          };
        })
        .toList(growable: false);
    return _packageWithActions(package, actions);
  }

  JsonMap _guardRepeatedFollowupReviewCreation(
    JsonMap package, {
    required JsonMap sourceTask,
    required String checkpointReviewPath,
  }) {
    final cleanCheckpointReviewPath = checkpointReviewPath.trim();
    if (cleanCheckpointReviewPath.isEmpty ||
        !_wasFollowupReviewCreationAlreadyApplied(
          sourceTask,
          checkpointReviewPath: cleanCheckpointReviewPath,
        )) {
      return package;
    }
    final actions = ValueReaders.mapList(package['actions'])
        .map((action) {
          if (ValueReaders.stringValue(action['id']).trim() !=
              'create_followup_review_tasks') {
            return action;
          }
          return <String, Object?>{
            ...action,
            'enabled': false,
            'disabled_reason': 'checkpoint_action_already_applied',
          };
        })
        .toList(growable: false);
    return _packageWithActions(package, actions);
  }

  bool _canApplyCheckpointContinuation(JsonMap sourceTask) {
    if (sourceTask.isEmpty) {
      return false;
    }
    final status = ValueReaders.stringValue(sourceTask['status']).trim();
    final isExplicitCheckpoint =
        ValueReaders.stringValue(sourceTask['task_type']).trim() ==
        'checkpoint';
    if (!<String>{
          TaskRuntimeConstants.statusSucceeded,
          TaskRuntimeConstants.statusWaitingUser,
        }.contains(status) &&
        !(isExplicitCheckpoint &&
            status == TaskRuntimeConstants.statusQueued)) {
      return false;
    }
    final lastWritingExecutionResult = ValueReaders.mapValue(
      sourceTask['last_writing_execution_result'],
    );
    return !ValueReaders.boolValue(
      lastWritingExecutionResult['blocks_progress'],
    );
  }

  JsonMap _packageWithActions(JsonMap package, List<JsonMap> actions) {
    final normalizedActions = List<JsonMap>.unmodifiable(actions);
    return <String, Object?>{
      ...package,
      'actions': normalizedActions,
      'action_summary': _actionSummary(normalizedActions),
      'recommended_action_id': _recommendedActionId(
        normalizedActions,
        ValueReaders.stringValue(package['severity']),
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            package['disposition'],
          )['recommended_action_id'],
        ),
      ),
    };
  }

  String _actionSummary(List<JsonMap> actions) {
    final enabled = <String>[];
    for (final action in actions) {
      if (ValueReaders.boolValue(action['enabled'])) {
        enabled.add(ValueReaders.stringValue(action['label']));
      }
    }
    return enabled.isEmpty ? '当前暂无可执行动作。' : '建议动作：${enabled.join('、')}';
  }

  String _recommendedActionId(
    List<JsonMap> actions,
    String severity,
    String dispositionRecommendedActionId,
  ) {
    if (dispositionRecommendedActionId.trim().isNotEmpty) {
      for (final action in actions) {
        if (ValueReaders.boolValue(action['enabled']) &&
            ValueReaders.stringValue(action['id']) ==
                dispositionRecommendedActionId) {
          return dispositionRecommendedActionId;
        }
      }
    }
    final priority = <String>[
      if (severity == 'critical') 'revisit_mode_guidance',
      if (severity == 'high') 'request_revision_followup',
      if (severity == 'medium') 'create_followup_review_tasks',
      'continue_long_task',
      'confirm_checkpoint_continue',
    ];
    for (final id in priority) {
      for (final action in actions) {
        if (ValueReaders.boolValue(action['enabled']) &&
            ValueReaders.stringValue(action['id']) == id) {
          return id;
        }
      }
    }
    return '';
  }

  bool _wasContinuationAlreadyApplied(
    JsonMap sourceTask, {
    required String checkpointReviewPath,
  }) {
    return ValueReaders.stringValue(
              sourceTask['continued_checkpoint_review_path'],
            ).trim() ==
            checkpointReviewPath ||
        ValueReaders.stringValue(
              sourceTask['confirmed_checkpoint_review_path'],
            ).trim() ==
            checkpointReviewPath;
  }

  bool _wasFollowupReviewCreationAlreadyApplied(
    JsonMap sourceTask, {
    required String checkpointReviewPath,
  }) {
    return ValueReaders.stringValue(
              sourceTask['followup_review_checkpoint_review_path'],
            ).trim() ==
            checkpointReviewPath ||
        ValueReaders.stringValue(
              ValueReaders.mapValue(
                sourceTask['metadata'],
              )['followup_review_checkpoint_review_path'],
            ).trim() ==
            checkpointReviewPath;
  }

  Future<JsonMap> _markFollowupReviewCreationApplied({
    required ProjectDescriptor project,
    required JsonMap sourceTask,
    required String checkpointReviewPath,
    required JsonMap created,
  }) async {
    final taskSelector = _taskSelector(sourceTask);
    if (taskSelector.isEmpty || checkpointReviewPath.trim().isEmpty) {
      return const <String, Object?>{};
    }
    final relatedTasks = ValueReaders.mapList(created['tasks']);
    final relatedTaskIds = relatedTasks
        .map((item) => ValueReaders.stringValue(item['id']))
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
    final relatedTaskPaths = relatedTasks
        .map((item) => ValueReaders.stringValue(item['relative_path']))
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
    final now = DateTime.now().toIso8601String();
    final saved = await _taskRepository.saveTask(
      project,
      ValueReaders.deepCopyMap(sourceTask)
        ..['followup_review_state'] = 'created'
        ..['followup_review_checkpoint_review_path'] = checkpointReviewPath
            .trim()
        ..['followup_review_task_ids'] = relatedTaskIds
        ..['followup_review_task_paths'] = relatedTaskPaths
        ..['followup_review_created_at'] = now
        ..['metadata'] = <String, Object?>{
          ...ValueReaders.deepCopyMap(
            ValueReaders.mapValue(sourceTask['metadata']),
          ),
          'followup_review_state': 'created',
          'followup_review_checkpoint_review_path': checkpointReviewPath.trim(),
          'followup_review_task_ids': relatedTaskIds,
          'followup_review_task_paths': relatedTaskPaths,
          'followup_review_created_at': now,
        },
    );
    return saved;
  }

  Future<List<JsonMap>> _confirmImmediateCheckpointDependents({
    required ProjectDescriptor project,
    required JsonMap sourceTask,
    required String checkpointReviewPath,
  }) async {
    // 中文注释: 模型任务完成后可能还有一个显式手动 checkpoint 作为依赖门；用户已确认该模型产物时，应同步解锁这个紧邻的门。
    if (ValueReaders.stringValue(sourceTask['task_type']) == 'checkpoint') {
      return const <JsonMap>[];
    }
    final sourceTaskId = ValueReaders.stringValue(sourceTask['id']).trim();
    if (sourceTaskId.isEmpty) {
      return const <JsonMap>[];
    }
    final sourceMetadata = ValueReaders.mapValue(sourceTask['metadata']);
    final sourcePlanId = ValueReaders.stringValue(
      sourceMetadata['plan_id'],
    ).trim();
    final tasks = await _taskRepository.listTasks(project);
    final unlocked = <JsonMap>[];
    for (final candidate in tasks) {
      if (!_isImmediateManualCheckpoint(
        candidate,
        sourceTaskId: sourceTaskId,
        sourcePlanId: sourcePlanId,
      )) {
        continue;
      }
      final transitioned = await _taskRepository.transitionTask(
        project,
        _taskSelector(candidate),
        TaskRuntimeConstants.statusSucceeded,
        note: '用户已确认前序产物 checkpoint，自动确认紧邻的显式检查点。',
        extra: <String, Object?>{
          'auto_confirmed_by_checkpoint_review_path': checkpointReviewPath,
          'auto_confirmed_after_task_id': sourceTaskId,
        },
      );
      if (!ValueReaders.boolValue(transitioned['ok'])) {
        continue;
      }
      unlocked.add(ValueReaders.mapValue(transitioned['task']));
    }
    return unlocked;
  }

  Future<List<JsonMap>> _resumePausedRunsWaitingForCheckpointConfirmation({
    required ProjectDescriptor project,
    required JsonMap sourceTask,
    required String checkpointReviewPath,
  }) async {
    final taskId = ValueReaders.stringValue(sourceTask['id']).trim();
    final taskPath = ValueReaders.stringValue(
      sourceTask['relative_path'],
    ).trim();
    final planId = ValueReaders.stringValue(
      ValueReaders.mapValue(sourceTask['metadata'])['plan_id'],
    ).trim();
    if (taskId.isEmpty && taskPath.isEmpty && planId.isEmpty) {
      return const <JsonMap>[];
    }
    final records = await _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/long_task_runs/',
      limit: 50,
    );
    final resumed = <JsonMap>[];
    final now = DateTime.now().toIso8601String();
    for (final record in records) {
      if (!_matchesPausedRunWaitingForCheckpointConfirmation(
        record,
        taskId: taskId,
        taskPath: taskPath,
        planId: planId,
        checkpointReviewPath: checkpointReviewPath,
      )) {
        continue;
      }
      final recordPath = ValueReaders.stringValue(
        record['relative_path'],
      ).trim();
      if (recordPath.isEmpty) {
        continue;
      }
      final clearedRecord = _runLifecycleService
          .resumeRecordAfterCheckpointConfirmation(
            record,
            note: '用户已通过 checkpoint review 确认当前产物，长任务恢复继续调度。',
            checkpointReviewPath: checkpointReviewPath,
            createdAt: now,
          );
      final saved = await _taskRepository.saveRecord(
        project,
        recordPath,
        clearedRecord,
      );
      await _syncLongTaskRunRecord(project, saved);
      resumed.add(saved);
    }
    return resumed;
  }

  Future<void> _syncLongTaskRunRecord(
    ProjectDescriptor project,
    JsonMap runRecord,
  ) async {
    final service = _longTaskRunRegistrySyncService;
    if (service == null || runRecord.isEmpty) {
      return;
    }
    await service.syncRecord(project, runRecord);
  }

  bool _matchesPausedRunWaitingForCheckpointConfirmation(
    JsonMap record, {
    required String taskId,
    required String taskPath,
    required String planId,
    required String checkpointReviewPath,
  }) {
    if (ValueReaders.stringValue(record['status']).trim() !=
        TaskRuntimeConstants.statusPaused) {
      return false;
    }
    if (ValueReaders.stringValue(
          record['last_writing_execution_next_action'],
        ).trim() !=
        'resume_when_user_confirms') {
      return false;
    }
    final recordCheckpointPath = ValueReaders.stringValue(
      record['last_checkpoint_review_path'],
    ).trim();
    if (recordCheckpointPath.isNotEmpty &&
        recordCheckpointPath == checkpointReviewPath) {
      return true;
    }
    if (planId.isNotEmpty &&
        ValueReaders.stringValue(record['plan_id']).trim() != planId) {
      return false;
    }
    if (taskId.isNotEmpty &&
        ValueReaders.stringValue(record['last_task_id']).trim() == taskId) {
      return true;
    }
    return taskPath.isNotEmpty &&
        ValueReaders.stringValue(record['last_task_path']).trim() == taskPath;
  }

  bool _isImmediateManualCheckpoint(
    JsonMap task, {
    required String sourceTaskId,
    required String sourcePlanId,
  }) {
    if (ValueReaders.stringValue(task['task_type']) != 'checkpoint') {
      return false;
    }
    if (ValueReaders.stringValue(task['status']) !=
        TaskRuntimeConstants.statusWaitingUser) {
      return false;
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (!ValueReaders.boolValue(metadata['manual_checkpoint'])) {
      return false;
    }
    if (sourcePlanId.isNotEmpty &&
        ValueReaders.stringValue(metadata['plan_id']).trim() != sourcePlanId) {
      return false;
    }
    return ValueReaders.stringList(task['depends_on']).contains(sourceTaskId);
  }
}

class _ResolvedCheckpointReviewPackage {
  const _ResolvedCheckpointReviewPackage({required this.package});

  final JsonMap package;
}
