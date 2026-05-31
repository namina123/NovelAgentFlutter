class ConversationInputCapabilityContext {
  const ConversationInputCapabilityContext({
    required this.hasActiveProject,
    required this.isGenerating,
    required this.hostSupportsAttachmentPicking,
    required this.modelSupportsReasoning,
    this.modelReasoningCanToggle = false,
    required this.modelSupportsFileAttachments,
    required this.modelSupportsImageAttachments,
    required this.modelSupportsAttachmentUrlsOnly,
    required this.modelSupportsMultiAttachments,
    required this.collaborationSupportsReasoning,
    required this.collaborationSupportsAttachments,
    required this.collaborationSupportsToolOptions,
    required this.reasoningEnabled,
    required this.productExposesReasoningToggle,
    required this.productExposesAttachmentEntry,
    required this.productExposesStopAction,
    required this.productExposesToolOptionsAction,
    required this.productExposesOptimizeAction,
  });

  const ConversationInputCapabilityContext.initial()
    : hasActiveProject = false,
      isGenerating = false,
      hostSupportsAttachmentPicking = false,
      modelSupportsReasoning = false,
      modelReasoningCanToggle = false,
      modelSupportsFileAttachments = false,
      modelSupportsImageAttachments = false,
      modelSupportsAttachmentUrlsOnly = false,
      modelSupportsMultiAttachments = false,
      collaborationSupportsReasoning = true,
      collaborationSupportsAttachments = true,
      collaborationSupportsToolOptions = true,
      reasoningEnabled = false,
      productExposesReasoningToggle = true,
      productExposesAttachmentEntry = false,
      productExposesStopAction = false,
      productExposesToolOptionsAction = false,
      productExposesOptimizeAction = false;

  final bool hasActiveProject;
  final bool isGenerating;
  final bool hostSupportsAttachmentPicking;
  final bool modelSupportsReasoning;
  final bool modelReasoningCanToggle;
  final bool modelSupportsFileAttachments;
  final bool modelSupportsImageAttachments;
  final bool modelSupportsAttachmentUrlsOnly;
  final bool modelSupportsMultiAttachments;
  final bool collaborationSupportsReasoning;
  final bool collaborationSupportsAttachments;
  final bool collaborationSupportsToolOptions;
  final bool reasoningEnabled;
  final bool productExposesReasoningToggle;
  final bool productExposesAttachmentEntry;
  final bool productExposesStopAction;
  final bool productExposesToolOptionsAction;
  final bool productExposesOptimizeAction;

  ConversationInputCapabilityContext copyWith({
    bool? hasActiveProject,
    bool? isGenerating,
    bool? hostSupportsAttachmentPicking,
    bool? modelSupportsReasoning,
    bool? modelReasoningCanToggle,
    bool? modelSupportsFileAttachments,
    bool? modelSupportsImageAttachments,
    bool? modelSupportsAttachmentUrlsOnly,
    bool? modelSupportsMultiAttachments,
    bool? collaborationSupportsReasoning,
    bool? collaborationSupportsAttachments,
    bool? collaborationSupportsToolOptions,
    bool? reasoningEnabled,
    bool? productExposesReasoningToggle,
    bool? productExposesAttachmentEntry,
    bool? productExposesStopAction,
    bool? productExposesToolOptionsAction,
    bool? productExposesOptimizeAction,
  }) {
    // 中文注释: capability context 允许在工作台层只覆写当前运行态，避免模型与产品策略事实源被重复拼装。
    return ConversationInputCapabilityContext(
      hasActiveProject: hasActiveProject ?? this.hasActiveProject,
      isGenerating: isGenerating ?? this.isGenerating,
      hostSupportsAttachmentPicking:
          hostSupportsAttachmentPicking ?? this.hostSupportsAttachmentPicking,
      modelSupportsReasoning:
          modelSupportsReasoning ?? this.modelSupportsReasoning,
      modelReasoningCanToggle:
          modelReasoningCanToggle ?? this.modelReasoningCanToggle,
      modelSupportsFileAttachments:
          modelSupportsFileAttachments ?? this.modelSupportsFileAttachments,
      modelSupportsImageAttachments:
          modelSupportsImageAttachments ?? this.modelSupportsImageAttachments,
      modelSupportsAttachmentUrlsOnly:
          modelSupportsAttachmentUrlsOnly ??
          this.modelSupportsAttachmentUrlsOnly,
      modelSupportsMultiAttachments:
          modelSupportsMultiAttachments ?? this.modelSupportsMultiAttachments,
      collaborationSupportsReasoning:
          collaborationSupportsReasoning ?? this.collaborationSupportsReasoning,
      collaborationSupportsAttachments:
          collaborationSupportsAttachments ??
          this.collaborationSupportsAttachments,
      collaborationSupportsToolOptions:
          collaborationSupportsToolOptions ??
          this.collaborationSupportsToolOptions,
      reasoningEnabled: reasoningEnabled ?? this.reasoningEnabled,
      productExposesReasoningToggle:
          productExposesReasoningToggle ?? this.productExposesReasoningToggle,
      productExposesAttachmentEntry:
          productExposesAttachmentEntry ?? this.productExposesAttachmentEntry,
      productExposesStopAction:
          productExposesStopAction ?? this.productExposesStopAction,
      productExposesToolOptionsAction:
          productExposesToolOptionsAction ??
          this.productExposesToolOptionsAction,
      productExposesOptimizeAction:
          productExposesOptimizeAction ?? this.productExposesOptimizeAction,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationInputCapabilityContext &&
            other.hasActiveProject == hasActiveProject &&
            other.isGenerating == isGenerating &&
            other.hostSupportsAttachmentPicking ==
                hostSupportsAttachmentPicking &&
            other.modelSupportsReasoning == modelSupportsReasoning &&
            other.modelReasoningCanToggle == modelReasoningCanToggle &&
            other.modelSupportsFileAttachments ==
                modelSupportsFileAttachments &&
            other.modelSupportsImageAttachments ==
                modelSupportsImageAttachments &&
            other.modelSupportsAttachmentUrlsOnly ==
                modelSupportsAttachmentUrlsOnly &&
            other.modelSupportsMultiAttachments ==
                modelSupportsMultiAttachments &&
            other.collaborationSupportsReasoning ==
                collaborationSupportsReasoning &&
            other.collaborationSupportsAttachments ==
                collaborationSupportsAttachments &&
            other.collaborationSupportsToolOptions ==
                collaborationSupportsToolOptions &&
            other.reasoningEnabled == reasoningEnabled &&
            other.productExposesReasoningToggle ==
                productExposesReasoningToggle &&
            other.productExposesAttachmentEntry ==
                productExposesAttachmentEntry &&
            other.productExposesStopAction == productExposesStopAction &&
            other.productExposesToolOptionsAction ==
                productExposesToolOptionsAction &&
            other.productExposesOptimizeAction == productExposesOptimizeAction;
  }

  @override
  int get hashCode => Object.hashAll([
    hasActiveProject,
    isGenerating,
    hostSupportsAttachmentPicking,
    modelSupportsReasoning,
    modelReasoningCanToggle,
    modelSupportsFileAttachments,
    modelSupportsImageAttachments,
    modelSupportsAttachmentUrlsOnly,
    modelSupportsMultiAttachments,
    collaborationSupportsReasoning,
    collaborationSupportsAttachments,
    collaborationSupportsToolOptions,
    reasoningEnabled,
    productExposesReasoningToggle,
    productExposesAttachmentEntry,
    productExposesStopAction,
    productExposesToolOptionsAction,
    productExposesOptimizeAction,
  ]);
}
