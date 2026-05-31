import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_analysis_result.dart';
import 'chapter_analysis_result_normalizer_service.dart';
import 'chapter_rewrite_action_kind.dart';
import 'review_type_catalog_service.dart';

class ReviewReportChapterAnalysisProjectionService {
  ReviewReportChapterAnalysisProjectionService({
    ReviewTypeCatalogService? reviewTypeCatalogService,
    ChapterAnalysisResultNormalizerService? resultNormalizerService,
  }) : _reviewTypeCatalogService =
           reviewTypeCatalogService ?? ReviewTypeCatalogService(),
       _resultNormalizerService =
           resultNormalizerService ?? ChapterAnalysisResultNormalizerService();

  final ReviewTypeCatalogService _reviewTypeCatalogService;
  final ChapterAnalysisResultNormalizerService _resultNormalizerService;

  ChapterAnalysisResult project(
    JsonMap report, {
    String generatedId = '',
    String createdAt = '',
    String reportPath = '',
  }) {
    // 中文注释: 这里把已有审稿报告投影成章节分析对象，让 GUI/CLI 先跑通“分析 -> 建议 -> 重写”闭环，而不依赖另一套落盘格式先齐活。
    final reviewType = _reviewTypeCatalogService.normalizeReviewType(
      ValueReaders.stringValue(report['review_type']),
    );
    final reportId = ValueReaders.stringValue(
      report['id'],
      generatedId,
    ).trim();
    final analysisId = reportId.isEmpty ? 'analysis_from_review' : reportId;
    final title = ValueReaders.stringValue(
      report['title'],
      _reviewTypeCatalogService.reviewTypeLabel(reviewType),
    );
    final sourcePaths = ValueReaders.stringList(report['source_paths']);
    final chapterPath = _chapterPath(
      report,
      sourcePaths: sourcePaths,
    );
    final rawIssues = ValueReaders.mapList(report['issues']);
    final rawSuggestions = <Object?>[
      ..._suggestionsFromIssues(
        rawIssues,
        chapterPath: chapterPath,
        suggestionIdPrefix: '${analysisId}_issue_fix',
      ),
      ..._suggestionsFromReportSuggestions(
        ValueReaders.stringList(report['suggestions']),
        chapterPath: chapterPath,
        suggestionIdPrefix: '${analysisId}_suggestion',
      ),
    ];
    final projected = <String, Object?>{
      'id': analysisId,
      'analysis_type': reviewType,
      'title': title,
      'scope': chapterPath,
      'summary': ValueReaders.stringValue(report['summary']),
      'overall_assessment': _overallAssessment(report),
      'issues': rawIssues,
      'suggestions': rawSuggestions,
      'source_paths': sourcePaths,
      'related_paths': ValueReaders.stringList(report['related_paths']),
      'created_at': ValueReaders.stringValue(report['created_at'], createdAt),
      'metadata': <String, Object?>{
        'origin': 'review_report_projection',
        'review_report_path': reportPath.trim(),
        ...ValueReaders.deepCopyMap(ValueReaders.mapValue(report['metadata'])),
      },
    };
    return _resultNormalizerService.normalizeResult(
      projected,
      generatedId: analysisId,
      createdAt: ValueReaders.stringValue(projected['created_at']),
    );
  }

  String _chapterPath(
    JsonMap report, {
    required List<String> sourcePaths,
  }) {
    final scope = ValueReaders.stringValue(report['scope']).trim();
    if (scope.contains('/') || scope.endsWith('.md') || scope.endsWith('.txt')) {
      return scope;
    }
    if (sourcePaths.isNotEmpty) {
      return sourcePaths.first;
    }
    return scope;
  }

  String _overallAssessment(JsonMap report) {
    final metadata = ValueReaders.mapValue(report['metadata']);
    final explicit = ValueReaders.stringValue(
      metadata['overall_assessment'],
      ValueReaders.stringValue(report['overall_assessment']),
    ).trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return ValueReaders.stringValue(report['summary']).trim();
  }

  List<JsonMap> _suggestionsFromIssues(
    List<JsonMap> issues, {
    required String chapterPath,
    required String suggestionIdPrefix,
  }) {
    final result = <JsonMap>[];
    for (var index = 0; index < issues.length; index += 1) {
      final issue = issues[index];
      final suggestion = ValueReaders.stringValue(issue['suggestion']).trim();
      if (suggestion.isEmpty) {
        continue;
      }
      final sourcePath = ValueReaders.stringValue(
        issue['source_path'],
        chapterPath,
      ).trim();
      final startLine = ValueReaders.intValue(issue['start_line']);
      final endLine = ValueReaders.intValue(issue['end_line']);
      final hasLineRange = startLine > 0 && endLine >= startLine;
      result.add(<String, Object?>{
        'id': '${suggestionIdPrefix}_${index + 1}',
        'title': ValueReaders.stringValue(issue['title'], '问题修订'),
        'summary': suggestion,
        'action_kind': hasLineRange && sourcePath.isNotEmpty
            ? ChapterRewriteActionKind.rewritePartial
            : ChapterRewriteActionKind.rewriteFull,
        'issue_ids': <String>[
          ValueReaders.stringValue(issue['id'], 'issue_${index + 1}'),
        ],
        'source_paths': sourcePath.isEmpty ? const <String>[] : <String>[sourcePath],
        'output_paths': sourcePath.isEmpty ? const <String>[] : <String>[sourcePath],
        'target_segments': hasLineRange && sourcePath.isNotEmpty
            ? <Object?>[
                <String, Object?>{
                  'id': '${suggestionIdPrefix}_${index + 1}_segment',
                  'source_path': sourcePath,
                  'label': ValueReaders.stringValue(issue['title'], '命中片段'),
                  'start_line': startLine,
                  'end_line': endLine,
                  'summary': ValueReaders.stringValue(
                    issue['detail'],
                    ValueReaders.stringValue(issue['impact']),
                  ),
                },
              ]
            : const <Object?>[],
      });
    }
    return result;
  }

  List<JsonMap> _suggestionsFromReportSuggestions(
    List<String> suggestions, {
    required String chapterPath,
    required String suggestionIdPrefix,
  }) {
    final result = <JsonMap>[];
    for (var index = 0; index < suggestions.length; index += 1) {
      final summary = suggestions[index].trim();
      if (summary.isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        'id': '${suggestionIdPrefix}_${index + 1}',
        'title': '综合建议 ${index + 1}',
        'summary': summary,
        'action_kind': ChapterRewriteActionKind.suggestionsOnly,
        'source_paths': chapterPath.isEmpty ? const <String>[] : <String>[chapterPath],
      });
    }
    return result;
  }
}
