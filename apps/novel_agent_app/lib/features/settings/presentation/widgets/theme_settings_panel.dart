import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../models/theme_settings_view_data.dart';
import 'settings_form_section.dart';
import 'theme_option_tile.dart';

class ThemeSettingsPanel extends StatefulWidget {
  const ThemeSettingsPanel({
    super.key,
    required this.viewData,
    required this.onSaved,
  });

  final ThemeSettingsViewData viewData;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ThemeSettingsPanel> createState() => _ThemeSettingsPanelState();
}

class _ThemeSettingsPanelState extends State<ThemeSettingsPanel> {
  late String _selectedThemeId;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ThemeSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData != widget.viewData) {
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final currentTheme = _selectedOption();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '内置主题',
          description: widget.viewData.builtInSectionDescription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前应用：${widget.viewData.currentThemeLabel}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: surface.mutedForegroundColor,
                ),
              ),
              const SizedBox(height: 12),
              for (
                var index = 0;
                index < widget.viewData.builtInThemes.length;
                index += 1
              ) ...[
                ThemeOptionTile(
                  option: widget.viewData.builtInThemes[index].copyWith(
                    isSelected:
                        widget.viewData.builtInThemes[index].id ==
                        _selectedThemeId,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedThemeId =
                          widget.viewData.builtInThemes[index].id;
                    });
                  },
                ),
                if (index != widget.viewData.builtInThemes.length - 1)
                  const SizedBox(height: 10),
              ],
              if (currentTheme != null) ...[
                const SizedBox(height: 12),
                Text(
                  '将应用到资源树、会话栏、输入区、文档工作区和主要工具按钮。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存主题设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'selected_theme_id': _selectedThemeId,
            });
          },
        ),
      ],
    );
  }

  ThemeOptionViewData? _selectedOption() {
    for (final option in widget.viewData.builtInThemes) {
      if (option.id == _selectedThemeId) {
        return option;
      }
    }
    return widget.viewData.builtInThemes.isEmpty
        ? null
        : widget.viewData.builtInThemes.first;
  }

  void _sync() {
    _selectedThemeId = widget.viewData.selectedThemeId;
  }
}

extension on ThemeOptionViewData {
  ThemeOptionViewData copyWith({bool? isSelected}) {
    return ThemeOptionViewData(
      id: id,
      label: label,
      description: description,
      badgeLabel: badgeLabel,
      previewSwatches: previewSwatches,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
