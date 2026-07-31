import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/model_parameter_entry_view_data.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_labeled_text_field.dart';

class ModelCustomParameterRow extends StatelessWidget {
  const ModelCustomParameterRow({
    super.key,
    required this.entry,
    required this.onKeyChanged,
    required this.onTypeChanged,
    required this.onValueChanged,
    required this.onRemoved,
  });

  final ModelParameterEntryViewData entry;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单条高级参数行只负责字段编辑，不承担列表增删和保存编解码职责。
    final typeOptions = const <SettingsDropdownOption<String>>[
      SettingsDropdownOption(value: 'string', label: '字符串'),
      SettingsDropdownOption(value: 'number', label: '数字'),
      SettingsDropdownOption(value: 'integer', label: '整数'),
      SettingsDropdownOption(value: 'boolean', label: '布尔'),
      SettingsDropdownOption(value: 'json', label: 'JSON'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: SettingsLabeledTextField(
                  label: '参数键',
                  initialValue: entry.keyName,
                  hintText: '例如 max_tokens',
                  onChanged: onKeyChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SettingsLabeledDropdownField<String>(
                  label: '类型',
                  value: entry.valueType,
                  options: typeOptions,
                  onChanged: (value) => onTypeChanged(value ?? 'string'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: entry.valueType == 'boolean'
                    ? SettingsLabeledDropdownField<String>(
                        label: '值',
                        value: entry.valueText().isEmpty
                            ? 'false'
                            : entry.valueText().toLowerCase(),
                        options: const [
                          SettingsDropdownOption(value: 'true', label: 'true'),
                          SettingsDropdownOption(
                            value: 'false',
                            label: 'false',
                          ),
                        ],
                        onChanged: (value) => onValueChanged(value ?? 'false'),
                      )
                    : SettingsLabeledTextField(
                        label: '值',
                        initialValue: entry.valueText(),
                        hintText: entry.valueType == 'json'
                            ? '{"key":"value"}'
                            : '输入默认值',
                        onChanged: onValueChanged,
                      ),
              ),
              const SizedBox(width: 12),
              ActionButton(
                label: '删除',
                compact: true,
                icon: Icons.delete_outline,
                tone: ActionButtonTone.danger,
                onPressed: onRemoved,
              ),
            ],
          );
        }
        return Column(
          children: [
            SettingsLabeledTextField(
              label: '参数键',
              initialValue: entry.keyName,
              hintText: '例如 max_tokens',
              onChanged: onKeyChanged,
            ),
            const SizedBox(height: 12),
            SettingsLabeledDropdownField<String>(
              label: '类型',
              value: entry.valueType,
              options: typeOptions,
              onChanged: (value) => onTypeChanged(value ?? 'string'),
            ),
            const SizedBox(height: 12),
            entry.valueType == 'boolean'
                ? SettingsLabeledDropdownField<String>(
                    label: '值',
                    value: entry.valueText().isEmpty
                        ? 'false'
                        : entry.valueText().toLowerCase(),
                    options: const [
                      SettingsDropdownOption(value: 'true', label: 'true'),
                      SettingsDropdownOption(value: 'false', label: 'false'),
                    ],
                    onChanged: (value) => onValueChanged(value ?? 'false'),
                  )
                : SettingsLabeledTextField(
                    label: '值',
                    initialValue: entry.valueText(),
                    hintText: entry.valueType == 'json'
                        ? '{"key":"value"}'
                        : '输入默认值',
                    onChanged: onValueChanged,
                  ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ActionButton(
                label: '删除',
                compact: true,
                icon: Icons.delete_outline,
                tone: ActionButtonTone.danger,
                onPressed: onRemoved,
              ),
            ),
          ],
        );
      },
    );
  }
}
