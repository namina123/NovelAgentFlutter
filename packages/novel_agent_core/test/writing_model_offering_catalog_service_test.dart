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
  });
}
