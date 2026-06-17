class AppShellProjectOpenController {
  AppShellProjectOpenController({
    required void Function() showWorkbench,
    required Future<void> Function() refreshProjectOpenView,
    required void Function(String entryId) selectProjectOpenEntry,
    required Future<void> Function(String projectPath)
    openProjectFromProjectOpen,
    required Future<void> Function() importLocalProjectFromProjectOpen,
  }) : _showWorkbench = showWorkbench,
       _refreshProjectOpenView = refreshProjectOpenView,
       _selectProjectOpenEntry = selectProjectOpenEntry,
       _openProjectFromProjectOpen = openProjectFromProjectOpen,
       _importLocalProjectFromProjectOpen = importLocalProjectFromProjectOpen;

  final void Function() _showWorkbench;
  final Future<void> Function() _refreshProjectOpenView;
  final void Function(String entryId) _selectProjectOpenEntry;
  final Future<void> Function(String projectPath) _openProjectFromProjectOpen;
  final Future<void> Function() _importLocalProjectFromProjectOpen;

  void onProjectOpenRefreshRequested() {
    // 中文注释: 项目入口页刷新只重建项目发现结果，不切换当前全局目的地。
    _refreshProjectOpenView();
  }

  void onProjectOpenCreateRequested() {
    // 中文注释: 新建项目入口仍先回到工作台，后续项目创建流程继续由既有主入口承接。
    _showWorkbench();
  }

  void onProjectOpenImportRequested() {
    // 中文注释: 本地导入只负责拉起宿主导入流程，不在这里自己处理目录合法性。
    _importLocalProjectFromProjectOpen();
  }

  void onProjectOpenEntrySelected(String entryId) {
    // 中文注释: 条目选中只更新项目入口页的局部视图态，不触发项目加载。
    _selectProjectOpenEntry(entryId);
  }

  void onProjectOpenOpenRequested(String projectPath) {
    // 中文注释: 打开动作只把路径交给统一开项目链路，不在入口页再做第二次判断。
    _openProjectFromProjectOpen(projectPath);
  }
}
