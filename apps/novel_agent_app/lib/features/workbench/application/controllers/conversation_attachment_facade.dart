part of 'workbench_conversation_controller.dart';

class ConversationAttachmentFacade {
  ConversationAttachmentFacade(this._controller);

  final WorkbenchConversationController _controller;

  Future<void> onAttachmentRequested() async {
    // 中文注释: 附件入口只管 picker、权限门槛与 session 草稿，不把文件探测和发送链塞回 controller 总中心。
    if (_controller._readRuntimeState().activeModeGuidanceState != null) {
      _controller._announce('当前引导阶段暂不接受会话附件。');
      return;
    }
    final capabilities = const ConversationInputCapabilityService().resolve(
      context: _controller._readWorkbench().inputCapabilityContext.copyWith(
        hasActiveProject: _controller._workspaceController.currentProject != null,
        isGenerating: _controller._readWorkbench().isGenerating,
      ),
    );
    if (!capabilities.supportsAttachmentEntry) {
      _controller._announce('当前模型或本机环境暂不支持会话附件。');
      return;
    }
    if (_controller._readWorkbench().isGenerating) {
      _controller._announce('请等待当前生成结束后再选择附件。');
      return;
    }
    final selectedPaths = await _controller._conversationAttachmentPickerService
        .pickFiles();
    if (selectedPaths.isEmpty) {
      _controller._announce('没有选择任何会话附件。');
      return;
    }
    final activeState = _controller._ensureConversationSession();
    final incomingDrafts = await _controller._conversationAttachmentDraftService
        .createDrafts(selectedPaths);
    final mergedDrafts = _controller._conversationAttachmentDraftService.mergeDrafts(
      currentDrafts: activeState.attachmentDrafts,
      incomingDrafts: incomingDrafts,
    );
    final nextState = _controller._conversationSessionStateService
        .stateWithAttachmentDrafts(activeState, mergedDrafts);
    _controller._replaceConversationSession(nextState, activate: true);
    _controller._mutateWorkbench((current) => _controller.applyConversationState(current));
    _controller._announce(
      _controller._attachmentSelectionMessage(incomingDrafts, mergedDrafts),
    );
  }
}
