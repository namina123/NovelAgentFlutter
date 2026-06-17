import 'package:flutter/material.dart';

import '../models/model_editor_view_data.dart';
import '../models/settings_search_option.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_search_dropdown_field.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class ModelSettingsPrimaryPanel extends StatelessWidget {
  const ModelSettingsPrimaryPanel({
    super.key,
    required this.providerOptions,
    required this.providerController,
    required this.selectedProviderId,
    required this.modelController,
    required this.modelOptions,
    required this.editor,
    required this.thinkingEnabled,
    required this.thinkingEffort,
    required this.temperatureController,
    required this.topPController,
    required this.onProviderSelected,
    required this.onModelSelected,
    required this.onThinkingChanged,
    required this.onThinkingEffortChanged,
  });

  final List<SettingsSearchOption<String>> providerOptions;
  final TextEditingController providerController;
  final String selectedProviderId;
  final TextEditingController modelController;
  final List<SettingsSearchOption<String>> modelOptions;
  final ModelEditorViewData editor;
  final bool thinkingEnabled;
  final String thinkingEffort;
  final TextEditingController temperatureController;
  final TextEditingController topPController;
  final ValueChanged<String?> onProviderSelected;
  final ValueChanged<String?> onModelSelected;
  final ValueChanged<bool> onThinkingChanged;
  final ValueChanged<String?> onThinkingEffortChanged;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 主设置区只放写作时最常碰的模型选择与四个高价值参数，不把运行兼容细节掺进来。
    final visibleAdvancedFields = editor.visibleAdvancedFields;
    final showsReasoning = visibleAdvancedFields.isEmpty
        ? editor.supportsReasoning
        : visibleAdvancedFields.contains('thinking_enabled');
    final showsEffort = visibleAdvancedFields.isEmpty
        ? editor.supportsReasoning && editor.thinkingEffortSupported
        : visibleAdvancedFields.contains('thinking_effort');
    return SettingsFormSection(
      title: '写作模型',
      description: '选择默认接口与写作模型，并设置写作时最常调整的默认参数。',
      child: Column(
        children: [
          SettingsLabeledSearchDropdownField<String>(
            label: '接口',
            controller: providerController,
            selectedValue: selectedProviderId.isEmpty
                ? null
                : selectedProviderId,
            options: providerOptions,
            hintText: '输入接口名称筛选',
            onSelected: onProviderSelected,
          ),
          const SizedBox(height: 12),
          SettingsLabeledSearchDropdownField<String>(
            label: '模型',
            controller: modelController,
            selectedValue: null,
            options: modelOptions,
            hintText: '输入模型名称或型号筛选，也可以直接选择',
            onSelected: onModelSelected,
          ),
          if (showsReasoning) ...[
            const SizedBox(height: 16),
            if (editor.reasoningCanToggle)
              SettingsSwitchRow(
                label: '启用深度思考',
                value: thinkingEnabled,
                onChanged: onThinkingChanged,
                note: editor.thinkingParameterLabel,
              )
            else
              const SettingsSwitchRow(
                label: '深度思考',
                value: true,
                onChanged: null,
                note: '当前模型始终启用',
              ),
          ],
          if (showsEffort) ...[
            const SizedBox(height: 12),
            SettingsLabeledDropdownField<String>(
              label: editor.thinkingEffortParameterLabel,
              value: thinkingEffort,
              options: editor.thinkingEffortOptions
                  .map(
                    (item) => SettingsDropdownOption<String>(
                      value: item,
                      label: item,
                    ),
                  )
                  .toList(growable: false),
              onChanged: onThinkingEffortChanged,
            ),
          ],
          if (editor.supportsTemperature) ...[
            const SizedBox(height: 16),
            SettingsLabeledTextField(
              label: '温度',
              controller: temperatureController,
              hintText: '例如 0.8',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          if (editor.supportsTopP) ...[
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: 'Top P',
              controller: topPController,
              hintText: '例如 0.95',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
