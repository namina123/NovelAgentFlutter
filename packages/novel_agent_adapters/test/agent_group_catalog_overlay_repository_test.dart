import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('AgentGroupCatalogOverlayRepository', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-group-overlay-',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves and lists normalized overlays', () async {
      final repository = AgentGroupCatalogOverlayRepository(
        settingsRootPath: tempDirectory.path,
      );

      await repository.saveOverlay(<String, Object?>{
        'group_id': 'starter_long_novel_seed_generalist',
        'display_label': '长任务灵感开局',
        'recommended_by_default': true,
        'applicability_scope': <String, Object?>{
          'project_type_ids': <String>['long_novel'],
          'required_traits': <String>['long_task', 'seed_driven'],
        },
      });

      final overlays = await repository.listOverlays();

      expect(overlays, hasLength(1));
      final overlay = overlays.single;
      expect(overlay['group_id'], 'starter_long_novel_seed_generalist');
      expect(overlay['display_label'], '长任务灵感开局');
      final scope = Map<String, Object?>.from(
        overlay['applicability_scope']! as Map<Object?, Object?>,
      );
      expect(
        List<Object?>.from(scope['allowed_project_type_ids']! as List<Object?>),
        <Object?>['long_novel'],
      );
      expect(
        List<Object?>.from(scope['required_trait_ids']! as List<Object?>),
        <Object?>['long_task', 'seed_driven'],
      );
    });
  });
}
