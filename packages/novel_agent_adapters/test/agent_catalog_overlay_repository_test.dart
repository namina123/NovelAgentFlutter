import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('AgentCatalogOverlayRepository', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-agent-overlay-',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves and lists normalized overlays', () async {
      final repository = AgentCatalogOverlayRepository(
        settingsRootPath: tempDirectory.path,
      );

      await repository.saveOverlay(<String, Object?>{
        'agent_id': 'default_generalist',
        'display_label': '默认创作智能体',
        'recommended_by_default': true,
        'applicability_scope': <String, Object?>{
          'project_types': <String>['novel', 'long_novel'],
          'required_traits': <String>['opening_guided'],
        },
      });

      final overlays = await repository.listOverlays();

      expect(overlays, hasLength(1));
      final overlay = overlays.single;
      expect(overlay['agent_id'], 'default_generalist');
      expect(overlay['display_label'], '默认创作智能体');
      final scope = Map<String, Object?>.from(
        overlay['applicability_scope']! as Map<Object?, Object?>,
      );
      expect(
        List<Object?>.from(scope['allowed_project_type_ids']! as List<Object?>),
        <Object?>['novel', 'long_novel'],
      );
      expect(
        List<Object?>.from(scope['required_trait_ids']! as List<Object?>),
        <Object?>['opening_guided'],
      );
    });
  });
}
