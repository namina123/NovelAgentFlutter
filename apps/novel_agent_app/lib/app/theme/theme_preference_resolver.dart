import 'package:flutter/material.dart';

import 'theme_registry.dart';

class ThemePreferenceResolver {
  ThemePreferenceResolver({ThemeRegistry? registry})
    : _registry = registry ?? ThemeRegistry.builtIn();

  static const String selectedThemeIdKey = 'selected_theme_id';
  static const String legacyModeKey = 'mode';
  static const String lightThemeId = 'builtin.light';
  static const String darkThemeId = 'builtin.dark';

  final ThemeRegistry _registry;

  String resolveSelectedThemeId(Map<String, Object?> themeSettings) {
    // 中文注释: 主题偏好优先认正式的 selected_theme_id，兼容旧 mode 时再按亮暗兜底映射。
    final rawSelectedThemeId = _stringValue(themeSettings[selectedThemeIdKey]);
    if (rawSelectedThemeId.isNotEmpty &&
        _registry.contains(rawSelectedThemeId)) {
      return rawSelectedThemeId;
    }
    return _legacyModeToThemeId(_stringValue(themeSettings[legacyModeKey]));
  }

  Map<String, Object?> payloadForSelectedTheme({
    required String selectedThemeId,
    Map<String, Object?>? base,
  }) {
    final resolvedThemeId = _registry.contains(selectedThemeId)
        ? selectedThemeId
        : lightThemeId;
    return <String, Object?>{
      ...?base,
      selectedThemeIdKey: resolvedThemeId,
      legacyModeKey: _legacyModeOf(resolvedThemeId),
    };
  }

  String quickToggleThemeId(String currentThemeId) {
    final descriptor = _registry
        .requireColorTokenSet(
          _registry.contains(currentThemeId) ? currentThemeId : lightThemeId,
        )
        .descriptor;
    for (final candidate in _registry.builtInDescriptors()) {
      if (candidate.id == descriptor.id) {
        continue;
      }
      if (candidate.brightness != descriptor.brightness) {
        return candidate.id;
      }
    }
    return descriptor.brightness == Brightness.dark
        ? lightThemeId
        : darkThemeId;
  }

  String labelOf(String selectedThemeId) {
    return _registry
        .requireColorTokenSet(
          _registry.contains(selectedThemeId) ? selectedThemeId : lightThemeId,
        )
        .descriptor
        .label;
  }

  String _legacyModeToThemeId(String mode) {
    switch (mode.trim().toLowerCase()) {
      case 'dark':
      case 'night':
        return darkThemeId;
      case 'system':
      case 'custom':
      case 'light':
      case 'day':
      default:
        return lightThemeId;
    }
  }

  String _legacyModeOf(String selectedThemeId) {
    final descriptor = _registry.requireColorTokenSet(selectedThemeId).descriptor;
    return descriptor.brightness == Brightness.dark ? 'dark' : 'light';
  }

  String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}
