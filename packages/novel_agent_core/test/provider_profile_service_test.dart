import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderProfileService', () {
    final service = ProviderProfileService(
      catalogPort: ProviderCatalogService.seeded(),
      capabilityPort: ProviderCapabilityResolver.seeded(),
    );

    test('normalizes model defaults and fills runtime capability mapping', () {
      // 中文注释: 这里验证模型与接口合成后的运行配置会带上目录能力与规则映射结果。
      final runtime = service.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': '',
          'model': 'deepseek-ai/DeepSeek-V4-Flash',
          'thinking_parameter_format': 'none',
        },
        <String, Object?>{
          'name': 'DeepSeek 主接口',
          'provider_id': 'deepseek',
          'base_url': 'https://api.deepseek.com',
        },
      );

      expect(runtime['name'], 'DeepSeek V4 Flash');
      expect(runtime['supports_tool_choice'], isFalse);
      expect(
        (runtime['provider_model_capability']
            as Map<String, Object?>)['excluded_parameters'],
        contains('tool_choice'),
      );
      expect(runtime['supports_file_attachments'], isFalse);
      expect(runtime['supports_image_attachments'], isFalse);
      expect(runtime['supports_attachment_urls_only'], isFalse);
      expect(runtime['supports_multi_attachments'], isFalse);
    });

    test('maps attachment capabilities from provider capability rules', () {
      // 中文注释: 这里验证输入模态能力能从能力规则稳定落到运行态配置，供后续输入能力合同复用。
      final runtime = service.runtimeProfiles.composeRuntimeProfile(
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

      expect(runtime['supports_file_attachments'], isTrue);
      expect(runtime['supports_image_attachments'], isTrue);
      expect(runtime['supports_attachment_urls_only'], isFalse);
      expect(runtime['supports_multi_attachments'], isTrue);
    });

    test('maps qwen coding endpoint into a usable runtime profile', () {
      final runtime = service.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Qwen3 Coder Plus',
          'model': 'qwen3-coder-plus',
          'thinking_parameter_format': 'none',
        },
        <String, Object?>{
          'name': 'DashScope Coding',
          'provider_id': 'dashscope_coding',
          'kind': 'openai_compatible',
          'base_url': 'https://coding.dashscope.aliyuncs.com/v1',
        },
      );

      expect(runtime['provider_id'], 'dashscope_coding');
      expect(runtime['supports_tools'], isTrue);
      expect(runtime['supports_tool_choice'], isFalse);
      expect(runtime['context_length'], 131072);
    });

    test('maps minimax and doubao endpoints into usable runtime profiles', () {
      final minimaxRuntime = service.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'ABAB 6.5',
          'model': 'abab6.5',
        },
        <String, Object?>{
          'name': 'MiniMax 主接口',
          'provider_id': 'minimax',
          'kind': 'openai_compatible',
          'base_url': 'https://api.minimax.chat/v1',
        },
      );
      final doubaoRuntime = service.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Doubao Seed 1.8',
          'model': 'doubao-seed-1.8',
          'thinking_effort': 'high',
        },
        <String, Object?>{
          'name': '火山方舟主接口',
          'provider_id': 'doubao',
          'kind': 'openai_compatible',
          'base_url': 'https://ark.cn-beijing.volces.com/api/v3',
        },
      );

      expect(minimaxRuntime['provider_id'], 'minimax');
      expect(minimaxRuntime['supports_tools'], isTrue);
      expect(doubaoRuntime['provider_id'], 'doubao');
      expect(doubaoRuntime['supports_tools'], isTrue);
      expect(doubaoRuntime['context_length'], 256000);
      expect(
        doubaoRuntime['matched_writing_model_canonical_id'],
        'doubao:doubao-seed-1.8',
      );
    });

    test('builds reasoning parameters for deepseek format', () {
      // 中文注释: 这里验证思考参数映射仍按旧项目约定输出 deepseek thinking 对象。
      final parameters = service.thinking.thinkingRequestParameters(
        true,
        'high',
        ProviderProfileConstants.thinkingFormatDeepseekObject,
      );

      expect(
        (parameters['thinking'] as Map<String, Object?>)['type'],
        'enabled',
      );
      expect(parameters['reasoning_effort'], 'high');
    });
  });
}
