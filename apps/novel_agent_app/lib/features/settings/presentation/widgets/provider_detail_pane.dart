import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/model_editor_view_data.dart';
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
    required this.onConnectionTestRequested,
    this.onBackRequested,
  });

  final ProviderEndpointViewData? provider;
  final List<ProviderDirectoryOptionViewData> providerDirectoryOptions;
  final List<SettingsSearchOptionViewData> modelOptions;
  final ValueChanged<Map<String, Object?>> onProviderSaved;
  final ValueChanged<String> onProviderDeleted;
  final ValueChanged<Map<String, Object?>> onConnectionTestRequested;
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
          subtitle: '首次使用先补齐接口、模型与密钥；协议和地址默认收进高级设置。',
        ),
        const SizedBox(height: 18),
        SettingsFormSection(
          title: '基础信息',
          description: '先完成作品常用的厂商和模型配置，协议细节按需展开。',
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
          title: '凭据与连接测试',
          description: '先填写 API Key，再点一次测试连接，确认这组配置已经具备发送请求的基础条件。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              ActionButton(
                label: '测试连接',
                icon: Icons.wifi_tethering_rounded,
                tone: ActionButtonTone.neutral,
                compact: true,
                onPressed: _testConnection,
              ),
              const SizedBox(height: 12),
              _ProviderConnectionStatusCard(
                key: const ValueKey('provider-connection-status'),
                result: widget.provider?.connectionValidationResult ??
                    ProviderConnectionValidationResultViewData.initial,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '高级设置',
          description: '只有在协议、地址或补充说明需要自定义时再展开，默认无需调整。',
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12),
                title: const Text(
                  '展开高级设置',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('协议、Base URL 与补充说明默认收起。'),
                children: [
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
                  SettingsLabeledTextField(
                    label: '说明',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
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

  void _testConnection() {
    widget.onConnectionTestRequested(<String, Object?>{
      'source_id': widget.provider?.id ?? '',
      'title': _titleController.text.trim(),
      'protocol': _protocol,
      'base_url': _baseUrlController.text.trim(),
      'api_key': _apiKeyController.text,
      'model_id': _modelIdController.text.trim(),
      'api_mode': widget.provider?.connectionValidationResult.selectedRouteFamily,
    });
  }
}

class _ProviderConnectionStatusCard extends StatelessWidget {
  const _ProviderConnectionStatusCard({
    super.key,
    required this.result,
  });

  final ProviderConnectionValidationResultViewData result;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = result.isSuccess
        ? const Color(0xFF23663A)
        : const Color(0xFF8A5A12);
    final backgroundColor = result.isSuccess
        ? const Color(0xFFE8F5EC)
        : const Color(0xFFFCF2DD);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.summary,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
          for (final detail in result.details) ...[
            const SizedBox(height: 6),
            Text(
              '• $detail',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '错误：${result.errors.join('；')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (result.hideOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '需要隐藏的选项：${result.hideOptions.join('、')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.fallbackNotAllowed) ...[
            const SizedBox(height: 8),
            Text(
              '当前组合不允许 fallback。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '警告：${result.warnings.join('；')}',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: foregroundColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
