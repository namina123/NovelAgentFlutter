import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/context_settings_panel.dart';

void main() {
  testWidgets(
    'context settings panel saves token-pressure fields and historical values',
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
              draftFallbackProtectionEnabled: true,
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
      expect(find.text('预留输出 token'), findsNothing);
      expect(find.text('优先 exact count'), findsNothing);
      expect(find.text('压缩输出策略'), findsNothing);
      expect(find.text('disabled / warning / warning_and_critical'), findsNothing);
      expect(
        find.text('structured_bullets / balanced_bullets / detailed_bullets'),
        findsNothing,
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'D:/NovelAgent/updated_project');
      await tester.enterText(textFields.at(1), '120000');
      await tester.enterText(textFields.at(2), '100000');
      await tester.enterText(textFields.at(3), '75');
      await tester.enterText(textFields.at(4), '92');
      await tester.enterText(textFields.at(5), '4096');
      await _selectDropdownOption(
        tester,
        '在接近上限或到达临界时压缩',
        '仅在接近上限时压缩',
      );
      await _selectDropdownOption(
        tester,
        '结构化条目',
        '详细展开',
      );
      await tester.dragUntilVisible(
        find.text('普通会话草稿保护'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('优先精确计数'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('历史上下文参数'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('历史上下文参数'), findsOneWidget);
      await tester.tap(find.text('历史上下文参数'));
      await tester.pumpAndSettle();

      final expandedTextFields = find.byType(TextField);
      await tester.enterText(expandedTextFields.at(6), '60');
      await tester.enterText(expandedTextFields.at(7), '55');
      await tester.enterText(expandedTextFields.at(8), '2400');
      await tester.enterText(expandedTextFields.at(9), '6');
      await tester.enterText(expandedTextFields.at(10), '20000');

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
      expect(savedPayload!['prefer_exact_count'], isTrue);
      expect(savedPayload!['auto_compact_policy'], 'warning');
      expect(savedPayload!['draft_fallback_protection'], isFalse);
      expect(savedPayload!['compaction_output_policy'], 'detailed_bullets');
      expect(savedPayload!['compression_threshold_percent'], 60);
      expect(savedPayload!['context_pack_budget_percent'], 55);
      expect(savedPayload!['max_context_file_chars'], 2400);
      expect(savedPayload!['max_context_files_per_kind'], 6);
      expect(savedPayload!['reserved_output_chars'], 20000);
    },
  );
}

Future<void> _selectDropdownOption(
  WidgetTester tester,
  String currentLabel,
  String nextLabel,
) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    find.text(currentLabel),
    200,
    scrollable: scrollable,
  );
  await tester.ensureVisible(find.text(currentLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(currentLabel).last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(nextLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nextLabel).last);
  await tester.pumpAndSettle();
}
