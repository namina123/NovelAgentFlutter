import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderRouteContract', () {
    test('projects protocol options with supported route families', () {
      final service = ProviderProtocolService();

      final options = service.protocolOptions();
      final openai = options.firstWhere(
        (entry) => ValueReaders.stringValue(entry['id']) == 'openai_compatible',
      );
      final anthropic = options.firstWhere(
        (entry) =>
            ValueReaders.stringValue(entry['id']) == 'anthropic_compatible',
      );
      final gemini = options.firstWhere(
        (entry) => ValueReaders.stringValue(entry['id']) == 'gemini_native',
      );

      expect(openai['default_route_family'], 'chat_completions');
      expect(
        ValueReaders.stringList(openai['route_families']),
        containsAll(<String>['chat_completions', 'responses', 'embeddings']),
      );
      expect(
        ValueReaders.stringList(openai['api_modes']),
        containsAll(<String>['chat', 'responses', 'embeddings']),
      );
      expect(anthropic['default_route_family'], 'messages');
      expect(ValueReaders.stringList(anthropic['route_families']), ['messages']);
      expect(ValueReaders.stringList(anthropic['api_modes']), ['messages']);
      expect(gemini['default_route_family'], 'generate_content');
      expect(
        ValueReaders.stringList(gemini['route_families']),
        ['generate_content', 'stream_generate_content'],
      );
      expect(
        ValueReaders.stringList(gemini['api_modes']),
        ['generate_content', 'stream_generate_content'],
      );
    });

    test('maps api modes into formal route family contracts', () {
      expect(
        ApiModeRouteMapping.normalizeApiMode(
          'chat_completions',
          protocolKind: ProtocolKind.openAiCompatible,
        ),
        'chat',
      );
      expect(
        ApiModeRouteMapping.normalizeApiMode(
          'responses',
          protocolKind: ProtocolKind.openAiCompatible,
        ),
        'responses',
      );
      expect(
        ApiModeRouteMapping.normalizeApiMode(
          'chat',
          protocolKind: ProtocolKind.anthropicCompatible,
        ),
        'messages',
      );
      expect(
        ApiModeRouteMapping.routeFamilyForApiMode(
          'generate_content',
          protocolKind: ProtocolKind.openAiCompatible,
          allowedRouteFamilies: const <RequestRouteFamily>[
            RequestRouteFamily.generateContent,
          ],
        ),
        RequestRouteFamily.generateContent,
      );
    });

    test('resolves gateway routes with protocol defaults and fallbacks', () {
      final openai = GatewayRouteResolution.resolve(
        protocolKind: ProtocolKind.openAiCompatible,
        apiMode: 'responses',
      );
      final anthropic = GatewayRouteResolution.resolve(
        protocolKind: ProtocolKind.anthropicCompatible,
        apiMode: 'chat',
      );

      expect(openai.routeFamily, RequestRouteFamily.responses);
      expect(openai.apiMode, 'responses');
      expect(openai.isAllowed, isTrue);
      expect(anthropic.routeFamily, RequestRouteFamily.messages);
      expect(anthropic.apiMode, 'messages');
      expect(anthropic.isFallbackUsed, isTrue);
      expect(
        anthropic.toJson()['allowed_route_families'],
        ['messages'],
      );
    });
  });
}
