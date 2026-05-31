import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

class ProjectPanelActionTile extends StatelessWidget {
  const ProjectPanelActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目动作条目统一使用轻量行项，避免左栏再长出“卡片里套卡片”的次级导航。
    final surface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: surface.foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: visual.sectionTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: surface.foregroundColor,
                      ),
                    ),
                    SizedBox(height: visual.microGap - 1),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: visual.bodyFontSize,
                        height: visual.bodyLineHeight,
                        fontWeight: FontWeight.w600,
                        color: surface.mutedForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: surface.mutedForegroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
