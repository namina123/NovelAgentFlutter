import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/theme_preference_resolver.dart';

void main() {
  test('theme preference resolver prefers explicit selected theme id', () {
    final resolver = ThemePreferenceResolver();

    final selectedThemeId = resolver.resolveSelectedThemeId(<String, Object?>{
      'selected_theme_id': ThemePreferenceResolver.darkThemeId,
      'mode': 'light',
    });

    expect(selectedThemeId, ThemePreferenceResolver.darkThemeId);
  });

  test('theme preference resolver falls back to legacy mode', () {
    final resolver = ThemePreferenceResolver();

    final selectedThemeId = resolver.resolveSelectedThemeId(<String, Object?>{
      'mode': 'dark',
    });

    expect(selectedThemeId, ThemePreferenceResolver.darkThemeId);
  });

  test('quick toggle switches to the opposite built-in brightness', () {
    final resolver = ThemePreferenceResolver();

    expect(
      resolver.quickToggleThemeId(ThemePreferenceResolver.lightThemeId),
      ThemePreferenceResolver.darkThemeId,
    );
    expect(
      resolver.quickToggleThemeId(ThemePreferenceResolver.darkThemeId),
      ThemePreferenceResolver.lightThemeId,
    );
  });

  test(
    'payload for selected theme keeps explicit id and legacy compatibility',
    () {
      final resolver = ThemePreferenceResolver();

      final payload = resolver.payloadForSelectedTheme(
        selectedThemeId: ThemePreferenceResolver.darkThemeId,
      );

      expect(
        payload[ThemePreferenceResolver.selectedThemeIdKey],
        ThemePreferenceResolver.darkThemeId,
      );
      expect(payload[ThemePreferenceResolver.legacyModeKey], 'dark');
    },
  );
}
