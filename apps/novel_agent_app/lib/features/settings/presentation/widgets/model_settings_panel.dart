import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/settings_view_data.dart';
import '../models/custom_model_reasoning_effort_entry_view_data.dart';
import '../models/model_editor_view_data.dart';
import '../models/model_parameter_entry_view_data.dart';
import '../models/settings_search_option.dart';
import 'model_settings_advanced_panel.dart';
import 'model_settings_primary_panel.dart';
import 'settings_labeled_text_field.dart';

typedef ModelConnectionTestCallback =
    Future<ProviderConnectionValidationResultViewData> Function(
      Map<String, Object?>,
    );

class ModelSettingsPanel extends StatefulWidget {
  const ModelSettingsPanel({
    super.key,
    required this.viewData,
    required this.onSaved,
    required this.onConnectionTestRequested,
  });

  final SettingsViewData viewData;
  final ValueChanged<Map<String, Object?>> onSaved;
  /// 中文注释: 连接测试由模型页发起，使用"当前选中接口 + 模型"真实配对；壳层负责联网探测并回传结果。
  final ModelConnectionTestCallback onConnectionTestRequested;

  @override
  State<ModelSettingsPanel> createState() => _ModelSettingsPanelState();
}

class _ModelSettingsPanelState extends State<ModelSettingsPanel> {
  late String _providerId;
  late final TextEditingController _modelIdController;
  late final TextEditingController _embeddingModelIdController;
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
  late bool _customSupportsReasoning;
  late bool _customReasoningCanToggle;
  late bool _customReasoningDefaultEnabled;
  late bool _customReasoningSupportsEffort;
  late String _customToggleStrategyKind;
  late final TextEditingController _customToggleKeyController;
  late final TextEditingController _customToggleEnabledValueController;
  late final TextEditingController _customToggleDisabledValueController;
  late final TextEditingController _customEffortKeyController;
  late List<CustomModelReasoningEffortEntryViewData> _customEffortEntries;
  int _customEffortEntrySerial = 0;
  // 中文注释: 连接测试结果只活在模型页本地：壳层回传后直接展示，不再回灌接口页或全局缓存，
  // 避免刷新设置视图时把用户正在编辑的接口/模型表单重置。
  ProviderConnectionValidationResultViewData _connectionResult =
      ProviderConnectionValidationResultViewData.initial;
  bool _connectionTesting = false;

  @override
  void initState() {
    super.initState();
    _providerSearchController = TextEditingController();
    _modelIdController = TextEditingController();
    _embeddingModelIdController = TextEditingController();
    _compatibleContextWindowController = TextEditingController();
    _appContextWindowController = TextEditingController();
    _temperatureController = TextEditingController();
    _topPController = TextEditingController();
    _topKController = TextEditingController();
    _customToggleKeyController = TextEditingController();
    _customToggleEnabledValueController = TextEditingController();
    _customToggleDisabledValueController = TextEditingController();
    _customEffortKeyController = TextEditingController();
    _customEffortEntries = const [];
    _modelIdController.addListener(_onModelTextChanged);
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
    _modelIdController.removeListener(_onModelTextChanged);
    _providerSearchController.dispose();
    _modelIdController.dispose();
    _embeddingModelIdController.dispose();
    _compatibleContextWindowController.dispose();
    _appContextWindowController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _customToggleKeyController.dispose();
    _customToggleEnabledValueController.dispose();
    _customToggleDisabledValueController.dispose();
    _customEffortKeyController.dispose();
    super.dispose();
  }

