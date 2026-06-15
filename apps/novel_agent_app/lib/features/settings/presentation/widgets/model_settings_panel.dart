import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/custom_model_reasoning_effort_entry_view_data.dart';
import '../models/model_editor_view_data.dart';
import '../models/model_parameter_entry_view_data.dart';
import '../models/settings_search_option.dart';
import '../models/settings_view_data.dart';
import 'model_settings_advanced_panel.dart';
import 'model_settings_primary_panel.dart';

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
    _customToggleKeyController = TextEditingController();
    _customToggleEnabledValueController = TextEditingController();
    _customToggleDisabledValueController = TextEditingController();
    _customEffortKeyController = TextEditingController();
    _customEffortEntries = const [];
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
    _customToggleKeyController.dispose();
    _customToggleEnabledValueController.dispose();
    _customToggleDisabledValueController.dispose();
    _customEffortKeyController.dispose();
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
    final modelOptions = widget.viewData.allModelOptions
        .map(
          (option) => SettingsSearchOption<String>(
            value: option.value,
            label: option.label,
            note: option.note,
          ),
        )
        .toList(growable: false);
    final editor = widget.viewData.modelEditor;
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
          '首次配置建议：先到“接口”页填写 API Key 并点击“测试连接”，确认无误后再回来保存默认模型。',
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
              _providerId = value ?? '';
            });
          },
          onModelSelected: (value) {
            if (value == null) {
              return;
            }
            _modelIdController.text = value;
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
          onPressed: _save,
        ),
      ],
    );
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
    widget.onSaved(<String, Object?>{
      'default_provider_id': _providerId,
      'provider_id': _providerId,
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
