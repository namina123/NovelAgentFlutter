import '../common/json_types.dart';
import '../common/value_readers.dart';

class ReviewIssueNormalizerService {
  const ReviewIssueNormalizerService();

  List<JsonMap> normalizeIssues(Object? rawIssues) {
    // 中文注释: 审稿问题既可能来自结构化对象，也可能只是字符串，这里统一收敛为标准问题项。
    final result = <JsonMap>[];
    for (final rawIssue in ValueReaders.objectList(rawIssues)) {
      final issue = rawIssue is Map
          ? ValueReaders.mapValue(rawIssue)
          : <String, Object?>{'title': rawIssue};
      final title = ValueReaders.stringValue(
        issue['title'],
        ValueReaders.stringValue(issue['name'], '问题'),
      ).trim();
      if (title.isEmpty) {
        continue;
      }
      var severity = ValueReaders.stringValue(
        issue['severity'],
        'normal',
      ).trim().toLowerCase();
      if (!const <String>{
        'low',
        'normal',
        'medium',
        'high',
        'critical',
      }.contains(severity)) {
        severity = 'normal';
      }
      result.add(<String, Object?>{
        'title': title,
        'category': ValueReaders.stringValue(issue['category']),
        'severity': severity,
        'detail': ValueReaders.stringValue(issue['detail']),
        'impact': ValueReaders.stringValue(issue['impact']),
        'suggestion': ValueReaders.stringValue(issue['suggestion']),
        'source_path': ValueReaders.stringValue(issue['source_path']),
        'start_line': ValueReaders.intValue(issue['start_line']),
        'end_line': ValueReaders.intValue(issue['end_line']),
        'related_entity_ids': ValueReaders.stringList(
          issue['related_entity_ids'],
        ),
        'related_foreshadow_ids': ValueReaders.stringList(
          issue['related_foreshadow_ids'],
        ),
        'related_timeline_ids': ValueReaders.stringList(
          issue['related_timeline_ids'],
        ),
        'related_relationship_ids': ValueReaders.stringList(
          issue['related_relationship_ids'],
        ),
      });
    }
    return result;
  }
}
