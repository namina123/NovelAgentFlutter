import '../reference_substrate/reference_source_document_models.dart';
import 'source_analysis_style_metrics.dart';

class SourceAnalysisStyleSignalService {
  const SourceAnalysisStyleSignalService();

  SourceAnalysisStyleMetrics analyze({
    required String normalizedText,
    required List<ReferenceSourceDocumentSection> sections,
  }) {
    final paragraphCount = normalizedText
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .where((entry) => entry.trim().isNotEmpty)
        .length;
    final dialogueCount = RegExp(r'["“”]').allMatches(normalizedText).length;
    final averageSectionLength = sections.isEmpty
        ? normalizedText.length
        : (normalizedText.length / sections.length).round();
    return SourceAnalysisStyleMetrics(
      sectionCount: sections.length,
      paragraphCount: paragraphCount,
      dialogueQuoteCount: dialogueCount,
      averageSectionLengthChars: averageSectionLength,
    );
  }

  String localizedSummary(
    SourceAnalysisStyleMetrics metrics, {
    required String targetLanguage,
  }) {
    if (targetLanguage.startsWith('zh')) {
      return '该文本呈现出明显的章节推进结构，共识别 ${metrics.sectionCount} 个章节/片段，'
          '约 ${metrics.paragraphCount} 个段落，含 ${metrics.dialogueQuoteCount} 处对话引号，'
          '适合作为叙事节奏与视角组织的风格依据。';
    }
    return 'The document shows a chapter-based progression with '
        '${metrics.sectionCount} sections, about ${metrics.paragraphCount} '
        'paragraphs and ${metrics.dialogueQuoteCount} dialogue quotes.';
  }
}