  void _onModelTextChanged() {
    if (!mounted) {
      return;
    }
    // 中文注释: 手输模型 ID 时也要刷新保存按钮禁用态。
    setState(() {});
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
    final modelOptions = widget.viewData.allModelOptions
        .map(
          (option) => SettingsSearchOption<String>(
            value: option.value,
            label: option.label,
            note: option.note,
            providerId: option.providerId,
          ),
        )
        .where(
          (option) =>
              option.providerId.trim().isEmpty ||
              option.providerId.trim() == _providerId.trim(),
        )
        .toList(growable: false);
    final suggestedModelOptions = editor.modelSuggestions;
    final useSuggestedModelOptions =
        suggestedModelOptions.isNotEmpty && _providerId == editor.providerId;
    final visibleModelOptions = useSuggestedModelOptions
        ? suggestedModelOptions
        : modelOptions;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '首次配置建议：①「接口」页添加厂商并填 API Key → ②本页选择默认接口与模型 → ③测试连接 → ④保存。',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ModelSettingsPrimaryPanel(
          providerOptions: providerOptions,
          providerController: _providerSearchController,
          selectedProviderId: _providerId,
          modelController: _modelIdController,
          modelOptions: visibleModelOptions,
          editor: editor,
          thinkingEnabled: _thinkingEnabled,
          thinkingEffort: _thinkingEffort,
          temperatureController: _temperatureController,
          topPController: _topPController,
          onProviderSelected: (value) {
            setState(() {
              final nextProviderId = value ?? '';
              if (nextProviderId != _providerId) {
                // 中文注释: 切换接口后清空模型，避免把上一个厂商的模型 ID 误带到新接口。
                _modelIdController.clear();
              }
              _providerId = nextProviderId;
              _providerSearchController.text = _providerTitleOf(_providerId);
            });
          },
          onModelSelected: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _modelIdController.text = value;
            });
          },
          onThinkingChanged: (value) {
            setState(() {
              _thinkingEnabled = value;
            });
          },
          onThinkingEffortChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _thinkingEffort = value;
            });
          },
          onTestConnection: _testConnection,
          connectionResult: _connectionResult,
          connectionTesting: _connectionTesting,
        ),
        const SizedBox(height: 16),
        SettingsLabeledTextField(
          label: 'RAG 向量化模型 ID（可选）',
          controller: _embeddingModelIdController,
          hintText: '留空则知识库检索走关键词匹配；填写则用默认接口的该模型做向量化召回',
        ),
        const SizedBox(height: 16),
        ModelSettingsAdvancedPanel(
          editor: editor,
          compatibleContextWindowController: _compatibleContextWindowController,
          appContextWindowController: _appContextWindowController,
          topKController: _topKController,
          streamMode: _streamMode,
          apiMode: _apiMode,
          customParameters: _customParameters,
          customReasoningOverride: editor.customReasoningOverride,
          supportsReasoningOverride: _customSupportsReasoning,
          reasoningCanToggleOverride: _customReasoningCanToggle,
          reasoningDefaultEnabledOverride: _customReasoningDefaultEnabled,
          reasoningSupportsEffortOverride: _customReasoningSupportsEffort,
          toggleStrategyKindOverride: _customToggleStrategyKind,
          toggleKeyController: _customToggleKeyController,
          toggleEnabledValueController: _customToggleEnabledValueController,
          toggleDisabledValueController: _customToggleDisabledValueController,
          effortKeyController: _customEffortKeyController,
          effortEntries: _customEffortEntries,
          onStreamModeChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _streamMode = value;
            });
          },
          onApiModeChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _apiMode = value;
            });
          },
          onSupportsReasoningOverrideChanged: (value) {
            setState(() {
              _customSupportsReasoning = value;
            });
          },
          onReasoningCanToggleOverrideChanged: (value) {
            setState(() {
              _customReasoningCanToggle = value;
            });
          },
          onReasoningDefaultEnabledOverrideChanged: (value) {
            setState(() {
              _customReasoningDefaultEnabled = value;
            });
          },
          onReasoningSupportsEffortOverrideChanged: (value) {
            setState(() {
              _customReasoningSupportsEffort = value;
            });
          },
          onToggleStrategyKindOverrideChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _customToggleStrategyKind = value;
            });
          },
          onEffortEntryAdded: _addEffortEntry,
          onEffortEntryRemoved: _removeEffortEntry,
          onEffortEntryKeyChanged: _updateEffortEntryKey,
          onEffortEntryValueChanged: _updateEffortEntryValue,
          onAdded: _addCustomParameter,
          onKeyChanged: _updateCustomParameterKey,
          onTypeChanged: _updateCustomParameterType,
          onValueChanged: _updateCustomParameterValue,
          onRemoved: _removeCustomParameter,
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存模型设置',
          expanded: true,
          icon: Icons.save_outlined,
          disabled: widget.viewData.providers.isEmpty ||
              _providerId.trim().isEmpty ||
              _modelIdController.text.trim().isEmpty,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    // 中文注释: 用表单当前的"接口 + 模型"组合发起探测；壳层做本地自检 + 真联网，回传结果。
    final providerId = _providerId.trim();
    final modelId = _modelIdController.text.trim();
    if (providerId.isEmpty || modelId.isEmpty || _connectionTesting) {
      return;
    }
    final provider = widget.viewData.providers
        .where((entry) => entry.id == providerId)
        .firstOrNull;
    if (provider == null) {
      return;
    }
    final editor = widget.viewData.modelEditor;
    final payload = <String, Object?>{
      'source_id': provider.id,
      'title': provider.title,
      'protocol': provider.protocol,
      'base_url': provider.baseUrl,
      'api_key': provider.rawApiKey,
      'model_id': modelId,
      'api_mode': editor.capabilityExposure.apiMode,
    };
    setState(() {
      _connectionTesting = true;
      _connectionResult = ProviderConnectionValidationResultViewData(
        isSuccess: false,
        summary: '正在联网验证…',
        details: const <String>[],
        errors: const <String>[],
        templateId: '',
        providerId: provider.id,
        protocolId: '',
        protocolMode: provider.protocol,
        routeFamily: '',
        selectedRouteFamily: '',
        allowedRouteFamilies: const <String>[],
        hideOptions: const <String>[],
        fallbackNotAllowed: false,
        warnings: const <String>[],
        matchedTemplateId: '',
        matchedTemplateLabel: '',
      );
    });
    ProviderConnectionValidationResultViewData result;
    try {
      result = await widget.onConnectionTestRequested(payload);
    } catch (error) {
      result = ProviderConnectionValidationResultViewData(
        isSuccess: false,
        summary: '测试连接失败：$error',
        details: const <String>[],
        errors: <String>[error.toString()],
        templateId: '',
        providerId: provider.id,
        protocolId: '',
        protocolMode: provider.protocol,
        routeFamily: '',
        selectedRouteFamily: '',
        allowedRouteFamilies: const <String>[],
        hideOptions: const <String>[],
        fallbackNotAllowed: false,
        warnings: const <String>[],
        matchedTemplateId: '',
        matchedTemplateLabel: '',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _connectionTesting = false;
      _connectionResult = result;
    });
  }

  void _sync() {
    final modelSettings = widget.viewData.modelSettings;
    final editor = widget.viewData.modelEditor;
    _customEffortEntrySerial = 0;
    _providerId = _stringValue(
      modelSettings['provider_id'],
      widget.viewData.defaultProviderId,
    );
    _providerSearchController.text = _providerTitleOf(_providerId);
    _modelIdController.text = _stringValue(
      modelSettings['model_id'],
      widget.viewData.defaultModelId,
    );
    _embeddingModelIdController.text = editor.embeddingModelId;
    _compatibleContextWindowController.text =
        (modelSettings['compatible_context_window'] ?? '').toString();
    _appContextWindowController.text =
        (modelSettings['app_context_window'] ?? '').toString();
    _streamMode = (modelSettings['stream_mode'] ?? 'stream').toString();
    _apiMode = (modelSettings['api_mode'] ?? 'chat').toString();
    _thinkingEnabled = _boolValue(
      modelSettings['thinking_enabled'],
      editor.reasoningCanToggle ? editor.thinkingEnabled : true,
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
    _customSupportsReasoning = editor.customReasoningOverride.supportsReasoning;
    _customReasoningCanToggle =
        editor.customReasoningOverride.reasoningCanToggle;
    _customReasoningDefaultEnabled =
        editor.customReasoningOverride.reasoningDefaultEnabled;
    _customReasoningSupportsEffort =
        editor.customReasoningOverride.reasoningSupportsEffort;
    _customToggleStrategyKind =
        editor.customReasoningOverride.toggleStrategyKind;
    _customToggleKeyController.text = editor.customReasoningOverride.toggleKey;
    _customToggleEnabledValueController.text =
        editor.customReasoningOverride.toggleEnabledValue;
    _customToggleDisabledValueController.text =
        editor.customReasoningOverride.toggleDisabledValue;
    _customEffortKeyController.text = editor.customReasoningOverride.effortKey;
    _customEffortEntries = _initialEffortEntries(
      editor.customReasoningOverride.effortValues,
    );
  }

  void _save() {
    final providerId = _providerId.trim();
    final modelId = _modelIdController.text.trim();
    if (widget.viewData.providers.isEmpty) {
      // 中文注释: 无接口时不提交空保存，避免把 defaultProviderId 清空。
      return;
    }
    if (providerId.isEmpty || modelId.isEmpty) {
      return;
    }
    widget.onSaved(<String, Object?>{
      'default_provider_id': providerId,
      'provider_id': providerId,
      'default_model_id': modelId,
      'model_id': modelId,
      'embedding_model_id': _embeddingModelIdController.text.trim(),
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
      'custom_reasoning_override': _customReasoningOverrideDocument(
        widget.viewData.modelEditor,
      ),
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

  Map<String, Object?> _customReasoningOverrideDocument(
    ModelEditorViewData editor,
  ) {
    if (!editor.customReasoningOverride.showCustomOverrideEditor) {
      return const <String, Object?>{};
    }
    if (!_customSupportsReasoning) {
      return const <String, Object?>{'supports_reasoning': false};
    }
    final effortValues = <String, Object?>{};
    for (final entry in _customEffortEntries) {
      final key = entry.keyName.trim();
      if (key.isEmpty) {
        continue;
      }
      effortValues[key] = entry.valueText.trim();
    }
    return <String, Object?>{
      'supports_reasoning': true,
      'reasoning_can_toggle': _customReasoningCanToggle,
      'reasoning_default_enabled': _customReasoningCanToggle
          ? _customReasoningDefaultEnabled
          : true,
      'reasoning_supports_effort': _customReasoningSupportsEffort,
      'reasoning_toggle_parameter_strategy': <String, Object?>{
        'kind': _customToggleStrategyKind,
        'key': _customToggleKeyController.text.trim(),
        'enabled_value': _parseCustomReasoningValue(
          _customToggleEnabledValueController.text,
          kind: _customToggleStrategyKind,
          fallback: _customToggleStrategyKind == 'boolean' ? true : 'enabled',
        ),
        'disabled_value': _customReasoningCanToggle
            ? _parseCustomReasoningValue(
                _customToggleDisabledValueController.text,
                kind: _customToggleStrategyKind,
                fallback: _customToggleStrategyKind == 'boolean'
                    ? false
                    : 'disabled',
              )
            : null,
      },
      'reasoning_effort_parameter_strategy': _customReasoningSupportsEffort
          ? <String, Object?>{
              'key': _customEffortKeyController.text.trim(),
              'values': effortValues,
            }
          : const <String, Object?>{},
    };
  }

  List<CustomModelReasoningEffortEntryViewData> _initialEffortEntries(
    Map<String, String> values,
  ) {
    if (values.isEmpty) {
      return const <CustomModelReasoningEffortEntryViewData>[];
    }
    return values.entries
        .map(
          (entry) => CustomModelReasoningEffortEntryViewData(
            id: _nextEffortEntryId(entry.key),
            keyName: entry.key,
            valueText: entry.value,
          ),
        )
        .toList(growable: false);
  }

  String _nextEffortEntryId(String seed) {
    final cleanSeed = seed.trim().isEmpty ? 'entry' : seed.trim();
    final id = 'effort_${_customEffortEntrySerial++}_$cleanSeed';
    return id;
  }

  void _addEffortEntry() {
    setState(() {
      _customEffortEntries = <CustomModelReasoningEffortEntryViewData>[
        ..._customEffortEntries,
        CustomModelReasoningEffortEntryViewData(
          id: _nextEffortEntryId('custom'),
          keyName: '',
          valueText: '',
        ),
      ];
    });
  }

  void _removeEffortEntry(int index) {
    setState(() {
      final next = List<CustomModelReasoningEffortEntryViewData>.from(
        _customEffortEntries,
      );
      next.removeAt(index);
      _customEffortEntries = next;
    });
  }

  void _updateEffortEntryKey(int index, String value) {
    _updateEffortEntry(
      index,
      _customEffortEntries[index].copyWith(keyName: value),
    );
  }

  void _updateEffortEntryValue(int index, String value) {
    _updateEffortEntry(
      index,
      _customEffortEntries[index].copyWith(valueText: value),
    );
  }

  void _updateEffortEntry(
    int index,
    CustomModelReasoningEffortEntryViewData nextEntry,
  ) {
    setState(() {
      final next = List<CustomModelReasoningEffortEntryViewData>.from(
        _customEffortEntries,
      );
      next[index] = nextEntry;
      _customEffortEntries = next;
    });
  }

  Object? _parseCustomReasoningValue(
    String rawValue, {
    required String kind,
    required Object? fallback,
  }) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    switch (kind) {
      case 'boolean':
        return _boolValue(trimmed, ValueReaders.boolValue(fallback));
      case 'thinking_object':
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, Object?>) {
            return decoded;
          }
          if (decoded is Map) {
            return decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } catch (_) {
          return fallback;
        }
        return fallback;
      default:
        return trimmed;
    }
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
