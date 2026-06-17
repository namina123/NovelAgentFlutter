import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDiagnosticsProjectionService', () {
    test('builds shared diagnostics for openai anthropic and gemini families', () {
      const service = ProviderDiagnosticsProjectionService();
      final profileService = ProviderProfileService(
        catalogPort: ProviderCatalogService.seeded(),
        capabilityPort: ProviderCapabilityResolver.seeded(),
      );

      final openaiRuntime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'GPT-5.5',
          'model': 'gpt-5.5',
        },
        <String, Object?>{
          'name': 'OpenAI',
          'provider_id': 'openai',
          'kind': 'openai_compatible',
          'base_url': 'https://api.openai.com/v1',
        },
        apiMode: 'responses',
      );
      final anthropicRuntime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Claude Sonnet',
          'model': 'claude-3-5-sonnet-20241022',
        },
        <String, Object?>{
          'name': 'Anthropic',
          'provider_id': 'anthropic',
          'kind': 'anthropic_compatible',
          'base_url': 'https://api.anthropic.com/v1',
        },
      );
      final geminiRuntime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Gemini 3.5',
          'model': 'gemini-3.5',
        },
        <String, Object?>{
          'name': 'Google Gemini Native',
          'provider_id': 'google',
          'kind': 'gemini_native',
          'base_url': 'https://generativelanguage.googleapis.com/v1beta',
        },
      );

      final openaiDiagnostics = service.build(
        runtimeProfile: openaiRuntime,
        providerSettings: const ProviderEndpointSettings(
          id: 'openai',
          title: 'OpenAI',
          protocol: ProviderProfileConstants.kindOpenAiCompatible,
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'test-key',
          modelId: 'gpt-5.5',
          description: 'openai',
        ),
      );
      final anthropicDiagnostics = service.build(
        runtimeProfile: anthropicRuntime,
        providerSettings: const ProviderEndpointSettings(
          id: 'anthropic',
          title: 'Anthropic',
          protocol: ProviderProfileConstants.kindAnthropicCompatible,
          baseUrl: 'https://api.anthropic.com/v1',
          apiKey: 'test-key',
          modelId: 'claude-3-5-sonnet-20241022',
          description: 'anthropic',
        ),
      );
      final geminiDiagnostics = service.build(
        runtimeProfile: geminiRuntime,
        providerSettings: const ProviderEndpointSettings(
          id: 'google',
          title: 'Google',
          protocol: 'gemini_native',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          apiKey: 'test-key',
          modelId: 'gemini-3.5',
          description: 'gemini',
        ),
      );

      expect(openaiDiagnostics.protocolKind, ProtocolKind.openAiCompatible);
      expect(openaiDiagnostics.resolvedApiMode, 'responses');
      expect(openaiDiagnostics.selectedRouteFamily, RequestRouteFamily.responses);
      expect(openaiDiagnostics.apiModeVisible, isTrue);
      expect(anthropicDiagnostics.protocolKind, ProtocolKind.anthropicCompatible);
      expect(anthropicDiagnostics.resolvedApiMode, 'messages');
      expect(
        anthropicDiagnostics.selectedRouteFamily,
        RequestRouteFamily.messages,
      );
      expect(anthropicDiagnostics.apiModeVisible, isFalse);
      expect(geminiDiagnostics.protocolKind, ProtocolKind.geminiNative);
      expect(geminiDiagnostics.resolvedApiMode, 'generate_content');
      expect(
        geminiDiagnostics.selectedRouteFamily,
        RequestRouteFamily.generateContent,
      );
      expect(geminiDiagnostics.apiModeVisible, isFalse);
      expect(
        geminiDiagnostics.allowedRouteFamilies,
        contains(RequestRouteFamily.generateContent),
      );
    });
  });
}
