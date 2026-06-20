part of 'workbench_workspace_controller.dart';

class WorkbenchProjectActionFacade {
  WorkbenchProjectActionFacade(this._controller);

  final WorkbenchWorkspaceController _controller;
  final ProjectRuntimeBaselineCatalogService _runtimeBaselineCatalogService =
      const ProjectRuntimeBaselineCatalogService();

  void onProjectTypeTransitionRequested() {
    // 中文注释: 项目类型转换入口交给专门的项目动作 facade，避免工作区状态层再长计划逻辑。
    final project = _controller.currentProject;
    if (project == null) {
      _controller._announce('请先打开项目。');
      return;
    }
    final targetProjectTypeId = _controller._projectTypeTransitionTargetId(
      project.projectType,
    );
    final hasActiveLongTaskRun = _controller
        ._readProjectState()
        .currentProjectLongTaskRuns
        .any((run) => run.isActive);
    final runtimeBaselineId = _runtimeBaselineCatalogService
        .normalizeForProjectType(targetProjectTypeId, '');
    final plan = _controller._projectTypeTransitionPreparationService.prepare(
      project: project,
      targetProjectTypeId: targetProjectTypeId,
      runtimeBaselineId: runtimeBaselineId,
      hasActiveLongTaskRun: hasActiveLongTaskRun,
    );
    _controller._showWorkspaceCommand(
      _controller._projectTypeTransitionCommandViewDataService.build(
        project: project,
        plan: plan,
        runtimeBaselineId: runtimeBaselineId,
        confirmLabel: plan.canTransition ? '执行转换' : '重新检查',
      ),
    );
  }

  void onRefreshFilesRequested() {
    final project = _controller.currentProject;
    if (project == null) {
      unawaited(_controller._projectCreationController?.loadDefaultProject());
      return;
    }
    unawaited(_refreshFiles(project));
  }

  void onImportRequested() {
    final project = _controller.currentProject;
    if (project == null) {
      _controller._announce('请先打开项目。');
      return;
    }
    _controller._showWorkspaceCommand(
      _controller._projectImportWorkspaceCommandViewDataService.build(
        projectType: project.projectType,
        storageStrategy: project.storageStrategy,
        smartAnalysisModelOptions: _controller._smartAnalysisModelOptions(),
        smartDeconstructionModelOptions: _controller
            ._smartDeconstructionModelOptions(),
        requestedTargetDirectory: _controller
            ._workspaceCommandDefaultTargetService
            .importTargetDirectory(storageStrategy: project.storageStrategy),
      ),
    );
  }

