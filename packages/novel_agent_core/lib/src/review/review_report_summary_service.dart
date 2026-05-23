import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_report_normalizer_service.dart';
import 'review_type_catalog_service.dart';

class ReviewReportSummaryService {
  ReviewReportSummaryService({
    ReviewReportNormalizerService? normalizerService,
    ReviewTypeCatalogService? typeCatalogService,
  }) : _normalizerService =
           normalizerService ?? ReviewReportNormalizerService(),
       _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService();

  final ReviewReportNormalizerService _normalizerService;
  final ReviewTypeCatalogService _typeCatalogService;

  JsonMap reportSummary(JsonMap report) {
    // 中文注释: 列表摘要只保留任务中心和报告页真正需要的轻量字段。
    final normalized = _normalizerService.normalizeReport(report);
    final issues = ValueReaders.objectList(normalized['issues']);
    return <String, Object?>{
      'id': ValueReaders.stringValue(normalized['id']),
      'title': ValueReaders.stringValue(normalized['title']),
      'review_type': ValueReaders.stringValue(normalized['review_type']),
      'review_type_label': _typeCatalogService.reviewTypeLabel(
        ValueReaders.stringValue(normalized['review_type']),
      ),
      'scope': ValueReaders.stringValue(normalized['scope']),
      'summary': ValueReaders.stringValue(normalized['summary']),
      'issue_count': issues.length,
      'source_paths': normalized['source_paths'],
      'related_paths': normalized['related_paths'],
      'json_path': ValueReaders.stringValue(normalized['json_path']),
      'markdown_path': ValueReaders.stringValue(normalized['markdown_path']),
      'created_at': ValueReaders.stringValue(normalized['created_at']),
    };
  }
}
