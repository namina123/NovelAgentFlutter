import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';

class ThemeSettingsPanel extends StatefulWidget {
  const ThemeSettingsPanel({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ThemeSettingsPanel> createState() => _ThemeSettingsPanelState();
}

class _ThemeSettingsPanelState extends State<ThemeSettingsPanel> {
  late String _mode;
  late final TextEditingController _backgroundOpacityController;
  late final TextEditingController _panelOpacityController;
  late final TextEditingController _panelColorController;
  late final TextEditingController _borderColorController;
  late final TextEditingController _accentColorController;

  @override
  void initState() {
    super.initState();
    _backgroundOpacityController = TextEditingController();
    _panelOpacityController = TextEditingController();
    _panelColorController = TextEditingController();
    _borderColorController = TextEditingController();
    _accentColorController = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ThemeSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _sync();
    }
  }

  @override
  void dispose() {
    _backgroundOpacityController.dispose();
    _panelOpacityController.dispose();
    _panelColorController.dispose();
    _borderColorController.dispose();
    _accentColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '主题与颜色',
          description: '主题保存后立即影响当前应用；自定义颜色会保存在本地设置里。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '主题模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'light', label: '浅色'),
                  SettingsDropdownOption(value: 'dark', label: '夜间'),
                  SettingsDropdownOption(value: 'custom', label: '自定义'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _mode = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '背景透明度',
                controller: _backgroundOpacityController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '面板透明度',
                controller: _panelOpacityController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '面板颜色',
                controller: _panelColorController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '边框颜色',
                controller: _borderColorController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '强调颜色',
                controller: _accentColorController,
              ),
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
              'mode': _mode,
              'background_opacity': _backgroundOpacityController.text.trim(),
              'panel_opacity': _panelOpacityController.text.trim(),
              'panel_color': _panelColorController.text.trim(),
              'border_color': _borderColorController.text.trim(),
              'accent_color': _accentColorController.text.trim(),
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _mode = (widget.settings['mode'] ?? 'light').toString();
    _backgroundOpacityController.text =
        (widget.settings['background_opacity'] ?? '0.18').toString();
    _panelOpacityController.text =
        (widget.settings['panel_opacity'] ?? '0.92').toString();
    _panelColorController.text =
        (widget.settings['panel_color'] ?? '#F9F6ED').toString();
    _borderColorController.text =
        (widget.settings['border_color'] ?? '#9FC8D6').toString();
    _accentColorController.text =
        (widget.settings['accent_color'] ?? '#2D7A8C').toString();
  }
}
