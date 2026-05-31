import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

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
    final surface = context.novelThemeSurfaces.panel;
    return Container(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.76),
        border: Border.all(
          color: surface.borderColor,
          width: surface.borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: surface.foregroundColor,
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: surface.mutedForegroundColor,
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
