import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_view_data.dart';

class ResourceTreeEntryTile extends StatelessWidget {
  const ResourceTreeEntryTile({
    super.key,
    required this.entry,
    required this.onPressed,
  });

  final ResourceEntryViewData entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 目录树行单独拆出后，后续要继续收窄行高、换树控件或加拖拽，都不用回头碰整个目录卡片。
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final panelSurface = context.novelThemeSurfaces.panel;
    final foreground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.foregroundColor;
    final mutedForeground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.mutedForegroundColor;
    final background = entry.isSelected
        ? optionSurface.highlightBackgroundColor
        : Colors.transparent;
    final borderColor = entry.isSelected
        ? optionSurface.highlightBorderColor
        : Colors.transparent;
    final chevron = entry.isDirectory
        ? (entry.hasChildren
              ? (entry.isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded)
              : Icons.chevron_right_rounded)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: EdgeInsets.only(
            left: 8 + (entry.depth * 14),
            right: 8,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: chevron == null
                    ? const SizedBox.shrink()
                    : Icon(chevron, size: 16, color: mutedForeground),
              ),
              const SizedBox(width: 2),
              Icon(
                entry.isDirectory
                    ? Icons.folder_outlined
                    : Icons.description_outlined,
                size: 15,
                color: mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.isDirectory
                      ? '${entry.title}(${entry.childCount})'
                      : entry.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: entry.isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
