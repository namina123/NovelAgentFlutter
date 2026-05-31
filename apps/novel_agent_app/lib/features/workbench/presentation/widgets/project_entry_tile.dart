import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/project_entry_view_data.dart';

class ProjectEntryTile extends StatelessWidget {
  const ProjectEntryTile({
    super.key,
    required this.entry,
    required this.onOpen,
  });

  final ProjectEntryViewData entry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单个项目条目只负责展示和打开动作，不关心弹层模式和创建流程。
    final colors = context.novelThemeColors;
    final cardChrome = context.novelCardChrome;
    return Material(
      color: colors.panelBackground,
      borderRadius: BorderRadius.circular(cardChrome.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(cardChrome.radius),
        onTap: () => onOpen(entry.path),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardChrome.radius),
            border: Border.all(
              color: colors.lineColor,
              width: cardChrome.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.path,
                style: TextStyle(
                  color: colors.mutedTextColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
