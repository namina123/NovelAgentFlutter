import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../models/settings_search_option.dart';

class SettingsLabeledSearchDropdownField<T> extends StatelessWidget {
  const SettingsLabeledSearchDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.controller,
    this.selectedValue,
    this.hintText = '',
    this.enabled = true,
    this.onSelected,
  });

  final String label;
  final List<SettingsSearchOption<T>> options;
  final TextEditingController controller;
  final T? selectedValue;
  final String hintText;
  final bool enabled;
  final ValueChanged<T?>? onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 这个搜索下拉控件统一承担“可输入 + 静态筛选 + 可选中”的设置页交互。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppPalette.mutedText,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<T>(
              controller: controller,
              enabled: enabled,
              initialSelection: selectedValue,
              width: constraints.maxWidth,
              requestFocusOnTap: true,
              enableSearch: true,
              enableFilter: true,
              hintText: hintText,
              onSelected: onSelected,
              dropdownMenuEntries: options
                  .map(
                    (option) => DropdownMenuEntry<T>(
                      value: option.value,
                      label: option.label,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}
