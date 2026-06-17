part of 'workbench_workspace_controller.dart';

class WorkbenchWorkspaceStateController {
  WorkbenchWorkspaceStateController(this._controller);

  final WorkbenchWorkspaceController _controller;

  ProjectDescriptor? get currentProject =>
      _controller._readProjectState().currentProject;

  ProjectRuntimeProfile? get currentProjectRuntimeProfile =>
      _controller._readProjectState().currentRuntimeProfile;

  WorkbenchProjectRuntimeState get currentProjectRuntimeState =>
      _controller._readProjectState();

  JsonMap currentProjectInfo() {
    // 中文注释: 工作区状态层只暴露轻量项目摘要，避免把完整项目对象扩散到其他层。
    final project = currentProject;
    if (project == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
    };
  }

  String get activeDocumentPath =>
      _controller._readWorkbench().activeDocumentPath;

  String get activeDocumentBody =>
      _controller._activeOpenDocument()?.content ?? '';

  OpenDocumentState? activeOpenDocument() => _controller._activeOpenDocument();

  Future<void> openResource(String relativePath) async {
    // 中文注释: 资源打开入口保留在状态层，具体读盘依旧由工作区内部实现。
    await _controller._openResource(relativePath);
  }

  Future<void> saveCurrentDocument() async {
    // 中文注释: 保存活动文档是工作区状态的一部分，不属于项目动作或导航。
    await _controller._saveCurrentDocument();
  }

  bool stageGeneratedDraftOnActiveDocument(String content) {
    // 中文注释: fallback 草稿只允许暂存到当前文档，不能冒充正式产物。
    final active = _controller._activeOpenDocument();
    final trimmedContent = content.trim();
    if (active == null || trimmedContent.isEmpty) {
      return false;
    }
    _controller._replaceOpenDocument(
      active.copyWith(
        content: content,
        isDirty: true,
        isRendered: false,
        isBufferedDraft: true,
      ),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyWorkbenchState(current),
    );
    _controller._persistWorkbenchSnapshot();
    return true;
  }

  WorkbenchViewData applyWorkbenchState(WorkbenchViewData base) {
    // 中文注释: 工作台投影仍然由工作区状态层统一生成。
    return _controller._projectedWorkbenchState(base);
  }

  Future<bool> loadProject(String rootPath) async {
    // 中文注释: 项目加载属于工作区状态生命周期，保持单一入口。
    return _controller.loadProject(rootPath);
  }

  Future<void> refreshProjectLongTaskSummary() async {
    // 中文注释: 长任务摘要刷新仍属于工作区状态刷新的一部分。
    await _controller.refreshProjectLongTaskSummary();
  }

  Future<List<ResourceEntryViewData>> reloadResourceEntries({
    required String selectedId,
  }) async {
    return _controller.reloadResourceEntries(selectedId: selectedId);
  }

  Future<String> resolvedDocumentBody({
    required ProjectDescriptor project,
    required String generatedMarkdown,
    required String relativePath,
  }) async {
    return _controller.resolvedDocumentBody(
      project: project,
      generatedMarkdown: generatedMarkdown,
      relativePath: relativePath,
    );
  }

  void openOrActivateDocument({
    required String relativePath,
    required String title,
    required String content,
  }) {
    _controller.openOrActivateDocument(
      relativePath: relativePath,
      title: title,
      content: content,
    );
  }

  Future<void> restoreWorkbenchSnapshot(ProjectDescriptor project) async {
    await _controller.restoreWorkbenchSnapshot(project);
  }

  void resetToProjectlessWorkbench({required String status}) {
    _controller.resetToProjectlessWorkbench(status: status);
  }
}
