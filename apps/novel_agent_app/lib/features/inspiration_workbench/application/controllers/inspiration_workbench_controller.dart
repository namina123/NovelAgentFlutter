import 'package:flutter/foundation.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/contracts/inspiration_workbench_action_handler.dart';
import '../../presentation/models/inspiration_workbench_view_data.dart';
import '../models/inspiration_workbench_snapshot.dart';
import '../services/inspiration_workbench_loader_service.dart';
import '../services/inspiration_workbench_long_task_launcher_service.dart';
import '../services/inspiration_workbench_view_data_service.dart';

class InspirationWorkbenchController extends ChangeNotifier
    implements InspirationWorkbenchActionHandler {
  InspirationWorkbenchController({
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required AnswerModeGuidanceStageUseCase answerModeGuidanceStageUseCase,
    BuildModeGuidancePlanInputUseCase? buildModeGuidancePlanInputUseCase,
    ProjectWorkflowRuntimeService? workflowRuntimeService,
    required ProjectDescriptor? Function() readCurrentProject,
    required String Function() readCurrentProjectTitle,
    required Future<void> Function() syncWorkbenchResources,
    required VoidCallback onBackRequested,
    required Future<void> Function() showTaskCenterRequested,
    InspirationWorkbenchLoaderService? loaderService,
    InspirationWorkbenchLongTaskLauncherService? longTaskLauncherService,
    InspirationWorkbenchViewDataService? viewDataService,
  }) : assert(
         longTaskLauncherService != null ||
             (buildModeGuidancePlanInputUseCase != null &&
                 workflowRuntimeService != null),
       ),
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _readCurrentProject = readCurrentProject,
       _readCurrentProjectTitle = readCurrentProjectTitle,
       _syncWorkbenchResources = syncWorkbenchResources,
       _onBackRequested = onBackRequested,
       _showTaskCenterRequested = showTaskCenterRequested,
       _loaderService =
           loaderService ??
           InspirationWorkbenchLoaderService(
             loadModeGuidanceStateUseCase: loadModeGuidanceStateUseCase,
           ),
       _longTaskLauncherService =
           longTaskLauncherService ??
           InspirationWorkbenchLongTaskLauncherService(
             buildModeGuidancePlanInputUseCase:
                 buildModeGuidancePlanInputUseCase!,
             workflowRuntimeService: workflowRuntimeService!,
           ),
       _viewDataService =
           viewDataService ?? InspirationWorkbenchViewDataService(),
       _snapshot = InspirationWorkbenchSnapshot.initial(),
       _viewData = InspirationWorkbenchViewData.initial();

  final AnswerModeGuidanceStageUseCase _answerModeGuidanceStageUseCase;
  final ProjectDescriptor? Function() _readCurrentProject;
  final String Function() _readCurrentProjectTitle;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final Future<void> Function() _showTaskCenterRequested;
  final InspirationWorkbenchLoaderService _loaderService;
  final InspirationWorkbenchLongTaskLauncherService _longTaskLauncherService;
  final InspirationWorkbenchViewDataService _viewDataService;

  InspirationWorkbenchSnapshot _snapshot;
  InspirationWorkbenchViewData _viewData;
  String _statusMessage = '';
  bool _disposed = false;

  InspirationWorkbenchViewData get viewData => _viewData;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh({String? status, String? preferredModeId}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _snapshot = InspirationWorkbenchSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开项目。';
      _rebuildView();
      return;
    }
    final resolvedModeId = _loaderService.resolveDefaultModeId(
      preferredModeId ?? _snapshot.selectedModeId,
    );
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      selectedModeId: resolvedModeId,
    );
    _statusMessage = status ?? '正在加载灵感工作台...';
    _rebuildView();
    try {
      _snapshot = await _loaderService.load(
        project,
        modeId: resolvedModeId,
        selectedStageId: _snapshot.selectedStageId,
      );
      _statusMessage = status ?? _readyStatus(_snapshot);
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '加载灵感工作台失败：$error';
      _rebuildView();
    }
  }

  @override
  void onInspirationWorkbenchBackRequested() => _onBackRequested();

  @override
  void onInspirationWorkbenchRefreshRequested() {
    refresh();
  }

  @override
  void onInspirationWorkbenchModeSelected(String modeId) {
    refresh(preferredModeId: modeId.trim());
  }

  @override
  void onInspirationWorkbenchStageSelected(String stageId) {
    _snapshot = _snapshot.copyWith(selectedStageId: stageId.trim());
    _rebuildView();
  }

  @override
  Future<void> onInspirationWorkbenchOptionSelected({
    required String stageId,
    required String fieldKey,
    required String value,
    required String label,
  }) async {
    await _submitAnswer(
      stageId: stageId,
      fieldKey: fieldKey,
      value: value,
      label: label,
      source: 'option',
    );
  }

  @override
  Future<void> onInspirationWorkbenchTextSubmitted({
    required String stageId,
    required String fieldKey,
    required String value,
  }) async {
    await _submitAnswer(
      stageId: stageId,
      fieldKey: fieldKey,
      value: value,
      label: value,
      source: 'free_text',
    );
  }

  @override
  Future<void> onInspirationWorkbenchLongTaskLaunchRequested() async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    if (project.projectType.trim() != 'long_novel') {
      _statusMessage = '只有长任务项目才会显示长任务启动入口。';
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在根据当前灵感约束生成长任务队列...';
    _rebuildView();
    try {
      final result = await _longTaskLauncherService.launch(
        project,
        modeId: _snapshot.selectedModeId,
      );
      await _syncWorkbenchResources();
      if (result.ok) {
        _statusMessage = '${result.message} 已自动切到长任务总站。';
        _snapshot = _snapshot.copyWith(isLoading: false);
        _rebuildView();
        await _showTaskCenterRequested();
        return;
      }
      _statusMessage = result.message;
      _snapshot = _snapshot.copyWith(isLoading: false);
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '启动长任务失败：$error';
      _rebuildView();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _submitAnswer({
    required String stageId,
    required String fieldKey,
    required String value,
    required String label,
    required String source,
  }) async {
    final project = _readCurrentProject();
    final cleanValue = value.trim();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    if (cleanValue.isEmpty) {
      _statusMessage = '请先填写当前阶段内容。';
      _rebuildView();
      return;
    }
    try {
      final state = await _answerModeGuidanceStageUseCase.execute(
        project,
        modeId: _snapshot.selectedModeId,
        stageId: stageId.trim(),
        fieldKey: fieldKey.trim(),
        value: cleanValue,
        label: label.trim(),
        source: source,
      );
      await _syncWorkbenchResources();
      _snapshot = await _loaderService.load(
        project,
        modeId: _snapshot.selectedModeId,
        selectedStageId: state.currentStageId,
      );
      _statusMessage = state.isReady
          ? _readyCompletionStatus(project.projectType)
          : '当前阶段已保存，项目资产投影已同步更新。';
      _rebuildView();
    } catch (error) {
      _statusMessage = '保存灵感阶段失败：$error';
      _rebuildView();
    }
  }

  void _rebuildView() {
    _viewData = _viewDataService.build(
      projectTitle: _readCurrentProjectTitle(),
      snapshot: _snapshot,
      status: _statusMessage,
    );
    if (!_disposed) {
      notifyListeners();
    }
  }

  String _readyStatus(InspirationWorkbenchSnapshot snapshot) {
    final state = snapshot.state;
    if (state == null) {
      return '请先创建或打开项目。';
    }
    if (state.isReady) {
      return _readyCompletionStatus(snapshot.projectType);
    }
    return '灵感工作台已加载，可继续整理并沉淀项目资产。';
  }

  String _readyCompletionStatus(String projectType) {
    if (projectType.trim() == 'long_novel') {
      return '灵感约束已收束完成，相关 premise/style/world/characters 已同步到项目资产。现在可以直接点击“启动长任务”。';
    }
    return '灵感约束已收束完成，相关 premise/style/world/characters 已同步到项目资产。';
  }
}
