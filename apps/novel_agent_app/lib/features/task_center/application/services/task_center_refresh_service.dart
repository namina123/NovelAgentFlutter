import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_action_group_view_data.dart';
import '../../presentation/models/task_center_view_data.dart';
import 'task_center_command_orchestration_service.dart';
import 'task_center_guidance_revisit_markdown_service.dart';
import 'task_center_view_data_service.dart';

class TaskCenterRefreshRequest {
  const TaskCenterRefreshRequest({
    required this.project,
    required this.selectedTaskId,
    required this.selectedLongTaskRunPath,
    required this.selectedTaskQueueRunPath,
    required this.statusMessage,
    required this.taskCenterCommandInFlight,
    required this.runtimeProfile,
    required this.projectStorageStrategy,
  });

  final ProjectDescriptor? project;
  final String selectedTaskId;
  final String selectedLongTaskRunPath;
  final String selectedTaskQueueRunPath;
  final String statusMessage;
  final bool taskCenterCommandInFlight;
  final ProjectRuntimeProfile? runtimeProfile;
  final ProjectStorageStrategy? projectStorageStrategy;
}

class TaskCenterRefreshResult {
  const TaskCenterRefreshResult({
    required this.tasks,
    required this.selectedTaskId,
    required this.selectedLongTaskRunPath,
    required this.selectedTaskQueueRunPath,
    required this.statusMessage,
    required this.viewData,
  });

  final List<JsonMap> tasks;
  final String selectedTaskId;
  final String selectedLongTaskRunPath;
  final String selectedTaskQueueRunPath;
  final String statusMessage;
  final TaskCenterViewData viewData;
}

class TaskCenterRefreshService {
  const TaskCenterRefreshService({
    required TaskCenterRuntimeQueryPort runtimeQueryPort,
    TaskCenterViewDataService? taskCenterViewDataService,
    TaskCenterCommandOrchestrationService?
    taskCenterCommandOrchestrationService,
    TaskCenterGuidanceRevisitMarkdownService?
    taskCenterGuidanceRevisitMarkdownService,
  })  : _runtimeQueryPort = runtimeQueryPort,
        _taskCenterViewDataService =
            taskCenterViewDataService ?? const TaskCenterViewDataService(),
        _taskCenterCommandOrchestrationService =
            taskCenterCommandOrchestrationService ??
            const TaskCenterCommandOrchestrationService(),
        _taskCenterGuidanceRevisitMarkdownService =
            taskCenterGuidanceRevisitMarkdownService ??
            const TaskCenterGuidanceRevisitMarkdownService();

  final TaskCenterRuntimeQueryPort _runtimeQueryPort;
  final TaskCenterViewDataService _taskCenterViewDataService;
  final TaskCenterCommandOrchestrationService
  _taskCenterCommandOrchestrationService;
  final TaskCenterGuidanceRevisitMarkdownService
  _taskCenterGuidanceRevisitMarkdownService;

