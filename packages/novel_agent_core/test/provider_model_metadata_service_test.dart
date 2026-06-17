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
      expect(metadata['protocol_label'], 'OpenAI 协议格式');
      expect(metadata['route_family'], 'chat_completions');
      expect(ValueReaders.stringList(metadata['allowed_api_modes']), ['chat']);
      expect(metadata['api_mode_visible'], isFalse);
      expect(
        ValueReaders.stringList(metadata['visible_advanced_fields']),
        isNot(contains('api_mode')),
      );
      expect(metadata['supports_reasoning'], isTrue);
      expect(metadata['reasoning_mode_behavior'], 'hybrid_default_on');
      expect(metadata['reasoning_can_toggle'], isTrue);
      expect(metadata['supports_temperature'], isTrue);
      expect(metadata['supports_top_p'], isTrue);
      expect(metadata['thinking_parameter_format'], 'deepseek_thinking_object');
      expect(metadata['thinking_enable_parameter_keys'], contains('thinking'));
      expect(metadata['thinking_effort_supported'], isTrue);
      expect(metadata['supports_file_attachments'], isFalse);
      expect(metadata['supports_image_attachments'], isFalse);
      expect(metadata['supports_attachment_urls_only'], isFalse);
      expect(metadata['supports_multi_attachments'], isFalse);
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

    test('exports attachment capability metadata for anthropic models', () {
      // 中文注释: 这里验证编辑元数据会把附件模态能力一起导出，供工作台输入能力后续消费。
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Claude Sonnet',
          'model': 'claude-3-5-sonnet-20241022',
        },
        <String, Object?>{
          'name': 'Anthropic 主接口',
          'provider_id': 'anthropic',
          'kind': 'anthropic_compatible',
          'base_url': 'https://api.anthropic.com/v1',
        },
      );
      final metadata = profileService.metadata.buildEditorMetadata(runtime);

      expect(metadata['supports_file_attachments'], isTrue);
      expect(metadata['supports_image_attachments'], isTrue);
      expect(metadata['supports_attachment_urls_only'], isFalse);
      expect(metadata['supports_multi_attachments'], isTrue);
      expect(metadata['api_mode_visible'], isFalse);
    });

    test('projects relay override metadata for siliconflow deepseek models', () {
      // 中文注释: 这里验证 metadata 摘要会读到 offering 级 thinking override，而不是继续沿用 canonical 默认格式。
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'DeepSeek V4 Flash',
          'model': 'deepseek-ai/DeepSeek-V4-Flash',
          'thinking_parameter_format': 'none',
        },
        <String, Object?>{
          'name': '硅基流动',
          'provider_id': 'siliconflow',
          'kind': 'openai_compatible',
          'base_url': 'https://api.siliconflow.cn/v1',
        },
      );
      final metadata = profileService.metadata.buildEditorMetadata(runtime);

      expect(metadata['supports_reasoning'], isTrue);
      expect(metadata['reasoning_can_toggle'], isTrue);
      expect(metadata['thinking_parameter_format'], 'enable_thinking_boolean');
      expect(metadata['protocol_mode'], 'openai_compatible');
      expect(
        metadata['thinking_enable_parameter_keys'],
        contains('enable_thinking'),
      );
      final strategy =
          metadata['reasoning_toggle_parameter_strategy']
              as Map<String, Object?>;
      expect(strategy['kind'], 'boolean');
      expect(strategy['key'], 'enable_thinking');
    });

    test('keeps thinking-only models non-toggleable in editor metadata', () {
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Kimi K2 Thinking',
          'model': 'kimi-k2-thinking',
        },
        <String, Object?>{
          'name': 'Kimi 主接口',
          'provider_id': 'moonshot',
          'kind': 'openai_compatible',
          'base_url': 'https://platform.kimi.ai',
        },
      );
      final metadata = profileService.metadata.buildEditorMetadata(runtime);

      expect(metadata['supports_reasoning'], isTrue);
      expect(metadata['reasoning_mode_behavior'], 'thinking_only');
      expect(metadata['reasoning_can_toggle'], isFalse);
      expect(metadata['api_mode_visible'], isFalse);
      expect(
        (metadata['model_default_parameters'] as List<Object?>)
            .whereType<Map<String, Object?>>()
            .map((entry) => entry['key'])
            .toList(),
        isNot(contains('thinking_enabled')),
      );
    });

    test('projects custom reasoning override metadata for unknown models', () {
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Custom Writer',
          'model': 'custom-writer-v1',
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
                'medium': 'med',
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
      final metadata = profileService.metadata.buildEditorMetadata(runtime);

      expect(metadata['supports_reasoning'], isTrue);
      expect(metadata['reasoning_mode_behavior'], 'hybrid_optional');
      expect(metadata['reasoning_can_toggle'], isTrue);
      expect(metadata['thinking_parameter_label'], '自定义深度思考参数');
      expect(metadata['has_custom_reasoning_override'], isTrue);
      expect(
        metadata['thinking_enable_parameter_keys'],
        contains('thinking_mode'),
      );
      expect(
        metadata['thinking_effort_options'],
        containsAll(['low', 'medium', 'high']),
      );
    });

    test(
      'does not expose toggle parameter keys for always-thinking custom override metadata',
      () {
        final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
          <String, Object?>{
            'name': 'Custom Writer',
            'model': 'custom-writer-v1',
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
                'values': <String, Object?>{'medium': 'med'},
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
        final metadata = profileService.metadata.buildEditorMetadata(runtime);

        expect(metadata['supports_reasoning'], isTrue);
        expect(metadata['reasoning_mode_behavior'], 'thinking_only');
        expect(metadata['reasoning_can_toggle'], isFalse);
        expect(metadata['api_mode_visible'], isFalse);
        expect(metadata['thinking_enable_parameter_keys'], isEmpty);
        expect(metadata['thinking_effort_supported'], isTrue);
        expect(metadata['thinking_effort_options'], contains('medium'));
      },
    );

    test(
      'exports model-specific effort vocabulary for budget-style builtin models',
      () {
        final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
          <String, Object?>{
            'name': 'Gemini 2.5 Pro',
            'model': 'gemini-2.5-pro',
            'thinking_effort': 'dynamic',
          },
          <String, Object?>{
            'name': 'Google 主接口',
            'provider_id': 'google',
            'kind': 'openai_compatible',
            'base_url': 'https://generativelanguage.googleapis.com',
          },
        );
        final metadata = profileService.metadata.buildEditorMetadata(runtime);

        expect(metadata['supports_reasoning'], isTrue);
        expect(metadata['thinking_effort_supported'], isTrue);
        expect(metadata['protocol_label'], 'OpenAI 协议格式');
        expect(
          metadata['thinking_effort_options'],
          containsAll(['dynamic', 'budget']),
        );
        expect(metadata['thinking_effort_parameter_key'], 'thinkingBudget');
        expect(metadata['thinking_effort_parameter_label'], '深度思考预算');
        expect(metadata['thinking_parameter_label'], isNotEmpty);
      },
    );
  });
}
