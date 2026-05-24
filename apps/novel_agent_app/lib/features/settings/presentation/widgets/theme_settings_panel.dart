import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';

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

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '主题模式',
          description: '主题保存后会立即作用到工作台、按钮、资源树和编辑区。当前只开放稳定的主题模式切换。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '主题模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'light', label: '浅色'),
                  SettingsDropdownOption(value: 'dark', label: '夜间'),
                  SettingsDropdownOption(value: 'system', label: '跟随系统'),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存主题设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{'mode': _mode});
          },
        ),
      ],
    );
  }

  void _sync() {
    _mode = (widget.settings['mode'] ?? 'light').toString();
  }
}
