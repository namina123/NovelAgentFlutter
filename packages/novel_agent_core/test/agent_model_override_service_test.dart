import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentModelOverrideService', () {
    final profileService = ProviderProfileService(
      catalogPort: ProviderCatalogService.seeded(),
      capabilityPort: ProviderCapabilityResolver.seeded(),
    );
    final overrideService = AgentModelOverrideService();

    test(
      'rewrites effective runtime parameters without mutating source defaults',
      () {
        // 中文注释: 这里验证智能体参数作为覆盖层生效，模型层默认参数仍保留在原始运行配置中。
        final sourceRuntime = profileService.runtimeProfiles
            .composeRuntimeProfile(
              <String, Object?>{
                'name': 'DeepSeek V4 Flash',
                'model': 'deepseek-ai/DeepSeek-V4-Flash',
                'thinking_parameter_format': 'none',
                'temperature': 0.7,
                'top_p': 0.9,
                'custom_parameters': <Object?>[
                  <String, Object?>{
                    'key': 'response_format',
                    'type': 'json',
                    'value': <String, Object?>{'type': 'json_object'},
                  },
                ],
              },
              <String, Object?>{
                'name': 'DeepSeek 主接口',
                'provider_id': 'deepseek',
                'kind': 'openai_compatible',
                'base_url': 'https://api.deepseek.com',
              },
            );

        final effectiveRuntime = overrideService.applyOverrides(
          sourceRuntime,
          <String, Object?>{
            'thinking_enabled': true,
            'thinking_effort': 'max',
            'temperature': 0.35,
            'top_p': 0.8,
            'advanced_model_overrides': <Object?>[
              <String, Object?>{
                'key': 'response_format',
                'type': 'json',
                'value': <String, Object?>{'type': 'text'},
              },
              <String, Object?>{'key': 'seed', 'type': 'integer', 'value': 42},
            ],
          },
        );

        expect(sourceRuntime['temperature'], 0.7);
        expect(sourceRuntime['top_p'], 0.9);

        expect(effectiveRuntime['thinking_enabled'], isTrue);
        expect(effectiveRuntime['thinking_effort'], 'max');
        expect(effectiveRuntime['temperature'], 0.35);
        expect(effectiveRuntime['top_p'], 0.8);

        final parameters =
            (effectiveRuntime['custom_parameters'] as List<Object?>)
                .whereType<Map<String, Object?>>()
                .toList();
        expect(
          parameters.firstWhere(
            (entry) => entry['key'] == 'response_format',
          )['value'],
          <String, Object?>{'type': 'text'},
        );
        expect(
          parameters.firstWhere((entry) => entry['key'] == 'seed')['value'],
          42,
        );
      },
    );
  });
}
