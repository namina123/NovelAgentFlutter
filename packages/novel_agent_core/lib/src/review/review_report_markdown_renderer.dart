import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_report_normalizer_service.dart';
import 'review_type_catalog_service.dart';

class ReviewReportMarkdownRenderer {
  ReviewReportMarkdownRenderer({
    ReviewReportNormalizerService? normalizerService,
    ReviewTypeCatalogService? typeCatalogService,
  }) : _normalizerService =
           normalizerService ?? ReviewReportNormalizerService(),
       _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService();

  final ReviewReportNormalizerService _normalizerService;
  final ReviewTypeCatalogService _typeCatalogService;

  String renderMarkdown(JsonMap report) {
    // 中文注释: Markdown 渲染保持一眼可读，方便用户直接查看报告而不必先开 JSON。
    final normalized = _normalizerService.normalizeReport(report);
    final lines = <String>[
      '# ${ValueReaders.stringValue(normalized['title'], '审稿报告')}',
      '',
      '- 类型：${_typeCatalogService.reviewTypeLabel(ValueReaders.stringValue(normalized['review_type']))}',
      '- 范围：${ValueReaders.stringValue(normalized['scope'], '当前范围')}',
      '- 来源：${_joinValues(ValueReaders.objectList(normalized['source_paths']))}',
      '- 关联：${_joinValues(ValueReaders.objectList(normalized['related_paths']))}',
      '- 时间：${ValueReaders.stringValue(normalized['created_at'])}',
    ];
    final summary = ValueReaders.stringValue(normalized['summary']).trim();
    if (summary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 总结')
        ..add(summary);
    }
    lines
      ..add('')
      ..add('## 问题');
    final issues = ValueReaders.mapList(normalized['issues']);
    if (issues.isEmpty) {
      lines.add('未记录明确问题。');
    } else {
      for (final issue in issues) {
        lines.add(
          '- [${ValueReaders.stringValue(issue['severity'], 'normal')}] '
          '${ValueReaders.stringValue(issue['title'], '问题')}',
        );
        _appendIssueLine(lines, '细节', issue['detail']);
        _appendIssueLine(lines, '影响', issue['impact']);
        _appendIssueLine(lines, '建议', issue['suggestion']);
      }
    }
    final suggestions = ValueReaders.stringList(normalized['suggestions']);
    if (suggestions.isNotEmpty) {
      lines
        ..add('')
        ..add('## 综合建议');
      for (final suggestion in suggestions) {
        lines.add('- $suggestion');
      }
    }
    return lines.join('\n');
  }

  void _appendIssueLine(List<String> lines, String label, Object? value) {
    // 中文注释: 问题子字段有值才渲染，避免 Markdown 里出现一堆空标签。
    final text = ValueReaders.stringValue(value).trim();
    if (text.isNotEmpty) {
      lines.add('  $label：$text');
    }
  }

  String _joinValues(List<Object?> values) {
    // 中文注释: 路径列表在报告头部只展示摘要串，空列表统一显示“无”。
    final parts = <String>[];
    for (final value in values) {
      final text = ValueReaders.stringValue(value).trim();
      if (text.isNotEmpty) {
        parts.add(text);
      }
    }
    if (parts.isEmpty) {
      return '无';
    }
    return parts.join('、');
  }
}
