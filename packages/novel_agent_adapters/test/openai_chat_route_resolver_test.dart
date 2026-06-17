import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiChatRouteResolver', () {
    test('always resolves chat completions route for api_mode inputs', () {
      const resolver = OpenAiChatRouteResolver();

      final resolution = resolver.resolve(apiMode: 'responses');

      expect(resolution.routeFamily, RequestRouteFamily.chatCompletions);
      expect(resolution.apiMode, ProviderProfileConstants.apiModeChat);
      expect(resolution.isFallbackUsed, isTrue);
      expect(resolution.allowedRouteFamilies, hasLength(1));
    });

    test('builds chat completions request uri from base url', () {
      const resolver = OpenAiChatRouteResolver();

      final uri = resolver.resolveRequestUri(
        'https://example.com/v1/',
        apiMode: 'responses',
      );

      expect(uri.toString(), 'https://example.com/v1/chat/completions');
    });
  });
}
