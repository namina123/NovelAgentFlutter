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
      // 中文注释: 默认保守：无项目信息时不可发送，与"无项目不可发"的产品语义一致。
      canSendAction = false,
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

  ConversationInputCapabilityState copyWith({bool? canSendAction}) {
    return ConversationInputCapabilityState(
      supportsReasoningToggle: supportsReasoningToggle,
      showReasoningToggle: showReasoningToggle,
      reasoningEnabled: reasoningEnabled,
      supportsOptimizeAction: supportsOptimizeAction,
      showOptimizeAction: showOptimizeAction,
      supportsToolOptionsAction: supportsToolOptionsAction,
      showToolOptionsAction: showToolOptionsAction,
      supportsAttachmentEntry: supportsAttachmentEntry,
      showAttachmentEntry: showAttachmentEntry,
      supportsStopAction: supportsStopAction,
      showStopAction: showStopAction,
      canSendAction: canSendAction ?? this.canSendAction,
      submitLabel: submitLabel,
    );
  }
}
