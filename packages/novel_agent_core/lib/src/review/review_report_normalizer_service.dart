import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_issue_normalizer_service.dart';
import 'review_type_catalog_service.dart';

class ReviewReportNormalizerService {
  ReviewReportNormalizerService({
    ReviewTypeCatalogService? typeCatalogService,
    ReviewIssueNormalizerService? issueNormalizerService,
  }) : _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService(),
       _issueNormalizerService =
           issueNormalizerService ?? ReviewIssueNormalizerService();

  final ReviewTypeCatalogService _typeCatalogService;
  final ReviewIssueNormalizerService _issueNormalizerService;

  JsonMap normalizeReport(
    JsonMap report, {
    String generatedId = '',
    String createdAt = '',
  }) {
    // 中文注释: 报告规范化把模型或人工输入收敛成稳定结构，供列表、详情、修复任务统一复用。
    final reviewType = _typeCatalogService.normalizeReviewType(
      ValueReaders.stringValue(report['review_type']),
    );
    var reportId = ValueReaders.stringValue(report['id'], generatedId).trim();
    if (reportId.isEmpty) {
      reportId = 'review_pending';
    }
    final normalized = <String, Object?>{
      'schema_version': 1,
      'id': reportId,
      'review_type': reviewType,
      'title': ValueReaders.stringValue(
        report['title'],
        _typeCatalogService.reviewTypeLabel(reviewType),
      ),
      'scope': ValueReaders.stringValue(report['scope'], '当前范围'),
      'summary': ValueReaders.stringValue(report['summary']),
      'issues': _issueNormalizerService.normalizeIssues(report['issues']),
      'suggestions': ValueReaders.stringList(report['suggestions']),
      'source_paths': ValueReaders.stringList(report['source_paths']),
      'related_paths': ValueReaders.stringList(report['related_paths']),
      'metadata': ValueReaders.mapValue(report['metadata']),
      'created_at': ValueReaders.stringValue(report['created_at'], createdAt),
    };
    if (report.containsKey('json_path')) {
      normalized['json_path'] = report['json_path'];
    }
    if (report.containsKey('markdown_path')) {
      normalized['markdown_path'] = report['markdown_path'];
    }
    return normalized;
  }
}
