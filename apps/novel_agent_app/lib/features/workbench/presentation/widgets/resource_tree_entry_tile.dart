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
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final panelSurface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final foreground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.foregroundColor;
    final mutedForeground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.mutedForegroundColor;
    final background = entry.isSelected
        ? optionSurface.highlightBackgroundColor.withValues(alpha: 0.14)
        : panelSurface.backgroundColor.withValues(alpha: 0.01);
    final borderColor = entry.isSelected
        ? optionSurface.highlightBorderColor.withValues(alpha: 0.14)
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
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _DepthGuides(
                    depth: entry.depth,
                    color: panelSurface.borderColor.withValues(alpha: 0.045),
                  ),
                  SizedBox(width: entry.depth > 0 ? 1 : 0),
                  SizedBox(
                    width: 16,
                    child: chevron == null
                        ? const SizedBox.shrink()
                        : Icon(chevron, size: 14, color: mutedForeground),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    entry.isDirectory
                        ? (entry.isExpanded
                              ? Icons.folder_open_outlined
                              : Icons.folder_outlined)
                        : Icons.description_outlined,
                    size: 15,
                    color: entry.isDirectory
                        ? colors.accentColor.withValues(
                            alpha: entry.isSelected ? 0.9 : 0.62,
                          )
                        : mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.2,
                              fontWeight: entry.isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: foreground,
                            ),
                          ),
                        ),
                        if (entry.isDirectory && entry.childCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: panelSurface.backgroundColor.withValues(
                                alpha: entry.isSelected ? 0.18 : 0.06,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${entry.childCount}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (entry.isSelected)
              Positioned(
                left: 2,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: colors.accentColor.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DepthGuides extends StatelessWidget {
  const _DepthGuides({required this.depth, required this.color});

  final int depth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) {
      return const SizedBox(width: 4);
    }
    return SizedBox(
      width: depth * 9,
      child: Row(
        children: List.generate(
          depth,
          (_) => Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(width: 1, height: 14, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
