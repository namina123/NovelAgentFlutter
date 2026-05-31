import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderRequestOptionsService', () {
    test('builds relay offering reasoning parameters from builtin catalog', () {
      final runtime =
          ProviderProfileService(
            catalogPort: ProviderCatalogService.seeded(),
            capabilityPort: ProviderCapabilityResolver.seeded(),
          ).runtimeProfiles.composeRuntimeProfile(
            <String, Object?>{
              'name': 'DeepSeek V4 Flash',
              'model': 'deepseek-ai/DeepSeek-V4-Flash',
              'thinking_enabled': true,
              'thinking_effort': 'medium',
              'thinking_parameter_format': 'none',
            },
            <String, Object?>{
              'name': '硅基流动',
              'provider_id': 'siliconflow',
              'kind': 'openai_compatible',
              'base_url': 'https://api.siliconflow.cn/v1',
            },
          );

      final options = ProviderRequestOptionsService().buildRequestOptions(
        runtime,
      );

      expect(options['enable_thinking'], isTrue);
      expect(options['reasoning_effort'], 'medium');
      expect(options.containsKey('thinking'), isFalse);
    });

    test(
      'thinking-only builtin models omit toggle parameters when effort is unsupported',
      () {
        final runtime =
            ProviderProfileService(
              catalogPort: ProviderCatalogService.seeded(),
              capabilityPort: ProviderCapabilityResolver.seeded(),
            ).runtimeProfiles.composeRuntimeProfile(
              <String, Object?>{
                'name': 'Kimi K2 Thinking',
                'model': 'kimi-k2-thinking',
                'thinking_effort': 'high',
              },
              <String, Object?>{
                'name': 'Kimi 主接口',
                'provider_id': 'moonshot',
                'kind': 'openai_compatible',
                'base_url': 'https://platform.kimi.ai',
              },
            );

        final options = ProviderRequestOptionsService().buildRequestOptions(
          runtime,
        );

        expect(options.containsKey('thinking'), isFalse);
        expect(options.containsKey('enable_thinking'), isFalse);
        expect(options.containsKey('reasoning_effort'), isFalse);
        expect(options['temperature'], isNotNull);
        expect(options['top_p'], isNotNull);
      },
    );

    test('builds request parameters from custom reasoning override', () {
      final runtime =
          ProviderProfileService(
            catalogPort: ProviderCatalogService.seeded(),
            capabilityPort: ProviderCapabilityResolver.seeded(),
          ).runtimeProfiles.composeRuntimeProfile(
            <String, Object?>{
              'name': 'Custom Writer',
              'model': 'custom-writer-v1',
              'thinking_enabled': true,
              'thinking_effort': 'medium',
              'custom_reasoning_override': <String, Object?>{
                'supports_reasoning': true,
                'reasoning_can_toggle': true,
                'reasoning_default_enabled': false,
                'reasoning_supports_effort': true,
                'reasoning_toggle_parameter_strategy': <String, Object?>{
                  'kind': 'custom_text',
                  'key': 'thinking_mode',
                  'enabled_value': 'enabled',
                  'disabled_value': 'disabled',
                },
                'reasoning_effort_parameter_strategy': <String, Object?>{
                  'key': 'thinking_level',
                  'values': <String, Object?>{
                    'low': 'low',
                    'medium': 'mid',
                    'high': 'high',
                  },
                },
              },
            },
            <String, Object?>{
              'name': 'Custom Provider',
              'provider_id': 'custom_provider',
              'kind': 'openai_compatible',
              'base_url': 'https://custom.example.com/v1',
            },
          );

      final options = ProviderRequestOptionsService().buildRequestOptions(
        runtime,
      );

      expect(options['thinking_mode'], 'enabled');
      expect(options['thinking_level'], 'mid');
      expect(options.containsKey('thinking'), isFalse);
      expect(options.containsKey('enable_thinking'), isFalse);
    });

    test(
      'does not emit toggle parameter for always-thinking custom reasoning override',
      () {
        final runtime =
            ProviderProfileService(
              catalogPort: ProviderCatalogService.seeded(),
              capabilityPort: ProviderCapabilityResolver.seeded(),
            ).runtimeProfiles.composeRuntimeProfile(
              <String, Object?>{
                'name': 'Custom Writer',
                'model': 'custom-writer-v1',
                'thinking_enabled': false,
                'thinking_effort': 'medium',
                'custom_reasoning_override': <String, Object?>{
                  'supports_reasoning': true,
                  'reasoning_can_toggle': false,
                  'reasoning_default_enabled': true,
                  'reasoning_supports_effort': true,
                  'reasoning_toggle_parameter_strategy': <String, Object?>{
                    'kind': 'custom_text',
                    'key': 'thinking_mode',
                    'enabled_value': 'enabled',
                    'disabled_value': 'disabled',
                  },
                  'reasoning_effort_parameter_strategy': <String, Object?>{
                    'key': 'thinking_level',
                    'values': <String, Object?>{
                      'medium': 'mid',
                    },
                  },
                },
              },
              <String, Object?>{
                'name': 'Custom Provider',
                'provider_id': 'custom_provider',
                'kind': 'openai_compatible',
                'base_url': 'https://custom.example.com/v1',
              },
            );

        final options = ProviderRequestOptionsService().buildRequestOptions(
          runtime,
        );

        expect(options.containsKey('thinking_mode'), isFalse);
        expect(options['thinking_level'], 'mid');
      },
    );
  });
}
