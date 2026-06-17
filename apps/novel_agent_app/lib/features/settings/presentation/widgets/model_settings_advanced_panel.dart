import 'package:flutter/material.dart';

import '../models/custom_model_reasoning_effort_entry_view_data.dart';
import '../models/custom_model_reasoning_override_view_data.dart';
import '../models/model_editor_view_data.dart';
import '../models/model_parameter_entry_view_data.dart';
import 'custom_model_reasoning_override_form.dart';
import 'model_custom_parameter_list.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';

class ModelSettingsAdvancedPanel extends StatelessWidget {
  const ModelSettingsAdvancedPanel({
    super.key,
    required this.editor,
    required this.compatibleContextWindowController,
    required this.appContextWindowController,
    required this.topKController,
    required this.streamMode,
    required this.apiMode,
    required this.customParameters,
    required this.customReasoningOverride,
    required this.supportsReasoningOverride,
    required this.reasoningCanToggleOverride,
    required this.reasoningDefaultEnabledOverride,
    required this.reasoningSupportsEffortOverride,
    required this.toggleStrategyKindOverride,
    required this.toggleKeyController,
    required this.toggleEnabledValueController,
    required this.toggleDisabledValueController,
    required this.effortKeyController,
    required this.effortEntries,
    required this.onStreamModeChanged,
    required this.onApiModeChanged,
    required this.onSupportsReasoningOverrideChanged,
    required this.onReasoningCanToggleOverrideChanged,
    required this.onReasoningDefaultEnabledOverrideChanged,
    required this.onReasoningSupportsEffortOverrideChanged,
    required this.onToggleStrategyKindOverrideChanged,
    required this.onEffortEntryAdded,
    required this.onEffortEntryRemoved,
    required this.onEffortEntryKeyChanged,
    required this.onEffortEntryValueChanged,
    required this.onAdded,
    required this.onKeyChanged,
    required this.onTypeChanged,
    required this.onValueChanged,
    required this.onRemoved,
  });

