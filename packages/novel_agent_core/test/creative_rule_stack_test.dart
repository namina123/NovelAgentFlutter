import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreativeRuleStack.isEmpty', () {
    test('empty when no structured fields are set', () {
      final stack = CreativeRuleStack();
      expect(stack.isEmpty, isTrue);
    });

    test('non-empty when only expression constraint bindings are present', () {
      // 中文注释: 这是 isEmpty 曾经的回归点：旧实现只查 expressionConstraints/styles，
      // 漏掉两个 binding 列表，导致“只配了 binding 但 resolver 尚未展开成 profile”的栈被
      // 误判空，两个渲染器（brief / context section）会短路丢栈。这里锁定 6 字段全检。
      final stack = CreativeRuleStack(
        expressionConstraintBindings: <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(profileId: 'de_ai'),
        ],
      );
      expect(stack.isEmpty, isFalse);
    });

    test('non-empty when only style bindings are present', () {
      final stack = CreativeRuleStack(
        styleBindings: <ProjectStyleBinding>[
          ProjectStyleBinding(styleId: 'plain_style'),
        ],
      );
      expect(stack.isEmpty, isFalse);
    });

    test('non-empty when only expression constraint profiles are present', () {
      final stack = CreativeRuleStack(
        expressionConstraints: <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达。',
          ),
        ],
      );
      expect(stack.isEmpty, isFalse);
    });
  });
}
