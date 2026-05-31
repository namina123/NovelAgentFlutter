import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WritingModelRuntimeDefaultsService', () {
    test('returns offering-backed defaults for siliconflow deepseek relay', () {
      final service = WritingModelRuntimeDefaultsService();

      final defaults = service.resolveDefaults(
        providerId: 'siliconflow',
        modelId: 'deepseek-ai/DeepSeek-V4-Flash',
        credentialId: 'credential_demo',
      );

      expect(
        defaults['matched_writing_model_canonical_id'],
        'deepseek:deepseek-v4-flash',
      );
      expect(defaults['name'], 'DeepSeek V4 Flash');
      expect(defaults['context_length'], 131072);
      expect(defaults['compression_context_length'], 98304);
      expect(defaults['max_output_tokens'], 65536);
      expect(
        ValueReaders.stringList(defaults['supported_parameters']),
        contains('enable_thinking'),
      );
      expect(defaults['supports_temperature'], isTrue);
      expect(defaults['supports_tools'], isTrue);
      expect(defaults['supports_streaming'], isTrue);
    });

    test('returns empty defaults for unknown provider/model', () {
      final service = WritingModelRuntimeDefaultsService();

      final defaults = service.resolveDefaults(
        providerId: 'custom_provider',
        modelId: 'custom-model',
        credentialId: 'credential_demo',
      );

      expect(defaults, isEmpty);
    });
  });
}
