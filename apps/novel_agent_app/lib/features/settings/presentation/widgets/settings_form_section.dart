import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

class SettingsFormSection extends StatelessWidget {
  const SettingsFormSection({
    super.key,
    required this.title,
    required this.child,
    this.description = '',
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 设置表单分区统一收口，避免每个设置子页分别维护标题、边框和说明样式。
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppPalette.text,
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppPalette.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
