import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/theme_preference_resolver.dart';
import 'package:novel_agent_app/features/settings/application/services/theme_settings_view_data_service.dart';

void main() {
  test(
    'theme settings view data service exposes built-in themes and selection',
    () {
      final service = ThemeSettingsViewDataService();

      final viewData = service.build(
        themeSettings: <String, Object?>{
          'selected_theme_id': ThemePreferenceResolver.darkThemeId,
        },
      );

      expect(viewData.selectedThemeId, ThemePreferenceResolver.darkThemeId);
      expect(viewData.currentThemeLabel, '偏暗');
      expect(viewData.builtInThemes, hasLength(2));
      expect(
        viewData.builtInThemes.where((option) => option.isSelected),
        hasLength(1),
      );
      expect(
        viewData.builtInThemes.singleWhere((option) => option.isSelected).id,
        ThemePreferenceResolver.darkThemeId,
      );
    },
  );
}
