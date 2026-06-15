import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/task_center_contract_action_view_data.dart';
import 'task_center_action_execution_outcome_service.dart';

class TaskCenterCommandEnvironment {
  const TaskCenterCommandEnvironment({
    required this.currentProject,
    required this.settings,
    required this.selectedTaskId,
    required this.setSelectedTaskId,
    required this.setTaskCenterCommandInFlight,
    required this.setTaskCenterStatusMessage,
    required this.selectedTaskSelector,
    required this.refreshTaskCenter,
    required this.refreshTaskCenterView,
    required this.requestTaskCenterLongTaskPulse,
    required this.syncWorkbenchResources,
    required this.adoptTaskCenterRunSelectionsFromResult,
    required this.refreshLongTaskStationAfterTaskCenterMutation,
  });

  final ProjectDescriptor? Function() currentProject;
  final AppSettings? Function() settings;
  final String Function() selectedTaskId;
  final void Function(String value) setSelectedTaskId;
  final void Function(bool value) setTaskCenterCommandInFlight;
  final void Function(String value) setTaskCenterStatusMessage;
  final JsonMap Function() selectedTaskSelector;
  final Future<void> Function({String? status}) refreshTaskCenter;
  final Future<void> Function() refreshTaskCenterView;
  final void Function() requestTaskCenterLongTaskPulse;
  final Future<void> Function() syncWorkbenchResources;
  final Future<void> Function(JsonMap result)
  adoptTaskCenterRunSelectionsFromResult;
  final Future<void> Function()
  refreshLongTaskStationAfterTaskCenterMutation;
}

class TaskCenterCommandOrchestrationService {
  const TaskCenterCommandOrchestrationService({
    TaskCenterActionExecutionOutcomeService? actionExecutionOutcomeService,
  }) : _actionExecutionOutcomeService =
           actionExecutionOutcomeService ?? const TaskCenterActionExecutionOutcomeService();

  final TaskCenterActionExecutionOutcomeService
  _actionExecutionOutcomeService;

