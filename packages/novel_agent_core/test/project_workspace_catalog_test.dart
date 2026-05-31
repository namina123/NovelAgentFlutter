import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWorkspaceCatalog', () {
    test('default resource tree descriptors do not include advanced dirs', () {
      final defaultPaths = ProjectWorkspaceCatalog
          .defaultResourceTreeDirectoryDescriptors
          .map((descriptor) => descriptor.path)
          .toSet();

      expect(defaultPaths.contains('agents/'), isFalse);
      expect(defaultPaths.contains('agent_groups/'), isFalse);
      expect(defaultPaths.contains('skills/'), isFalse);
      expect(defaultPaths.contains('skill_groups/'), isFalse);
      expect(defaultPaths.contains('prompts/'), isFalse);
      expect(defaultPaths.contains('tracking/'), isFalse);
      expect(defaultPaths.contains('runs/'), isFalse);
      expect(defaultPaths.contains('premise/'), isTrue);
      expect(defaultPaths.contains('outlines/story/'), isTrue);
      expect(defaultPaths.contains('assets/characters/'), isTrue);
    });

    test('classifies default, advanced and internal paths separately', () {
      expect(
        ProjectWorkspaceCatalog.isDefaultResourceTreePath(
          'assets/characters/hero.md',
        ),
        isTrue,
      );
      expect(
        ProjectWorkspaceCatalog.isDefaultResourceTreePath(
          'tasks/reviews/review_01.md',
        ),
        isTrue,
      );
      expect(
        ProjectWorkspaceCatalog.isDefaultResourceTreePath(
          'agents/default_generalist/AGENT.md',
        ),
        isFalse,
      );

      expect(
        ProjectWorkspaceCatalog.isAdvancedWorkspacePath(
          'agents/default_generalist/AGENT.md',
        ),
        isTrue,
      );
      expect(
        ProjectWorkspaceCatalog.isAdvancedWorkspacePath(
          'tracking/current_run.md',
        ),
        isTrue,
      );
      expect(
        ProjectWorkspaceCatalog.isAdvancedWorkspacePath('chapters/ch01.md'),
        isFalse,
      );

      expect(
        ProjectWorkspaceCatalog.isInternalWorkspacePath(
          '.novel_agent/state/runtime.json',
        ),
        isTrue,
      );
      expect(
        ProjectWorkspaceCatalog.isInternalWorkspacePath('runs/ch01.md'),
        isFalse,
      );
    });
  });
}
