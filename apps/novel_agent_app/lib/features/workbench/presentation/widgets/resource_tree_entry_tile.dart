import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/resource_tree_entry_semantic_view_data.dart';
import '../models/workbench_view_data.dart';

class ResourceTreeEntryTile extends StatelessWidget {
  const ResourceTreeEntryTile({
    super.key,
    required this.entry,
    required this.onPressed,
    this.semantic = const ResourceTreeEntrySemanticViewData(
      detailLabel: '',
      leadingIcon: Icons.description_outlined,
    ),
  });

  final ResourceEntryViewData entry;
  final ResourceTreeEntrySemanticViewData semantic;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final panelSurface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final hasSecondaryLabel = semantic.detailLabel.trim().isNotEmpty;
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
    final toneColor = _toneColor(colors.accentColor);
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
              constraints: BoxConstraints(
                minHeight: hasSecondaryLabel ? 40 : 32,
              ),
              padding: EdgeInsets.fromLTRB(
                8,
                hasSecondaryLabel ? 4 : 3,
                8,
                hasSecondaryLabel ? 4 : 3,
              ),
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
                    semantic.leadingIcon,
                    size: 15,
                    color: entry.isSelected
                        ? foreground
                        : toneColor.withValues(
                            alpha: entry.isDirectory ? 0.92 : 0.84,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                                  if (semantic.hasBadge) ...[
                                    const SizedBox(width: 6),
                                    _SemanticBadge(
                                      label: semantic.badgeLabel,
                                      toneColor: toneColor,
                                      selected: entry.isSelected,
                                      foreground: foreground,
                                      mutedForeground: mutedForeground,
                                    ),
                                  ],
                                ],
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
                                  color: panelSurface.backgroundColor
                                      .withValues(
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
                        if (semantic.detailLabel.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            semantic.detailLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: mutedForeground,
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

  Color _toneColor(Color accentColor) {
    switch (semantic.tone) {
      case ResourceTreeSemanticTone.blue:
        return const Color(0xFF4C7DFF);
      case ResourceTreeSemanticTone.teal:
        return const Color(0xFF0E8E7A);
      case ResourceTreeSemanticTone.amber:
        return const Color(0xFFB7791F);
      case ResourceTreeSemanticTone.green:
        return const Color(0xFF2F855A);
      case ResourceTreeSemanticTone.purple:
        return const Color(0xFF6B46C1);
      case ResourceTreeSemanticTone.rose:
        return const Color(0xFFB83280);
      case ResourceTreeSemanticTone.neutral:
        return accentColor;
    }
  }
}

class _SemanticBadge extends StatelessWidget {
  const _SemanticBadge({
    required this.label,
    required this.toneColor,
    required this.selected,
    required this.foreground,
    required this.mutedForeground,
  });

  final String label;
  final Color toneColor;
  final bool selected;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: selected
            ? foreground.withValues(alpha: 0.1)
            : toneColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? foreground.withValues(alpha: 0.12)
              : toneColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.2,
          fontWeight: FontWeight.w700,
          color: selected ? foreground : mutedForeground,
          height: 1.1,
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
