import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/settings_view_data.dart';
import 'settings_form_section.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ProviderDetailPane extends StatefulWidget {
  const ProviderDetailPane({
    super.key,
    required this.provider,
    required this.onProviderSaved,
    required this.onProviderDeleted,
  });

  final ProviderEndpointViewData provider;
  final ValueChanged<Map<String, Object?>> onProviderSaved;
  final ValueChanged<String> onProviderDeleted;

  @override
  State<ProviderDetailPane> createState() => _ProviderDetailPaneState();
}

class _ProviderDetailPaneState extends State<ProviderDetailPane> {
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _protocolController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelIdController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _descriptionController;
  bool _isDefault = false;
  bool _revealApiKey = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _titleController = TextEditingController();
    _protocolController = TextEditingController();
    _baseUrlController = TextEditingController();
    _modelIdController = TextEditingController();
    _apiKeyController = TextEditingController();
    _descriptionController = TextEditingController();
    _syncFromProvider(widget.provider);
  }

  @override
  void didUpdateWidget(covariant ProviderDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id ||
        oldWidget.provider.baseUrl != widget.provider.baseUrl ||
        oldWidget.provider.modelId != widget.provider.modelId ||
        oldWidget.provider.rawApiKey != widget.provider.rawApiKey ||
        oldWidget.provider.description != widget.provider.description ||
        oldWidget.provider.isDefault != widget.provider.isDefault) {
      _syncFromProvider(widget.provider);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _protocolController.dispose();
    _baseUrlController.dispose();
    _modelIdController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口详情编辑区只负责当前 provider 的表单和提交，不进入设置仓储与保存逻辑。
    return ListView(
      children: [
        SectionHeading(
          title: widget.provider.title,
          subtitle: '接口信息、默认模型和密钥都在这里直接编辑。',
        ),
        const SizedBox(height: 18),
        SettingsFormSection(
          title: '基础信息',
          child: Column(
            children: [
              SettingsLabeledTextField(label: 'ID', controller: _idController),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '接口名称',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '协议',
                controller: _protocolController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: 'Base URL',
                controller: _baseUrlController,
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '默认模型',
                controller: _modelIdController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '凭据与说明',
          child: Column(
            children: [
              SettingsLabeledTextField(
                label: 'API Key',
                controller: _apiKeyController,
                hintText: '留空则表示当前接口没有密钥',
                obscureText: !_revealApiKey,
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '显示 API Key 明文',
                value: _revealApiKey,
                onChanged: (value) {
                  setState(() {
                    _revealApiKey = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '说明',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '作为默认接口',
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: '新建接口',
                icon: Icons.add_rounded,
                tone: ActionButtonTone.neutral,
                compact: true,
                onPressed: _createNew,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                label: '保存接口',
                icon: Icons.save_outlined,
                compact: true,
                onPressed: _save,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                label: '删除接口',
                icon: Icons.delete_outline_rounded,
                tone: ActionButtonTone.danger,
                compact: true,
                onPressed: () => widget.onProviderDeleted(widget.provider.id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncFromProvider(ProviderEndpointViewData provider) {
    // 中文注释: 切换 provider 时统一刷新编辑草稿，避免多个面板各自同步字段而出现旧值残留。
    _idController.text = provider.id;
    _titleController.text = provider.title;
    _protocolController.text = provider.protocol;
    _baseUrlController.text = provider.baseUrl;
    _modelIdController.text = provider.modelId;
    _apiKeyController.text = provider.rawApiKey;
    _descriptionController.text = provider.description;
    _isDefault = provider.isDefault;
    _revealApiKey = false;
  }

  void _createNew() {
    // 中文注释: 新建接口直接提交一份空草稿，让控制器统一决定默认值与选中状态。
    widget.onProviderSaved(<String, Object?>{
      'source_id': '',
      'id': '',
      'title': '新接口',
      'protocol': 'openai_compatible',
      'base_url': '',
      'model_id': '',
      'api_key': '',
      'description': '',
      'is_default': false,
      'is_new': true,
    });
  }

  void _save() {
    // 中文注释: provider 保存只上交结构化 payload，具体写盘与默认接口去重仍由控制器处理。
    widget.onProviderSaved(<String, Object?>{
      'source_id': widget.provider.id,
      'id': _idController.text.trim(),
      'title': _titleController.text.trim(),
      'protocol': _protocolController.text.trim(),
      'base_url': _baseUrlController.text.trim(),
      'model_id': _modelIdController.text.trim(),
      'api_key': _apiKeyController.text,
      'description': _descriptionController.text.trim(),
      'is_default': _isDefault,
      'is_new': false,
    });
  }
}
