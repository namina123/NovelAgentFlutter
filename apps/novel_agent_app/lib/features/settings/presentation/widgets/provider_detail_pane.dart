import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/settings_search_option.dart';
import '../models/settings_view_data.dart';
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
    required this.onProviderSaved,
    required this.onProviderDeleted,
    this.onBackRequested,
  });

  final ProviderEndpointViewData? provider;
  final List<ProviderDirectoryOptionViewData> providerDirectoryOptions;
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
  late String _protocol;
  String? _selectedDirectoryProviderId;
  bool _revealApiKey = false;
  String? _loadedProviderId;
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _protocolService = ProviderProtocolService();
    _titleController = TextEditingController();
    _baseUrlController = TextEditingController();
    _apiKeyController = TextEditingController();
    _descriptionController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 接口详情只负责"地址 + 凭据"的录入与保存；它不依赖、也不提及模型，
    // 模型选择与连接测试统一在「模型」页完成。
    final provider = widget.provider;
    final surface = context.novelThemeSurfaces.panel;
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
    // 中文注释: 协议显示复用下拉里的友好标签，避免把 anthropic/google_openai_compatible 等
    // 原始 id 直接抛给用户。
    var friendlyProtocol = _protocol;
    for (final option in protocolOptions) {
      if (option.value == _protocol) {
        friendlyProtocol = option.label;
        break;
      }
    }
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
          title: provider == null ||
                  provider.id == '__new__' ||
                  provider.title.trim().isEmpty
              ? '添加接口'
              : provider.title,
          subtitle: '从厂商目录选一个模板，或直接输入名称；再填 API Key 与地址后保存。',
        ),
        const SizedBox(height: 18),
        SettingsFormSection(
          title: '基础信息',
          description: '点输入框或右侧箭头可展开厂商目录；选中后自动填协议与默认地址。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsLabeledSearchDropdownField<String>(
                key: const ValueKey('provider-directory-field'),
                label: '接口/厂商名称',
                controller: _titleController,
                selectedValue: _selectedDirectoryProviderId,
                options: providerOptions,
                hintText: '点此展开厂商列表，或输入名称筛选（OpenAI / DeepSeek / 硅基流动）',
                openOnFocus: true,
                onSelected: _onProviderDirectorySelected,
              ),
              if (widget.providerDirectoryOptions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '常用厂商（点选即填模板）',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: surface.mutedForegroundColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _quickDirectoryOptions())
                      ActionChip(
                        label: Text(option.label),
                        onPressed: () => _onProviderDirectorySelected(option.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '接口只保存地址与凭据；模型在「模型」页绑定到接口。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: surface.mutedForegroundColor,
                ),
              ),
              if (_baseUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '当前地址：${_baseUrlController.text.trim()} · 协议：$friendlyProtocol',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ],
              if (_formError.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _formError,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '凭据',
          description: '云端接口必填 API Key；纯本地服务可留空。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsLabeledTextField(
                label: 'API Key',
                controller: _apiKeyController,
                hintText: '云端接口必填；纯本地服务可留空',
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
                disabled: provider == null || provider.id == '__new__',
                onPressed: () async {
                  if (provider == null || provider.id == '__new__') {
                    return;
                  }
                  // 中文注释: 删除接口不可恢复，且若删的是当前默认接口会直接断掉生成，
                  // 二次确认避免误删。
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: '删除该接口？',
                    message: '删除后不可恢复。若这是当前默认接口，生成将无法继续，'
                        '需要重新配置其他接口。',
                    confirmLabel: '删除',
                  );
                  if (!mounted) {
                    return;
                  }
                  if (confirmed) {
                    widget.onProviderDeleted(provider.id);
                  }
                },
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
    _selectedDirectoryProviderId = _directoryProviderIdFor(provider);
    _revealApiKey = false;
    _formError = '';
  }

  void _save() {
    // 中文注释: provider 保存只上交结构化 payload，具体写盘与默认接口去重仍由控制器处理。
    final title = _titleController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final validationError = _localFormError(
      title: title,
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
    if (validationError != null) {
      setState(() {
        _formError = validationError;
      });
      return;
    }
    if (_formError.isNotEmpty) {
      setState(() {
        _formError = '';
      });
    }
    final sourceId = widget.provider?.id ?? '';
    widget.onProviderSaved(<String, Object?>{
      'source_id': sourceId == '__new__' ? '' : sourceId,
      'title': title,
      'protocol': _protocol,
      'base_url': baseUrl,
      'api_key': _apiKeyController.text,
      'description': _descriptionController.text.trim(),
      'is_new': sourceId.isEmpty || sourceId == '__new__',
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
      // 中文注释: 用户明确点选厂商模板时，地址/协议以模板为准，避免还停在空白或旧值。
      if (option.defaultBaseUrl.trim().isNotEmpty) {
        _baseUrlController.text = option.defaultBaseUrl;
      }
      _formError = '';
    });
  }

  List<ProviderDirectoryOptionViewData> _quickDirectoryOptions() {
    // 中文注释: 快捷芯片只挑常见入口，完整列表仍走搜索下拉。
    const preferredIds = <String>{
      'openai_api',
      'deepseek_openai',
      'siliconflow_openai',
      'anthropic_api',
      'google_openai_compatible',
      'moonshot_openai',
      'zhipu_openai',
      'qwen_openai',
      'local_openai',
    };
    final preferred = <ProviderDirectoryOptionViewData>[];
    final rest = <ProviderDirectoryOptionViewData>[];
    for (final option in widget.providerDirectoryOptions) {
      if (preferredIds.contains(option.id)) {
        preferred.add(option);
      } else {
        rest.add(option);
      }
    }
    final ordered = <ProviderDirectoryOptionViewData>[
      ...preferred,
      ...rest,
    ];
    return ordered.take(8).toList(growable: false);
  }

  String? _directoryProviderIdFor(ProviderEndpointViewData? provider) {
    if (provider == null || provider.id == '__new__') {
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

  String? _localFormError({
    required String title,
    required String baseUrl,
    required String apiKey,
  }) {
    if (title.isEmpty) {
      return '请先填写或选择接口/厂商名称。';
    }
    if (baseUrl.isEmpty) {
      return '请填写 Base URL：可在上方下拉里点选一个厂商模板自动填入，'
          '或展开「高级设置」手动填写。';
    }
    final uri = Uri.tryParse(baseUrl);
    final validScheme =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty;
    if (!validScheme) {
      return 'Base URL 需要是完整的 http/https 地址。';
    }
    final isLocal =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host.startsWith('192.168.') ||
        uri.host.startsWith('10.');
    if (apiKey.isEmpty && !isLocal) {
      return '云端接口需要填写 API Key；纯本地服务可留空。';
    }
    return null;
  }
}
