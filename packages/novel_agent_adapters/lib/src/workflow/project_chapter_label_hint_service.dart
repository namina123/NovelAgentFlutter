import 'project_chapter_label_parser_service.dart';

class ProjectChapterLabelHintService {
  const ProjectChapterLabelHintService({
    ProjectChapterLabelParserService? parserService,
  }) : _parserService =
           parserService ?? const ProjectChapterLabelParserService();

  final ProjectChapterLabelParserService _parserService;

  String resolve({
    String chapterLabelHint = '',
    String activeDocumentPath = '',
    List<String> pinnedRelativePaths = const <String>[],
  }) {
    final explicit = _parserService.extractLikelyTargetCanonicalLabel(
      chapterLabelHint,
    );
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final activePathMatch = _parserService.extractCanonicalLabel(
      activeDocumentPath,
    );
    if (activePathMatch.isNotEmpty) {
      return activePathMatch;
    }
    for (final path in pinnedRelativePaths) {
      final match = _parserService.extractCanonicalLabel(path);
      if (match.isNotEmpty) {
        return match;
      }
    }
    return '';
  }
}
