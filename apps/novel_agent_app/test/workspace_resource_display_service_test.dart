import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_resource_display_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_resource_visibility_service.dart';

void main() {
  group('WorkspaceResourceDisplayService', () {
    const service = WorkspaceResourceDisplayService();

    test('delegates default tree visibility to visibility service', () {
      const visibilityService = WorkspaceResourceVisibilityService();

      expect(
        service.shouldHidePath('agents/default_generalist/AGENT.md'),
        visibilityService.shouldHideFromDefaultTree(
          'agents/default_generalist/AGENT.md',
        ),
      );
      expect(
        service.shouldHidePath('drafts/ch01.md'),
        visibilityService.shouldHideFromDefaultTree('drafts/ch01.md'),
      );
      expect(
        service.shouldHidePath('premise/project_brief.md'),
        visibilityService.shouldHideFromDefaultTree('premise/project_brief.md'),
      );
    });

    test(
      'maps legacy directories to Chinese labels through unified descriptors',
      () {
        expect(service.titleOf('outline', isDirectory: true), '大纲');
        expect(service.titleOf('volume_outlines', isDirectory: true), '卷纲');
        expect(service.titleOf('chapter_outlines', isDirectory: true), '章纲');
        expect(service.titleOf('styles', isDirectory: true), '风格');
        expect(service.titleOf('world', isDirectory: true), '世界');
        expect(service.titleOf('knowledge', isDirectory: true), '知识');
        expect(service.titleOf('summaries', isDirectory: true), '摘要');
        expect(service.titleOf('reviews', isDirectory: true), '审稿');
      },
    );

    test(
      'keeps new skeleton directories and legacy outline candidates together',
      () {
        final candidates = service.likelyOutlineDocumentCandidates();

        expect(candidates, contains('outlines/story/story_outline.md'));
        expect(candidates, contains('outline/outline.md'));
        expect(candidates, contains('volume_outlines/index.md'));
        expect(candidates, contains('chapter_outlines/index.md'));
      },
    );
  });
}
