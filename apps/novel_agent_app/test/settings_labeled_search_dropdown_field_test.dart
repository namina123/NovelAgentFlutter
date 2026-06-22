import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_search_option.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/settings_labeled_search_dropdown_field.dart';

void main() {
  testWidgets('search dropdown auto opens when text is entered', (tester) async {
    final controller = TextEditingController();
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SettingsLabeledSearchDropdownField<String>(
            label: '模型',
            controller: controller,
            options: const [
              SettingsSearchOption(value: 'deepseek-v4-flash', label: 'DeepSeek V4 Flash'),
              SettingsSearchOption(value: 'gpt-4.1', label: 'GPT-4.1'),
            ],
            onSelected: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'gpt');
    await tester.pumpAndSettle();

    expect(find.text('GPT-4.1'), findsOneWidget);

    await tester.tap(find.text('GPT-4.1'));
    await tester.pumpAndSettle();

    expect(selectedValue, 'gpt-4.1');
    expect(controller.text, 'GPT-4.1');
  });
}
