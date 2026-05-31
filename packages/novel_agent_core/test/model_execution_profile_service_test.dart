import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModelExecutionProfileService', () {
    test('resolves runtime profile and request options from settings', () {
      final service = ModelExecutionProfileService();
      final settings = AppSettings(
        defaultProviderId: 'deepseek',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-pro',
        defaultProjectPath: 'D:/Novel',
        autoSaveDrafts: true,
        providers: const <ProviderEndpointSettings>[
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'demo-key',
            modelId: 'deepseek-v4-pro',
            description: '',
          ),
        ],
        extraSettings: const <String, Object?>{
          'model_settings': <String, Object?>{
            'provider_id': 'deepseek',
            'model_id': 'deepseek-v4-pro',
            'stream_mode': 'non_stream',
            'api_mode': 'chat',
            'thinking_enabled': true,
            'thinking_effort': 'medium',
            'temperature': '0.66',
            'top_p': '0.88',
            'custom_parameters': <Object?>[
              <String, Object?>{
                'key': 'max_tokens',
                'type': 'integer',
                'value': 4096,
              },
            ],
          },
        },
      );

      final resolved = service.resolve(settings: settings);
      final runtimeProfile = ValueReaders.mapValue(resolved['runtime_profile']);
      final requestOptions = ValueReaders.mapValue(resolved['request_options']);

      expect(resolved['resolved_model_id'], 'deepseek-v4-pro');
      expect(runtimeProfile['model'], 'deepseek-v4-pro');
      expect(
        runtimeProfile['matched_writing_model_canonical_id'],
        'deepseek:deepseek-v4-pro',
      );
      expect(runtimeProfile['context_length'], 131072);
      expect(runtimeProfile['compression_context_length'], 98304);
      expect(runtimeProfile['max_output_tokens'], 65536);
      expect(runtimeProfile['thinking_enabled'], isTrue);
      expect(runtimeProfile['temperature'], 0.66);
      expect(requestOptions['stream'], isFalse);
      expect(requestOptions['temperature'], 0.66);
      expect(requestOptions['top_p'], 0.88);
      expect(requestOptions['reasoning_effort'], 'medium');
      expect(requestOptions['max_tokens'], 4096);
      expect(
        ValueReaders.mapValue(requestOptions['thinking'])['type'],
        'enabled',
      );
    });

    test('runtime capability summary prefers writing offering overrides', () {
      final profileService = ProviderProfileService(
        catalogPort: ProviderCatalogService.seeded(),
        capabilityPort: ProviderCapabilityResolver.seeded(),
      );

      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': '',
          'model': 'deepseek-ai/DeepSeek-V4-Flash',
          'thinking_parameter_format': 'none',
        },
        <String, Object?>{
          'name': '硅基流动',
          'provider_id': 'siliconflow',
          'base_url': 'https://api.siliconflow.cn/v1',
        },
      );
      final capability = ValueReaders.mapValue(
        runtime['provider_model_capability'],
      );

      expect(
        ValueReaders.stringValue(runtime['matched_writing_model_canonical_id']),
        'deepseek:deepseek-v4-flash',
      );
      expect(
        ValueReaders.stringList(capability['supported_parameters']),
        contains('enable_thinking'),
      );
      expect(
        ValueReaders.stringList(capability['supported_parameters']),
        isNot(contains('thinking')),
      );
      expect(runtime['supports_streaming'], isTrue);
      expect(runtime['supports_tools'], isTrue);
    });

    test('applies agent overrides on top of model defaults', () {
      final service = ModelExecutionProfileService();
      final settings = AppSettings(
        defaultProviderId: 'deepseek',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'deepseek-v4-pro',
        defaultProjectPath: 'D:/Novel',
        autoSaveDrafts: true,
        providers: const <ProviderEndpointSettings>[
          ProviderEndpointSettings(
            id: 'deepseek',
            title: 'DeepSeek',
            protocol: 'openai_compatible',
            baseUrl: 'https://api.deepseek.com',
            apiKey: 'demo-key',
            modelId: 'deepseek-v4-pro',
            description: '',
          ),
        ],
        extraSettings: const <String, Object?>{
          'model_settings': <String, Object?>{
            'provider_id': 'deepseek',
            'model_id': 'deepseek-v4-pro',
            'temperature': '0.60',
            'custom_parameters': <Object?>[
              <String, Object?>{
                'key': 'max_tokens',
                'type': 'integer',
                'value': 2048,
              },
            ],
          },
        },
      );

      final resolved = service.resolve(
        settings: settings,
        agent: const <String, Object?>{
          'thinking_enabled': true,
          'thinking_effort': 'high',
          'temperature': 0.92,
          'top_p': 0.81,
          'advanced_model_overrides': <Object?>[
            <String, Object?>{
              'key': 'max_tokens',
              'type': 'integer',
              'value': 8192,
            },
          ],
        },
      );
      final requestOptions = ValueReaders.mapValue(resolved['request_options']);

      expect(requestOptions['temperature'], 0.92);
      expect(requestOptions['top_p'], 0.81);
      expect(requestOptions['max_tokens'], 8192);
      expect(requestOptions['reasoning_effort'], 'high');
    });

    test(
      'applies project agent model override before agent profile override',
      () {
        final service = ModelExecutionProfileService();
        final settings = AppSettings(
          defaultProviderId: 'deepseek',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'deepseek-v4-pro',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'deepseek',
              title: 'DeepSeek',
              protocol: 'openai_compatible',
              baseUrl: 'https://api.deepseek.com',
              apiKey: 'demo-key',
              modelId: 'deepseek-v4-pro',
              description: '',
            ),
          ],
          extraSettings: const <String, Object?>{
            'model_settings': <String, Object?>{
              'provider_id': 'deepseek',
              'model_id': 'deepseek-v4-pro',
              'temperature': '0.60',
            },
          },
        );

        final resolved = service.resolve(
          settings: settings,
          projectAgentBinding: const ProjectAgentBinding(
            agentId: 'writer',
            modelOverride: ProjectAgentModelOverride(
              agentId: 'writer',
              modelId: 'deepseek-v4-flash',
              temperature: 0.41,
              topP: 0.74,
            ),
          ),
          agent: const <String, Object?>{'temperature': 0.88},
        );
        final runtimeProfile = ValueReaders.mapValue(
          resolved['runtime_profile'],
        );
        final requestOptions = ValueReaders.mapValue(
          resolved['request_options'],
        );

        expect(runtimeProfile['model'], 'deepseek-v4-flash');
        expect(requestOptions['temperature'], 0.88);
        expect(requestOptions['top_p'], 0.74);
      },
    );

    test('resolves custom reasoning override from model settings', () {
      final service = ModelExecutionProfileService();
      final settings = AppSettings(
        defaultProviderId: 'custom_provider',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'custom-writer-v1',
        defaultProjectPath: 'D:/Novel',
        autoSaveDrafts: true,
        providers: const <ProviderEndpointSettings>[
          ProviderEndpointSettings(
            id: 'custom_provider',
            title: 'Custom Provider',
            protocol: 'openai_compatible',
            baseUrl: 'https://custom.example.com/v1',
            apiKey: 'demo-key',
            modelId: 'custom-writer-v1',
            description: '',
          ),
        ],
        extraSettings: const <String, Object?>{
          'model_settings': <String, Object?>{
            'provider_id': 'custom_provider',
            'model_id': 'custom-writer-v1',
            'thinking_enabled': true,
            'thinking_effort': 'high',
            'custom_reasoning_override': <String, Object?>{
              'supports_reasoning': true,
              'reasoning_can_toggle': true,
              'reasoning_default_enabled': false,
              'reasoning_supports_effort': true,
              'reasoning_toggle_parameter_strategy': <String, Object?>{
                'kind': 'boolean',
                'key': 'enable_reasoning',
              },
              'reasoning_effort_parameter_strategy': <String, Object?>{
                'key': 'reasoning_level',
                'values': <String, Object?>{'high': 'strong'},
              },
            },
          },
        },
      );

      final resolved = service.resolve(settings: settings);
      final runtimeProfile = ValueReaders.mapValue(resolved['runtime_profile']);
      final requestOptions = ValueReaders.mapValue(resolved['request_options']);

      expect(
        ValueReaders.mapValue(runtimeProfile['custom_reasoning_override']),
        isNotEmpty,
      );
      expect(runtimeProfile['reasoning_can_toggle'], isTrue);
      expect(requestOptions['enable_reasoning'], isTrue);
      expect(requestOptions['reasoning_level'], 'strong');
    });

    test(
      'projects reasoning-effort-only thinking format for always-thinking custom override',
      () {
        final service = ModelExecutionProfileService();
        final settings = AppSettings(
          defaultProviderId: 'custom_provider',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'custom-writer-v1',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'custom_provider',
              title: 'Custom Provider',
              protocol: 'openai_compatible',
              baseUrl: 'https://custom.example.com/v1',
              apiKey: 'demo-key',
              modelId: 'custom-writer-v1',
              description: '',
            ),
          ],
          extraSettings: const <String, Object?>{
            'model_settings': <String, Object?>{
              'provider_id': 'custom_provider',
              'model_id': 'custom-writer-v1',
              'thinking_enabled': false,
              'thinking_effort': 'high',
              'custom_reasoning_override': <String, Object?>{
                'supports_reasoning': true,
                'reasoning_can_toggle': false,
                'reasoning_default_enabled': true,
                'reasoning_supports_effort': true,
                'reasoning_toggle_parameter_strategy': <String, Object?>{
                  'kind': 'boolean',
                  'key': 'enable_reasoning',
                },
                'reasoning_effort_parameter_strategy': <String, Object?>{
                  'key': 'reasoning_level',
                  'values': <String, Object?>{'high': 'strong'},
                },
              },
            },
          },
        );

        final resolved = service.resolve(settings: settings);
        final runtimeProfile = ValueReaders.mapValue(resolved['runtime_profile']);
        final requestOptions = ValueReaders.mapValue(resolved['request_options']);

        expect(runtimeProfile['reasoning_mode_behavior'], 'thinking_only');
        expect(runtimeProfile['reasoning_can_toggle'], isFalse);
        expect(
          runtimeProfile['thinking_parameter_format'],
          ProviderProfileConstants.thinkingFormatReasoningEffortOnly,
        );
        expect(requestOptions.containsKey('enable_reasoning'), isFalse);
        expect(requestOptions['reasoning_level'], 'strong');
      },
    );

    test(
      'resolves provider from default_provider_id when provider_id is omitted',
      () {
        final service = ModelExecutionProfileService();
        final settings = AppSettings(
          defaultProviderId: 'deepseek',
          defaultAgentId: 'default_generalist',
          defaultModelId: 'fallback-default-model',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: const <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'deepseek',
              title: 'DeepSeek',
              protocol: 'openai_compatible',
              baseUrl: 'https://api.deepseek.com',
              apiKey: 'deepseek-key',
              modelId: 'deepseek-v4-pro',
              description: '',
            ),
            ProviderEndpointSettings(
              id: 'moonshot',
              title: 'Kimi',
              protocol: 'openai_compatible',
              baseUrl: 'https://platform.kimi.ai',
              apiKey: 'moonshot-key',
              modelId: 'kimi-k2-thinking',
              description: '',
            ),
          ],
          extraSettings: const <String, Object?>{
            'model_settings': <String, Object?>{
              'provider_id': 'deepseek',
              'model_id': 'deepseek-v4-pro',
            },
          },
        );

        final resolved = service.resolve(
          settings: settings.copyWith(
            extraSettings: const <String, Object?>{
              'model_settings': <String, Object?>{
                'default_provider_id': 'moonshot',
                'default_model_id': 'kimi-k2-thinking',
              },
            },
          ),
        );
        final runtimeProfile = ValueReaders.mapValue(resolved['runtime_profile']);

        expect(resolved['provider_id'], 'moonshot');
        expect(resolved['resolved_model_id'], 'kimi-k2-thinking');
        expect(runtimeProfile['base_url'], 'https://platform.kimi.ai');
      },
    );
  });
}
