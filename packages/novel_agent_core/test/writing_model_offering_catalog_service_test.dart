import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WritingModelOfferingCatalogService', () {
    test('returns provider-specific offerings for siliconflow', () {
      final service = WritingModelOfferingCatalogService();

      final options = service.offeringOptions(providerId: 'siliconflow');

      expect(options, isNotEmpty);
      expect(
        options.any(
          (entry) =>
              entry['provider_id'] == 'siliconflow' &&
              entry['model_id'] == 'deepseek-ai/DeepSeek-V4-Flash',
        ),
        isTrue,
      );
      expect(
        options.any(
          (entry) =>
              entry['provider_id'] == 'siliconflow' &&
              entry['model_id'] == 'Qwen/Qwen3-32B',
        ),
        isFalse,
      );
    });

    test('matches opencode go offering by provider and model id', () {
      final service = WritingModelOfferingCatalogService();

      final matched = service.bestMatch(
        providerId: 'opencode_go',
        modelId: 'DeepSeek V4 Flash',
      );

      expect(matched, isNotNull);
      expect(matched!['canonical_model_id'], 'deepseek:deepseek-v4-flash');
      expect(matched['provider_id'], 'opencode_go');
    });

    test('matches mainland mainstream offerings by provider and model id', () {
      final service = WritingModelOfferingCatalogService();

      final minimax = service.bestMatch(
        providerId: 'minimax',
        modelId: 'abab6.5',
      );
      final qianfan = service.bestMatch(
        providerId: 'baidu_qianfan',
        modelId: 'ernie-4.5',
      );
      final hunyuan = service.bestMatch(
        providerId: 'tencent_hunyuan',
        modelId: 'hunyuan-turbo',
      );

      expect(minimax, isNotNull);
      expect(minimax!['canonical_model_id'], 'minimax:abab6.5');
      expect(qianfan, isNotNull);
      expect(qianfan!['canonical_model_id'], 'baidu_qianfan:ernie-4.5');
      expect(hunyuan, isNotNull);
      expect(hunyuan!['canonical_model_id'], 'tencent_hunyuan:hunyuan-turbo');
    });

    test(
      'matches google gemini openai-compatible offerings by provider and model id',
      () {
        final service = WritingModelOfferingCatalogService();

        final gemini35 = service.bestMatch(
          providerId: 'google',
          modelId: 'gemini-3.5',
        );
        final gemini25 = service.bestMatch(
          providerId: 'google',
          modelId: 'gemini-2.5-pro',
        );

        expect(gemini35, isNotNull);
        expect(gemini35!['canonical_model_id'], 'google:gemini-3.5');
        expect(gemini35['provider_id'], 'google');
        expect(gemini25, isNotNull);
        expect(gemini25!['canonical_model_id'], 'google:gemini-2.5-pro');
        expect(gemini25['provider_id'], 'google');
      },
    );
  });
}
