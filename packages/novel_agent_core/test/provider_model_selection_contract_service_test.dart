import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderModelSelectionContractService', () {
    test('keeps provider-bound candidates inside selected provider scope', () {
      final service = ProviderModelSelectionContractService();

      final options = service.providerModelOptions(
        providerId: 'siliconflow',
        query: 'deepseek',
      );

      expect(options, isNotEmpty);
      expect(options.every((entry) => entry.providerId == 'siliconflow'), isTrue);
      expect(
        options.any((entry) => entry.modelId == 'deepseek-ai/DeepSeek-V4-Flash'),
        isTrue,
      );
      expect(
        options.any((entry) => entry.providerId == 'openai'),
        isFalse,
      );
    });

    test('best provider model match prefers the current provider scope', () {
      final service = ProviderModelSelectionContractService();

      final matched = service.bestProviderModelMatch(
        providerId: 'siliconflow',
        modelId: 'deepseek-ai/DeepSeek-V4-Flash',
      );

      expect(matched, isNotNull);
      expect(matched!.providerId, 'siliconflow');
      expect(matched.modelId, 'deepseek-ai/DeepSeek-V4-Flash');
    });

    test('auto expand is driven by visible candidates rather than blank text', () {
      final service = ProviderModelSelectionContractService();
      final options = service.providerModelOptions(
        providerId: 'siliconflow',
        query: 'deepseek',
      );

      expect(
        service.shouldAutoExpandModelOptions(
          typedText: 'deepseek',
          selectedProviderId: 'siliconflow',
          currentOptions: options,
        ),
        isTrue,
      );
      expect(
        service.shouldAutoExpandModelOptions(
          typedText: '',
          selectedProviderId: 'siliconflow',
          currentOptions: options,
        ),
        isTrue,
      );
    });
  });
}
