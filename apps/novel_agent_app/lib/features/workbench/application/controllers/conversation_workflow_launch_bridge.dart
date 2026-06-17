part of 'workbench_conversation_controller.dart';

class ConversationWorkflowLaunchBridge {
  ConversationWorkflowLaunchBridge(this._controller);

  final WorkbenchConversationController _controller;

  String buildLongTaskEntryPrompt({
    required ProjectDescriptor project,
    required OpeningSessionProjection? projection,
    required String activeDocumentPath,
    required String activeDocumentExcerpt,
  }) {
    return _controller._openingLaunchBridgeService.buildLongTaskEntryPrompt(
      project: project,
      projection: projection,
      activeDocumentPath: activeDocumentPath,
      activeDocumentExcerpt: activeDocumentExcerpt,
    );
  }

  Future<JsonMap> createWorkflowFromModeGuidance(
    ProjectDescriptor project, {
    required String modeId,
  }) {
    return _controller._openingLaunchBridgeService.createWorkflowFromModeGuidance(
      project,
      modeId: modeId,
    );
  }

  Future<JsonMap> launchLongTaskFromModeGuidance(
    ProjectDescriptor project, {
    required String modeId,
  }) {
    return _controller._openingLaunchBridgeService.launchLongTaskFromModeGuidance(
      project,
      modeId: modeId,
    );
  }
}
