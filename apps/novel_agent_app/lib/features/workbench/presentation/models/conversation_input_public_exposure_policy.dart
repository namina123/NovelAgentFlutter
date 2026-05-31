class ConversationInputPublicExposurePolicy {
  const ConversationInputPublicExposurePolicy({
    required this.showReasoningToggle,
    required this.showOptimizeAction,
    required this.showToolOptionsAction,
    required this.showAttachmentEntry,
    required this.showStopAction,
  });

  const ConversationInputPublicExposurePolicy.none()
    : showReasoningToggle = false,
      showOptimizeAction = false,
      showToolOptionsAction = false,
      showAttachmentEntry = false,
      showStopAction = false;

  final bool showReasoningToggle;
  final bool showOptimizeAction;
  final bool showToolOptionsAction;
  final bool showAttachmentEntry;
  final bool showStopAction;
}
