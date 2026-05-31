import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/selector_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selector field keeps 智能体 label on one line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: SelectorField(
              label: '智能体',
              value: '审阅智能体',
              options: const [
                SelectorOptionViewData(id: 'reviewer', label: '审阅智能体'),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelText = tester.widget<Text>(
      find.descendant(
        of: find.byType(SelectorField),
        matching: find.text('智能体'),
      ),
    );
    expect(labelText.maxLines, 1);
    expect(labelText.softWrap, isFalse);
  });

  testWidgets('selector field keeps 模型 label contract unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: SelectorField(
              label: '模型',
              value: 'gpt-4.1',
              options: const [
                SelectorOptionViewData(id: 'gpt-4.1', label: 'gpt-4.1'),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelText = tester.widget<Text>(
      find.descendant(
        of: find.byType(SelectorField),
        matching: find.text('模型'),
      ),
    );
    expect(labelText.maxLines, 1);
    expect(labelText.softWrap, isFalse);
  });
}
