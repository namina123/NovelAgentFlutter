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
  });
}
