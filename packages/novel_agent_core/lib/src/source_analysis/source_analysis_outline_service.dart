import '../reference_substrate/reference_source_document_models.dart';
import '../reference_substrate/reference_source_document_structure_service.dart';
import 'source_analysis_chapter_summary.dart';
import 'source_analysis_outline.dart';

class SourceAnalysisOutlineService {
  const SourceAnalysisOutlineService({
    ReferenceSourceDocumentStructureService structureService =
        const ReferenceSourceDocumentStructureService(),
  }) : _structureService = structureService;

  final ReferenceSourceDocumentStructureService _structureService;

  SourceAnalysisOutline analyze(String content) {
    final chapterSummaries = chapterSummariesOf(content);
    final storyOutlineSummary = storyOutlineSummaryOf(
      content,
      chapterSummaries,
    );
    final premiseSummary = premiseSummaryOf(content, storyOutlineSummary);
    return SourceAnalysisOutline(
      chapterSummaries: chapterSummaries,
      storyOutlineSummary: storyOutlineSummary,
      premiseSummary: premiseSummary,
    );
  }

  List<SourceAnalysisChapterSummary> chapterSummariesOf(String content) {
    final structure = _structureService.analyze(content);
    if (structure.sections.isEmpty) {
      return const <SourceAnalysisChapterSummary>[];
    }
    return structure.sections
        .map(_chapterSummaryFromSection)
        .toList(growable: false);
  }

  String storyOutlineSummaryOf(
    String content,
    List<SourceAnalysisChapterSummary> chapterSummaries,
  ) {
    if (chapterSummaries.isNotEmpty) {
      final snippets = chapterSummaries
          .take(4)
          .map((item) => '${item.title}：${item.summary}')
          .where((item) => item.trim().isNotEmpty)
          .join('；');
      if (snippets.trim().isNotEmpty) {
        return _truncate(snippets, 320);
      }
    }
    final structure = _structureService.analyze(content);
    final fallback = structure.sections
        .take(4)
        .map((item) => item.content.replaceAll('\n', ' ').trim())
        .where((item) => item.isNotEmpty)
        .join(' ');
    return _truncate(fallback, 320);
  }

  String premiseSummaryOf(String content, String storyOutlineSummary) {
    final structure = _structureService.analyze(content);
    final base = structure.sections
        .take(2)
        .map((item) {
          final heading = item.heading.trim();
          final text = item.content.replaceAll('\n', ' ').trim();
          return heading.isEmpty ? text : '$heading $text';
        })
        .where((item) => item.trim().isNotEmpty)
        .join(' ');
    if (base.trim().isNotEmpty) {
      return _truncate(base, 220);
    }
    return _truncate(storyOutlineSummary, 220);
  }

  SourceAnalysisChapterSummary _chapterSummaryFromSection(
    ReferenceSourceDocumentSection section,
  ) {
    final title = section.heading.trim().isNotEmpty
        ? section.heading.trim()
        : '结构片段 ${section.sectionIndex}';
    return SourceAnalysisChapterSummary(
      sequence: section.sectionIndex,
      title: title,
      summary: _truncate(section.content.replaceAll('\n', ' ').trim(), 160),
      sectionId: section.sectionId,
      structureKind: section.structureKind,
      keywords: List<String>.unmodifiable(section.keywords),
      metadata: <String, Object?>{
        'synthetic': section.synthetic,
        if (section.parentSectionId.trim().isNotEmpty)
          'parent_section_id': section.parentSectionId,
      },
    );
  }

  String _truncate(String value, int maxLength) {
    final clean = value.trim();
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength)}...';
  }
}
