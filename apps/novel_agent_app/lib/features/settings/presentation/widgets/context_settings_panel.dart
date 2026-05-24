import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import 'settings_form_section.dart';
import 'settings_labeled_text_field.dart';

class ContextSettingsPanel extends StatefulWidget {
  const ContextSettingsPanel({
    super.key,
    required this.settings,
    required this.defaultProjectPath,
    required this.allowProjectPathEdit,
    required this.onSaved,
  });

  final Map<String, Object?> settings;
  final String defaultProjectPath;
  final bool allowProjectPathEdit;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ContextSettingsPanel> createState() => _ContextSettingsPanelState();
}

class _ContextSettingsPanelState extends State<ContextSettingsPanel> {
  late final TextEditingController _projectPathController;
  late final TextEditingController _compressionThresholdController;
  late final TextEditingController _budgetController;
  late final TextEditingController _maxCharsController;
  late final TextEditingController _maxFilesController;
  late final TextEditingController _reservedOutputController;

  @override
  void initState() {
    super.initState();
    _projectPathController = TextEditingController();
    _compressionThresholdController = TextEditingController();
    _budgetController = TextEditingController();
    _maxCharsController = TextEditingController();
    _maxFilesController = TextEditingController();
    _reservedOutputController = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ContextSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings ||
        oldWidget.defaultProjectPath != widget.defaultProjectPath) {
      _sync();
    }
  }

  @override
  void dispose() {
    _projectPathController.dispose();
    _compressionThresholdController.dispose();
    _budgetController.dispose();
    _maxCharsController.dispose();
    _maxFilesController.dispose();
    _reservedOutputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '上下文预算',
          description: '这些设置决定项目文件如何进入上下文包，以及何时触发压缩。',
          child: Column(
            children: [
              SettingsLabeledTextField(
                label: '默认项目路径',
                controller: _projectPathController,
                enabled: widget.allowProjectPathEdit,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '压缩阈值百分比',
                controller: _compressionThresholdController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '上下文包预算百分比',
                controller: _budgetController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '单文件字符上限',
                controller: _maxCharsController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '每类文件纳入上限',
                controller: _maxFilesController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '预留输出字符',
                controller: _reservedOutputController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存上下文设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'default_project_path': _projectPathController.text.trim(),
              'compression_threshold_percent': _compressionThresholdController
                  .text
                  .trim(),
              'context_pack_budget_percent': _budgetController.text.trim(),
              'max_context_file_chars': _maxCharsController.text.trim(),
              'max_context_files_per_kind': _maxFilesController.text.trim(),
              'reserved_output_chars': _reservedOutputController.text.trim(),
            });
          },
        ),
      ],
    );
  }

  void _sync() {
    _projectPathController.text = widget.defaultProjectPath;
    _compressionThresholdController.text =
        (widget.settings['compression_threshold_percent'] ?? '60').toString();
    _budgetController.text =
        (widget.settings['context_pack_budget_percent'] ?? '55').toString();
    _maxCharsController.text =
        (widget.settings['max_context_file_chars'] ?? '2400').toString();
    _maxFilesController.text =
        (widget.settings['max_context_files_per_kind'] ?? '6').toString();
    _reservedOutputController.text =
        (widget.settings['reserved_output_chars'] ?? '20000').toString();
  }
}
