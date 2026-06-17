import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderRequestRouteResolver', () {
    test('resolves openai chat and responses routes from one runtime entry', () {
      const resolver = ProviderRequestRouteResolver();

      final chatResolution = resolver.resolve(
        protocol: ProviderProfileConstants.kindOpenAiCompatible,
        apiMode: 'chat',
      );
      final responsesResolution = resolver.resolve(
        protocol: ProviderProfileConstants.kindOpenAiCompatible,
        apiMode: 'responses',
      );

      expect(chatResolution.routeFamily, RequestRouteFamily.chatCompletions);
      expect(chatResolution.apiMode, ProviderProfileConstants.apiModeChat);
      expect(chatResolution.isAllowed, isTrue);
      expect(responsesResolution.routeFamily, RequestRouteFamily.responses);
      expect(
        responsesResolution.apiMode,
        ProviderProfileConstants.apiModeResponses,
      );
      expect(responsesResolution.isAllowed, isTrue);
    });

    test('keeps anthropic messages route closed to messages', () {
      const resolver = ProviderRequestRouteResolver();

      final resolution = resolver.resolve(
        protocol: ProviderProfileConstants.kindAnthropicCompatible,
        apiMode: 'responses',
      );

      expect(resolution.routeFamily, RequestRouteFamily.messages);
      expect(resolution.apiMode, ProviderProfileConstants.apiModeMessages);
      expect(resolution.isFallbackUsed, isTrue);
      expect(resolution.isAllowed, isTrue);
    });

    test('keeps gemini native routes closed to native content families', () {
      const resolver = ProviderRequestRouteResolver();

      final resolution = resolver.resolve(
        protocol: 'gemini_native',
        apiMode: 'responses',
      );

      expect(resolution.routeFamily, RequestRouteFamily.generateContent);
      expect(
        resolution.apiMode,
        ProviderProfileConstants.apiModeGenerateContent,
      );
      expect(resolution.isFallbackUsed, isTrue);
      expect(resolution.isAllowed, isTrue);
    });
  });
}
