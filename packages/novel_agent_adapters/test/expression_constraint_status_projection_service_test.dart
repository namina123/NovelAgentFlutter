import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintStatusProjectionService', () {
    const service = ExpressionConstraintStatusProjectionService();

    test('projects disabled constraint summary as closed status', () {
      final projection = service.fromWritingExecutionResult(<String, Object?>{
        'constraints': <String, Object?>{
          'present': true,
          'expression_constraint_active': true,
          'expression_constraint_policy_mode': 'disabled',
          'expression_constraint_disabled': true,
          'summary': '表达限制当前已关闭。',
        },
      });

      expect(projection.present, isTrue);
      expect(projection.status, 'disabled');
      expect(projection.disabled, isTrue);
      expect(projection.statusLabel, '已关闭');
    });

    test('projects adaptive escalation as suggest strengthen', () {
      final projection = service.fromWritingExecutionResult(<String, Object?>{
        'constraints': <String, Object?>{
          'present': true,
          'expression_constraint_active': true,
          'expression_constraint_policy_mode': 'adaptive',
          'expression_constraint_applied': true,
          'expression_constraint_runtime_escalated': true,
          'review_suggested': true,
          'summary': '表达限制当前建议加强后续章节执行。',
        },
      });

      expect(projection.present, isTrue);
      expect(projection.status, 'suggest_strengthen');
      expect(projection.applied, isTrue);
      expect(projection.suggestStrengthen, isTrue);
    });

    test('projects repair required as repair blocked', () {
      final projection = service.fromWritingExecutionResult(<String, Object?>{
        'constraints': <String, Object?>{
          'present': true,
          'expression_constraint_active': true,
          'expression_constraint_policy_mode': 'force',
          'expression_constraint_applied': true,
          'repair_required': true,
          'expression_constraint_gate': <String, Object?>{
            'present': true,
            'repair_required': true,
          },
          'summary': '表达限制当前要求先修订后再继续。',
        },
      });

      expect(projection.present, isTrue);
      expect(projection.status, 'repair_blocked');
      expect(projection.blocksRepair, isTrue);
      expect(projection.statusLabel, '阻塞修订');
    });
  });
}
