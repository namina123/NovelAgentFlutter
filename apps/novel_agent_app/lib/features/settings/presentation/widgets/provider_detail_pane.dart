import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/settings_view_data.dart';
import '../models/settings_search_option.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_search_dropdown_field.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ProviderDetailPane extends StatefulWidget {
  const ProviderDetailPane({
    super.key,
    this.provider,
    required this.providerDirectoryOptions,
    required this.modelOptions,
    required this.onProviderSaved,
    required this.onProviderDeleted,
    this.onBackRequested,
  });

  final ProviderEndpointViewData? provider;
  final List<ProviderDirectoryOptionViewData> providerDirectoryOptions;
  final List<SettingsSearchOptionViewData> modelOptions;
  final ValueChanged<Map<String, Object?>> onProviderSaved;
  final ValueChanged<String> onProviderDeleted;
  final VoidCallback? onBackRequested;

  @override
  State<ProviderDetailPane> createState() => _ProviderDetailPaneState();
}

class _ProviderDetailPaneState extends State<ProviderDetailPane> {
  late final TextEditingController _titleController;
  late final ProviderProtocolService _protocolService;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _modelIdController;
  late String _protocol;
  String? _selectedDirectoryProviderId;
  bool _revealApiKey = false;
  String? _loadedProviderId;

  @override
  void initState() {
    super.initState();
    _protocolService = ProviderProtocolService();
    _titleController = TextEditingController();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _descriptionController = TextEditingController();
    _modelIdController = TextEditingController();
    _syncFromProvider(widget.provider);
  }

  @override
  void didUpdateWidget(covariant ProviderDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider?.id != widget.provider?.id ||
        oldWidget.provider?.title != widget.provider?.title ||
        oldWidget.provider?.baseUrl != widget.provider?.baseUrl ||
        oldWidget.provider?.rawApiKey != widget.provider?.rawApiKey ||
        oldWidget.provider?.description != widget.provider?.description ||
        oldWidget.provider?.protocol != widget.provider?.protocol) {
      _syncFromProvider(widget.provider);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    _modelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口详情编辑区只负责当前接口的表单和提交，内部 ID 由控制器自动生成而不暴露给用户。
    final provider = widget.provider;
    final protocolOptions = _protocolService
        .protocolOptions()
        .map(
          (entry) => SettingsDropdownOption<String>(
            value: ValueReaders.stringValue(entry['id']),
            label: ValueReaders.stringValue(entry['label']),
          ),
        )
        .toList(growable: false);
    final providerOptions = widget.providerDirectoryOptions
        .map(
          (option) => SettingsSearchOption<String>(
            value: option.id,
            label: option.label,
          ),
        )
        .toList(growable: false);
    final modelOptions = widget.modelOptions
        .map(
          (option) => SettingsSearchOption<String>(
            value: option.value,
            label: option.label,
            note: option.note,
          ),
        )
        .toList(growable: false);
    return ListView(
      children: [
        if (widget.onBackRequested != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBackRequested,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('返回接口列表'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SectionHeading(
          title: provider?.title.trim().isNotEmpty == true
              ? provider!.title
              : '新接口',
          subtitle: '这里只编辑接口/厂商、协议、地址、模型与密钥；内部 ID 会自动生成。',
        ),
        const SizedBox(height: 18),
        SettingsFormSection(
          title: '基础信息',
          child: Column(
            children: [
              SettingsLabeledSearchDropdownField<String>(
                key: const ValueKey('provider-directory-field'),
                label: '接口/厂商名称',
                controller: _titleController,
                selectedValue: _selectedDirectoryProviderId,
                options: providerOptions,
                hintText: '输入厂商名称筛选，例如 OpenAI / DeepSeek',
                onSelected: _onProviderDirectorySelected,
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: '协议',
                value: _protocol,
                options: protocolOptions,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _protocol = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: 'Base URL',
                controller: _baseUrlController,
                hintText: '例如 https://api.deepseek.com',
              ),
              const SizedBox(height: 12),
              SettingsLabeledSearchDropdownField<String>(
                key: const ValueKey('provider-model-field'),
                label: '模型 ID',
                controller: _modelIdController,
                selectedValue: null,
                options: modelOptions,
                hintText: '输入模型 ID 筛选，也可从全部模型里选择',
                onSelected: (value) {
                  if (value == null) {
                    return;
                  }
                  _modelIdController.text = value;
                },
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
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
                onPressed: provider == null
                    ? () {}
                    : () => widget.onProviderDeleted(provider.id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncFromProvider(ProviderEndpointViewData? provider) {
    // 中文注释: 切换 provider 时统一刷新编辑草稿，避免多个面板各自同步字段而出现旧值残留。
    final nextProviderId = provider?.id ?? '__new__';
    if (_loadedProviderId == nextProviderId) {
      return;
    }
    _loadedProviderId = nextProviderId;
    _titleController.text = provider?.title ?? '';
    _protocol = provider?.protocol ?? 'openai_compatible';
    _baseUrlController.text = provider?.baseUrl ?? '';
    _apiKeyController.text = provider?.rawApiKey ?? '';
    _descriptionController.text = provider?.description ?? '';
    _modelIdController.text = '';
    _selectedDirectoryProviderId = _directoryProviderIdFor(provider);
    _revealApiKey = false;
  }

  void _save() {
    // 中文注释: provider 保存只上交结构化 payload，具体写盘与默认接口去重仍由控制器处理。
    widget.onProviderSaved(<String, Object?>{
      'source_id': widget.provider?.id ?? '',
      'title': _titleController.text.trim(),
      'protocol': _protocol,
      'base_url': _baseUrlController.text.trim(),
      'api_key': _apiKeyController.text,
      'model_id': _modelIdController.text.trim(),
      'description': _descriptionController.text.trim(),
      'is_new': false,
    });
  }

  void _onProviderDirectorySelected(String? providerId) {
    if (providerId == null) {
      return;
    }
    final matched = widget.providerDirectoryOptions.where(
      (option) => option.id == providerId,
    );
    if (matched.isEmpty) {
      return;
    }
    final option = matched.first;
    setState(() {
      _selectedDirectoryProviderId = option.id;
      _titleController.text = option.label;
      _protocol = option.protocol;
      if (_baseUrlController.text.trim().isEmpty ||
          widget.provider?.baseUrl.trim() == _baseUrlController.text.trim()) {
        _baseUrlController.text = option.defaultBaseUrl;
      }
    });
  }

  String? _directoryProviderIdFor(ProviderEndpointViewData? provider) {
    if (provider == null) {
      return null;
    }
    for (final option in widget.providerDirectoryOptions) {
      if (option.id == provider.id) {
        return option.id;
      }
      if (option.label.trim().toLowerCase() ==
          provider.title.trim().toLowerCase()) {
        return option.id;
      }
    }
    return null;
  }

}
