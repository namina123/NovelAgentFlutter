import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CapabilityExposureView', () {
    test('projects openai runtime exposure with api mode visibility', () {
      final profileService = ProviderProfileService(
        catalogPort: ProviderCatalogService.seeded(),
        capabilityPort: ProviderCapabilityResolver.seeded(),
      );
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'GPT-5.5',
          'model': 'gpt-5.5',
        },
        <String, Object?>{
          'name': 'OpenAI 主接口',
          'provider_id': 'openai',
          'kind': 'openai_compatible',
          'base_url': 'https://api.openai.com/v1',
        },
      );

      final exposure = CapabilityExposureView.fromRuntimeProfile(runtime);

      expect(exposure.protocolMode, 'openai_compatible');
      expect(exposure.protocolLabel, 'OpenAI 协议格式');
      expect(exposure.routeFamily, 'chat_completions');
      expect(exposure.apiModeVisible, isTrue);
      expect(exposure.allowedApiModes, containsAll(<String>['chat', 'responses']));
      expect(exposure.visibleAdvancedFields, contains('api_mode'));
    });

    test('projects anthropic runtime exposure without api mode toggle', () {
      final profileService = ProviderProfileService(
        catalogPort: ProviderCatalogService.seeded(),
        capabilityPort: ProviderCapabilityResolver.seeded(),
      );
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
        <String, Object?>{
          'name': 'Claude Sonnet',
          'model': 'claude-3-5-sonnet-20241022',
        },
        <String, Object?>{
          'name': 'Anthropic 主接口',
          'provider_id': 'anthropic',
          'kind': 'anthropic_compatible',
          'base_url': 'https://api.anthropic.com/v1',
        },
      );

      final exposure = CapabilityExposureView.fromRuntimeProfile(runtime);

      expect(exposure.protocolMode, 'anthropic_compatible');
      expect(exposure.routeFamily, 'messages');
      expect(exposure.apiModeVisible, isFalse);
      expect(exposure.allowedApiModes, ['messages']);
      expect(exposure.visibleAdvancedFields, isNot(contains('api_mode')));
    });

    test('projects gemini native runtime exposure without api mode toggle', () {
      final profileService = ProviderProfileService(
        catalogPort: ProviderCatalogService.seeded(),
        capabilityPort: ProviderCapabilityResolver.seeded(),
      );
      final runtime = profileService.runtimeProfiles.composeRuntimeProfile(
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

      final exposure = CapabilityExposureView.fromRuntimeProfile(runtime);

      expect(exposure.protocolMode, 'gemini_native');
      expect(exposure.protocolLabel, 'Gemini 原生协议');
      expect(exposure.routeFamily, 'generate_content');
      expect(exposure.apiModeVisible, isFalse);
      expect(
        exposure.allowedApiModes,
        ['generate_content', 'stream_generate_content'],
      );
      expect(exposure.visibleAdvancedFields, isNot(contains('api_mode')));
    });
  });
}
