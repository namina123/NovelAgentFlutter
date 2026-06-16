import 'package:novel_agent_cli/commands/workflow/workflow_output_expression_constraint_summary_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintSummaryRenderer', () {
    final renderer = ExpressionConstraintSummaryRenderer();

    test('builds expression constraint and chapter delivery contracts', () {
      final contract = renderer.buildContract(const <String, Object?>{
        'constraints': <String, Object?>{
          'present': true,
          'expression_constraint_active': true,
          'expression_constraint_policy_mode': 'adaptive',
          'expression_constraint_applied': true,
          'expression_constraint_review_required': true,
          'expression_constraint_review_provided': false,
          'expression_constraint_evidence_missing': true,
          'expression_constraint_violation_recorded': true,
          'review_suggested': true,
          'repair_required': false,
          'summary': '表达限制当前建议加强后续章节执行。',
          'expression_constraint_gate': <String, Object?>{
            'present': true,
            'adjust_next_chapter': true,
            'risk_signals': <Object?>['总而言之'],
          },
        },
        'expression_constraint_projection': <String, Object?>{
          'present': true,
          'status': 'suggest_strengthen',
          'status_label': '建议加强',
          'summary': '表达限制当前建议加强后续章节执行。',
          'policy_mode': 'adaptive',
          'active': true,
          'applied': true,
          'suggest_strengthen': true,
          'review_required': true,
          'review_provided': false,
          'evidence_missing': true,
        },
      });

      expect(contract['present'], isTrue);
      expect(contract['status_label'], '建议加强');
      expect(contract['policy_mode'], 'adaptive');
      expect(contract['review_missing'], isTrue);
      expect(contract['suggested_adjust'], isTrue);
      expect(contract['summary'], '表达限制当前建议加强后续章节执行。');

      final deliveryContract = renderer.buildChapterDeliveryContract(
        const <String, Object?>{
          'chapter_delivery': <String, Object?>{
            'delivery_state': 'delivered',
            'chapter_path': 'chapters/第01章.md',
            'title': '第01章',
            'path_resolution': <String, Object?>{
              'requested_path': 'chapters/第01章_seed_to_full.md',
              'resolved_path': 'chapters/第01章.md',
              'path_changed': true,
              'reason': 'normalized_chapter_title',
            },
          },
        },
        execution: const <String, Object?>{},
      );

      final summaryLines = renderer.renderSummaryLines(contract);
      final deliveryLines = renderer.renderChapterDeliverySummaryLines(
        deliveryContract,
      );

      expect(summaryLines, contains('表达规则：建议加强（智能使用）'));
      expect(summaryLines, contains('表达规则复核：缺少复核证据'));
      expect(summaryLines, contains('表达规则处置：建议后续章节加强'));
      expect(summaryLines, contains('表达规则信号：已记录风险信号（总而言之）'));
      expect(deliveryLines, contains('章节交付：已交付 | chapters/第01章.md'));
      expect(
        deliveryLines,
        contains('路径诊断：请求 chapters/第01章_seed_to_full.md，已归一为 chapters/第01章.md'),
      );
      expect(deliveryLines, contains('标题口径：第01章'));
      expect(deliveryLines, contains('路径说明：normalized_chapter_title'));
    });

    test('renders disabled and repair-required states distinctly', () {
      final disabledLines = renderer.renderSummaryLines(const <String, Object?>{
        'present': true,
        'status_label': '已关闭',
        'policy_mode': 'disabled',
        'disabled': true,
        'summary': '表达限制当前已关闭。',
      });
      final repairLines = renderer.renderSummaryLines(const <String, Object?>{
        'present': true,
        'status_label': '阻塞修订',
        'policy_mode': 'force',
        'repair_required': true,
        'review_provided': true,
        'violation_recorded': true,
        'risk_signals': <Object?>['视角泄漏'],
        'summary': '表达限制当前要求先修订后再继续。',
      });

      expect(disabledLines, contains('表达规则：已关闭（关闭）'));
      expect(disabledLines, contains('表达规则处置：当前策略已关闭'));
      expect(repairLines, contains('表达规则：阻塞修订（强力约束）'));
      expect(repairLines, contains('表达规则复核：已记录复核证据'));
      expect(repairLines, contains('表达规则处置：需要修补后再继续'));
      expect(repairLines, contains('表达规则信号：已记录风险信号（视角泄漏）'));
    });
  });
}
