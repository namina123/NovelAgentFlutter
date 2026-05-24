import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderModelMetadataService', () {
    final profileService = ProviderProfileService(
      catalogPort: ProviderCatalogService.seeded(),
      capabilityPort: ProviderCapabilityResolver.seeded(),
    );

    test('builds editor metadata for deepseek reasoning model', () {
      // 中文注释: 这里验证前端需要的协议、思考和采样能力字段能从运行态配置稳定导出。
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'DeepSeek V4 Flash',
          'model': 'deepseek-ai/DeepSeek-V4-Flash',
          'thinking_parameter_format': 'none',
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
      final metadata = profileService.metadata.buildEditorMetadata(runtime);

      expect(metadata['protocol_mode'], 'openai_compatible');
      expect(metadata['supports_reasoning'], isTrue);
      expect(metadata['supports_temperature'], isTrue);
      expect(metadata['supports_top_p'], isTrue);
      expect(metadata['thinking_parameter_format'], 'deepseek_thinking_object');
      expect(metadata['thinking_enable_parameter_keys'], contains('thinking'));
      expect(metadata['thinking_effort_supported'], isTrue);
      expect(
        (metadata['model_default_parameters'] as List<Object?>)
            .whereType<Map<String, Object?>>()
            .map((entry) => entry['key'])
            .toList(),
        containsAll(<String>[
          'thinking_enabled',
          'thinking_effort',
          'temperature',
          'top_p',
          'response_format',
        ]),
      );
    });
  });
}
