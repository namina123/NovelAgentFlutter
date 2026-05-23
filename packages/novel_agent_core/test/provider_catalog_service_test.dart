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
  });
}
