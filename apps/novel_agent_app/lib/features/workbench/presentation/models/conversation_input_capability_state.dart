class ConversationInputCapabilityState {
  const ConversationInputCapabilityState({
    required this.supportsReasoningToggle,
    required this.showReasoningToggle,
    required this.reasoningEnabled,
    required this.supportsOptimizeAction,
    required this.showOptimizeAction,
    required this.supportsToolOptionsAction,
    required this.showToolOptionsAction,
    required this.supportsAttachmentEntry,
    required this.showAttachmentEntry,
    required this.supportsStopAction,
    required this.showStopAction,
    required this.canSendAction,
    required this.submitLabel,
  });

  const ConversationInputCapabilityState.initial()
    : supportsReasoningToggle = false,
      showReasoningToggle = false,
      reasoningEnabled = false,
      supportsOptimizeAction = false,
      showOptimizeAction = false,
      supportsToolOptionsAction = false,
      showToolOptionsAction = false,
      supportsAttachmentEntry = false,
      showAttachmentEntry = false,
      supportsStopAction = false,
      showStopAction = false,
      canSendAction = true,
      submitLabel = '发送';

  final bool supportsReasoningToggle;
  final bool showReasoningToggle;
  final bool reasoningEnabled;
  final bool supportsOptimizeAction;
  final bool showOptimizeAction;
  final bool supportsToolOptionsAction;
  final bool showToolOptionsAction;
  final bool supportsAttachmentEntry;
  final bool showAttachmentEntry;
  final bool supportsStopAction;
  final bool showStopAction;
  final bool canSendAction;
  final String submitLabel;
}
