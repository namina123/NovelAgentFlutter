import 'book_deconstruction_chapter_outline.dart';
import '../inspiration/inspiration_premise.dart';

class BookDeconstructionSourceTextOutlineService {
  const BookDeconstructionSourceTextOutlineService();

  List<BookDeconstructionChapterOutline> chapterOutlinesOf(String content) {
    // 中文注释: 章节切分只处理原始文本结构，不承担任何写盘或 UI 语义。
    final paragraphs = _paragraphsOf(content);
    final lines = content.split('\n');
    final headingMatches = <_HeadingMatch>[];
    final headingPattern = RegExp(
      r'^(?:#{1,6}\s*)?(第[^\n]{0,18}[章节回卷]|chapter\s*\d+|CHAPTER\s*\d+)\s*[:：\-]?\s*(.*)$',
      caseSensitive: false,
    );
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        continue;
      }
      final match = headingPattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      final chapterLabel = match.group(1)?.trim() ?? '章节';
      final suffix = match.group(2)?.trim() ?? '';
      headingMatches.add(
        _HeadingMatch(
          lineIndex: index,
          title: suffix.isEmpty ? chapterLabel : '$chapterLabel $suffix',
        ),
      );
    }
    if (headingMatches.isEmpty) {
      return _fallbackChapterOutlines(paragraphs);
    }
    final outlines = <BookDeconstructionChapterOutline>[];
    for (var index = 0; index < headingMatches.length; index += 1) {
      final current = headingMatches[index];
      final nextLineIndex = index + 1 < headingMatches.length
          ? headingMatches[index + 1].lineIndex
          : lines.length;
      final buffer = <String>[];
      for (
        var lineIndex = current.lineIndex + 1;
        lineIndex < nextLineIndex;
        lineIndex += 1
      ) {
        final line = lines[lineIndex].trim();
        if (line.isNotEmpty) {
          buffer.add(line);
        }
      }
      outlines.add(
        BookDeconstructionChapterOutline(
          id: 'chapter_${index + 1}',
          title: current.title,
          sequence: index + 1,
          summary: _truncate(buffer.join(' '), 160),
        ),
      );
    }
    return outlines;
  }

  String storyOutlineSummaryOf(
    String content,
    List<BookDeconstructionChapterOutline> chapterOutlines,
  ) {
    // 中文注释: 总纲摘要优先从章节骨架收束，若没有骨架再退回到段落摘要。
    if (chapterOutlines.isNotEmpty) {
      final snippets = chapterOutlines
          .take(4)
          .map((item) => '${item.title}：${item.summary}')
          .where((item) => item.trim().isNotEmpty)
          .join('；');
      if (snippets.trim().isNotEmpty) {
        return _truncate(snippets, 320);
      }
    }
    final paragraphs = _paragraphsOf(content);
    return _truncate(paragraphs.take(4).join(' '), 320);
  }

  String premiseSummaryOf(String content, String storyOutlineSummary) {
    // 中文注释: 前提摘要只做最短可用收束，优先使用前两段原文作为基础语义。
    final paragraphs = _paragraphsOf(content);
    final base = paragraphs.take(2).join(' ');
    if (base.trim().isNotEmpty) {
      return _truncate(base, 220);
    }
    return _truncate(storyOutlineSummary, 220);
  }

  List<InspirationPremise> buildPremises({
    required String content,
    required String sourceAbsolutePath,
    required String storyOutlineSummary,
  }) {
    // 中文注释: 前提构造只生成最小可复用的结构化条目，供后续 application plan 和 narrative bridge 消费。
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      return const <InspirationPremise>[];
    }
    return <InspirationPremise>[
      InspirationPremise(
        id: 'premise_main',
        displayName: '核心前提',
        summary: premiseSummaryOf(cleanContent, storyOutlineSummary),
        sourcePath: sourceAbsolutePath.trim(),
      ),
    ];
  }

  List<String> _paragraphsOf(String content) {
    return content
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.replaceAll('\n', ' ').trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<BookDeconstructionChapterOutline> _fallbackChapterOutlines(
    List<String> paragraphs,
  ) {
    if (paragraphs.isEmpty) {
      return const <BookDeconstructionChapterOutline>[];
    }
    final chunkCount = paragraphs.length >= 6 ? 3 : 2;
    final result = <BookDeconstructionChapterOutline>[];
    final chunkSize = (paragraphs.length / chunkCount).ceil();
    for (var index = 0; index < chunkCount; index += 1) {
      final start = index * chunkSize;
      if (start >= paragraphs.length) {
        break;
      }
      final end = (start + chunkSize) > paragraphs.length
          ? paragraphs.length
          : start + chunkSize;
      final summary = _truncate(paragraphs.sublist(start, end).join(' '), 160);
      result.add(
        BookDeconstructionChapterOutline(
          id: 'chapter_${index + 1}',
          title: '结构片段 ${index + 1}',
          sequence: index + 1,
          summary: summary,
        ),
      );
    }
    return result;
  }

  String _truncate(String value, int maxLength) {
    final clean = value.trim();
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength)}...';
  }
}

class _HeadingMatch {
  const _HeadingMatch({required this.lineIndex, required this.title});

  final int lineIndex;
  final String title;
}
