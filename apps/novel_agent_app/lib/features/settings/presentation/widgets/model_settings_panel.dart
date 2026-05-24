import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/model_editor_view_data.dart';
import '../models/model_parameter_entry_view_data.dart';
import '../models/settings_search_option.dart';
import '../models/settings_view_data.dart';
import 'model_custom_parameter_list.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_search_dropdown_field.dart';
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
  late final TextEditingController _providerSearchController;
  late final TextEditingController _compatibleContextWindowController;
  late final TextEditingController _appContextWindowController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _topPController;
  late final TextEditingController _topKController;
  late String _streamMode;
  late String _apiMode;
  late bool _thinkingEnabled;
  late String _thinkingEffort;
  late List<ModelParameterEntryViewData> _customParameters;

  @override
  void initState() {
    super.initState();
    _providerSearchController = TextEditingController();
    _modelIdController = TextEditingController();
    _compatibleContextWindowController = TextEditingController();
    _appContextWindowController = TextEditingController();
    _temperatureController = TextEditingController();
    _topPController = TextEditingController();
    _topKController = TextEditingController();
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
    _providerSearchController.dispose();
    _modelIdController.dispose();
    _compatibleContextWindowController.dispose();
    _appContextWindowController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 模型设置面板只处理运行时模型入口和上下文参数，不与接口创建职责混在一起。
    final providerOptions = widget.viewData.providers
        .map(
          (provider) => SettingsSearchOption<String>(
            value: provider.id,
            label: provider.title,
          ),
        )
        .toList(growable: false);
    final editor = widget.viewData.modelEditor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '模型运行设置',
          description: '这里定义当前应用默认使用哪个接口和模型，以及上下文窗口、流式与 API 模式。',
          child: Column(
            children: [
              SettingsLabeledSearchDropdownField<String>(
                label: '接口',
                controller: _providerSearchController,
                selectedValue: _providerId.isEmpty ? null : _providerId,
                options: providerOptions,
                hintText: '输入接口名称筛选',
                onSelected: (value) {
                  setState(() {
                    _providerId = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledSearchDropdownField<String>(
                label: '模型 ID',
                controller: _modelIdController,
                selectedValue: null,
                options: editor.modelSuggestions,
                hintText: '必填，例如 deepseek-v4-pro',
                onSelected: (value) {
                  if (value == null) {
                    return;
                  }
                  _modelIdController.text = value;
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '兼容上下文长度',
                controller: _compatibleContextWindowController,
                hintText: '例如 65536',
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '应用上下文长度',
                controller: _appContextWindowController,
                hintText: '例如 24000',
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: '流式传输',
                value: _streamMode,
                options: const [
                  SettingsDropdownOption(value: 'stream', label: '流式'),
                  SettingsDropdownOption(value: 'non_stream', label: '非流式'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _streamMode = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: 'API 模式',
                value: _apiMode,
                options: const [
                  SettingsDropdownOption(value: 'chat', label: '聊天 API'),
                  SettingsDropdownOption(
                    value: 'responses',
                    label: 'Responses API',
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _apiMode = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '能力摘要',
          description: '这里显示当前接口与模型组合在核心目录中识别到的能力，供高级设置和后续智能体重写共用。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryLine('协议', _protocolLabel(editor.protocolMode)),
              _summaryLine(
                'Base URL',
                editor.baseUrl.isEmpty ? '未配置' : editor.baseUrl,
              ),
              _summaryLine(
                '深度思考',
                editor.supportsReasoning
                    ? editor.thinkingParameterLabel
                    : '当前目录未识别到',
              ),
              _summaryLine('参数支持', _parameterSummary(editor)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '默认参数',
          description: '这里配置模型级默认参数。智能体层后续可以在此基础上做持久化重写。',
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 12),
              title: const Text(
                '高级设置',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('默认折叠，按需展开设置模型默认参数。'),
              children: [
                if (editor.supportsReasoning) ...[
                  SettingsSwitchRow(
                    label: '启用深度思考',
                    value: _thinkingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _thinkingEnabled = value;
                      });
                    },
                    note: editor.thinkingParameterLabel,
                  ),
                  if (editor.thinkingEffortSupported) ...[
                    const SizedBox(height: 12),
                    SettingsLabeledDropdownField<String>(
                      label: '深度思考强度',
                      value: _thinkingEffort,
                      options: editor.thinkingEffortOptions
                          .map(
                            (item) => SettingsDropdownOption<String>(
                              value: item,
                              label: item,
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _thinkingEffort = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                if (editor.supportsTemperature) ...[
                  SettingsLabeledTextField(
                    label: 'Temperature',
                    controller: _temperatureController,
                    hintText: '例如 0.8',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (editor.supportsTopP) ...[
                  SettingsLabeledTextField(
                    label: 'Top P',
                    controller: _topPController,
                    hintText: '例如 0.95',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (editor.supportsTopK) ...[
                  SettingsLabeledTextField(
                    label: 'Top K',
                    controller: _topKController,
                    hintText: '例如 40',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                ],
                ModelCustomParameterList(
                  entries: _customParameters,
                  onAdded: _addCustomParameter,
                  onKeyChanged: _updateCustomParameterKey,
                  onTypeChanged: _updateCustomParameterType,
                  onValueChanged: _updateCustomParameterValue,
                  onRemoved: _removeCustomParameter,
                ),
              ],
            ),
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
    final modelSettings = widget.viewData.modelSettings;
    final editor = widget.viewData.modelEditor;
    _providerId = _stringValue(
      modelSettings['provider_id'],
      widget.viewData.defaultProviderId,
    );
    _providerSearchController.text = _providerTitleOf(_providerId);
    _modelIdController.text = _stringValue(
      modelSettings['model_id'],
      widget.viewData.defaultModelId,
    );
    _compatibleContextWindowController.text =
        (modelSettings['compatible_context_window'] ?? '').toString();
    _appContextWindowController.text =
        (modelSettings['app_context_window'] ?? '').toString();
    _streamMode = (modelSettings['stream_mode'] ?? 'stream').toString();
    _apiMode = (modelSettings['api_mode'] ?? 'chat').toString();
    _thinkingEnabled = _boolValue(
      modelSettings['thinking_enabled'],
      editor.thinkingEnabled,
    );
    _thinkingEffort = _stringValue(
      modelSettings['thinking_effort'],
      editor.thinkingEffort,
    );
    _temperatureController.text = _stringValue(
      modelSettings['temperature'],
      editor.temperature.toString(),
    );
    _topPController.text = _stringValue(
      modelSettings['top_p'],
      editor.topP.toString(),
    );
    _topKController.text = _stringValue(
      modelSettings['top_k'],
      editor.topK.toString(),
    );
    _customParameters = _initialCustomParameters(modelSettings, editor);
  }

  void _save() {
    widget.onSaved(<String, Object?>{
      'default_provider_id': _providerId,
      'default_model_id': _modelIdController.text.trim(),
      'model_id': _modelIdController.text.trim(),
      'compatible_context_window': _compatibleContextWindowController.text
          .trim(),
      'app_context_window': _appContextWindowController.text.trim(),
      'stream_mode': _streamMode,
      'api_mode': _apiMode,
      'thinking_enabled': _thinkingEnabled,
      'thinking_effort': _thinkingEffort,
      'temperature': _temperatureController.text.trim(),
      'top_p': _topPController.text.trim(),
      'top_k': _topKController.text.trim(),
      'custom_parameters': _customParameters
          .where((entry) => entry.keyName.trim().isNotEmpty)
          .map(_parameterDocument)
          .toList(growable: false),
    });
  }

  List<ModelParameterEntryViewData> _initialCustomParameters(
    Map<String, Object?> modelSettings,
    ModelEditorViewData editor,
  ) {
    final stored = ValueReaders.mapList(modelSettings['custom_parameters']);
    if (stored.isEmpty) {
      return List<ModelParameterEntryViewData>.from(editor.customParameters);
    }
    return stored
        .map(ModelParameterEntryViewData.fromMap)
        .toList(growable: false);
  }

  void _addCustomParameter() {
    setState(() {
      _customParameters = <ModelParameterEntryViewData>[
        ..._customParameters,
        const ModelParameterEntryViewData(
          keyName: '',
          valueType: 'string',
          value: '',
        ),
      ];
    });
  }

  void _updateCustomParameterKey(int index, String value) {
    _updateCustomParameter(
      index,
      _customParameters[index].copyWith(keyName: value),
    );
  }

  void _updateCustomParameterType(int index, String value) {
    _updateCustomParameter(
      index,
      _customParameters[index].copyWith(
        valueType: value,
        value: value == 'boolean' ? false : '',
      ),
    );
  }

  void _updateCustomParameterValue(int index, String value) {
    _updateCustomParameter(
      index,
      _customParameters[index].copyWith(
        value: _coerceValue(value, _customParameters[index].valueType),
      ),
    );
  }

  void _removeCustomParameter(int index) {
    setState(() {
      final next = List<ModelParameterEntryViewData>.from(_customParameters);
      next.removeAt(index);
      _customParameters = next;
    });
  }

  void _updateCustomParameter(
    int index,
    ModelParameterEntryViewData nextEntry,
  ) {
    setState(() {
      final next = List<ModelParameterEntryViewData>.from(_customParameters);
      next[index] = nextEntry;
      _customParameters = next;
    });
  }

  Map<String, Object?> _parameterDocument(ModelParameterEntryViewData entry) {
    return <String, Object?>{
      ...entry.toDocument(),
      'value': _coerceValue(entry.valueText(), entry.valueType),
    };
  }

  Object? _coerceValue(String rawValue, String valueType) {
    switch (valueType) {
      case 'boolean':
        return rawValue.trim().toLowerCase() == 'true';
      case 'integer':
        return int.tryParse(rawValue.trim()) ?? 0;
      case 'number':
        return double.tryParse(rawValue.trim()) ?? 0;
      case 'json':
        final trimmed = rawValue.trim();
        if (trimmed.isEmpty) {
          return '';
        }
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return trimmed;
        }
      default:
        return rawValue;
    }
  }

  String _providerTitleOf(String providerId) {
    for (final provider in widget.viewData.providers) {
      if (provider.id == providerId) {
        return provider.title;
      }
    }
    return '';
  }

  String _protocolLabel(String mode) {
    switch (mode) {
      case ProviderProfileConstants.kindAnthropicCompatible:
        return 'Anthropic 兼容';
      default:
        return 'OpenAI 兼容';
    }
  }

  String _parameterSummary(ModelEditorViewData editor) {
    final chips = <String>[];
    if (editor.supportsTemperature) {
      chips.add('temperature');
    }
    if (editor.supportsTopP) {
      chips.add('top_p');
    }
    if (editor.supportsTopK) {
      chips.add('top_k');
    }
    if (editor.supportsToolChoice) {
      chips.add('tool_choice');
    }
    return chips.isEmpty ? '未识别到可调标准参数' : chips.join(' / ');
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value, bool fallback) {
    if (value == null) {
      return fallback;
    }
    if (value is bool) {
      return value;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) {
      return fallback;
    }
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
