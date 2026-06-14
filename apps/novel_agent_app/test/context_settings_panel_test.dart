import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/context_settings_panel.dart';

void main() {
  testWidgets(
    'context settings panel saves token-pressure fields and legacy bridge values',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ContextSettingsPanel(
              settings: const {
                'compression_threshold_percent': 60,
                'context_pack_budget_percent': 55,
                'max_context_file_chars': 2400,
                'max_context_files_per_kind': 6,
                'reserved_output_chars': 20000,
              },
              defaultProjectPath: 'D:/NovelAgent/default_project',
              allowProjectPathEdit: true,
              onSaved: (payload) {
                savedPayload = payload;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('上下文压力'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'D:/NovelAgent/updated_project');
      await tester.enterText(textFields.at(1), '120000');
      await tester.enterText(textFields.at(2), '100000');
      await tester.enterText(textFields.at(3), '75');
      await tester.enterText(textFields.at(4), '92');
      await tester.enterText(textFields.at(5), '4096');
      await tester.enterText(textFields.at(6), 'warning');
      await tester.enterText(textFields.at(7), 'structured_bullets');
      await tester.dragUntilVisible(
        find.byType(Switch),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('高级兼容桥'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('高级兼容桥'), findsOneWidget);
      await tester.tap(find.text('高级兼容桥'));
      await tester.pumpAndSettle();

      final expandedTextFields = find.byType(TextField);
      await tester.enterText(expandedTextFields.at(8), '60');
      await tester.enterText(expandedTextFields.at(9), '55');
      await tester.enterText(expandedTextFields.at(10), '2400');
      await tester.enterText(expandedTextFields.at(11), '6');
      await tester.enterText(expandedTextFields.at(12), '20000');

      await tester.dragUntilVisible(
        find.text('保存上下文设置'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存上下文设置'));
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(
        savedPayload!['default_project_path'],
        'D:/NovelAgent/updated_project',
      );
      expect(savedPayload!['model_context_window_tokens'], 120000);
      expect(savedPayload!['context_window_hint_tokens'], 100000);
      expect(savedPayload!['warning_threshold_ratio'], closeTo(0.75, 0.0001));
      expect(savedPayload!['critical_threshold_ratio'], closeTo(0.92, 0.0001));
      expect(savedPayload!['reserved_output_tokens'], 4096);
      expect(savedPayload!['auto_compact_policy'], 'warning');
      expect(savedPayload!['prefer_exact_count'], isTrue);
      expect(savedPayload!['compaction_output_policy'], 'structured_bullets');
      expect(savedPayload!['compression_threshold_percent'], 60);
      expect(savedPayload!['context_pack_budget_percent'], 55);
      expect(savedPayload!['max_context_file_chars'], 2400);
      expect(savedPayload!['max_context_files_per_kind'], 6);
      expect(savedPayload!['reserved_output_chars'], 20000);
    },
  );
}
