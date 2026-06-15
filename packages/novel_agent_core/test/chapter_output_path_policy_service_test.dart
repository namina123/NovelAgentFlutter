import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterOutputPathPolicyService', () {
    const service = ChapterOutputPathPolicyService();

    test('upgrades chapter placeholder path with markdown heading title', () {
      final resolution = service.resolveChapterPath(
        requestedPath: 'chapters/第01章.md',
        title: '第01章',
        chapterContent: '# 第01章 醒在败家子床上\n\n风从窗缝里吹进来。',
      );

      expect(resolution.requestedPath, 'chapters/第01章.md');
      expect(resolution.resolvedPath, 'chapters/第01章_醒在败家子床上.md');
      expect(resolution.title, '第01章 醒在败家子床上');
      expect(resolution.chapterNumber, 1);
      expect(resolution.pathChanged, isTrue);
      expect(resolution.reason, 'chapter_placeholder_path_upgraded');
    });

    test('does not rename explicit non-placeholder chapter path', () {
      final resolution = service.resolveChapterPath(
        requestedPath: 'chapters/开篇_旧标题.md',
        title: '第01章 新标题',
        chapterContent: '# 第01章 新标题\n\n正文。',
      );

      expect(resolution.resolvedPath, 'chapters/开篇_旧标题.md');
      expect(resolution.pathChanged, isFalse);
    });

    test('removes duplicated chapter prefix when building file stem', () {
      expect(service.chapterFileStem(chapterNumber: 4, title: '第04章'), '第04章');
      expect(service.chapterFileStem(chapterNumber: 4, title: '第4章'), '第04章');
      expect(
        service.chapterFileStem(chapterNumber: 4, title: '第04章：族中压力'),
        '第04章_族中压力',
      );
      expect(
        service.chapterFileStem(chapterNumber: 4, title: '族中压力'),
        '第04章_族中压力',
      );
    });

    test('falls back to canonical chapter title when title is missing', () {
      final resolution = service.resolveChapterOutput(
        requestedPath: 'chapters/第04章_第04章.md',
        chapterContent: '正文还没有写出标题。',
      );

      expect(resolution.resolvedPath, 'chapters/第04章.md');
      expect(resolution.title, '第04章');
      expect(resolution.chapterNumber, 4);
      expect(resolution.pathChanged, isTrue);
    });

    test(
      'normalizes weird model path before resolving duplicate chapter path',
      () {
        final resolution = service.resolveChapterOutput(
          requestedPath: 'chapters\\..\\chapters\\.\\第04章_第04章.md',
          explicitTitle: '',
          submissionTitle: '第04章',
          chapterContent: '',
        );

        expect(resolution.requestedPath, 'chapters/第04章_第04章.md');
        expect(resolution.resolvedPath, 'chapters/第04章.md');
        expect(resolution.title, '第04章');
        expect(resolution.pathChanged, isTrue);
      },
    );

    test('normalizes markdown heading to the canonical chapter title', () {
      final normalized = service.normalizeChapterMarkdownHeading(
        chapterContent: '# 第04章\n\n正文。',
        title: '第04章 雪夜入城',
      );

      expect(normalized, startsWith('# 第04章 雪夜入城'));
      expect(normalized, contains('正文。'));
    });

    test('suggests chapter path from numbered markdown heading', () {
      final path = service.suggestChapterPath(
        explicitTitle: '',
        chapterContent: '# 第03章 雪夜折返\n\n正文。',
      );

      expect(path, 'chapters/第03章_雪夜折返.md');
    });

    test('suggests chapter path from unnumbered title when number is absent', () {
      final path = service.suggestChapterPath(
        explicitTitle: '雨夜归人',
        chapterContent: '正文。',
      );

      expect(path, 'chapters/雨夜归人.md');
    });
  });
}
