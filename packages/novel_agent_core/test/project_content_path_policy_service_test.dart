import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContentPathPolicyService', () {
    const service = ProjectContentPathPolicyService();

    test('workspace defaults align to visible modern roots', () {
      // 中文注释: 这里锁定工作区默认目标目录，避免 GUI 后续又退回 drafts 或 world 这类旧兼容根。
      expect(service.defaultWorkspaceFileDirectory(), 'chapters');
      expect(service.defaultWorkspaceFolderDirectory(), 'assets');
      expect(service.defaultImportTargetDirectory(), 'assets');
    });

    test('content type directories follow chapter and scene split', () {
      // 中文注释: 内容类型目录映射必须稳定，章节级正文与局部场景不能再混回同一个旧草稿目录。
      expect(service.directoryForContentType('chapter'), 'chapters');
      expect(service.directoryForContentType('scene'), 'scenes');
      expect(service.directoryForContentType('character'), 'assets/characters');
    });

    test('infer content type recognizes canonical chapter paths', () {
      // 中文注释: 从正式目录反推内容类型也要走同一口径，供工具层和宿主展示共享。
      expect(service.inferContentTypeFromPath('chapters/ch01.md'), 'chapter');
      expect(service.inferContentTypeFromPath('scenes/flashback.md'), 'scene');
      expect(
        service.inferContentTypeFromPath('assets/characters/hero.md'),
        'character',
      );
    });
  });
}