  Future<TaskCenterRefreshResult> refresh(TaskCenterRefreshRequest request) async {
    // 中文注释: 任务中心刷新把“读取运行态、整理选中项、拼装视图”收口到同一个正式服务，控制器只负责提交状态。
    final project = request.project;
    if (project == null) {
      return _buildEmptyResult(
        statusMessage: request.statusMessage.isEmpty
            ? '请先创建或打开项目。'
            : request.statusMessage,
        runtimeProfile: request.runtimeProfile,
        projectStorageStrategy: request.projectStorageStrategy,
      );
    }
    final tasks = await _runtimeQueryPort.listWorkflowTasks(project);
    final selectedTaskId = _initialSelectedTaskId(
      tasks: tasks,
      selectedTaskId: request.selectedTaskId,
    );
    final chainView = await _runtimeQueryPort.workflowChainView(project);
    final preflight = await _runtimeQueryPort.taskQueuePreflight(project);
    final scheduler = await _runtimeQueryPort.longTaskSchedulerPlan(project);
    final longTaskRuns = await _runtimeQueryPort.listLongTaskRuns(
      project,
      limit: 12,
    );
    final taskQueueRuns = await _runtimeQueryPort.listTaskQueueRuns(
      project,
      limit: 12,
    );
    final selectedLongTaskRunPath = _resolvedLongTaskRunPath(
      taskCenterRuns: longTaskRuns,
      selectedPath: request.selectedLongTaskRunPath,
    );
    final selectedTaskQueueRunPath = _taskCenterViewDataService
        .resolveSelectedTaskQueueRunPath(
          taskQueueRuns: taskQueueRuns,
          selectedTaskQueueRunPath: request.selectedTaskQueueRunPath,
        );
    final selectedLongRun = selectedLongTaskRunPath.isEmpty
        ? const <String, Object?>{}
        : await _runtimeQueryPort.loadLongTaskRun(
            project,
            selectedLongTaskRunPath,
          );
    final selectedQueueRun = selectedTaskQueueRunPath.isEmpty
        ? const <String, Object?>{}
        : await _runtimeQueryPort.loadTaskQueueRun(
            project,
            selectedTaskQueueRunPath,
          );
    final resolvedSelectedTaskId = _taskCenterViewDataService.resolveSelectedTaskId(
      tasks: tasks,
      selectedTaskId: selectedTaskId,
      selectedLongTaskRun: selectedLongRun,
      selectedTaskQueueRun: selectedQueueRun,
    );
    final selectedTask = _taskByPath(tasks, resolvedSelectedTaskId);
    final execution = selectedTask.isEmpty
        ? const <String, Object?>{}
        : await _runtimeQueryPort.loadWorkflowTaskExecution(
            project,
            _taskSelector(selectedTask),
          );
    final checkpointActionPackage = selectedTask.isEmpty
        ? const <String, Object?>{}
        : await _taskCenterCommandOrchestrationService.loadCheckpointActionPackage(
            project: project,
            task: selectedTask,
            execution: execution,
            loadActionPackage:
                _runtimeQueryPort.buildCheckpointReviewActionPackage,
          );
    final guidanceRevisitPackage = checkpointActionPackage.isEmpty
        ? const <String, Object?>{}
        : await _taskCenterCommandOrchestrationService.loadGuidanceRevisitPackage(
            project: project,
            checkpointActionPackage: checkpointActionPackage,
            loadGuidanceRevisitPackage:
                _runtimeQueryPort.buildCheckpointGuidanceRevisitPackage,
          );
    final revisionResolution = selectedTask.isEmpty
        ? const <String, Object?>{}
        : await _taskCenterCommandOrchestrationService.loadRevisionResolution(
            project: project,
            task: selectedTask,
            taskSelector: _taskSelector,
            loadRevisionResolution: _runtimeQueryPort.buildRevisionResolution,
          );
    final taskRunControlGroup = _taskCenterViewDataService.buildRunControlActionGroup(
      longTaskRun: selectedLongRun,
      task: selectedTask,
      selectedLongTaskRunPath: selectedLongTaskRunPath,
    );
    final taskUserOptionGroup = _taskCenterViewDataService.buildUserOptionActionGroup(
      task: selectedTask,
      execution: execution,
    );
    final longTaskRunsForViewData = selectedLongRun.isEmpty
        ? longTaskRuns
        : longTaskRuns
              .map(
                (record) =>
                    ValueReaders.stringValue(record['relative_path']) ==
                        selectedLongTaskRunPath
                    ? selectedLongRun
                    : record,
              )
              .toList(growable: false);
    final statusMessage = _settlePendingStatusIfNeeded(
      currentStatusMessage: request.statusMessage,
      taskCenterCommandInFlight: request.taskCenterCommandInFlight,
      selectedTask: selectedTask,
      selectedLongRun: selectedLongRun,
      selectedQueueRun: selectedQueueRun,
    );
    return TaskCenterRefreshResult(
      tasks: tasks,
      selectedTaskId: resolvedSelectedTaskId,
      selectedLongTaskRunPath: selectedLongTaskRunPath,
      selectedTaskQueueRunPath: selectedTaskQueueRunPath,
      statusMessage: statusMessage,
      viewData: _taskCenterViewDataService.build(
        tasks: tasks,
        modeDefinitions: _runtimeQueryPort.listTaskRuntimeModes(),
        selectedTaskId: resolvedSelectedTaskId,
        detailBody: _taskCenterViewDataService.buildDetailBody(
          selectedTask,
          execution: execution,
        ),
        queueSummary: _taskCenterViewDataService.buildQueueSummary(preflight),
        schedulerSummary: _taskCenterViewDataService.buildSchedulerSummary(
          scheduler,
        ),
        chainMarkdown: _taskCenterViewDataService.buildChainMarkdown(
          chainView,
        ),
        longTaskRuns: longTaskRunsForViewData,
        taskQueueRuns: taskQueueRuns,
        selectedLongTaskRunPath: selectedLongTaskRunPath,
        selectedTaskQueueRunPath: selectedTaskQueueRunPath,
        longTaskRunLog: selectedLongRun.isEmpty
            ? ''
            : _runtimeQueryPort.renderLongTaskRunMarkdown(selectedLongRun),
        resumeBriefBody: selectedLongRun.isEmpty
            ? ''
            : _taskCenterViewDataService.buildResumeBriefBody(
                selectedLongRun,
                checkpointActionPackage: checkpointActionPackage,
                revisionResolution: revisionResolution,
                selectedTask: selectedTask,
                selectedTaskExecution: execution,
              ),
        taskQueueRunLog: selectedQueueRun.isEmpty
            ? ''
            : _runtimeQueryPort.renderTaskQueueRunMarkdown(selectedQueueRun),
        runtimeProfile: request.runtimeProfile,
        projectStorageStrategy: request.projectStorageStrategy,
        nextTaskPath: ValueReaders.stringValue(
          ValueReaders.mapValue(chainView['next_task'])['relative_path'],
        ),
        nextPostprocessPath: ValueReaders.stringValue(
          ValueReaders.mapValue(chainView['next_postprocess_task'])['relative_path'],
        ),
        checkpointActionPackage: checkpointActionPackage,
        revisionResolution: revisionResolution,
        guidanceRevisitBody: _taskCenterGuidanceRevisitMarkdownService.render(
          guidanceRevisitPackage,
        ),
        status: statusMessage,
        supplementalActionGroups: <TaskCenterActionGroupViewData>[
          ?taskRunControlGroup,
          ?taskUserOptionGroup,
        ],
      ),
    );
  }

