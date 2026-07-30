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
    // 中文注释: 禁用态走真正的「置灰」配色（与 ActionButton 一致），而非 Opacity 半透明——
    // 后者看起来仍像可点，且不会被无障碍工具正确识别为不可用。
    final tileForeground =
        isEnabled ? surface.foregroundColor : surface.mutedForegroundColor;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltipMessage,
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: surface.backgroundColor.withValues(
                alpha: isEnabled ? 0.26 : 0.12,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                top: BorderSide(
                  color: surface.borderColor.withValues(
                    alpha: isEnabled ? 0.28 : 0.14,
                  ),
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
                      alpha: isEnabled ? 0.3 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: tileForeground),
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
                          color: tileForeground,
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
                  color: surface.mutedForegroundColor.withValues(
                    alpha: isEnabled ? 0.82 : 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
