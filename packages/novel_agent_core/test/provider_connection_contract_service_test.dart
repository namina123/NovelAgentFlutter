import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderConnectionContractService', () {
    test('normalizes a single route family template into a connection contract', () {
      final service = ProviderConnectionContractService();

      final contract = service.contractByTemplateId('anthropic_api');

      expect(contract, isNotNull);
      expect(contract!.providerId, 'anthropic');
      expect(contract.protocolKind, ProtocolKind.anthropicCompatible);
      expect(contract.defaultBaseUrl, 'https://api.anthropic.com/v1');
      expect(contract.routeFamily, RequestRouteFamily.messages);
      expect(contract.allowedRouteFamilies, [RequestRouteFamily.messages]);
      expect(contract.allowedApiModes, ['messages']);
    });

    test('normalizes a multi-route template into a connection contract', () {
      final service = ProviderConnectionContractService();

      final openai = service.contractByTemplateId('openai_api');
      final doubao = service.contractByTemplateId('doubao_openai');

      expect(openai, isNotNull);
      expect(openai!.protocolKind, ProtocolKind.openAiCompatible);
      expect(
        openai.allowedRouteFamilies,
        containsAll(<RequestRouteFamily>[
          RequestRouteFamily.chatCompletions,
          RequestRouteFamily.responses,
        ]),
      );
      expect(openai.allowedApiModes, containsAll(<String>['chat', 'responses']));
      expect(doubao, isNotNull);
      expect(
        doubao!.allowedRouteFamilies,
        containsAll(<RequestRouteFamily>[
          RequestRouteFamily.chatCompletions,
          RequestRouteFamily.responses,
        ]),
      );
    });

    test('keeps google openai-compatible and native contracts separate', () {
      final service = ProviderConnectionContractService();

      final openaiCompatible = service.contractByTemplateId(
        'google_openai_compatible',
      );
      final native = service.contractByTemplateId('google_gemini_native');

      expect(openaiCompatible, isNotNull);
      expect(native, isNotNull);
      expect(openaiCompatible!.protocolKind, ProtocolKind.openAiCompatible);
      expect(native!.protocolKind, ProtocolKind.geminiNative);
      expect(native.protocolId, 'gemini_native');
      expect(
        openaiCompatible.allowedRouteFamilies,
        containsAll(<RequestRouteFamily>[
          RequestRouteFamily.chatCompletions,
          RequestRouteFamily.responses,
        ]),
      );
      expect(
        native.allowedRouteFamilies,
        [
          RequestRouteFamily.generateContent,
          RequestRouteFamily.streamGenerateContent,
        ],
      );
    });

    test('resolves connection contracts from base url hints and defaults', () {
      final service = ProviderConnectionContractService();

      final openaiResolution = service.resolve(
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );
      final manualResolution = service.resolve();

      expect(openaiResolution.contract.providerId, 'openai');
      expect(openaiResolution.contract.routeFamily, RequestRouteFamily.chatCompletions);
      expect(openaiResolution.matchedTemplate['id'], 'openai_api');
      expect(manualResolution.contract.providerId, '');
      expect(manualResolution.contract.defaultBaseUrl, '');
      expect(manualResolution.contract.routeFamily, RequestRouteFamily.chatCompletions);
    });
  });
}
