part of 'workbench_workspace_controller.dart';

class WorkbenchProjectActionFacade {
  WorkbenchProjectActionFacade(this._controller);

  final WorkbenchWorkspaceController _controller;

  void onProjectTypeTransitionRequested() {
    // 中文注释: 项目类型转换入口交给专门的项目动作 facade，避免工作区状态层再长计划逻辑。
    _controller.onProjectTypeTransitionRequested();
  }

  void onRefreshFilesRequested() {
    _controller.onRefreshFilesRequested();
  }

  void onImportRequested() {
    _controller.onImportRequested();
  }

  void onCreateFileRequested() {
    _controller.onCreateFileRequested();
  }

  void onCreateFolderRequested() {
    _controller.onCreateFolderRequested();
  }

  void onCreateChapterRequested() {
    _controller.onCreateChapterRequested();
  }

  void onSaveCurrentRequested() {
    _controller.onSaveCurrentRequested();
  }

  void onProjectAgentGroupRequested() {
    _controller.onProjectAgentGroupRequested();
  }

  void onProjectAgentGroupDismissed() {
    _controller.onProjectAgentGroupDismissed();
  }

  void onProjectAgentGroupSelected(String groupId) {
    _controller.onProjectAgentGroupSelected(groupId);
  }

  void onResourceEntrySelected(String entryId) {
    _controller.onResourceEntrySelected(entryId);
  }

  Future<void> onPendingResearchApproved(String requestId) async {
    await _controller.onPendingResearchApproved(requestId);
  }

  Future<void> onPendingResearchRejected(String requestId) async {
    await _controller.onPendingResearchRejected(requestId);
  }

  void onWorkspaceCommandDismissed() {
    _controller.onWorkspaceCommandDismissed();
  }

  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {
    _controller.onWorkspaceImportFilesPickRequested(request);
  }

  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    _controller.onWorkspaceCommandSubmitted(request);
  }

  void onDocumentActionRequested(DocumentToolbarAction action) {
    _controller.onDocumentActionRequested(action);
  }

  void onDocumentSelected(String documentId) {
    _controller.onDocumentSelected(documentId);
  }

  void onDocumentClosed(String documentId) {
    _controller.onDocumentClosed(documentId);
  }

  void onDocumentBodyChanged(String value) {
    _controller.onDocumentBodyChanged(value);
  }

  void onEditProjectInfoRequested() {
    _controller.onEditProjectInfoRequested();
  }
}
