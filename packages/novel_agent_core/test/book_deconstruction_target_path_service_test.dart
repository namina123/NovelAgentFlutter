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

  test('liveChapterPath 把续写正文落到正文区域 chapters/ 且文件名带可解析"第N章"', () {
    // 中文注释: 规格要求续写把分好的正文放进正文区域。liveChapterPath 必须落在 chapters/ 根
    // （而非 inherited/），并且文件名带"第N章"，让续写优先级服务能解析出章节号。
    // 标题已含"第N章"时直接用标题。
    expect(
      service.liveChapterPath(sequence: 1, title: '第一章 港口风暴'),
      'chapters/第一章_港口风暴.md',
    );
    // 标题没有章节标记时，用序号合成"第N章"前缀，保证可解析。
    expect(
      service.liveChapterPath(sequence: 3, title: '港口风暴'),
      'chapters/第3章_港口风暴.md',
    );
    // sequence<=0 兜底为第 1 章。
    expect(
      service.liveChapterPath(sequence: 0, title: '序'),
      'chapters/第1章_序.md',
    );
  });
}
