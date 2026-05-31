import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuiltinWritingModelCatalogService', () {
    test('contains the first writing-model coverage set', () {
      // 中文注释: 这里验证 WM-01 首批写作模型事实层已经覆盖本轮要求的主要厂商与模型家族。
      final service = BuiltinWritingModelCatalogService.seeded();

      final models = service.models();
      final canonicalIds = models
          .map((entry) => entry.canonicalModelId)
          .toSet();

      expect(service.version, 1);
      expect(
        canonicalIds,
        containsAll(<String>{
          'openai:gpt-5.5',
          'anthropic:claude-sonnet-4.8',
          'google:gemini-3.5',
          'deepseek:deepseek-v4-flash',
          'qwen:qwen-3.6-plus',
          'glm:glm-5.1',
          'moonshot:kimi-k2.6',
          'minimax:minimax-m2.7',
          'mimo:mimo-v2.5-pro',
          'doubao:doubao-seed-1.8',
        }),
      );
    });

    test('matches canonical model by provider offering id', () {
      // 中文注释: 这里验证聚合平台 offering 能稳定回指 canonical 条目，避免后续再靠 provider 名硬编码。
      final service = BuiltinWritingModelCatalogService.seeded();

      final matched = service.matchByProviderModelId(
        providerId: 'siliconflow',
        modelId: 'deepseek-ai/DeepSeek-V4-Flash',
      );

      expect(matched, isNotNull);
      expect(matched!.canonicalModelId, 'deepseek:deepseek-v4-flash');
      expect(matched.reasoning.modeBehavior, 'hybrid_default_on');
      expect(matched.contextLength, 131072);
      expect(matched.maxOutputTokens, 65536);
      expect(matched.supportedParameters, contains('thinking'));
    });

    test('stores provider offering reasoning override for relays', () {
      // 中文注释: 这里验证中转 offering 可独立覆盖思考参数格式，而不污染 canonical 默认值。
      final service = BuiltinWritingModelCatalogService.seeded();

      final model = service.modelByCanonicalId('deepseek:deepseek-v4-flash');

      expect(model, isNotNull);
      final siliconflow = model!.providerOfferings.firstWhere(
        (entry) => entry.providerId == 'siliconflow',
      );
      expect(
        siliconflow.reasoningOverride['toggle_parameter_strategy'],
        isA<Map<String, Object?>>(),
      );
      final strategy =
          siliconflow.reasoningOverride['toggle_parameter_strategy']
              as Map<String, Object?>;
      expect(strategy['kind'], 'boolean');
      expect(strategy['key'], 'enable_thinking');
    });

    test('supports alias matching for legacy and current writing models', () {
      // 中文注释: 这里验证目录既能认当前主线，也能认保留的历史兼容模型别名。
      final service = BuiltinWritingModelCatalogService.seeded();

      final latest = service.matchByAlias('gemini 3.5');
      final legacy = service.matchByAlias('deepseek-v3');

      expect(latest?.canonicalModelId, 'google:gemini-3.5');
      expect(legacy?.canonicalModelId, 'deepseek:deepseek-chat');
      expect(legacy?.status, 'deprecated');
    });
  });
}
