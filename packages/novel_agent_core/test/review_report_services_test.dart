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
        expressionConstraintProfiles: <Object?>[
          <String, Object?>{
            'id': 'de_ai',
            'display_name': '去 AI 风',
            'summary': '降低模板化表达和解释腔。',
            'kind': 'natural_expression',
          },
        ],
      );

      expect(report['id'], 'review_1');
      expect(markdown.renderMarkdown(report), contains('对白太硬'));
      expect(summary.reportSummary(report)['issue_count'], 1);
      expect(repairTask['task_type'], 'revision');
      expect(vars['review_goal'], contains('文风一致性'));
      expect(vars['authenticity_pass_level'], 'medium');
      expect(
        ValueReaders.stringValue(vars['review_focuses']),
        contains('人物声音'),
      );
    });

    test('builds review task with concrete report output paths', () {
      final reviewTask = taskFactory.reviewTaskFromSource(<String, Object?>{
        'source_path': 'chapters/ch01.md',
        'review_type': 'plot',
        'title': '剧情检查：第01章',
        'metadata': <String, Object?>{
          'expression_constraint_review': <String, Object?>{
            'authenticity_pass_level': 'medium',
            'review_focuses': <Object?>['严查视角泄漏与信息边界混用。'],
            'mini_recheck_items': <Object?>['确认修订后 POV 可知边界仍然成立。'],
          },
        },
      });

      expect(reviewTask['task_type'], 'review');
      expect(
        ValueReaders.stringList(reviewTask['output_paths']),
        containsAll(<String>[
          'reviews/plot/剧情检查：第01章.md',
          'reviews/plot/剧情检查：第01章.json',
        ]),
      );
      expect(
        ValueReaders.stringValue(reviewTask['tool_hint']),
        contains('mini recheck'),
      );
      expect(
        ValueReaders.stringList(
          ValueReaders.mapValue(reviewTask['metadata'])['review_focuses'],
        ),
        contains('严查视角泄漏与信息边界混用。'),
      );
    });
  });
}
