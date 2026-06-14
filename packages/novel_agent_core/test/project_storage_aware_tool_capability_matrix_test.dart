import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectStorageAwareToolCapabilityMatrix', () {
    const matrix = ProjectStorageAwareToolCapabilityMatrix();

    test(
      'marks sqlite file mutation tools as compatibility and keeps domain tools primary',
      () {
        const context = ProjectToolExposureContext(
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        expect(
          matrix.roleForTool('submit_chapter_delivery', context: context),
          ProjectToolExposureRole.primary,
        );
        expect(
          matrix.roleForTool('write_project_file', context: context),
          ProjectToolExposureRole.compatibility,
        );
        expect(
          matrix.roleForTool('request_gateway_tool', context: context),
          ProjectToolExposureRole.transportOnly,
        );
        expect(
          matrix.sortToolIds(const <String>[
            'write_project_file',
            'submit_chapter_delivery',
            'read_project_file',
          ], context: context),
          orderedEquals(const <String>[
            'submit_chapter_delivery',
            'read_project_file',
            'write_project_file',
          ]),
        );
      },
    );

    test('describes sqlite compatibility layer in guidance text', () {
      const context = ProjectToolExposureContext(
        projectType: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );

      final guidance = matrix.guidanceFor(context);

      expect(guidance, contains('兼容层'));
      expect(guidance, contains('submit_chapter_delivery'));
      expect(guidance, contains('knowledge_base'));
    });
  });
}
