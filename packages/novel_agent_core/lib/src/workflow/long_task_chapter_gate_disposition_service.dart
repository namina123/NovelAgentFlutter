import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/review_issue_normalizer_service.dart';

class LongTaskChapterGateDispositionService {
  const LongTaskChapterGateDispositionService({
    ReviewIssueNormalizerService? issueNormalizerService,
  }) : _issueNormalizerService =
           issueNormalizerService ?? const ReviewIssueNormalizerService();

  final ReviewIssueNormalizerService _issueNormalizerService;

  JsonMap resolve(JsonMap reviewReport, {String runtimeBaselineId = ''}) {
    // 中文注释: 章级 gate disposition 只把 review report 翻译成“放行 / 阻塞 / 派生修复 / 人工处理”。
    if (runtimeBaselineId.trim() != 'chapter_collaboration_autorun') {
      return const <String, Object?>{
        'disposition': 'auto_continue',
        'action': 'pass_gate',
        'reason': 'baseline_has_no_gate',
        'blocks_auto_advance': false,
        'manual_attention_required': false,
        'should_create_repair_task': false,
        'issue_count': 0,
        'suggestion_count': 0,
        'critical_issue_count': 0,
        'high_issue_count': 0,
      };
    }

    final issues = _issueNormalizerService.normalizeIssues(
      reviewReport['issues'],
    );
    final suggestions = ValueReaders.stringList(reviewReport['suggestions']);
    final recommendedDisposition = ValueReaders.stringValue(
      ValueReaders.mapValue(reviewReport['metadata'])['recommended_disposition'],
    ).trim();
    final criticalIssueCount = issues
        .where(
          (issue) => ValueReaders.stringValue(issue['severity']) == 'critical',
        )
        .length;
    final highIssueCount = issues.where((issue) {
      final severity = ValueReaders.stringValue(issue['severity']);
      return severity == 'high' || severity == 'critical';
    }).length;

    if (issues.isEmpty && suggestions.isEmpty) {
      if (recommendedDisposition == 'manual_attention') {
        return const <String, Object?>{
          'disposition': 'manual_attention',
          'action': 'manual_attention',
          'reason': 'review_requests_manual_attention',
          'blocks_auto_advance': true,
          'manual_attention_required': true,
          'should_create_repair_task': false,
          'issue_count': 0,
          'suggestion_count': 0,
          'critical_issue_count': 0,
          'high_issue_count': 0,
        };
      }
      if (recommendedDisposition == 'repair') {
        return const <String, Object?>{
          'disposition': 'auto_create_repair_task',
          'action': 'create_repair_task',
          'reason': 'review_requests_repair',
          'blocks_auto_advance': true,
          'manual_attention_required': false,
          'should_create_repair_task': true,
          'issue_count': 0,
          'suggestion_count': 0,
          'critical_issue_count': 0,
          'high_issue_count': 0,
        };
      }
      if (recommendedDisposition == 'checkpoint_user') {
        return const <String, Object?>{
          'disposition': 'blocked_wait_user',
          'action': 'block_gate',
          'reason': 'review_requests_user_checkpoint',
          'blocks_auto_advance': true,
          'manual_attention_required': false,
          'should_create_repair_task': false,
          'issue_count': 0,
          'suggestion_count': 0,
          'critical_issue_count': 0,
          'high_issue_count': 0,
        };
      }
      return const <String, Object?>{
        'disposition': 'auto_continue',
        'action': 'pass_gate',
        'reason': 'review_clean',
        'blocks_auto_advance': false,
        'manual_attention_required': false,
        'should_create_repair_task': false,
        'issue_count': 0,
        'suggestion_count': 0,
        'critical_issue_count': 0,
        'high_issue_count': 0,
      };
    }

    if (criticalIssueCount > 0) {
      return <String, Object?>{
        'disposition': 'manual_attention',
        'action': 'manual_attention',
        'reason': 'review_has_critical_issues',
        'blocks_auto_advance': true,
        'manual_attention_required': true,
        'should_create_repair_task': false,
        'issue_count': issues.length,
        'suggestion_count': suggestions.length,
        'critical_issue_count': criticalIssueCount,
        'high_issue_count': highIssueCount,
      };
    }

    if (issues.isNotEmpty) {
      return <String, Object?>{
        'disposition': 'auto_create_repair_task',
        'action': 'create_repair_task',
        'reason': highIssueCount > 0
            ? 'review_has_high_issues'
            : 'review_has_issues',
        'blocks_auto_advance': true,
        'manual_attention_required': false,
        'should_create_repair_task': true,
        'issue_count': issues.length,
        'suggestion_count': suggestions.length,
        'critical_issue_count': criticalIssueCount,
        'high_issue_count': highIssueCount,
      };
    }

    return <String, Object?>{
      'disposition': 'blocked_wait_user',
      'action': 'block_gate',
      'reason': 'review_has_suggestions',
      'blocks_auto_advance': true,
      'manual_attention_required': false,
      'should_create_repair_task': false,
      'issue_count': 0,
      'suggestion_count': suggestions.length,
      'critical_issue_count': 0,
      'high_issue_count': 0,
    };
  }
}
