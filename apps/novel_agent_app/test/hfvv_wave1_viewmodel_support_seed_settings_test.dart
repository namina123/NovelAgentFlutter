import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/hfvv_wave1_viewmodel_support.dart';
import '../tool/probe_support.dart';

void main() {
  test(
    'buildHfvvWave1SeedSettings does not carry host workbench snapshot into isolated workspace settings',
    () {
      final hostSettings = AppSettings(
        defaultProviderId: 'host-provider',
        defaultAgentId: 'default_generalist',
        defaultModelId: 'host-model',
        defaultProjectPath: 'D:/Host/Projects/demo',
        autoSaveDrafts: true,
        providers: const <ProviderEndpointSettings>[],
        extraSettings: <String, Object?>{
          'workbench_state': <String, Object?>{
            'project_root_path': 'C:/Users/PC/Documents/NovelAgent/demo',
            'active_document_path': 'chapters/ch01.md',
          },
          'custom_flag': true,
        },
      );

      final seeded = buildHfvvWave1SeedSettings(
        apiConfig: const ProbeApiConfig(
          baseUrl: 'https://example.invalid/v1',
          apiKey: 'env-secret-key',
          modelId: 'hfvv-model',
          sourceLabel: 'test',
        ),
        hostSettings: hostSettings,
      );

      expect(seeded.defaultProjectPath, isEmpty);
      expect(seeded.providers.single.apiKey, isEmpty);
      expect(seeded.extraSettings.containsKey('workbench_state'), isFalse);
      expect(seeded.extraSettings['custom_flag'], isNull);
      expect(seeded.extraSettings['model_settings'], <String, Object?>{
        'provider_id': 'hfvv-wave1-provider',
        'model_id': 'hfvv-model',
        'stream_mode': 'stream',
        'api_mode': 'chat',
      });
    },
  );
}
