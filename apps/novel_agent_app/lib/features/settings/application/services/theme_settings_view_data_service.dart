import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/theme_preference_resolver.dart';
import '../../../../app/theme/theme_registry.dart';
import '../../presentation/models/theme_settings_view_data.dart';

class ThemeSettingsViewDataService {
  ThemeSettingsViewDataService({
    ThemeRegistry? registry,
    ThemePreferenceResolver? preferenceResolver,
  }) : _registry = registry ?? ThemeRegistry.builtIn(),
       _preferenceResolver =
           preferenceResolver ??
           ThemePreferenceResolver(
             registry: registry ?? ThemeRegistry.builtIn(),
           );

  final ThemeRegistry _registry;
  final ThemePreferenceResolver _preferenceResolver;

  ThemeSettingsViewData build({
    required Map<String, Object?> themeSettings,
    String? activeThemeId,
  }) {
    final selectedThemeId = activeThemeId?.trim().isNotEmpty == true
        ? activeThemeId!.trim()
        : _preferenceResolver.resolveSelectedThemeId(themeSettings);
    final builtInThemes = _registry
        .builtInDescriptors()
        .map((descriptor) {
          final tokenSet = AppTheme.tokenSetFor(descriptor.id);
          final colors = tokenSet.colors;
          return ThemeOptionViewData(
            id: descriptor.id,
            label: descriptor.label,
            description: descriptor.brightness == Brightness.dark
                ? '更接近现代 IDE 工作台，适合连续创作、代码和文档并行处理。'
                : '更适合白天整理资料、批量阅读和长时间扫描内容。',
            badgeLabel: descriptor.brightness == Brightness.dark ? 'IDE' : '日间',
            previewSwatches: <Color>[
              colors.canvasBackground,
              colors.panelBackground,
              colors.accentColor,
            ],
            isSelected: descriptor.id == selectedThemeId,
          );
        })
        .toList(growable: false);
      return ThemeSettingsViewData(
      selectedThemeId: selectedThemeId,
      currentThemeLabel: _preferenceResolver.labelOf(selectedThemeId),
      builtInThemes: builtInThemes,
      builtInSectionDescription: '当前内置主题会直接从 ThemeRegistry 读取，切换后立即作用到工作台核心表面。',
      futureSectionDescription: '更多官方内置主题会继续通过 ThemeRegistry 接入。',
      customSectionDescription: '自定义主题开放后，会接入同一套主题描述与保存合同。',
    );
  }
}
