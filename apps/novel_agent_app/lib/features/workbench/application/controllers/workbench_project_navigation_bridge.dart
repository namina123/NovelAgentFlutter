part of 'workbench_workspace_controller.dart';

class WorkbenchProjectNavigationBridge {
  WorkbenchProjectNavigationBridge(this._controller);

  final WorkbenchWorkspaceController _controller;

  void onModelSettingsRequested() {
    // 中文注释: 顶部设置入口只负责导航，不在工作区里再造一套设置逻辑。
    _controller._showSettings();
  }

  void onCreateProjectRequested() {
    _controller._projectCreationController?.onCreateProjectRequested();
  }

  void onOpenProjectRequested() {
    _controller._projectCreationController?.onOpenProjectRequested();
  }

  void onProjectLauncherDismissed() {
    _controller._projectCreationController?.onProjectLauncherDismissed();
  }

  void onProjectLauncherRefreshRequested() {
    _controller._projectCreationController?.onProjectLauncherRefreshRequested();
  }

  void onProjectEntryOpened(String projectPath) {
    _controller._projectCreationController?.onProjectEntryOpened(projectPath);
  }

  void onProjectCreationBackRequested() {
    _controller._projectCreationController?.onProjectCreationBackRequested();
  }

  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) {
    _controller._projectCreationController?.onProjectCreationSubmitted(request);
  }

  void onAgentEcosystemRequested() {
    _controller._showAgentEcosystem();
  }

  void onCurrentAgentSkillLoadoutRequested() {
    final agentId = _controller._readWorkbench().agentSelector.currentAgentId.trim();
    if (agentId.isEmpty) {
      _controller._announce('当前没有可定位的会话智能体。');
      return;
    }
    _controller._showCurrentAgentSkillLoadout(agentId);
  }

  void onCurrentAgentExpressionConstraintsRequested() {
    final agentId = _controller._readWorkbench().agentSelector.currentAgentId.trim();
    if (agentId.isEmpty) {
      _controller._announce('当前没有可定位的会话智能体。');
      return;
    }
    _controller._showCurrentAgentExpressionConstraints(agentId);
  }

  void onTasksRequested() => _controller._showLongTaskStation();

  void onLongTaskStationRequested() => _controller._showLongTaskStation();

  void onReviewsRequested() => _controller._showLongTaskStation();

  void onTemplatesRequested() => _controller._showPromptTemplates();

  void onProjectAssetsRequested() => _controller._showProjectAssets();

  void onProjectRagRequested() => _controller._showProjectRagAssets();

  void onInspirationWorkbenchRequested() => _controller._showInspirationWorkbench();
}
