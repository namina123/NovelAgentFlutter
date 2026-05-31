import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/models/theme_settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/theme_settings_panel.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/theme_option_tile.dart';

void main() {
  testWidgets('theme settings panel saves selected theme id', (tester) async {
    Map<String, Object?>? savedPayload;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ThemeSettingsPanel(
            viewData: const ThemeSettingsViewData(
              selectedThemeId: 'builtin.light',
              currentThemeLabel: '明亮',
              builtInThemes: <ThemeOptionViewData>[
                ThemeOptionViewData(
                  id: 'builtin.light',
                  label: '明亮',
                  description: 'light',
                  badgeLabel: '明亮',
                  previewSwatches: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFF7F2E7),
                    Color(0xFF2D7A8C),
                  ],
                  isSelected: true,
                ),
                ThemeOptionViewData(
                  id: 'builtin.dark',
                  label: '偏暗',
                  description: 'dark',
                  badgeLabel: '偏暗',
                  previewSwatches: <Color>[
                    Color(0xFF141A1F),
                    Color(0xFF1E252B),
                    Color(0xFF78B6C7),
                  ],
                  isSelected: false,
                ),
              ],
              builtInSectionDescription: 'builtin',
              futureSectionDescription: 'future',
              customSectionDescription: 'custom',
            ),
            onSaved: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ThemeOptionTile).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('保存主题设置'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('保存主题设置'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['selected_theme_id'], 'builtin.dark');
  });
}
