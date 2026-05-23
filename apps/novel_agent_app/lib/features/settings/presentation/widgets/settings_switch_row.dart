import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.note = '',
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String note;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 布尔型设置统一使用这一层，保证说明文字、开关和间距在不同页签里一致。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              if (note.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
