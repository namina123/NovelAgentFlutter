import '../../presentation/models/conversation_input_capability_context.dart';
import '../../presentation/models/conversation_input_capability_state.dart';
import '../../presentation/models/conversation_input_public_exposure_policy.dart';

class ConversationInputCapabilityResolver {
  const ConversationInputCapabilityResolver();

  ConversationInputCapabilityState resolve(
    ConversationInputCapabilityContext context,
  ) {
    // 中文注释: 输入能力解析只做联合判定与公开投影，不直接碰 widget、控制器动作或宿主副作用。
    final supportsReasoningToggle =
        context.hasActiveProject &&
        context.modelSupportsReasoning &&
        context.modelReasoningCanToggle &&
        context.collaborationSupportsReasoning;
    final supportsToolOptionsAction =
        context.hasActiveProject && context.collaborationSupportsToolOptions;
    final supportsAttachmentEntry =
        context.hasActiveProject &&
        context.hostSupportsAttachmentPicking &&
        context.collaborationSupportsAttachments &&
        (context.modelSupportsFileAttachments ||
            context.modelSupportsImageAttachments);
    final supportsStopAction = context.isGenerating;
    final supportsOptimizeAction = false;
    final exposure = _publicExposurePolicy(
      context,
      supportsReasoningToggle: supportsReasoningToggle,
      supportsOptimizeAction: supportsOptimizeAction,
      supportsToolOptionsAction: supportsToolOptionsAction,
      supportsAttachmentEntry: supportsAttachmentEntry,
      supportsStopAction: supportsStopAction,
    );
    return ConversationInputCapabilityState(
      supportsReasoningToggle: supportsReasoningToggle,
      showReasoningToggle: exposure.showReasoningToggle,
      reasoningEnabled: context.reasoningEnabled,
      supportsOptimizeAction: supportsOptimizeAction,
      showOptimizeAction: exposure.showOptimizeAction,
      supportsToolOptionsAction: supportsToolOptionsAction,
      showToolOptionsAction: exposure.showToolOptionsAction,
      supportsAttachmentEntry: supportsAttachmentEntry,
      showAttachmentEntry: exposure.showAttachmentEntry,
      supportsStopAction: supportsStopAction,
      showStopAction: exposure.showStopAction,
      canSendAction: !context.isGenerating,
      submitLabel: context.isGenerating ? '生成中' : '发送',
    );
  }

  ConversationInputPublicExposurePolicy _publicExposurePolicy(
    ConversationInputCapabilityContext context, {
    required bool supportsReasoningToggle,
    required bool supportsOptimizeAction,
    required bool supportsToolOptionsAction,
    required bool supportsAttachmentEntry,
    required bool supportsStopAction,
  }) {
    // 中文注释: 公开显隐策略单独收口，是为了允许“内部能力已具备，但产品暂不开放入口”的稳定状态长期存在。
    return ConversationInputPublicExposurePolicy(
      showReasoningToggle:
          supportsReasoningToggle &&
          context.productExposesReasoningToggle &&
          !context.isGenerating,
      showOptimizeAction:
          supportsOptimizeAction &&
          context.productExposesOptimizeAction &&
          !context.isGenerating,
      showToolOptionsAction:
          supportsToolOptionsAction &&
          context.productExposesToolOptionsAction &&
          !context.isGenerating,
      showAttachmentEntry:
          supportsAttachmentEntry &&
          context.productExposesAttachmentEntry &&
          !context.isGenerating,
      showStopAction: supportsStopAction && context.productExposesStopAction,
    );
  }
}
