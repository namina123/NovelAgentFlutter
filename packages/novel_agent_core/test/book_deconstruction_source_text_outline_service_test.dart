import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionSourceTextOutlineService', () {
    final service = BookDeconstructionSourceTextOutlineService();

    test('会从章节标题抽取章节骨架并生成总纲与前提摘要', () {
      const content = '''
第一章 港口风暴
主角在港口被迫卷入一场追捕。

第二章 议会阴影
城邦议会开始浮出水面。
''';

      final chapterOutlines = service.chapterOutlinesOf(content);

      expect(chapterOutlines, hasLength(2));
      expect(chapterOutlines.first.title, '第一章 港口风暴');
      expect(chapterOutlines.first.summary, '主角在港口被迫卷入一场追捕。');
      expect(
        chapterOutlines.first.metadata['structure_kind'],
        ReferenceSourceDocumentStructureKinds.explicitChapter,
      );
      expect(
        service.storyOutlineSummaryOf(content, chapterOutlines),
        '第一章 港口风暴：主角在港口被迫卷入一场追捕。；第二章 议会阴影：城邦议会开始浮出水面。',
      );
      expect(
        service.premiseSummaryOf(content, '任意总纲'),
        '第一章 港口风暴 主角在港口被迫卷入一场追捕。 第二章 议会阴影 城邦议会开始浮出水面。',
      );
      expect(
        service.buildPremises(
          content: content,
          sourceAbsolutePath: 'D:/books/harbor_story.txt',
          storyOutlineSummary: '任意总纲',
        ),
        hasLength(1),
      );
      expect(
        service.buildPremises(
          content: content,
          sourceAbsolutePath: 'D:/books/harbor_story.txt',
          storyOutlineSummary: '任意总纲',
        ).single.sourcePath,
        'D:/books/harbor_story.txt',
      );
    });

    test('没有显式章节标题时会退回段落分块', () {
      const content = '''
第一段内容。

第二段内容。

第三段内容。

第四段内容。
''';

      final chapterOutlines = service.chapterOutlinesOf(content);

      expect(chapterOutlines, isNotEmpty);
      expect(chapterOutlines.first.title, startsWith('结构片段'));
      expect(
        chapterOutlines.first.metadata['structure_kind'],
        ReferenceSourceDocumentStructureKinds.paragraphCluster,
      );
      expect(service.storyOutlineSummaryOf(content, chapterOutlines), isNotEmpty);
    });

    test('会复用共享结构服务识别 markdown 风格标题章节', () {
      const content = '''
# 第一卷

## 第一章 夜行
主角第一次进入陌生都城。

## 第二章 入局
朝堂与江湖同时向他逼近。
''';

      final chapterOutlines = service.chapterOutlinesOf(content);

      expect(chapterOutlines, hasLength(2));
      expect(chapterOutlines.first.title, '第一章 夜行');
      expect(chapterOutlines.last.title, '第二章 入局');
    });
  });
}
