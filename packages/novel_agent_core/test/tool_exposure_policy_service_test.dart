import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExposurePolicyService', () {
    const service = ToolExposurePolicyService();

    test('exposes start_long_task_run only for long task projects', () {
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'long_novel',
        ),
        isTrue,
      );
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'novel',
        ),
        isFalse,
      );
    });

    test('hides start_long_task_run from sub agents', () {
      expect(
        service.isToolExposed(
          'start_long_task_run',
          hostPlatform: HostPlatform.windows,
          projectType: 'long_novel',
          isSubAgent: true,
        ),
        isFalse,
      );
    });

    test('keeps external research tool behind platform policy', () {
      expect(
        service.isToolExposed(
          NarrativeDomainToolNames.requestExternalResearch,
          hostPlatform: HostPlatform.windows,
          projectType: 'novel',
        ),
        isTrue,
      );
      expect(
        service.isToolExposed(
          NarrativeDomainToolNames.requestExternalResearch,
          hostPlatform: HostPlatform.android,
          projectType: 'novel',
        ),
        isFalse,
      );
    });

    test(
      'sorts sqlite project tool surface to prefer structured tools before file compatibility tools',
      () {
        final exposed = service.filterExposedToolIds(
          const <String>[
            'write_project_file',
            'submit_chapter_delivery',
            'read_project_file',
          ],
          hostPlatform: HostPlatform.windows,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        expect(
          exposed,
          orderedEquals(const <String>[
            'submit_chapter_delivery',
            'read_project_file',
            'write_project_file',
          ]),
        );
      },
    );
  });
}
