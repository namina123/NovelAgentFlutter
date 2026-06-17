import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/settings/application/services/model_settings_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('custom provider does not inherit catalog model suggestions', () {
    final service = ModelSettingsViewDataService();
    const settings = AppSettings(
      defaultProviderId: 'opencode',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'deepseek-v4-flash',
      defaultProjectPath: 'D:/NovelAgent/default_project',
      autoSaveDrafts: true,
      providers: [
        ProviderEndpointSettings(
          id: 'opencode',
          title: 'opencode',
          protocol: 'openai_compatible',
          baseUrl: 'https://opencode.ai/zen/go/v1',
          apiKey: 'secret',
          modelId: 'deepseek-v4-flash',
          description: 'custom provider',
          isDefault: true,
        ),
      ],
      extraSettings: {
        'model_settings': {
          'provider_id': 'opencode',
          'model_id': 'deepseek-v4-flash',
        },
      },
    );

    final editor = service.build(settings, const <String, Object?>{
      'provider_id': 'opencode',
      'model_id': 'deepseek-v4-flash',
    });

    expect(editor.modelSuggestions, isEmpty);
  });

  test('editor view data exposes attachment capability flags', () {
    final service = ModelSettingsViewDataService();
    const settings = AppSettings(
      defaultProviderId: 'anthropic',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'claude-3-5-sonnet-20241022',
      defaultProjectPath: 'D:/NovelAgent/default_project',
      autoSaveDrafts: true,
      providers: [
        ProviderEndpointSettings(
          id: 'anthropic',
          title: 'Anthropic',
          protocol: 'anthropic_compatible',
          baseUrl: 'https://api.anthropic.com/v1',
          apiKey: 'secret',
          modelId: 'claude-3-5-sonnet-20241022',
          description: 'anthropic provider',
          isDefault: true,
        ),
      ],
      extraSettings: {
        'model_settings': {
          'provider_id': 'anthropic',
          'model_id': 'claude-3-5-sonnet-20241022',
        },
      },
    );

    final editor = service.build(settings, const <String, Object?>{
      'provider_id': 'anthropic',
      'model_id': 'claude-3-5-sonnet-20241022',
    });

    expect(editor.supportsFileAttachments, isTrue);
    expect(editor.supportsImageAttachments, isTrue);
    expect(editor.supportsAttachmentUrlsOnly, isFalse);
    expect(editor.supportsMultiAttachments, isTrue);
  });

  test('unknown models expose custom reasoning override editor', () {
    final service = ModelSettingsViewDataService();
    const settings = AppSettings(
      defaultProviderId: 'custom_provider',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'custom-writer-v1',
      defaultProjectPath: 'D:/NovelAgent/default_project',
      autoSaveDrafts: true,
      providers: [
        ProviderEndpointSettings(
          id: 'custom_provider',
          title: 'Custom Provider',
          protocol: 'openai_compatible',
          baseUrl: 'https://custom.example.com/v1',
          apiKey: 'secret',
          modelId: 'custom-writer-v1',
          description: 'custom provider',
          isDefault: true,
        ),
      ],
      extraSettings: {
        'model_settings': {
          'provider_id': 'custom_provider',
          'model_id': 'custom-writer-v1',
        },
      },
    );

    final editor = service.build(settings, const <String, Object?>{
      'provider_id': 'custom_provider',
      'model_id': 'custom-writer-v1',
    });

    expect(editor.customReasoningOverride.showCustomOverrideEditor, isTrue);
    expect(editor.customReasoningOverride.isKnownWritingModel, isFalse);
  });

  test('relay offerings project writing-model facts into settings editor', () {
    final service = ModelSettingsViewDataService();
    const settings = AppSettings(
      defaultProviderId: 'siliconflow',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'deepseek-ai/DeepSeek-V4-Flash',
      defaultProjectPath: 'D:/NovelAgent/default_project',
      autoSaveDrafts: true,
      providers: [
        ProviderEndpointSettings(
          id: 'siliconflow',
          title: 'SiliconFlow',
          protocol: 'openai_compatible',
          baseUrl: 'https://api.siliconflow.cn/v1',
          apiKey: 'secret',
          modelId: 'deepseek-ai/DeepSeek-V4-Flash',
          description: 'relay provider',
          isDefault: true,
        ),
      ],
      extraSettings: {
        'model_settings': {
          'provider_id': 'siliconflow',
          'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
        },
      },
    );

    final editor = service.build(settings, const <String, Object?>{
      'provider_id': 'siliconflow',
      'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
    });

    expect(editor.supportsReasoning, isTrue);
    expect(editor.reasoningCanToggle, isTrue);
    expect(editor.thinkingParameterFormat, 'enable_thinking_boolean');
    expect(editor.supportsTemperature, isTrue);
    expect(editor.supportsTopP, isTrue);
    expect(editor.supportsTopK, isFalse);
    expect(editor.supportedParameters, contains('enable_thinking'));
    expect(editor.customReasoningOverride.isKnownWritingModel, isTrue);
    expect(editor.thinkingEffortOptions, ['low', 'medium', 'high', 'max']);
    expect(editor.thinkingEffortOptions, isNot(contains('xhigh')));
    expect(
      editor.modelSuggestions.any((entry) => entry.value == editor.modelId),
      isTrue,
    );
  });

  test(
    'thinking-only writing models stay non-toggleable in settings editor',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'moonshot',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'kimi-k2-thinking',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'moonshot',
            title: 'Kimi',
            protocol: 'openai_compatible',
            baseUrl: 'https://platform.kimi.ai',
            apiKey: 'secret',
            modelId: 'kimi-k2-thinking',
            description: 'kimi provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'moonshot',
            'model_id': 'kimi-k2-thinking',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'moonshot',
        'model_id': 'kimi-k2-thinking',
      });

      expect(editor.supportsReasoning, isTrue);
      expect(editor.reasoningCanToggle, isFalse);
      expect(editor.reasoningDefaultEnabled, isTrue);
      expect(editor.customReasoningOverride.showCustomOverrideEditor, isFalse);
    },
  );

  test(
    'always-thinking custom overrides project reasoning-effort-only facts into settings editor',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'custom_provider',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'custom-writer-v1',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'custom_provider',
            title: 'Custom Provider',
            protocol: 'openai_compatible',
            baseUrl: 'https://custom.example.com/v1',
            apiKey: 'secret',
            modelId: 'custom-writer-v1',
            description: 'custom provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'custom_provider',
            'model_id': 'custom-writer-v1',
            'thinking_enabled': false,
            'thinking_effort': 'medium',
            'custom_reasoning_override': {
              'supports_reasoning': true,
              'reasoning_can_toggle': false,
              'reasoning_default_enabled': true,
              'reasoning_supports_effort': true,
              'reasoning_toggle_parameter_strategy': {
                'kind': 'custom_text',
                'key': 'thinking_mode',
                'enabled_value': 'enabled',
                'disabled_value': 'disabled',
              },
              'reasoning_effort_parameter_strategy': {
                'key': 'thinking_level',
                'values': {'low': 'low', 'medium': 'mid', 'high': 'high'},
              },
            },
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'custom_provider',
        'model_id': 'custom-writer-v1',
        'thinking_enabled': false,
        'thinking_effort': 'medium',
        'custom_reasoning_override': {
          'supports_reasoning': true,
          'reasoning_can_toggle': false,
          'reasoning_default_enabled': true,
          'reasoning_supports_effort': true,
          'reasoning_toggle_parameter_strategy': {
            'kind': 'custom_text',
            'key': 'thinking_mode',
            'enabled_value': 'enabled',
            'disabled_value': 'disabled',
          },
          'reasoning_effort_parameter_strategy': {
            'key': 'thinking_level',
            'values': {'low': 'low', 'medium': 'mid', 'high': 'high'},
          },
        },
      });

      expect(editor.supportsReasoning, isTrue);
      expect(editor.reasoningCanToggle, isFalse);
      expect(editor.reasoningDefaultEnabled, isTrue);
      expect(editor.thinkingParameterFormat, 'reasoning_effort_only');
      expect(editor.thinkingEffortSupported, isTrue);
      expect(editor.thinkingEffort, 'medium');
      expect(
        editor.thinkingEffortOptions,
        containsAll(['low', 'medium', 'high']),
      );
      expect(editor.customReasoningOverride.showCustomOverrideEditor, isTrue);
      expect(editor.customReasoningOverride.reasoningCanToggle, isFalse);
      expect(editor.customReasoningOverride.reasoningSupportsEffort, isTrue);
    },
  );

  test(
    'editor custom reasoning override view data uses the passed model settings document',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'custom_provider',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'custom-writer-v1',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'custom_provider',
            title: 'Custom Provider',
            protocol: 'openai_compatible',
            baseUrl: 'https://custom.example.com/v1',
            apiKey: 'secret',
            modelId: 'custom-writer-v1',
            description: 'custom provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'custom_provider',
            'model_id': 'custom-writer-v1',
            'custom_reasoning_override': {'supports_reasoning': false},
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'custom_provider',
        'model_id': 'custom-writer-v1',
        'custom_reasoning_override': {
          'supports_reasoning': true,
          'reasoning_can_toggle': false,
          'reasoning_default_enabled': true,
          'reasoning_supports_effort': true,
          'reasoning_effort_parameter_strategy': {
            'key': 'thinking_level',
            'values': {'medium': 'mid'},
          },
        },
      });

      expect(editor.customReasoningOverride.supportsReasoning, isTrue);
      expect(editor.customReasoningOverride.reasoningCanToggle, isFalse);
      expect(editor.customReasoningOverride.reasoningSupportsEffort, isTrue);
      expect(editor.customReasoningOverride.effortKey, 'thinking_level');
      expect(editor.customReasoningOverride.effortValues['medium'], 'mid');
    },
  );

  test(
    'editor custom reasoning override keeps empty effort values empty for unknown models',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'custom_provider',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'custom-writer-v1',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'custom_provider',
            title: 'Custom Provider',
            protocol: 'openai_compatible',
            baseUrl: 'https://custom.example.com/v1',
            apiKey: 'secret',
            modelId: 'custom-writer-v1',
            description: 'custom provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'custom_provider',
            'model_id': 'custom-writer-v1',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'custom_provider',
        'model_id': 'custom-writer-v1',
        'custom_reasoning_override': {
          'supports_reasoning': true,
          'reasoning_can_toggle': true,
          'reasoning_default_enabled': false,
          'reasoning_supports_effort': true,
          'reasoning_effort_parameter_strategy': {
            'key': 'thinking_level',
            'values': <String, Object?>{},
          },
        },
      });

      expect(editor.customReasoningOverride.showCustomOverrideEditor, isTrue);
      expect(editor.customReasoningOverride.reasoningSupportsEffort, isTrue);
      expect(editor.customReasoningOverride.effortValues, isEmpty);
    },
  );

  test(
    'passed model settings can drive a different resolved provider and model in the editor',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'siliconflow',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-ai/DeepSeek-V4-Flash',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'siliconflow',
            title: 'SiliconFlow',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.siliconflow.cn/v1',
            apiKey: 'secret',
            modelId: 'deepseek-ai/DeepSeek-V4-Flash',
            description: 'relay provider',
            isDefault: true,
          ),
          ProviderEndpointSettings(
            id: 'moonshot',
            title: 'Kimi',
            protocol: 'openai_compatible',
            baseUrl: 'https://platform.kimi.ai',
            apiKey: 'secret',
            modelId: 'kimi-k2-thinking',
            description: 'kimi provider',
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'siliconflow',
            'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'moonshot',
        'model_id': 'kimi-k2-thinking',
        'custom_reasoning_override': {'supports_reasoning': true},
      });

      expect(editor.providerId, 'moonshot');
      expect(editor.modelId, 'kimi-k2-thinking');
      expect(editor.supportsReasoning, isTrue);
      expect(editor.providerLabel, contains('Kimi'));
      expect(editor.baseUrl, 'https://platform.kimi.ai');
      expect(editor.customReasoningOverride.supportsReasoning, isTrue);
      expect(editor.customReasoningOverride.showCustomOverrideEditor, isTrue);
    },
  );

  test(
    'editor primary scalar values use the passed model settings overrides',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'deepseek',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-pro',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'secret',
            modelId: 'deepseek-v4-pro',
            description: 'deepseek provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'deepseek',
            'model_id': 'deepseek-v4-pro',
            'thinking_enabled': true,
            'thinking_effort': 'medium',
            'temperature': '0.66',
            'top_p': '0.88',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'deepseek',
        'model_id': 'deepseek-v4-pro',
        'thinking_enabled': false,
        'thinking_effort': 'low',
        'temperature': '0.12',
        'top_p': '0.34',
        'top_k': '5',
      });

      expect(editor.thinkingEnabled, isFalse);
      expect(editor.thinkingEffort, 'low');
      expect(editor.temperature, 0.12);
      expect(editor.topP, 0.34);
      expect(editor.topK, 5);
    },
  );

  test('editor custom parameters use the passed model settings overrides', () {
    final service = ModelSettingsViewDataService();
    const settings = AppSettings(
      defaultProviderId: 'deepseek',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'deepseek-v4-pro',
      defaultProjectPath: 'D:/NovelAgent/default_project',
      autoSaveDrafts: true,
      providers: [
        ProviderEndpointSettings(
          id: 'deepseek',
          title: 'DeepSeek',
          protocol: 'openai_compatible',
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'secret',
          modelId: 'deepseek-v4-pro',
          description: 'deepseek provider',
          isDefault: true,
        ),
      ],
      extraSettings: {
        'model_settings': {
          'provider_id': 'deepseek',
          'model_id': 'deepseek-v4-pro',
          'custom_parameters': [
            {
              'key': 'response_format',
              'type': 'json',
              'value': {'type': 'json_object'},
            },
          ],
        },
      },
    );

    final editor = service.build(settings, const <String, Object?>{
      'provider_id': 'deepseek',
      'model_id': 'deepseek-v4-pro',
      'custom_parameters': [
        {'key': 'max_tokens', 'type': 'integer', 'value': 2048},
      ],
    });

    expect(editor.customParameters, hasLength(1));
    expect(editor.customParameters.first.keyName, 'max_tokens');
    expect(editor.customParameters.first.valueType, 'integer');
    expect(editor.customParameters.first.value, 2048);
  });

  test(
    'editor custom parameters are empty when passed model settings do not provide them and resolved runtime has none',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'deepseek',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-pro',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'secret',
            modelId: 'deepseek-v4-pro',
            description: 'deepseek provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'deepseek',
            'model_id': 'deepseek-v4-pro',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'deepseek',
        'model_id': 'deepseek-v4-pro',
      });

      expect(editor.customParameters, isEmpty);
    },
  );

  test(
    'editor capability flags and parameter support lists still come from metadata rather than passed model settings',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'siliconflow',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-ai/DeepSeek-V4-Flash',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'siliconflow',
            title: 'SiliconFlow',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.siliconflow.cn/v1',
            apiKey: 'secret',
            modelId: 'deepseek-ai/DeepSeek-V4-Flash',
            description: 'relay provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'siliconflow',
            'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'siliconflow',
        'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
        'supports_temperature': false,
        'supports_top_p': false,
        'supports_top_k': true,
        'supported_parameters': ['totally_fake_param'],
        'unsupported_parameters': ['enable_thinking'],
      });

      expect(editor.supportsTemperature, isTrue);
      expect(editor.supportsTopP, isTrue);
      expect(editor.supportsTopK, isFalse);
      expect(editor.supportedParameters, contains('enable_thinking'));
      expect(editor.supportedParameters, isNot(contains('totally_fake_param')));
      expect(editor.unsupportedParameters, isNot(contains('enable_thinking')));
    },
  );

  test(
    'editor resolves model from passed default_model_id when model_id is omitted',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'moonshot',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'unused-default-model',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'moonshot',
            title: 'Kimi',
            protocol: 'openai_compatible',
            baseUrl: 'https://platform.kimi.ai',
            apiKey: 'secret',
            modelId: 'kimi-k2-thinking',
            description: 'kimi provider',
            isDefault: true,
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'moonshot',
            'model_id': 'unused-default-model',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'provider_id': 'moonshot',
        'default_model_id': 'kimi-k2-thinking',
      });

      expect(editor.providerId, 'moonshot');
      expect(editor.modelId, 'kimi-k2-thinking');
      expect(editor.baseUrl, 'https://platform.kimi.ai');
      expect(editor.supportsReasoning, isTrue);
    },
  );

  test(
    'editor resolves provider from passed default_provider_id when provider_id is omitted',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'deepseek',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-pro',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'secret',
            modelId: 'deepseek-v4-pro',
            description: 'deepseek provider',
            isDefault: true,
          ),
          ProviderEndpointSettings(
            id: 'moonshot',
            title: 'Kimi',
            protocol: 'openai_compatible',
            baseUrl: 'https://platform.kimi.ai',
            apiKey: 'secret',
            modelId: 'kimi-k2-thinking',
            description: 'kimi provider',
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'deepseek',
            'model_id': 'deepseek-v4-pro',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'default_provider_id': 'moonshot',
        'default_model_id': 'kimi-k2-thinking',
      });

      expect(editor.providerId, 'moonshot');
      expect(editor.modelId, 'kimi-k2-thinking');
      expect(editor.providerLabel, contains('Kimi'));
      expect(editor.baseUrl, 'https://platform.kimi.ai');
      expect(editor.supportsReasoning, isTrue);
    },
  );

  test(
    'editor model suggestions follow passed default_provider_id fallback',
    () {
      final service = ModelSettingsViewDataService();
      const settings = AppSettings(
        defaultProviderId: 'moonshot',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'kimi-k2-thinking',
        defaultProjectPath: 'D:/NovelAgent/default_project',
        autoSaveDrafts: true,
        providers: [
          ProviderEndpointSettings(
            id: 'moonshot',
            title: 'Kimi',
            protocol: 'openai_compatible',
            baseUrl: 'https://platform.kimi.ai',
            apiKey: 'secret',
            modelId: 'kimi-k2-thinking',
            description: 'kimi provider',
            isDefault: true,
          ),
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'secret',
            modelId: 'deepseek-v4-pro',
            description: 'deepseek provider',
          ),
        ],
        extraSettings: {
          'model_settings': {
            'provider_id': 'moonshot',
            'model_id': 'kimi-k2-thinking',
          },
        },
      );

      final editor = service.build(settings, const <String, Object?>{
        'default_provider_id': 'deepseek',
      });

      expect(editor.providerId, 'deepseek');
      expect(editor.modelSuggestions, isNotEmpty);
      expect(
        editor.modelSuggestions.any(
          (entry) => entry.value == 'deepseek-v4-pro',
        ),
        isTrue,
      );
      expect(
        editor.modelSuggestions.any(
          (entry) => entry.value == 'kimi-k2-thinking',
        ),
        isFalse,
      );
    },
  );
}
