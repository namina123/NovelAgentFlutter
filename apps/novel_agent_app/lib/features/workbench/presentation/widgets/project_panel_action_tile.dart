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
    this.showDescription = true,
    this.isEnabled = true,
    this.disabledReason = '',
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;
  final bool showDescription;
  final bool isEnabled;
  final String disabledReason;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目动作条目改成更像命令面板列表项，减少“功能卡片”味道。
    final surface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    final effectiveOnPressed = isEnabled ? onPressed : null;
    final tooltipMessage = isEnabled || disabledReason.trim().isEmpty
        ? title
        : disabledReason;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltipMessage,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.58,
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: surface.backgroundColor.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  top: BorderSide(
                    color: surface.borderColor.withValues(alpha: 0.28),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: surface.highlightBackgroundColor.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 14, color: surface.foregroundColor),
                  ),
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
                        if (showDescription &&
                            description.trim().isNotEmpty) ...[
                          SizedBox(height: visual.microGap - 1),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: visual.bodyFontSize,
                              height: visual.bodyLineHeight,
                              fontWeight: FontWeight.w500,
                              color: surface.mutedForegroundColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: surface.mutedForegroundColor.withValues(alpha: 0.82),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
