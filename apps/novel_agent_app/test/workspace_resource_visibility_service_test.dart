import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_resource_visibility_service.dart';

void main() {
  group('WorkspaceResourceVisibilityService', () {
    const service = WorkspaceResourceVisibilityService();

    test('hides legacy compatibility roots from default resource tree', () {
      expect(service.shouldHideFromDefaultTree('drafts/ch01.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('outline/outline.md'), isTrue);
      expect(
        service.shouldHideFromDefaultTree('volume_outlines/index.md'),
        isTrue,
      );
      expect(
        service.shouldHideFromDefaultTree('chapter_outlines/index.md'),
        isTrue,
      );
      expect(
        service.shouldHideFromDefaultTree('specs/project_brief.md'),
        isTrue,
      );
      expect(service.shouldHideFromDefaultTree('characters/苏九.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('styles/连载风格.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('world/世界规则.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('inspiration/seed.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('knowledge/神话资料.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('summaries/ch01.md'), isTrue);
      expect(
        service.shouldHideFromDefaultTree('constraints/opening.md'),
        isTrue,
      );
      expect(service.shouldHideFromDefaultTree('continuity/state.md'), isTrue);
      expect(service.shouldHideFromDefaultTree('reviews/review_01.md'), isTrue);
      expect(service.isLegacyCompatibilityPath('drafts/ch01.md'), isTrue);
      expect(service.isLegacyCompatibilityPath('outline/outline.md'), isTrue);
      expect(
        service.isLegacyCompatibilityPath('specs/project_brief.md'),
        isTrue,
      );
      expect(service.isLegacyCompatibilityPath('characters/苏九.md'), isTrue);
      expect(service.isLegacyCompatibilityPath('world/世界规则.md'), isTrue);
      expect(service.isLegacyCompatibilityPath('inspiration/seed.md'), isTrue);
    });

    test('keeps new user-facing directories visible by default', () {
      expect(
        service.shouldHideFromDefaultTree('premise/project_brief.md'),
        isFalse,
      );
      expect(
        service.shouldHideFromDefaultTree('outlines/story/story_outline.md'),
        isFalse,
      );
      expect(service.shouldHideFromDefaultTree('chapters/ch01.md'), isFalse);
      expect(
        service.shouldHideFromDefaultTree('assets/characters/hero.md'),
        isFalse,
      );
      expect(
        service.shouldHideFromDefaultTree('tasks/reviews/review_01.md'),
        isFalse,
      );
    });

    test('still hides internal and advanced workspace paths', () {
      expect(
        service.shouldHideFromDefaultTree(
          '.novel_agent/runtime/session_state.json',
        ),
        isTrue,
      );
      expect(
        service.shouldHideFromDefaultTree('agents/default_generalist/AGENT.md'),
        isTrue,
      );
      expect(service.shouldHideFromDefaultTree('prompts/opening.md'), isTrue);
    });

    test('hides SQLite database files from the default resource tree', () {
      expect(
        service.shouldHideFromDefaultTree('.novel_agent/sqlite/novel_agent.db'),
        isTrue,
      );
      expect(
        service.shouldHideFromDefaultTree('premise/project.sqlite'),
        isTrue,
      );
      expect(
        service.shouldHideFromDefaultTree('exports/projection.sqlite'),
        isTrue,
      );
    });
  });
}
