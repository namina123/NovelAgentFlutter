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

      expect(runtime['name'], '未命名模型');
      expect(runtime['supports_tool_choice'], isFalse);
      expect(
        (runtime['provider_model_capability']
            as Map<String, Object?>)['excluded_parameters'],
        contains('tool_choice'),
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
