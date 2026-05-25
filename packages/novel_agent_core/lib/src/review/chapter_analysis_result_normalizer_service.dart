import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_analysis_issue_normalizer_service.dart';
import 'chapter_analysis_result.dart';
import 'chapter_analysis_suggestion_normalizer_service.dart';
import 'review_type_catalog_service.dart';

class ChapterAnalysisResultNormalizerService {
  ChapterAnalysisResultNormalizerService({
    ReviewTypeCatalogService? reviewTypeCatalogService,
    ChapterAnalysisIssueNormalizerService? issueNormalizerService,
    ChapterAnalysisSuggestionNormalizerService? suggestionNormalizerService,
  }) : _reviewTypeCatalogService =
           reviewTypeCatalogService ?? ReviewTypeCatalogService(),
       _issueNormalizerService =
           issueNormalizerService ??
           const ChapterAnalysisIssueNormalizerService(),
       _suggestionNormalizerService =
           suggestionNormalizerService ??
           const ChapterAnalysisSuggestionNormalizerService();

  final ReviewTypeCatalogService _reviewTypeCatalogService;
  final ChapterAnalysisIssueNormalizerService _issueNormalizerService;
  final ChapterAnalysisSuggestionNormalizerService _suggestionNormalizerService;

  ChapterAnalysisResult normalizeResult(
    JsonMap raw, {
    String generatedId = '',
    String createdAt = '',
  }) {
    // 中文注释: 章节分析结果是给上层消费的稳定领域对象，不允许把 provider 原始字段结构直接泄漏出去。
    final resultId = _resultId(raw, generatedId);
    final chapterPath = ValueReaders.stringValue(
      raw['chapter_path'],
      ValueReaders.stringValue(raw['scope']),
    ).trim();
    final sourcePaths = _mergedPaths(
      chapterPath,
      ValueReaders.stringList(raw['source_paths']),
    );
    final issues = _issueNormalizerService.normalizeIssues(
      raw['issues'],
      issueIdPrefix: '${resultId}_issue',
    );
    final suggestions = _suggestionNormalizerService.normalizeSuggestions(
      raw['suggestions'],
      suggestionIdPrefix: '${resultId}_suggestion',
      fallbackSourcePaths: sourcePaths,
      fallbackOutputPaths: sourcePaths,
    );
    final analysisType = _reviewTypeCatalogService.normalizeReviewType(
      ValueReaders.stringValue(
        raw['analysis_type'],
        ValueReaders.stringValue(raw['review_type']),
      ),
    );
    return ChapterAnalysisResult(
      id: resultId,
      analysisType: analysisType,
      title: ValueReaders.stringValue(
        raw['title'],
        _reviewTypeCatalogService.reviewTypeLabel(analysisType),
      ).trim(),
      chapterPath: chapterPath,
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      overallAssessment: ValueReaders.stringValue(
        raw['overall_assessment'],
      ).trim(),
      issues: issues,
      suggestions: suggestions,
      sourcePaths: sourcePaths,
      relatedPaths: ValueReaders.stringList(raw['related_paths']),
      createdAt: ValueReaders.stringValue(raw['created_at'], createdAt).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(ChapterAnalysisResult result) {
    return <String, Object?>{
      'schema_version': 1,
      'id': result.id,
      'analysis_type': result.analysisType,
      'title': result.title,
      'chapter_path': result.chapterPath,
      'summary': result.summary,
      'overall_assessment': result.overallAssessment,
      'issues': result.issues
          .map(_issueNormalizerService.toDocument)
          .toList(growable: false),
      'suggestions': result.suggestions
          .map(_suggestionNormalizerService.toDocument)
          .toList(growable: false),
      'source_paths': result.sourcePaths,
      'related_paths': result.relatedPaths,
      'created_at': result.createdAt,
      'metadata': ValueReaders.deepCopyMap(result.metadata),
    };
  }

  String _resultId(JsonMap raw, String generatedId) {
    final explicitId = ValueReaders.stringValue(raw['id']).trim();
    if (explicitId.isNotEmpty) {
      return explicitId;
    }
    if (generatedId.trim().isNotEmpty) {
      return generatedId.trim();
    }
    return 'analysis_pending';
  }

  List<String> _mergedPaths(String chapterPath, List<String> sourcePaths) {
    final result = <String>[];
    if (chapterPath.isNotEmpty) {
      result.add(chapterPath);
    }
    for (final sourcePath in sourcePaths) {
      final clean = sourcePath.trim().replaceAll('\\', '/');
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }
}
