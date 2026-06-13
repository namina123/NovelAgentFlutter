import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'chapter_narrative_submission.dart';

class ChapterNarrativeSubmissionContinuityEnricherService {
  const ChapterNarrativeSubmissionContinuityEnricherService({
    this.chapterEndExcerptChars = 320,
    this.inlineExcerptChars = 180,
  });

  final int chapterEndExcerptChars;
  final int inlineExcerptChars;

  ChapterNarrativeSubmission enrich(
    ChapterNarrativeSubmission submission, {
    required String chapterPath,
    required String title,
    required String chapterContent,
  }) {
    final finalState = ValueReaders.deepCopyMap(submission.finalStateSummary);
    final chapterEndExcerpt = _chapterEndExcerpt(chapterContent);
    final inlineExcerpt = _inlineExcerpt(chapterEndExcerpt);

    if (chapterEndExcerpt.isNotEmpty &&
        ValueReaders.stringValue(
          finalState['chapter_end_excerpt'],
        ).trim().isEmpty) {
      finalState['chapter_end_excerpt'] = chapterEndExcerpt;
    }
    if (ValueReaders.stringValue(
      finalState['next_chapter_handoff'],
    ).trim().isEmpty) {
      finalState['next_chapter_handoff'] = _fallbackNextChapterHandoff(
        inlineExcerpt,
      );
    }

    final cleanTitle = title.trim().isNotEmpty
        ? title.trim()
        : submission.title.trim();
    final normalizedSummary = submission.summary.trim().isNotEmpty
        ? submission.summary.trim()
        : _fallbackSummary(
            label: cleanTitle.isNotEmpty
                ? cleanTitle
                : _fallbackLabel(chapterPath),
            inlineExcerpt: inlineExcerpt,
          );

    if (normalizedSummary == submission.summary &&
        _mapsEqual(finalState, submission.finalStateSummary)) {
      return submission;
    }

    return submission.copyWith(
      summary: normalizedSummary,
      finalStateSummary: finalState,
    );
  }

  String _fallbackSummary({
    required String label,
    required String inlineExcerpt,
  }) {
    if (inlineExcerpt.isNotEmpty) {
      return '$label 章末落点：$inlineExcerpt';
    }
    return '$label 已正式交付；下一章直接承接本章章末落点。';
  }

  String _fallbackNextChapterHandoff(String inlineExcerpt) {
    if (inlineExcerpt.isEmpty) {
      return '直接从本章章末已落定状态继续，不要回退重演上一章末尾已经完成的动作、对话或到达。';
    }
    return '直接从本章章末已落定状态继续；优先承接以下章末摘录，不要回退重演上一章末尾已经完成的动作、对话或到达：$inlineExcerpt';
  }

  String _fallbackLabel(String chapterPath) {
    final leaf = chapterPath.split('/').last.trim();
    if (leaf.isEmpty) {
      return '本章';
    }
    final dot = leaf.lastIndexOf('.');
    if (dot <= 0) {
      return leaf;
    }
    return leaf.substring(0, dot);
  }

  String _chapterEndExcerpt(String chapterContent) {
    final body = _chapterBodyWithoutHeading(chapterContent).trim();
    if (body.isEmpty) {
      return '';
    }
    if (body.length <= chapterEndExcerptChars) {
      return body;
    }
    final start = body.length - chapterEndExcerptChars;
    final paragraphBoundary = body.indexOf('\n', start);
    if (paragraphBoundary >= start && paragraphBoundary < body.length - 80) {
      return body.substring(paragraphBoundary + 1).trim();
    }
    return body.substring(start).trim();
  }

  String _chapterBodyWithoutHeading(String chapterContent) {
    final lines = chapterContent.replaceAll('\r\n', '\n').split('\n');
    var start = 0;
    while (start < lines.length && lines[start].trim().isEmpty) {
      start += 1;
    }
    if (start < lines.length && lines[start].trim().startsWith('#')) {
      start += 1;
      while (start < lines.length && lines[start].trim().isEmpty) {
        start += 1;
      }
    } else {
      start = 0;
    }
    return lines.skip(start).join('\n').trim();
  }

  String _inlineExcerpt(String excerpt) {
    final normalized = excerpt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= inlineExcerptChars) {
      return normalized;
    }
    return normalized.substring(0, inlineExcerptChars).trimRight();
  }

  bool _mapsEqual(JsonMap left, JsonMap right) {
    return ValueReaders.deepCopyMap(left).toString() ==
        ValueReaders.deepCopyMap(right).toString();
  }
}
