import '../../../settings/presentation/models/model_editor_view_data.dart';
import '../../presentation/models/conversation_input_capability_context.dart';

class ConversationInputCapabilityContextBuilderService {
  const ConversationInputCapabilityContextBuilderService();

  ConversationInputCapabilityContext build({
    required ModelEditorViewData modelEditor,
    required bool hasActiveProject,
    required bool hostSupportsAttachmentPicking,
    required bool collaborationSupportsReasoning,
    required bool collaborationSupportsAttachments,
    required bool collaborationSupportsToolOptions,
    bool productExposesReasoningToggle = true,
    bool productExposesAttachmentEntry = false,
    bool productExposesStopAction = false,
    bool productExposesToolOptionsAction = false,
    bool productExposesOptimizeAction = false,
  }) {
    // 中文注释: 这里负责把模型元能力、协作约束和产品开关压成统一 context，供输入能力解析层复用。
    return ConversationInputCapabilityContext(
      hasActiveProject: hasActiveProject,
      isGenerating: false,
      hostSupportsAttachmentPicking: hostSupportsAttachmentPicking,
      modelSupportsReasoning: modelEditor.supportsReasoning,
      modelReasoningCanToggle: modelEditor.reasoningCanToggle,
      modelSupportsFileAttachments: modelEditor.supportsFileAttachments,
      modelSupportsImageAttachments: modelEditor.supportsImageAttachments,
      modelSupportsAttachmentUrlsOnly: modelEditor.supportsAttachmentUrlsOnly,
      modelSupportsMultiAttachments: modelEditor.supportsMultiAttachments,
      collaborationSupportsReasoning: collaborationSupportsReasoning,
      collaborationSupportsAttachments: collaborationSupportsAttachments,
      collaborationSupportsToolOptions: collaborationSupportsToolOptions,
      reasoningEnabled: modelEditor.thinkingEnabled,
      productExposesReasoningToggle: productExposesReasoningToggle,
      productExposesAttachmentEntry: productExposesAttachmentEntry,
      productExposesStopAction: productExposesStopAction,
      productExposesToolOptionsAction: productExposesToolOptionsAction,
      productExposesOptimizeAction: productExposesOptimizeAction,
    );
  }
}
