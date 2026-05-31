import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_switch_row.dart';

class PermissionsSettingsPanel extends StatefulWidget {
  const PermissionsSettingsPanel({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<PermissionsSettingsPanel> createState() =>
      _PermissionsSettingsPanelState();
}

class _PermissionsSettingsPanelState extends State<PermissionsSettingsPanel> {
  late String _mode;
  late bool _allowRead;
  late bool _allowWrite;
  late bool _allowDelete;
  late bool _allowNetwork;
  late bool _allowProcess;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PermissionsSettingsPanel oldWidget) {
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
          title: '权限模式',
          description: '这里定义宿主允许哪些高层动作进入执行链；真正执行时仍会经过项目路径和危险修改校验。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'safe', label: '安全模式'),
                  SettingsDropdownOption(value: 'custom', label: '自定义权限'),
                  SettingsDropdownOption(value: 'all', label: '开放所有权限'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _applyMode(value);
                  });
                },
              ),
              const SizedBox(height: 12),
              _permissionSwitch(
                label: '允许读取文件',
                value: _allowRead,
                onChanged: (value) => setState(() {
                  _allowRead = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许写入文件',
                value: _allowWrite,
                onChanged: (value) => setState(() {
                  _allowWrite = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许删除文件',
                value: _allowDelete,
                onChanged: (value) => setState(() {
                  _allowDelete = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许联网调用',
                value: _allowNetwork,
                onChanged: (value) => setState(() {
                  _allowNetwork = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许宿主进程调用',
                value: _allowProcess,
                onChanged: (value) => setState(() {
                  _allowProcess = value;
                  _mode = 'custom';
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存权限设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'mode': _mode,
              'allow_read': _allowRead,
              'allow_write': _allowWrite,
              'allow_delete': _allowDelete,
              'allow_network': _allowNetwork,
              'allow_process': _allowProcess,
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _mode = (widget.settings['mode'] ?? 'safe').toString();
    _allowRead = widget.settings['allow_read'] == true;
    _allowWrite = widget.settings['allow_write'] == true;
    _allowDelete = widget.settings['allow_delete'] == true;
    _allowNetwork = widget.settings['allow_network'] == true;
    _allowProcess = widget.settings['allow_process'] == true;
    if (_mode == 'safe' || _mode == 'all') {
      _applyMode(_mode);
    }
  }

  void _applyMode(String mode) {
    // 中文注释: 权限模式切换时同步改写各开关，避免下拉只改文案却不影响实际设置值。
    _mode = mode;
    switch (mode) {
      case 'all':
        _allowRead = true;
        _allowWrite = true;
        _allowDelete = true;
        _allowNetwork = true;
        _allowProcess = true;
        return;
      case 'safe':
        _allowRead = true;
        _allowWrite = true;
        _allowDelete = false;
        _allowNetwork = false;
        _allowProcess = false;
        return;
      case 'custom':
      default:
        return;
    }
  }

  Widget _permissionSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DefaultTextStyle.merge(
      style: const TextStyle(color: AppPalette.text),
      child: SettingsSwitchRow(
        label: label,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
