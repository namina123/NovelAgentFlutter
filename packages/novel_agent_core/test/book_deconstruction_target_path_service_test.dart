import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  const service = BookDeconstructionTargetPathService();

  test('routes source archive and preview into canonical roots', () {
    expect(
      service.sourceArchivePath('C:\\temp\\source.txt'),
      'sources/original/book_deconstruction_source_source.md',
    );
    expect(service.previewPath(), 'analysis/book_deconstruction_preview.md');
  });

  test('routes inherited narrative paths by followup route family', () {
    expect(
      service.inheritedChapterPath(
        followupOptionId: 'continuation_novel',
        sequence: 1,
        title: '第一章',
      ),
      'chapters/inherited/continuation/continuation_novel/001_第一章.md',
    );
    expect(
      service.inheritedChapterPath(
        followupOptionId: 'fanfic_seed_autopilot_novel',
        sequence: 2,
        title: '第二章',
      ),
      'chapters/inherited/fanfic/fanfic_seed_autopilot_novel/002_第二章.md',
    );
  });

  test('routes deconstruction assets through shared content roots', () {
    expect(
      service.storyOutlinePath(),
      'outlines/story/book_deconstruction_story_outline.md',
    );
    expect(
      service.chapterOutlinePath(
        const BookDeconstructionChapterOutline(
          id: 'ch_01',
          title: '第一章',
          sequence: 1,
          summary: 'summary',
        ),
        1,
      ),
      'outlines/chapters/book_deconstruction_chapter_1.md',
    );
    expect(
      service.assetPath(BookDeconstructionArtifactKind.styleProfile, 'style-1'),
      'assets/styles/style-1.md',
    );
  });
}