  final ModelEditorViewData editor;
  final TextEditingController compatibleContextWindowController;
  final TextEditingController appContextWindowController;
  final TextEditingController topKController;
  final String streamMode;
  final String apiMode;
  final List<ModelParameterEntryViewData> customParameters;
  final CustomModelReasoningOverrideViewData customReasoningOverride;
  final bool supportsReasoningOverride;
  final bool reasoningCanToggleOverride;
  final bool reasoningDefaultEnabledOverride;
  final bool reasoningSupportsEffortOverride;
  final String toggleStrategyKindOverride;
  final TextEditingController toggleKeyController;
  final TextEditingController toggleEnabledValueController;
  final TextEditingController toggleDisabledValueController;
  final TextEditingController effortKeyController;
  final List<CustomModelReasoningEffortEntryViewData> effortEntries;
  final ValueChanged<String?> onStreamModeChanged;
  final ValueChanged<String?> onApiModeChanged;
  final ValueChanged<bool> onSupportsReasoningOverrideChanged;
  final ValueChanged<bool> onReasoningCanToggleOverrideChanged;
  final ValueChanged<bool> onReasoningDefaultEnabledOverrideChanged;
  final ValueChanged<bool> onReasoningSupportsEffortOverrideChanged;
  final ValueChanged<String?> onToggleStrategyKindOverrideChanged;
  final VoidCallback onEffortEntryAdded;
  final void Function(int index) onEffortEntryRemoved;
  final void Function(int index, String value) onEffortEntryKeyChanged;
  final void Function(int index, String value) onEffortEntryValueChanged;
  final VoidCallback onAdded;
  final void Function(int index, String value) onKeyChanged;
  final void Function(int index, String value) onTypeChanged;
  final void Function(int index, String value) onValueChanged;
  final void Function(int index) onRemoved;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 高级区承接运行兼容与协议细节，默认折叠，避免默认模型设置页退化成 provider 调试器。
    final visibleAdvancedFields = editor.visibleAdvancedFields;
    final showApiMode =
        editor.capabilityExposure.apiModeVisible ||
        editor.connectionValidationResult.allowedRouteFamilies.length > 1;
    final showTopK = visibleAdvancedFields.isEmpty
        ? editor.supportsTopK
        : visibleAdvancedFields.contains('top_k');
    final showStream = visibleAdvancedFields.isEmpty
        ? true
        : visibleAdvancedFields.contains('stream');
    return SettingsFormSection(
      title: '高级设置',
      description: '这里保留上下文窗口、流式模式和少数协议级参数，默认无需频繁调整。',
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 12),
            title: const Text(
              '展开高级项',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('按需调整上下文细节与高级参数。'),
            children: [
              SettingsLabeledTextField(
                label: '上下文窗口长度',
                controller: compatibleContextWindowController,
                hintText: '例如 65536',
              ),
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '应用上下文长度',
                controller: appContextWindowController,
                hintText: '例如 24000',
              ),
              const SizedBox(height: 12),
              SettingsLabeledDropdownField<String>(
                label: '流式传输',
                value: streamMode,
                options: const [
                  SettingsDropdownOption(value: 'stream', label: '流式'),
                  SettingsDropdownOption(value: 'non_stream', label: '非流式'),
                ],
                onChanged: onStreamModeChanged,
              ),
              const SizedBox(height: 12),
              if (showApiMode) ...[
                SettingsLabeledDropdownField<String>(
                  label: 'API 模式',
                  value: apiMode,
                  options:
                      (editor.capabilityExposure.allowedApiModes.isNotEmpty
                              ? editor.capabilityExposure.allowedApiModes
                              : editor
                                    .connectionValidationResult
                                    .allowedRouteFamilies)
                          .map(
                            (mode) => SettingsDropdownOption<String>(
                              value: mode,
                              label: mode == 'responses'
                                  ? 'Responses API'
                                  : '聊天 API',
                            ),
                          )
                          .toList(growable: false),
                  onChanged: onApiModeChanged,
                ),
                const SizedBox(height: 12),
              ],
              if (showTopK) ...[
                const SizedBox(height: 12),
                SettingsLabeledTextField(
                  label: 'Top K',
                  controller: topKController,
                  hintText: '例如 40',
                  keyboardType: TextInputType.number,
                ),
              ],
              if (showStream) const SizedBox(height: 0),
              if (customReasoningOverride.showCustomOverrideEditor) ...[
                const SizedBox(height: 16),
                CustomModelReasoningOverrideForm(
                  viewData: customReasoningOverride,
                  supportsReasoning: supportsReasoningOverride,
                  reasoningCanToggle: reasoningCanToggleOverride,
                  reasoningDefaultEnabled: reasoningDefaultEnabledOverride,
                  reasoningSupportsEffort: reasoningSupportsEffortOverride,
                  toggleStrategyKind: toggleStrategyKindOverride,
                  toggleKeyController: toggleKeyController,
                  toggleEnabledValueController: toggleEnabledValueController,
                  toggleDisabledValueController: toggleDisabledValueController,
                  effortKeyController: effortKeyController,
                  effortEntries: effortEntries,
                  onSupportsReasoningChanged:
                      onSupportsReasoningOverrideChanged,
                  onReasoningCanToggleChanged:
                      onReasoningCanToggleOverrideChanged,
                  onReasoningDefaultEnabledChanged:
                      onReasoningDefaultEnabledOverrideChanged,
                  onReasoningSupportsEffortChanged:
                      onReasoningSupportsEffortOverrideChanged,
                  onToggleStrategyKindChanged:
                      onToggleStrategyKindOverrideChanged,
                  onEffortEntryAdded: onEffortEntryAdded,
                  onEffortEntryRemoved: onEffortEntryRemoved,
                  onEffortEntryKeyChanged: onEffortEntryKeyChanged,
                  onEffortEntryValueChanged: onEffortEntryValueChanged,
                ),
              ],
              const SizedBox(height: 16),
              ModelCustomParameterList(
                entries: customParameters,
                onAdded: onAdded,
                onKeyChanged: onKeyChanged,
                onTypeChanged: onTypeChanged,
                onValueChanged: onValueChanged,
                onRemoved: onRemoved,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
