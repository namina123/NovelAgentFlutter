import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/model_parameter_entry_view_data.dart';
import 'model_custom_parameter_row.dart';

class ModelCustomParameterList extends StatelessWidget {
  const ModelCustomParameterList({
    super.key,
    required this.entries,
    required this.onAdded,
    required this.onKeyChanged,
    required this.onTypeChanged,
    required this.onValueChanged,
    required this.onRemoved,
  });

  final List<ModelParameterEntryViewData> entries;
  final VoidCallback onAdded;
  final void Function(int index, String value) onKeyChanged;
  final void Function(int index, String value) onTypeChanged;
  final void Function(int index, String value) onValueChanged;
  final void Function(int index) onRemoved;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 高级参数列表统一收口在这里，避免主面板文件被动态行编辑细节淹没。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          ModelCustomParameterRow(
            entry: entries[index],
            onKeyChanged: (value) => onKeyChanged(index, value),
            onTypeChanged: (value) => onTypeChanged(index, value),
            onValueChanged: (value) => onValueChanged(index, value),
            onRemoved: () => onRemoved(index),
          ),
          if (index < entries.length - 1) const SizedBox(height: 14),
        ],
        const SizedBox(height: 12),
        ActionButton(
          label: '添加高级参数',
          compact: true,
          icon: Icons.add_rounded,
          tone: ActionButtonTone.neutral,
          onPressed: onAdded,
        ),
      ],
    );
  }
}
