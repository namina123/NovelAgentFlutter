import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/settings_view_data.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ModelSettingsPanel extends StatefulWidget {
  const ModelSettingsPanel({
    super.key,
    required this.viewData,
    required this.onSaved,
  });

  final SettingsViewData viewData;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ModelSettingsPanel> createState() => _ModelSettingsPanelState();
}

class _ModelSettingsPanelState extends State<ModelSettingsPanel> {
  late String _providerId;
  late final TextEditingController _modelIdController;
  late final TextEditingController _agentIdController;
  late bool _autoSaveDrafts;

  @override
  void initState() {
    super.initState();
    _modelIdController = TextEditingController();
    _agentIdController = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ModelSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData != widget.viewData) {
      _sync();
    }
  }

  @override
  void dispose() {
    _modelIdController.dispose();
    _agentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 模型设置面板只处理默认模型与默认智能体的表单，不进入 provider 编辑和保存细节。
    final providerOptions = widget.viewData.providers
        .map(
          (provider) => SettingsDropdownOption<String>(
            value: provider.id,
            label: provider.title,
          ),
        )
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '默认运行入口',
          description: '主工作台、CLI 和共享 core 都会优先读取这里的默认 provider、模型和主智能体。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '默认接口',
                value: _providerId,
                options: providerOptions,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _providerId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '默认模型 ID',
                controller: _modelIdController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '默认智能体 ID',
                controller: _agentIdController,
              ),
              const SizedBox(height: 12),
              SettingsSwitchRow(
                label: '自动保存草稿',
                note: '生成结果落盘时会优先保存到项目 drafts/ 目录。',
                value: _autoSaveDrafts,
                onChanged: (value) {
                  setState(() {
                    _autoSaveDrafts = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存模型设置',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: _save,
        ),
      ],
    );
  }

  void _sync() {
    _providerId = widget.viewData.defaultProviderId.isEmpty &&
            widget.viewData.providers.isNotEmpty
        ? widget.viewData.providers.first.id
        : widget.viewData.defaultProviderId;
    _modelIdController.text = widget.viewData.defaultModelId;
    _agentIdController.text = widget.viewData.defaultAgentId;
    _autoSaveDrafts = widget.viewData.autoSaveDrafts;
  }

  void _save() {
    widget.onSaved(<String, Object?>{
      'default_provider_id': _providerId,
      'default_model_id': _modelIdController.text.trim(),
      'default_agent_id': _agentIdController.text.trim(),
      'auto_save_drafts': _autoSaveDrafts,
    });
  }
}
