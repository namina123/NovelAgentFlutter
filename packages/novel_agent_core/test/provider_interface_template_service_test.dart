import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderInterfaceTemplateService', () {
    test('recognizes deepseek anthropic as a distinct template', () {
      final service = ProviderInterfaceTemplateService.seeded();

      final matched = service.bestTemplateMatch(
        baseUrl: 'https://api.deepseek.com/anthropic',
      );

      expect(matched['id'], 'deepseek_anthropic');
      expect(matched['protocol'], 'anthropic_compatible');
    });

    test('keeps GLM openai and anthropic routes as separate templates', () {
      final service = ProviderInterfaceTemplateService.seeded();

      final openai = service.templateById('glm_openai');
      final anthropic = service.templateById('glm_anthropic');

      expect(openai['default_base_url'], 'https://open.bigmodel.cn/api/paas/v4');
      expect(anthropic['default_base_url'], 'https://open.bigmodel.cn/api/anthropic');
      expect(openai['protocol'], 'openai_compatible');
      expect(anthropic['protocol'], 'anthropic_compatible');
    });

    test('finds opencode go by query aliases', () {
      final service = ProviderInterfaceTemplateService.seeded();

      final matched = service.bestTemplateMatch(query: 'opencode go');

      expect(matched['id'], 'opencode_go');
      expect(matched['route_family'], 'mixed');
    });
  });
}
