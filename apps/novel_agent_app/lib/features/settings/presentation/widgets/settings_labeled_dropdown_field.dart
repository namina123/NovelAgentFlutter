import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class SettingsDropdownOption<T> {
  const SettingsDropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class SettingsLabeledDropdownField<T> extends StatelessWidget {
  const SettingsLabeledDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<SettingsDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置下拉框独立封装，后续替换成搜索选择器时不用改各个设置页本身的结构。
    final surface = context.novelThemeSurfaces.panel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
