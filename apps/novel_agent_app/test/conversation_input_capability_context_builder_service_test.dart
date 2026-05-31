import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/settings/presentation/models/custom_model_reasoning_override_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/model_editor_view_data.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_input_capability_context_builder_service.dart';

void main() {
  group('ConversationInputCapabilityContextBuilderService', () {
    const service = ConversationInputCapabilityContextBuilderService();

    test('projects relay-offering reasoning facts into workbench context', () {
      const modelEditor = ModelEditorViewData(
        providerId: 'siliconflow',
        providerLabel: 'SiliconFlow',
        protocolMode: 'openai_compatible',
        baseUrl: 'https://api.siliconflow.cn/v1',
        modelId: 'deepseek-ai/DeepSeek-V4-Flash',
        supportsReasoning: true,
        reasoningCanToggle: true,
        reasoningDefaultEnabled: true,
        supportsTemperature: true,
        supportsTopP: true,
        supportsTopK: false,
        supportsStreaming: true,
        supportsTools: true,
        supportsToolChoice: false,
        supportsFileAttachments: false,
        supportsImageAttachments: false,
        supportsAttachmentUrlsOnly: false,
        supportsMultiAttachments: false,
        thinkingParameterFormat: 'enable_thinking_boolean',
        thinkingParameterLabel: '深度思考',
        thinkingEnabled: true,
        thinkingEffortSupported: true,
        thinkingEffort: 'medium',
        thinkingEffortOptions: ['low', 'medium', 'high'],
        temperature: 0.7,
        topP: 0.95,
        topK: 0,
        modelSuggestions: [],
        customParameters: [],
        supportedParameters: ['temperature', 'top_p', 'enable_thinking'],
        unsupportedParameters: ['top_k'],
        customReasoningOverride: CustomModelReasoningOverrideViewData.initial,
      );

      final context = service.build(
        modelEditor: modelEditor,
        hasActiveProject: true,
        hostSupportsAttachmentPicking: true,
        collaborationSupportsReasoning: true,
        collaborationSupportsAttachments: true,
        collaborationSupportsToolOptions: true,
      );

      expect(context.modelSupportsReasoning, isTrue);
      expect(context.modelReasoningCanToggle, isTrue);
      expect(context.reasoningEnabled, isTrue);
      expect(context.modelSupportsFileAttachments, isFalse);
      expect(context.modelSupportsImageAttachments, isFalse);
    });

    test('keeps thinking-only models non-toggleable in workbench context', () {
      const modelEditor = ModelEditorViewData(
        providerId: 'moonshot',
        providerLabel: 'Kimi',
        protocolMode: 'openai_compatible',
        baseUrl: 'https://platform.kimi.ai',
        modelId: 'kimi-k2-thinking',
        supportsReasoning: true,
        reasoningCanToggle: false,
        reasoningDefaultEnabled: true,
        supportsTemperature: false,
        supportsTopP: false,
        supportsTopK: false,
        supportsStreaming: true,
        supportsTools: true,
        supportsToolChoice: false,
        supportsFileAttachments: false,
        supportsImageAttachments: false,
        supportsAttachmentUrlsOnly: false,
        supportsMultiAttachments: false,
        thinkingParameterFormat: 'reasoning_effort_only',
        thinkingParameterLabel: '深度思考',
        thinkingEnabled: true,
        thinkingEffortSupported: true,
        thinkingEffort: 'high',
        thinkingEffortOptions: ['low', 'medium', 'high'],
        temperature: 0.0,
        topP: 0.0,
        topK: 0,
        modelSuggestions: [],
        customParameters: [],
        supportedParameters: ['reasoning_effort'],
        unsupportedParameters: ['temperature', 'top_p', 'top_k'],
        customReasoningOverride: CustomModelReasoningOverrideViewData.initial,
      );

      final context = service.build(
        modelEditor: modelEditor,
        hasActiveProject: true,
        hostSupportsAttachmentPicking: true,
        collaborationSupportsReasoning: true,
        collaborationSupportsAttachments: true,
        collaborationSupportsToolOptions: true,
      );

      expect(context.modelSupportsReasoning, isTrue);
      expect(context.modelReasoningCanToggle, isFalse);
      expect(context.reasoningEnabled, isTrue);
    });

    test(
      'projects always-thinking custom override facts into workbench context',
      () {
        const modelEditor = ModelEditorViewData(
          providerId: 'custom_provider',
          providerLabel: 'Custom Provider',
          protocolMode: 'openai_compatible',
          baseUrl: 'https://custom.example.com/v1',
          modelId: 'custom-writer-v1',
          supportsReasoning: true,
          reasoningCanToggle: false,
          reasoningDefaultEnabled: true,
          supportsTemperature: true,
          supportsTopP: true,
          supportsTopK: false,
          supportsStreaming: true,
          supportsTools: true,
          supportsToolChoice: false,
          supportsFileAttachments: false,
          supportsImageAttachments: false,
          supportsAttachmentUrlsOnly: false,
          supportsMultiAttachments: false,
          thinkingParameterFormat: 'reasoning_effort_only',
          thinkingParameterLabel: '自定义深度思考参数',
          thinkingEnabled: true,
          thinkingEffortSupported: true,
          thinkingEffort: 'medium',
          thinkingEffortOptions: ['low', 'medium', 'high'],
          temperature: 0.8,
          topP: 0.95,
          topK: 0,
          modelSuggestions: [],
          customParameters: [],
          supportedParameters: ['temperature', 'top_p', 'reasoning_effort'],
          unsupportedParameters: ['top_k'],
          customReasoningOverride: CustomModelReasoningOverrideViewData(
            isKnownWritingModel: false,
            supportsReasoning: true,
            reasoningCanToggle: false,
            reasoningDefaultEnabled: true,
            reasoningSupportsEffort: true,
            toggleStrategyKind: 'custom_text',
            toggleKey: 'thinking_mode',
            toggleEnabledValue: 'enabled',
            toggleDisabledValue: 'disabled',
            effortKey: 'thinking_level',
            effortValues: {
              'auto': 'auto',
              'low': 'low',
              'medium': 'mid',
              'high': 'high',
              'max': 'max',
            },
          ),
        );

        final context = service.build(
          modelEditor: modelEditor,
          hasActiveProject: true,
          hostSupportsAttachmentPicking: true,
          collaborationSupportsReasoning: true,
          collaborationSupportsAttachments: true,
          collaborationSupportsToolOptions: true,
        );

        expect(context.modelSupportsReasoning, isTrue);
        expect(context.modelReasoningCanToggle, isFalse);
        expect(context.reasoningEnabled, isTrue);
        expect(context.modelSupportsFileAttachments, isFalse);
        expect(context.modelSupportsImageAttachments, isFalse);
      },
    );
  });
}
