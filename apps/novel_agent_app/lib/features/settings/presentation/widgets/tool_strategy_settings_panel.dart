import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_switch_row.dart';

class ToolStrategySettingsPanel extends StatefulWidget {
  const ToolStrategySettingsPanel({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ToolStrategySettingsPanel> createState() =>
      _ToolStrategySettingsPanelState();
}

class _ToolStrategySettingsPanelState extends State<ToolStrategySettingsPanel> {
  late String _mode;
  late bool _allowPlanning;
  late bool _allowSubAgents;
  late bool _allowFileMutation;
  late bool _allowRead;
  late bool _allowWrite;
  late bool _allowEdit;
  late bool _allowBackup;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ToolStrategySettingsPanel oldWidget) {
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
          title: '工具策略',
          description: '这里控制模型看见哪些工具，以及在草稿生成链中默认偏向哪种执行方式。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '策略模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'balanced', label: '平衡'),
                  SettingsDropdownOption(value: 'minimal', label: '最小工具集'),
                  SettingsDropdownOption(value: 'aggressive', label: '积极使用工具'),
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
              SettingsSwitchRow(
                label: '允许规划工具',
                value: _allowPlanning,
                onChanged: (value) => setState(() {
                  _allowPlanning = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许子智能体委派',
                value: _allowSubAgents,
                onChanged: (value) => setState(() {
                  _allowSubAgents = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许文件修改链',
                value: _allowFileMutation,
                onChanged: (value) => setState(() {
                  _allowFileMutation = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许读取',
                value: _allowRead,
                onChanged: (value) => setState(() {
                  _allowRead = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许写入',
                value: _allowWrite,
                onChanged: (value) => setState(() {
                  _allowWrite = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许编辑',
                value: _allowEdit,
                onChanged: (value) => setState(() {
                  _allowEdit = value;
                  _mode = 'custom';
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许备份',
                value: _allowBackup,
                onChanged: (value) => setState(() {
                  _allowBackup = value;
                  _mode = 'custom';
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存工具策略',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'mode': _mode,
              'allow_planning': _allowPlanning,
              'allow_sub_agents': _allowSubAgents,
              'allow_file_mutation': _allowFileMutation,
              'allow_read': _allowRead,
              'allow_write': _allowWrite,
              'allow_edit': _allowEdit,
              'allow_backup': _allowBackup,
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _mode = (widget.settings['mode'] ?? 'balanced').toString();
    _allowPlanning = widget.settings['allow_planning'] != false;
    _allowSubAgents = widget.settings['allow_sub_agents'] != false;
    _allowFileMutation = widget.settings['allow_file_mutation'] != false;
    _allowRead = widget.settings['allow_read'] != false;
    _allowWrite = widget.settings['allow_write'] != false;
    _allowEdit = widget.settings['allow_edit'] != false;
    _allowBackup = widget.settings['allow_backup'] != false;
    if (_mode != 'custom') {
      _applyMode(_mode);
    }
  }

  void _applyMode(String mode) {
    // 中文注释: 工具策略模式切换时同步映射到开关集合，避免模式下拉与具体策略值脱节。
    _mode = mode;
    switch (mode) {
      case 'minimal':
        _allowPlanning = false;
        _allowSubAgents = false;
        _allowFileMutation = false;
        _allowRead = true;
        _allowWrite = false;
        _allowEdit = false;
        _allowBackup = true;
        return;
      case 'aggressive':
        _allowPlanning = true;
        _allowSubAgents = true;
        _allowFileMutation = true;
        _allowRead = true;
        _allowWrite = true;
        _allowEdit = true;
        _allowBackup = true;
        return;
      case 'balanced':
        _allowPlanning = true;
        _allowSubAgents = true;
        _allowFileMutation = true;
        _allowRead = true;
        _allowWrite = true;
        _allowEdit = true;
        _allowBackup = true;
        return;
      case 'custom':
      default:
        return;
    }
  }
}
