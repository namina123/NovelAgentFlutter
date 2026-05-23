import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContextBudgetService', () {
    test('applies priority and truncation within budget', () {
      // 中文注释: 这里验证预算器会优先保留高优先级片段，并在预算不足时对后续片段进行截断。
      final service = ContextBudgetService();

      final result = service.applyBudget(
        <Object?>[
          <String, Object?>{
            'id': 'a',
            'title': 'A',
            'content': 'x' * 3000,
            'priority': 80,
            'order': 1,
          },
          <String, Object?>{
            'id': 'b',
            'title': 'B',
            'content': 'y' * 3000,
            'priority': 20,
            'order': 2,
          },
        ],
        <String, Object?>{
          'context_pack_budget_chars': 4000,
          'reserved_output_chars': 0,
        },
      );

      expect((result['sections'] as List<Object?>).length, 2);
      final second =
          ((result['sections'] as List<Object?>)[1] as Map<String, Object?>);
      expect(second['truncated'], isTrue);
    });
  });
}
