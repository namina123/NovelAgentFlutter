import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../models/project_type_option_view_data.dart';

class ProjectTypeOptionTile extends StatelessWidget {
  const ProjectTypeOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectTypeOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目类型条目只负责展示和选中状态，避免创建面板自己堆叠过多视觉细节。
    final borderColor = isSelected ? AppPalette.accent : AppPalette.line;
    final titleColor = isSelected ? AppPalette.accent : AppPalette.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          color: isSelected
              ? AppPalette.accentSoft.withValues(alpha: 0.55)
              : AppPalette.panel,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.4),
                color: isSelected ? AppPalette.accent : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: AppPalette.mutedText,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
