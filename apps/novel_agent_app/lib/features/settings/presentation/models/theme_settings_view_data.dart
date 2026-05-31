import 'package:flutter/material.dart';

class ThemeSettingsViewData {
  const ThemeSettingsViewData({
    required this.selectedThemeId,
    required this.currentThemeLabel,
    required this.builtInThemes,
    required this.builtInSectionDescription,
    required this.futureSectionDescription,
    required this.customSectionDescription,
  });

  final String selectedThemeId;
  final String currentThemeLabel;
  final List<ThemeOptionViewData> builtInThemes;
  final String builtInSectionDescription;
  final String futureSectionDescription;
  final String customSectionDescription;

  factory ThemeSettingsViewData.initial() {
    return const ThemeSettingsViewData(
      selectedThemeId: '',
      currentThemeLabel: '',
      builtInThemes: <ThemeOptionViewData>[],
      builtInSectionDescription: '',
      futureSectionDescription: '',
      customSectionDescription: '',
    );
  }
}

class ThemeOptionViewData {
  const ThemeOptionViewData({
    required this.id,
    required this.label,
    required this.description,
    required this.badgeLabel,
    required this.previewSwatches,
    required this.isSelected,
  });

  final String id;
  final String label;
  final String description;
  final String badgeLabel;
  final List<Color> previewSwatches;
  final bool isSelected;
}