  Future<void> runSelectorCommand({
    required TaskCenterCommandEnvironment environment,
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      JsonMap selector,
      AppSettings? settings,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 选中任务相关动作统一收进一个编排入口，避免控制器反复实现项目检查、设置检查和刷新闭环。
    final project = environment.currentProject();
    if (project == null) {
      await environment.refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final selector = environment.selectedTaskSelector();
    if (selector.isEmpty) {
      await environment.refreshTaskCenter(status: '请先选择一个任务。');
      return;
    }
    final settings = environment.settings();
    if (requireSettings && settings == null) {
      await environment.refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    await _runCommand(
      environment: environment,
      pendingMessage: pendingMessage,
      successMessage: successMessage,
      operation: () => operation(project, selector, settings),
      afterOperation: (result) async {
        await environment.syncWorkbenchResources();
        await environment.adoptTaskCenterRunSelectionsFromResult(result);
        await environment.refreshLongTaskStationAfterTaskCenterMutation();
      },
    );
  }

  Future<void> runProjectCommand({
    required TaskCenterCommandEnvironment environment,
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 不依赖具体任务选择的项目级动作也交给统一闭环处理，保证任务中心不会散出多套刷新逻辑。
    final project = environment.currentProject();
    if (project == null) {
      await environment.refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final settings = environment.settings();
    if (requireSettings && settings == null) {
      await environment.refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    await _runCommand(
      environment: environment,
      pendingMessage: pendingMessage,
      successMessage: successMessage,
      operation: () => operation(project, settings),
      afterOperation: (result) async {
        await environment.syncWorkbenchResources();
        await environment.adoptTaskCenterRunSelectionsFromResult(result);
        await environment.refreshLongTaskStationAfterTaskCenterMutation();
      },
    );
  }

  Future<void> runRecentRunCommand({
    required TaskCenterCommandEnvironment environment,
    required String pendingMessage,
    required String successMessage,
    required Future<List<JsonMap>> Function(ProjectDescriptor project)
    loadRecentRuns,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
      String runPath,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 暂停/恢复等动作依赖最近运行记录，这里统一把最近 run 查找、空态提示和操作闭环收敛起来。
    final project = environment.currentProject();
    if (project == null) {
      await environment.refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final recentRuns = await loadRecentRuns(project);
    final runPath = recentRuns.isEmpty
        ? ''
        : ValueReaders.stringValue(recentRuns.first['relative_path']);
    if (runPath.trim().isEmpty) {
      await environment.refreshTaskCenter(status: '当前没有可操作的长任务运行记录。');
      return;
    }
    final settings = environment.settings();
    if (requireSettings && settings == null) {
      await environment.refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    await _runCommand(
      environment: environment,
      pendingMessage: pendingMessage,
      successMessage: successMessage,
      operation: () => operation(project, settings, runPath),
      afterOperation: (result) async {
        await environment.syncWorkbenchResources();
        await environment.adoptTaskCenterRunSelectionsFromResult(result);
        await environment.refreshLongTaskStationAfterTaskCenterMutation();
      },
    );
  }

  Future<void> runSharedActionCommand({
    required TaskCenterCommandEnvironment environment,
    required TaskCenterContractActionViewData action,
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 共享动作执行后需要统一更新选中任务与状态文案，避免控制器再去理解各类 runtime 返回结构。
    final project = environment.currentProject();
    if (project == null) {
      await environment.refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final settings = environment.settings();
    if (requireSettings && settings == null) {
      await environment.refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    environment.setTaskCenterCommandInFlight(true);
    try {
      environment.setTaskCenterStatusMessage(pendingMessage);
      await environment.refreshTaskCenterView();
      environment.requestTaskCenterLongTaskPulse();
      final result = await operation(project, settings);
      final outcome = _actionExecutionOutcomeService.resolve(
        action: action,
        result: result,
        defaultSuccessMessage: successMessage,
        currentSelectedTaskId: environment.selectedTaskId(),
      );
      if (outcome.nextSelectedTaskId.trim().isNotEmpty) {
        environment.setSelectedTaskId(outcome.nextSelectedTaskId);
      }
      await environment.syncWorkbenchResources();
      await environment.adoptTaskCenterRunSelectionsFromResult(result);
      await environment.refreshLongTaskStationAfterTaskCenterMutation();
      await environment.refreshTaskCenter(status: outcome.statusMessage);
    } finally {
      environment.setTaskCenterCommandInFlight(false);
    }
  }

  Future<JsonMap> loadCheckpointActionPackage({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap execution,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      String checkpointReviewPath,
    )
    loadActionPackage,
  }) async {
    // 中文注释: 检查点动作包只负责挑出有效 review 路径，不在控制器里重复散布 path truth。
    final checkpointReviewPath = checkpointReviewPathOf(task, execution);
    if (checkpointReviewPath.isEmpty) {
      return const <String, Object?>{};
    }
    if (ValueReaders.stringValue(task['task_type']) == 'revision') {
      return const <String, Object?>{};
    }
    if (ValueReaders.stringValue(
      task['selected_user_option_prompt'],
    ).trim().isNotEmpty) {
      return const <String, Object?>{};
    }
    return loadActionPackage(project, checkpointReviewPath);
  }

  Future<JsonMap> loadRevisionResolution({
    required ProjectDescriptor project,
    required JsonMap task,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      JsonMap selector,
    )
    loadRevisionResolution,
    required JsonMap Function(JsonMap task) taskSelector,
  }) async {
    // 中文注释: revision 专属动作只消费统一的 revision resolution 合同，不在壳层里重写分支判断。
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return const <String, Object?>{};
    }
    return loadRevisionResolution(project, taskSelector(task));
  }

  Future<JsonMap> loadGuidanceRevisitPackage({
    required ProjectDescriptor project,
    required JsonMap checkpointActionPackage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      String checkpointReviewPath,
    )
    loadGuidanceRevisitPackage,
  }) async {
    // 中文注释: 长期约束回看只在 checkpoint 动作明确要求时加载，避免页面层自行猜测什么时候该回看。
    for (final action in ValueReaders.mapList(
      checkpointActionPackage['actions'],
    )) {
      if (ValueReaders.stringValue(action['id']) == 'revisit_mode_guidance' &&
          ValueReaders.boolValue(action['enabled'])) {
        final checkpointReviewPath = ValueReaders.stringValue(
          checkpointActionPackage['checkpoint_review_path'],
        ).trim();
        if (checkpointReviewPath.isEmpty) {
          return const <String, Object?>{};
        }
        return loadGuidanceRevisitPackage(project, checkpointReviewPath);
      }
    }
    return const <String, Object?>{};
  }

  String checkpointReviewPathOf(JsonMap task, JsonMap execution) {
    // 中文注释: 旧运行记录可能把检查点路径放在 task 或 execution 的不同字段里，这里只做唯一收敛，不新增分叉 truth。
    for (final candidate in <String>[
      ValueReaders.stringValue(task['postprocess_checkpoint_review_path']),
      ValueReaders.stringValue(task['checkpoint_review_path']),
      ValueReaders.stringValue(execution['postprocess_checkpoint_review_path']),
      ValueReaders.stringValue(execution['checkpoint_review_path']),
    ]) {
      final clean = candidate.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }

  Future<void> _runCommand({
    required TaskCenterCommandEnvironment environment,
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function() operation,
    Future<void> Function(JsonMap result)? afterOperation,
  }) async {
    // 中文注释: 所有 task center 命令共用同一执行壳，统一处理 in-flight 标记、脉冲刷新和结果后收口。
    environment.setTaskCenterCommandInFlight(true);
    try {
      environment.setTaskCenterStatusMessage(pendingMessage);
      await environment.refreshTaskCenterView();
      environment.requestTaskCenterLongTaskPulse();
      final result = await operation();
      if (afterOperation != null) {
        await afterOperation(result);
      }
      await environment.refreshTaskCenter(
        status: _resultMessage(result, success: successMessage),
      );
    } finally {
      environment.setTaskCenterCommandInFlight(false);
    }
  }

  String _resultMessage(JsonMap result, {required String success}) {
    // 中文注释: 结果文案只做统一翻译，不把业务判断重新回流到控制器里。
    if (ValueReaders.boolValue(result['ok'])) {
      final warning = ValueReaders.stringValue(result['warning']).trim();
      return warning.isEmpty ? success : '$success $warning';
    }
    final error = ValueReaders.stringValue(result['error']).trim();
    return error.isEmpty ? '操作失败。' : '操作失败：$error';
  }
}