  TaskCenterRefreshResult _buildEmptyResult({
    required String statusMessage,
    required ProjectRuntimeProfile? runtimeProfile,
    required ProjectStorageStrategy? projectStorageStrategy,
  }) {
    // 中文注释: 没有项目时仍返回正式 view data，GUI 可以稳定显示空态而不是额外猜测。
    return TaskCenterRefreshResult(
      tasks: const <JsonMap>[],
      selectedTaskId: '',
      selectedLongTaskRunPath: '',
      selectedTaskQueueRunPath: '',
      statusMessage: statusMessage,
      viewData: _taskCenterViewDataService.build(
        tasks: const <JsonMap>[],
        modeDefinitions: _runtimeQueryPort.listTaskRuntimeModes(),
        selectedTaskId: '',
        detailBody: '请先创建或打开项目。任务只读取当前项目目录，不会跨项目共享。',
        queueSummary: '',
        schedulerSummary: '',
        chainMarkdown: '',
        longTaskRuns: const <JsonMap>[],
        taskQueueRuns: const <JsonMap>[],
        selectedLongTaskRunPath: '',
        selectedTaskQueueRunPath: '',
        longTaskRunLog: '',
        taskQueueRunLog: '',
        runtimeProfile: runtimeProfile,
        projectStorageStrategy: projectStorageStrategy,
        status: statusMessage,
      ),
    );
  }

  String _initialSelectedTaskId({
    required List<JsonMap> tasks,
    required String selectedTaskId,
  }) {
    // 中文注释: 刷新时如果当前没有选中项，就回到任务列表首项，保证详情区始终有稳定落点。
    if (selectedTaskId.trim().isNotEmpty) {
      return selectedTaskId.trim();
    }
    if (tasks.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(tasks.first['relative_path']);
  }

  String _resolvedLongTaskRunPath({
    required List<JsonMap> taskCenterRuns,
    required String selectedPath,
  }) {
    // 中文注释: 长任务运行记录优先保留当前选择；如果当前选择失效，则退回最新一条可见运行。
    if (taskCenterRuns.isEmpty) {
      return '';
    }
    final selectedRun = _runByPath(taskCenterRuns, selectedPath);
    if (selectedRun.isNotEmpty) {
      return ValueReaders.stringValue(selectedRun['relative_path']);
    }
    return ValueReaders.stringValue(taskCenterRuns.first['relative_path']);
  }

  JsonMap _taskByPath(List<JsonMap> tasks, String taskPath) {
    // 中文注释: 任务查找只按 relative_path 做唯一定位，避免控制器继续复制自己的查找逻辑。
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['relative_path']) == taskPath) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _runByPath(List<JsonMap> runs, String runPath) {
    // 中文注释: 运行记录定位与任务定位保持同样的单一路径真相，避免页面层自己再分叉。
    for (final run in runs) {
      if (ValueReaders.stringValue(run['relative_path']) == runPath) {
        return run;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _taskSelector(JsonMap task) {
    // 中文注释: 任务执行和修复动作统一复用这个 selector，避免 view 层拼接 task_id / relative_path 的双轨写法。
    return <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'task_id': ValueReaders.stringValue(task['id']),
    };
  }

  String _settlePendingStatusIfNeeded({
    required String currentStatusMessage,
    required bool taskCenterCommandInFlight,
    required JsonMap selectedTask,
    required JsonMap selectedLongRun,
    required JsonMap selectedQueueRun,
  }) {
    // 中文注释: 刷新结束后的状态文案只在非命令执行中收口，避免把“正在...”提示过早冲掉。
    if (taskCenterCommandInFlight || !currentStatusMessage.startsWith('正在')) {
      return currentStatusMessage;
    }
    final taskStatus = ValueReaders.stringValue(selectedTask['status']).trim();
    if (taskStatus == TaskRuntimeConstants.statusWaitingUser) {
      return '当前任务已进入等待确认，可使用右侧动作继续。';
    }
    if (taskStatus == TaskRuntimeConstants.statusFailed) {
      return '当前任务执行失败，请查看诊断并选择恢复动作。';
    }
    final queueStatus = ValueReaders.stringValue(
      selectedQueueRun['status'],
    ).trim();
    if (const <String>{
      'stopped',
      'paused',
      'completed',
      'failed',
      'waiting_user',
    }.contains(queueStatus)) {
      return '队列运行已推进。';
    }
    final longRunStatus = ValueReaders.stringValue(
      selectedLongRun['status'],
    ).trim();
    if (<String>{
      LongTaskRunStatus.waitingGate.id,
      LongTaskRunStatus.paused.id,
      LongTaskRunStatus.stopped.id,
      LongTaskRunStatus.failedManualAttention.id,
    }.contains(longRunStatus)) {
      return '长任务运行已进入下一状态。';
    }
    return currentStatusMessage;
  }
}
