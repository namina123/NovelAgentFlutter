import 'package:flutter/material.dart';

import '../models/custom_model_reasoning_override_view_data.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';
import 'settings_switch_row.dart';

class CustomModelReasoningOverrideForm extends StatelessWidget {
  const CustomModelReasoningOverrideForm({
    super.key,
    required this.viewData,
    required this.supportsReasoning,
    required this.reasoningCanToggle,
    required this.reasoningDefaultEnabled,
    required this.reasoningSupportsEffort,
    required this.toggleStrategyKind,
    required this.toggleKeyController,
    required this.toggleEnabledValueController,
    required this.toggleDisabledValueController,
    required this.effortKeyController,
    required this.effortValueControllers,
    required this.onSupportsReasoningChanged,
    required this.onReasoningCanToggleChanged,
    required this.onReasoningDefaultEnabledChanged,
    required this.onReasoningSupportsEffortChanged,
    required this.onToggleStrategyKindChanged,
  });

  final CustomModelReasoningOverrideViewData viewData;
  final bool supportsReasoning;
  final bool reasoningCanToggle;
  final bool reasoningDefaultEnabled;
  final bool reasoningSupportsEffort;
  final String toggleStrategyKind;
  final TextEditingController toggleKeyController;
  final TextEditingController toggleEnabledValueController;
  final TextEditingController toggleDisabledValueController;
  final TextEditingController effortKeyController;
  final Map<String, TextEditingController> effortValueControllers;
  final ValueChanged<bool> onSupportsReasoningChanged;
  final ValueChanged<bool> onReasoningCanToggleChanged;
  final ValueChanged<bool> onReasoningDefaultEnabledChanged;
  final ValueChanged<bool> onReasoningSupportsEffortChanged;
  final ValueChanged<String?> onToggleStrategyKindChanged;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 自定义 reasoning 兜底表单只服务未知模型，避免已知模型也把用户拖进协议细节。
    if (!viewData.showCustomOverrideEditor) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自定义深度思考协议',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          '当前模型未命中内置写作模型列表时，可在这里补充深度思考参数协议。',
          style: TextStyle(fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 12),
        SettingsSwitchRow(
          label: '支持深度思考',
          value: supportsReasoning,
          onChanged: onSupportsReasoningChanged,
          note: '关闭后不会发送任何深度思考相关参数。',
        ),
        if (supportsReasoning) ...[
          const SizedBox(height: 12),
          SettingsSwitchRow(
            label: '允许开关',
            value: reasoningCanToggle,
            onChanged: onReasoningCanToggleChanged,
            note: '关闭后视为模型始终处于思考模式。',
          ),
          if (reasoningCanToggle) ...[
            const SizedBox(height: 12),
            SettingsSwitchRow(
              label: '默认开启',
              value: reasoningDefaultEnabled,
              onChanged: onReasoningDefaultEnabledChanged,
            ),
            const SizedBox(height: 12),
            SettingsLabeledDropdownField<String>(
              label: '开关参数类型',
              value: toggleStrategyKind,
              options: const [
                SettingsDropdownOption(value: 'boolean', label: '布尔值'),
                SettingsDropdownOption(value: 'custom_text', label: '文本值'),
                SettingsDropdownOption(value: 'thinking_object', label: '对象值'),
              ],
              onChanged: onToggleStrategyKindChanged,
            ),
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: '开关键名',
              controller: toggleKeyController,
              hintText: '例如 enable_thinking',
            ),
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: '开启时传值',
              controller: toggleEnabledValueController,
              hintText: toggleStrategyKind == 'thinking_object'
                  ? '{"type":"enabled"}'
                  : '例如 true / enabled',
            ),
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: '关闭时传值',
              controller: toggleDisabledValueController,
              hintText: toggleStrategyKind == 'thinking_object'
                  ? '{"type":"disabled"}'
                  : '例如 false / disabled',
            ),
          ],
          if (!reasoningCanToggle)
            const Text(
              '当前会按“始终思考”处理，不需要额外填写开关参数。',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
          const SizedBox(height: 12),
          SettingsSwitchRow(
            label: '支持强度调节',
            value: reasoningSupportsEffort,
            onChanged: onReasoningSupportsEffortChanged,
          ),
          if (reasoningSupportsEffort) ...[
            const SizedBox(height: 12),
            SettingsLabeledTextField(
              label: '强度键名',
              controller: effortKeyController,
              hintText: '例如 reasoning_effort',
            ),
            for (final option in const [
              'auto',
              'low',
              'medium',
              'high',
              'max',
            ]) ...[
              const SizedBox(height: 12),
              SettingsLabeledTextField(
                label: '$option 传值',
                controller: effortValueControllers[option],
                hintText: option,
              ),
            ],
          ],
        ],
      ],
    );
  }
}
