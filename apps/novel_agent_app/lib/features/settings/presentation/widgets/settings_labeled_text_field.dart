import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_palette.dart';

class SettingsLabeledTextField extends StatelessWidget {
  const SettingsLabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText = '',
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置文本输入统一在这里处理标签和输入框的排布，减少每个设置面板的重复样板代码。
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
        controller != null
            ? TextField(
                controller: controller,
                enabled: enabled,
                maxLines: maxLines,
                keyboardType: keyboardType,
                obscureText: obscureText,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(hintText: hintText),
              )
            : TextFormField(
                initialValue: initialValue,
                enabled: enabled,
                maxLines: maxLines,
                keyboardType: keyboardType,
                obscureText: obscureText,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(hintText: hintText),
              ),
      ],
    );
  }
}
