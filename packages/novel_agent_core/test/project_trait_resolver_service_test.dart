import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTraitResolverService', () {
    test('resolves long novel traits from project type and mode', () {
      final resolver = ProjectTraitResolverService();

      final traits = resolver.resolve(
        projectTypeId: 'long_novel',
        modeId: 'seed_autopilot_novel',
      );

      expect(traits.contains(ProjectTrait.longTask), isTrue);
      expect(traits.contains(ProjectTrait.openingGuided), isTrue);
      expect(traits.contains(ProjectTrait.seedDriven), isTrue);
    });

    test('merges runtime baseline and custom traits without duplication', () {
      final resolver = ProjectTraitResolverService();

      final traits = resolver.resolve(
        projectTypeId: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
        additionalTraitIds: const <String>[
          'full_outline',
          'custom_scope',
          'custom_scope',
        ],
      );

      expect(traits.contains(ProjectTrait.longTask), isTrue);
      expect(traits.contains(ProjectTrait.fullOutline), isTrue);
      expect(traits.containsId('custom_scope'), isTrue);
      expect(traits.ids.where((item) => item == 'custom_scope').length, 1);
    });

    test('keeps book deconstruction trait on deconstruction project', () {
      final resolver = ProjectTraitResolverService();

      final traits = resolver.resolve(projectTypeId: 'book_deconstruction');

      expect(traits.contains(ProjectTrait.bookDeconstruction), isTrue);
      expect(traits.contains(ProjectTrait.longTask), isFalse);
    });
  });
}
