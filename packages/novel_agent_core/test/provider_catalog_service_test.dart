import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderCatalogService', () {
    test('returns deepseek when base url hints match', () {
      // 中文注释: 这里验证旧项目迁移过来的厂商识别逻辑仍然可以按 base URL 自动命中。
      final service = ProviderCatalogService.seeded();

      final result = service.bestProviderMatch(
        baseUrl: 'https://api.deepseek.com',
      );

      expect(result['id'], 'deepseek');
    });

    test('returns exact model before fuzzy fallback', () {
      // 中文注释: 这里验证模型匹配先走精确命中，避免建议排序覆盖用户手输的真实模型 ID。
      final service = ProviderCatalogService.seeded();

      final result = service.matchModel('o4-mini', providerId: 'openai');

      expect(result['id'], 'o4-mini');
      expect(result['provider_id'], 'openai');
    });

    test('recognizes mainstream mainland provider endpoints', () {
      final service = ProviderCatalogService.seeded();

      final hunyuan = service.bestProviderMatch(
        baseUrl: 'https://api.hunyuan.cloud.tencent.com/v1',
      );
      final qianfan = service.bestProviderMatch(
        baseUrl: 'https://qianfan.baidubce.com/v2',
      );

      expect(hunyuan['id'], 'tencent_hunyuan');
      expect(qianfan['id'], 'baidu_qianfan');
    });

    test('recognizes qwen coding endpoint by base url', () {
      final service = ProviderCatalogService.seeded();

      final coding = service.bestProviderMatch(
        baseUrl: 'https://coding.dashscope.aliyuncs.com/v1',
      );

      expect(coding['id'], 'dashscope_coding');
    });

    test('recognizes minimax and doubao endpoints by base url', () {
      final service = ProviderCatalogService.seeded();

      final minimax = service.bestProviderMatch(
        baseUrl: 'https://api.minimax.chat/v1',
      );
      final doubao = service.bestProviderMatch(
        baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      );

      expect(minimax['id'], 'minimax');
      expect(doubao['id'], 'doubao');
    });

    test('recognizes google gemini openai-compatible endpoint by base url', () {
      final service = ProviderCatalogService.seeded();

      final google = service.bestProviderMatch(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      );

      expect(google['id'], 'google');
      expect(google['kind'], 'openai_compatible');
    });
  });
}
