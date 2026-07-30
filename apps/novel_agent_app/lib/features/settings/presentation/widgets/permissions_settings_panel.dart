import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
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
  late String _confirmationMode;
  late bool _allowRead;
  late bool _allowWrite;
  late bool _allowDelete;
  late bool _allowNetwork;
  late bool _allowProcess;
  late bool _allowImportCollection;
  late bool _allowSubAgents;
  late bool _allowLongTaskControl;
  late bool _allowFormalDelivery;

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
          description: '这里定义应用允许哪些能力真正进入执行链。工具策略决定“AI 倾向怎么用工具”，这里只决定“应用是否允许做”。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'safe', label: '安全模式'),
                  SettingsDropdownOption(value: 'import_only', label: '仅导入/收集'),
                  SettingsDropdownOption(value: 'custom', label: '自定义权限'),
                  SettingsDropdownOption(value: 'open', label: '开放模式'),
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
              SettingsLabeledDropdownField<String>(
                label: '未放行能力的处理方式',
                value: _confirmationMode,
                options: const [
                  SettingsDropdownOption(
                    value: 'user_confirmation_required',
                    label: '请求用户确认',
                  ),
                  SettingsDropdownOption(value: 'never', label: '直接拒绝'),
                  SettingsDropdownOption(value: 'automatic', label: '只执行已放行能力'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _confirmationMode = value;
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
                label: '允许正式章节/正文交付',
                value: _allowFormalDelivery,
                onChanged: (value) => setState(() {
                  _allowFormalDelivery = value;
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
                label: '允许导入资料收集',
                value: _allowImportCollection,
                onChanged: (value) => setState(() {
                  _allowImportCollection = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许子智能体委派',
                value: _allowSubAgents,
                onChanged: (value) => setState(() {
                  _allowSubAgents = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许长任务调度控制',
                value: _allowLongTaskControl,
                onChanged: (value) => setState(() {
                  _allowLongTaskControl = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              _permissionSwitch(
                label: '允许调用本机程序',
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
              'permission_mode': _mode,
              'tool_permission_mode': _mode,
              'information_permission_mode': _mode,
              'confirmation_mode': _confirmationMode,
              'tool_confirmation_mode': _confirmationMode,
              'information_confirmation_mode': _confirmationMode,
              'allow_read': _allowRead,
              'allow_write': _allowWrite,
              'allow_formal_delivery': _allowFormalDelivery,
              'allow_delete': _allowDelete,
              'allow_network': _allowNetwork,
              'allow_import_collection': _allowImportCollection,
              'allow_sub_agents': _allowSubAgents,
              'allow_long_task_control': _allowLongTaskControl,
              'allow_process': _allowProcess,
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _mode =
        (widget.settings['tool_permission_mode'] ??
                widget.settings['permission_mode'] ??
                widget.settings['mode'] ??
                'safe')
            .toString();
    _confirmationMode =
        (widget.settings['tool_confirmation_mode'] ??
                widget.settings['confirmation_mode'] ??
                widget.settings['information_confirmation_mode'] ??
                'user_confirmation_required')
            .toString();
    _allowRead = widget.settings['allow_read'] == true;
    _allowWrite = widget.settings['allow_write'] == true;
    _allowFormalDelivery = widget.settings['allow_formal_delivery'] != false;
    _allowDelete = widget.settings['allow_delete'] == true;
    _allowNetwork = widget.settings['allow_network'] == true;
    _allowImportCollection =
        widget.settings['allow_import_collection'] != false;
    _allowSubAgents = widget.settings['allow_sub_agents'] != false;
    _allowLongTaskControl = widget.settings['allow_long_task_control'] != false;
    _allowProcess = widget.settings['allow_process'] == true;
    if (_mode == 'safe' || _mode == 'open' || _mode == 'import_only') {
      _applyMode(_mode);
    }
  }

  void _applyMode(String mode) {
    // 中文注释: 权限模式切换时同步改写各开关，避免下拉只改文案却不影响实际设置值。
    _mode = mode;
    switch (mode) {
      case 'open':
        _allowRead = true;
        _allowWrite = true;
        _allowFormalDelivery = true;
        _allowDelete = true;
        _allowNetwork = true;
        _allowImportCollection = true;
        _allowSubAgents = true;
        _allowLongTaskControl = true;
        _allowProcess = true;
        _confirmationMode = 'automatic';
        return;
      case 'safe':
        _allowRead = true;
        _allowWrite = true;
        _allowFormalDelivery = true;
        _allowDelete = false;
        _allowNetwork = false;
        _allowImportCollection = true;
        _allowSubAgents = true;
        _allowLongTaskControl = true;
        _allowProcess = false;
        _confirmationMode = 'user_confirmation_required';
        return;
      case 'import_only':
        _allowRead = true;
        _allowWrite = false;
        _allowFormalDelivery = false;
        _allowDelete = false;
        _allowNetwork = false;
        _allowImportCollection = true;
        _allowSubAgents = false;
        _allowLongTaskControl = false;
        _allowProcess = false;
        _confirmationMode = 'user_confirmation_required';
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
      style: TextStyle(color: context.novelThemeColors.textColor),
      child: SettingsSwitchRow(
        label: label,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
