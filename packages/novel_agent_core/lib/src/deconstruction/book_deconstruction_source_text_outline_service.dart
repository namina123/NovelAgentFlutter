import 'book_deconstruction_chapter_outline.dart';
import '../inspiration/inspiration_premise.dart';
import '../source_analysis/source_analysis_chapter_summary.dart';
import '../source_analysis/source_analysis_outline_service.dart';

class BookDeconstructionSourceTextOutlineService {
  BookDeconstructionSourceTextOutlineService({
    SourceAnalysisOutlineService? outlineService,
  }) : _outlineService = outlineService ?? const SourceAnalysisOutlineService();

  final SourceAnalysisOutlineService _outlineService;

  List<BookDeconstructionChapterOutline> chapterOutlinesOf(String content) {
    return _outlineService.chapterSummariesOf(content)
        .map(_outlineFromSummary)
        .toList(growable: false);
  }

  String storyOutlineSummaryOf(
    String content,
    List<BookDeconstructionChapterOutline> chapterOutlines,
  ) {
    return _outlineService.storyOutlineSummaryOf(
      content,
      chapterOutlines
          .map(
            (item) => SourceAnalysisChapterSummary(
              sequence: item.sequence,
              title: item.title,
              summary: item.summary,
              sectionId:
                  item.metadata['source_section_id']?.toString() ?? '',
              structureKind:
                  item.metadata['structure_kind']?.toString() ?? '',
              metadata: Map<String, Object?>.from(item.metadata),
            ),
          )
          .toList(growable: false),
    );
  }

  String premiseSummaryOf(String content, String storyOutlineSummary) {
    return _outlineService.premiseSummaryOf(content, storyOutlineSummary);
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

  BookDeconstructionChapterOutline _outlineFromSummary(
    SourceAnalysisChapterSummary summary,
  ) {
    return BookDeconstructionChapterOutline(
      id: 'chapter_${summary.sequence}',
      title: summary.title,
      sequence: summary.sequence,
      summary: summary.summary,
      metadata: <String, Object?>{
        'structure_kind': summary.structureKind,
        'source_section_id': summary.sectionId,
        ...summary.metadata,
      },
    );
  }
}
