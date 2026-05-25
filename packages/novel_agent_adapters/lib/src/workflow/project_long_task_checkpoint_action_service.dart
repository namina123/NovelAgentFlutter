import 'package:novel_agent_core/novel_agent_core.dart';

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
           LongTaskCheckpointActionContractService();

  final ProjectTaskRepository _taskRepository;
  final ProjectLongTaskCheckpointReviewTaskService _checkpointReviewTaskService;
  final ProjectLongTaskCheckpointRevisionFollowupService
  _checkpointRevisionFollowupService;
  final ProjectModeGuidanceRevisitService _modeGuidanceRevisitService;
  final LongTaskCheckpointSeverityService _checkpointSeverityService;
  final LongTaskCheckpointActionContractService
  _checkpointActionContractService;

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
    final actionPackage = _checkpointActionContractService
        .buildPackage(<String, Object?>{
          ...review,
          'severity': resolvedSeverity,
          'severity_label': resolvedSeverityLabel,
        }, checkpointReviewPath: checkpointReviewPath);
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
    );
    final cleanCommand = command.trim().toLowerCase();
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
      );
      return <String, Object?>{
        ...created,
        'checkpoint_review_path': checkpointReviewPath,
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
      return <String, Object?>{
        ...transitioned,
        'checkpoint_review_path': checkpointReviewPath,
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
      return <String, Object?>{
        ...transitioned,
        'checkpoint_review_path': checkpointReviewPath,
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
      package: _checkpointActionContractService.buildPackage(<String, Object?>{
        ...review,
        'severity': resolvedSeverity,
        'severity_label': resolvedSeverityLabel,
      }, checkpointReviewPath: checkpointReviewPath),
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
}

class _ResolvedCheckpointReviewPackage {
  const _ResolvedCheckpointReviewPackage({required this.package});

  final JsonMap package;
}
