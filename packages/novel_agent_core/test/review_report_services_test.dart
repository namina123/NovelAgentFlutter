import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Review report services', () {
    final normalizer = ReviewReportNormalizerService();
    final markdown = ReviewReportMarkdownRenderer();
    final summary = ReviewReportSummaryService();
    final taskFactory = ReviewTaskFactoryService();
    final promptVariables = ReviewPromptVariableService();

    test('normalizes review report and builds repair task', () {
      // 中文注释: 这里验证报告会收敛成稳定结构，并能继续转成修复任务和提示变量。
      final report = normalizer.normalizeReport(
        <String, Object?>{
          'review_type': 'style',
          'title': '文风检查',
          'scope': 'chapters/ch01.md',
          'issues': <Object?>[
            <String, Object?>{
              'title': '对白太硬',
              'severity': 'high',
              'suggestion': '放松语气',
              'source_path': 'chapters/ch01.md',
            },
          ],
          'suggestions': <String>['减少说明'],
        },
        generatedId: 'review_1',
        createdAt: '2026-05-23T10:00:00Z',
      );
      final repairTask = taskFactory.repairTaskFromReport(
        report,
        reportPath: 'reviews/style/review_1.md',
      );
      final vars = promptVariables.promptVariables(
        'style',
        '第一章',
        sourcePaths: <Object?>['chapters/ch01.md'],
      );

      expect(report['id'], 'review_1');
      expect(markdown.renderMarkdown(report), contains('对白太硬'));
      expect(summary.reportSummary(report)['issue_count'], 1);
      expect(repairTask['task_type'], 'revision');
      expect(vars['review_goal'], contains('文风一致性'));
    });
  });
}
