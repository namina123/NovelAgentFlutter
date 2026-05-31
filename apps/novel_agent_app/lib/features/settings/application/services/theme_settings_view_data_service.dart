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
                ? '更适合夜间连续创作与低照环境。'
                : '更适合白天编辑、资料整理与长时间扫描。',
            badgeLabel: descriptor.brightness == Brightness.dark ? '偏暗' : '明亮',
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
      futureSectionDescription: '后续新增的官方内置主题会继续沿同一注册表接入，不需要重写设置页结构。',
      customSectionDescription: '自定义主题入口暂时保留为壳，后续开放时会复用当前的主题描述与 token 合同。',
    );
  }
}
