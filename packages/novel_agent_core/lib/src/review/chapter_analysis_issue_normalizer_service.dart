import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_analysis_issue.dart';

class ChapterAnalysisIssueNormalizerService {
  const ChapterAnalysisIssueNormalizerService();

  List<ChapterAnalysisIssue> normalizeIssues(
    Object? rawIssues, {
    String issueIdPrefix = 'issue',
  }) {
    // 中文注释: 章节分析问题对象要和 provider 原始响应脱钩，这里统一生成稳定字段，供后续建议、重写和图谱复用。
    final result = <ChapterAnalysisIssue>[];
    final rawList = ValueReaders.objectList(rawIssues);
    for (var index = 0; index < rawList.length; index += 1) {
      final rawIssue = rawList[index];
      final issue = rawIssue is Map
          ? ValueReaders.mapValue(rawIssue)
          : <String, Object?>{'title': rawIssue};
      final title = ValueReaders.stringValue(
        issue['title'],
        ValueReaders.stringValue(issue['name']),
      ).trim();
      if (title.isEmpty) {
        continue;
      }
      result.add(
        ChapterAnalysisIssue(
          id: _issueId(issue, issueIdPrefix, index),
          title: title,
          category: ValueReaders.stringValue(
            issue['category'],
            ValueReaders.stringValue(issue['domain']),
          ).trim(),
          severity: _severity(ValueReaders.stringValue(issue['severity'])),
          summary: ValueReaders.stringValue(
            issue['summary'],
            ValueReaders.stringValue(issue['impact']),
          ).trim(),
          detail: ValueReaders.stringValue(issue['detail']).trim(),
          evidence: ValueReaders.stringValue(issue['evidence']).trim(),
          suggestion: ValueReaders.stringValue(issue['suggestion']).trim(),
          sourcePath: ValueReaders.stringValue(issue['source_path']).trim(),
          startLine: ValueReaders.intValue(
            issue['start_line'],
            ValueReaders.intValue(issue['line_start']),
          ),
          endLine: ValueReaders.intValue(
            issue['end_line'],
            ValueReaders.intValue(issue['line_end']),
          ),
          relatedEntityIds: ValueReaders.stringList(
            issue['related_entity_ids'],
          ),
          relatedForeshadowIds: ValueReaders.stringList(
            issue['related_foreshadow_ids'],
          ),
          relatedTimelineIds: ValueReaders.stringList(
            issue['related_timeline_ids'],
          ),
          relatedRelationshipIds: ValueReaders.stringList(
            issue['related_relationship_ids'],
          ),
          metadata: ValueReaders.deepCopyMap(
            ValueReaders.mapValue(issue['metadata']),
          ),
        ),
      );
    }
    return result;
  }

  JsonMap toDocument(ChapterAnalysisIssue issue) {
    return <String, Object?>{
      'id': issue.id,
      'title': issue.title,
      'category': issue.category,
      'severity': issue.severity,
      'summary': issue.summary,
      'detail': issue.detail,
      'evidence': issue.evidence,
      'suggestion': issue.suggestion,
      'source_path': issue.sourcePath,
      'start_line': issue.startLine,
      'end_line': issue.endLine,
      'related_entity_ids': issue.relatedEntityIds,
      'related_foreshadow_ids': issue.relatedForeshadowIds,
      'related_timeline_ids': issue.relatedTimelineIds,
      'related_relationship_ids': issue.relatedRelationshipIds,
      'metadata': ValueReaders.deepCopyMap(issue.metadata),
    };
  }

  String _issueId(JsonMap issue, String issueIdPrefix, int index) {
    final explicitId = ValueReaders.stringValue(issue['id']).trim();
    if (explicitId.isNotEmpty) {
      return explicitId;
    }
    return '${issueIdPrefix}_${index + 1}';
  }

  String _severity(String rawSeverity) {
    final severity = rawSeverity.trim().toLowerCase();
    if (const <String>{
      'low',
      'normal',
      'medium',
      'high',
      'critical',
    }.contains(severity)) {
      return severity;
    }
    return 'normal';
  }
}
