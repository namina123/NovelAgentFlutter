import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_input_capability_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';

void main() {
  group('ConversationInputCapabilityService', () {
    test(
      'projects reasoning as a public capability but keeps attachments closed',
      () {
        const service = ConversationInputCapabilityService();

        final state = service.resolve(
          context: const ConversationInputCapabilityContext(
            hasActiveProject: true,
            isGenerating: false,
            hostSupportsAttachmentPicking: true,
            modelSupportsReasoning: true,
            modelReasoningCanToggle: true,
            modelSupportsFileAttachments: true,
            modelSupportsImageAttachments: true,
            modelSupportsAttachmentUrlsOnly: false,
            modelSupportsMultiAttachments: true,
            collaborationSupportsReasoning: true,
            collaborationSupportsAttachments: true,
            collaborationSupportsToolOptions: true,
            reasoningEnabled: true,
            productExposesReasoningToggle: true,
            productExposesAttachmentEntry: false,
            productExposesStopAction: false,
            productExposesToolOptionsAction: false,
            productExposesOptimizeAction: false,
          ),
        );

        expect(state.supportsReasoningToggle, isTrue);
        expect(state.showReasoningToggle, isTrue);
        expect(state.reasoningEnabled, isTrue);
        expect(state.supportsAttachmentEntry, isTrue);
        expect(state.showAttachmentEntry, isFalse);
        expect(state.supportsStopAction, isFalse);
        expect(state.showOptimizeAction, isFalse);
        expect(state.showToolOptionsAction, isFalse);
        expect(state.showStopAction, isFalse);
        expect(state.canSendAction, isTrue);
        expect(state.submitLabel, '发送');
      },
    );

    test(
      'keeps stop as an internal capability until public stop is enabled',
      () {
        const service = ConversationInputCapabilityService();

        final state = service.resolve(
          context: const ConversationInputCapabilityContext(
            hasActiveProject: true,
            isGenerating: true,
            hostSupportsAttachmentPicking: true,
            modelSupportsReasoning: true,
            modelReasoningCanToggle: true,
            modelSupportsFileAttachments: false,
            modelSupportsImageAttachments: false,
            modelSupportsAttachmentUrlsOnly: false,
            modelSupportsMultiAttachments: false,
            collaborationSupportsReasoning: true,
            collaborationSupportsAttachments: true,
            collaborationSupportsToolOptions: true,
            reasoningEnabled: false,
            productExposesReasoningToggle: true,
            productExposesAttachmentEntry: false,
            productExposesStopAction: false,
            productExposesToolOptionsAction: false,
            productExposesOptimizeAction: false,
          ),
        );

        expect(state.supportsReasoningToggle, isTrue);
        expect(state.showReasoningToggle, isFalse);
        expect(state.supportsStopAction, isTrue);
        expect(state.showStopAction, isFalse);
        expect(state.supportsAttachmentEntry, isFalse);
        expect(state.showAttachmentEntry, isFalse);
        expect(state.canSendAction, isFalse);
        expect(state.submitLabel, '生成中');
      },
    );

    test('exposes stop action publicly when product switch is enabled', () {
      const service = ConversationInputCapabilityService();

      final state = service.resolve(
        context: const ConversationInputCapabilityContext(
          hasActiveProject: true,
          isGenerating: true,
          hostSupportsAttachmentPicking: true,
          modelSupportsReasoning: true,
          modelReasoningCanToggle: true,
          modelSupportsFileAttachments: false,
          modelSupportsImageAttachments: false,
          modelSupportsAttachmentUrlsOnly: false,
          modelSupportsMultiAttachments: false,
          collaborationSupportsReasoning: true,
          collaborationSupportsAttachments: true,
          collaborationSupportsToolOptions: true,
          reasoningEnabled: false,
          productExposesReasoningToggle: true,
          productExposesAttachmentEntry: false,
          productExposesStopAction: true,
          productExposesToolOptionsAction: false,
          productExposesOptimizeAction: false,
        ),
      );

      expect(state.supportsStopAction, isTrue);
      expect(state.showStopAction, isTrue);
      expect(state.canSendAction, isFalse);
    });

    test('does not expose reasoning toggle for thinking-only models', () {
      const service = ConversationInputCapabilityService();

      final state = service.resolve(
        context: const ConversationInputCapabilityContext(
          hasActiveProject: true,
          isGenerating: false,
          hostSupportsAttachmentPicking: true,
          modelSupportsReasoning: true,
          modelReasoningCanToggle: false,
          modelSupportsFileAttachments: false,
          modelSupportsImageAttachments: false,
          modelSupportsAttachmentUrlsOnly: false,
          modelSupportsMultiAttachments: false,
          collaborationSupportsReasoning: true,
          collaborationSupportsAttachments: true,
          collaborationSupportsToolOptions: true,
          reasoningEnabled: true,
          productExposesReasoningToggle: true,
          productExposesAttachmentEntry: false,
          productExposesStopAction: false,
          productExposesToolOptionsAction: false,
          productExposesOptimizeAction: false,
        ),
      );

      expect(state.supportsReasoningToggle, isFalse);
      expect(state.showReasoningToggle, isFalse);
      expect(state.reasoningEnabled, isTrue);
    });
  });
}