  void onCreateFileRequested() {
    final project = _controller.currentProject;
    if (project == null) {
      _controller._announce('请先打开项目。');
      return;
    }
    _controller._showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFile,
        title: '新建文件',
        description: '在当前项目中创建一个新的文本文件。',
        confirmLabel: '创建文件',
        status: '',
        projectTitle: project.name,
        projectType: project.projectType,
        genre: '',
        premise: '',
        notes: '',
        relativePath: _controller._workspaceCommandDefaultTargetService
            .createFileDirectory(storageStrategy: project.storageStrategy),
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  void onCreateFolderRequested() {
    final project = _controller.currentProject;
    if (project == null) {
      _controller._announce('请先打开项目。');
      return;
    }
    _controller._showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFolder,
        title: '新建文件夹',
        description: '在当前项目中创建一个新的资源目录。',
        confirmLabel: '创建文件夹',
        status: '',
        projectTitle: project.name,
        projectType: project.projectType,
        genre: '',
        premise: '',
        notes: '',
        relativePath: _controller._workspaceCommandDefaultTargetService
            .createFolderParentDirectory(
              storageStrategy: project.storageStrategy,
            ),
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  void onCreateChapterRequested() {
    _controller.onCreateChapterRequested();
  }

  void onSaveCurrentRequested() {
    unawaited(_controller._saveCurrentDocument());
  }

  void onProjectAgentGroupRequested() {
    if (_controller.currentProject == null) {
      _controller._announce('请先打开项目。');
      return;
    }
    final overlay = _controller._readProjectAgentGroupWorkspaceViewData();
    if (overlay == null) {
      _controller._announce('当前项目还没有可配置的智能体组信息。');
      return;
    }
    _controller._mutateWorkbench(
      (current) => current.copyWith(projectAgentGroupWorkspace: overlay),
    );
  }

  void onProjectAgentGroupDismissed() {
    _controller._mutateWorkbench(
      (current) => current.copyWith(projectAgentGroupWorkspace: null),
    );
  }

  void onProjectAgentGroupSelected(String groupId) {
    unawaited(_controller._selectProjectAgentGroupAndRefreshOverlay(groupId));
  }

  void onResourceEntrySelected(String entryId) {
    unawaited(_controller._openResource(entryId));
  }

  Future<void> onPendingResearchApproved(String requestId) async {
    await _controller._applyPendingResearchAction(
      requestId,
      successMessage: '已通过资料请求。',
      action: (service, project, cleanRequestId) =>
          service.approve(project, requestId: cleanRequestId),
    );
  }

  Future<void> onPendingResearchRejected(String requestId) async {
    await _controller._applyPendingResearchAction(
      requestId,
      successMessage: '已拒绝资料请求。',
      action: (service, project, cleanRequestId) =>
          service.reject(project, requestId: cleanRequestId),
    );
  }

  void onWorkspaceCommandDismissed() {
    _controller._mutateWorkbench(
      (current) => current.copyWith(workspaceCommand: null),
    );
  }

  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    unawaited(_controller._pickImportFiles(request));
  }

  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    unawaited(_controller._pickImportDirectory(request));
  }

  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    switch (request.mode) {
      case WorkspaceCommandMode.editProjectInfo:
        unawaited(_controller._submitProjectInfoCommand(request));
        break;
      case WorkspaceCommandMode.transitionProjectType:
        unawaited(_controller._submitProjectTypeTransitionCommand(request));
        break;
      case WorkspaceCommandMode.createFile:
        unawaited(_controller._submitCreateFileCommand(request));
        break;
      case WorkspaceCommandMode.createFolder:
        unawaited(_controller._submitCreateFolderCommand(request));
        break;
      case WorkspaceCommandMode.importFiles:
        unawaited(_controller._submitImportFilesCommand(request));
        break;
    }
  }

  void onDocumentActionRequested(DocumentToolbarAction action) {
    switch (action) {
      case DocumentToolbarAction.outline:
        _controller._openLikelyOutlineDocument();
        break;
      case DocumentToolbarAction.render:
        _controller._toggleActiveDocumentRenderMode();
        break;
      case DocumentToolbarAction.save:
        unawaited(_controller._saveCurrentDocument());
        break;
      case DocumentToolbarAction.review:
        unawaited(_controller._createReviewTaskForCurrentDocument());
        break;
    }
  }

  void onDocumentSelected(String documentId) {
    final state = _controller._readProjectState();
    if (!state.openDocuments.any((document) => document.id == documentId)) {
      return;
    }
    _controller._writeProjectState(
      state.copyWith(activeOpenDocumentId: documentId),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyWorkbenchState(current),
    );
    _controller._scheduleWorkbenchSnapshotPersistence(
      refreshDraftRecoveries: false,
    );
  }

  void onDocumentClosed(String documentId) {
    final state = _controller._readProjectState();
    final nextDocuments = state.openDocuments
        .where((document) => document.id != documentId)
        .toList(growable: false);
    final nextActiveId = nextDocuments.isEmpty
        ? ''
        : state.activeOpenDocumentId == documentId
        ? nextDocuments.last.id
        : state.activeOpenDocumentId;
    _controller._writeProjectState(
      state.copyWith(
        openDocuments: nextDocuments,
        activeOpenDocumentId: nextActiveId,
      ),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyWorkbenchState(current),
    );
    _controller._scheduleWorkbenchSnapshotPersistence();
  }

  void onDocumentBodyChanged(String value) {
    final active = _controller._activeOpenDocument();
    if (active == null) {
      return;
    }
    _controller._replaceOpenDocument(
      active.copyWith(
        content: value,
        isDirty: true,
        isRendered: false,
        isBufferedDraft: false,
      ),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyWorkbenchState(current),
    );
    // 中文注释: 正文一旦变脏，就安排一次去抖持久化，确保草稿恢复快照能跟上最新未保存内容。
    _controller._scheduleWorkbenchSnapshotPersistence();
  }

  void onEditProjectInfoRequested() {
    _controller.onEditProjectInfoRequested();
  }

  Future<void> _refreshFiles(ProjectDescriptor project) async {
    try {
      final selectedId = _controller._readWorkbench().activeDocumentPath;
      final resourceEntries = await _controller.reloadResourceEntries(
        selectedId: selectedId,
      );
      _controller._mutateWorkbench(
        (current) => _controller.applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            informationViewData: _controller._latestInformationViewData,
            generationStatus: '已刷新 ${project.name} 的资源视图。',
          ),
        ),
      );
    } catch (error) {
      _controller._announce('刷新项目文件失败：$error');
    }
  }
}
