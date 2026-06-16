import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_view_data.dart';
import 'workbench_visual_style.dart';

class DocumentTabStrip extends StatelessWidget {
  const DocumentTabStrip({
    super.key,
    required this.documents,
    required this.onSelected,
    required this.onClosed,
  });

  final List<DocumentTabViewData> documents;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onClosed;

  @override
  Widget build(BuildContext context) {
    final panelSurface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
        itemCount: documents.length,
        separatorBuilder: (_, index) => const SizedBox(width: 1),
        itemBuilder: (context, index) {
          final document = documents[index];
          final isActive = document.isActive;
          final foreground = isActive
              ? panelSurface.foregroundColor
              : panelSurface.mutedForegroundColor;
          final descriptor = document.tooltip.trim().isNotEmpty
              ? document.tooltip
              : (document.relativePath.trim().isEmpty
                    ? document.title
                    : document.relativePath);
          return Tooltip(
            message: descriptor,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(document.id),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 104,
                    maxWidth: 220,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive
                            ? colors.accentColor.withValues(alpha: 0.9)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4, top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 12,
                          color: foreground.withValues(
                            alpha: isActive ? 0.86 : 0.58,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: document.isDirty
                                ? colors.accentColor
                                : foreground.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            document.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: visual.compactLabelFontSize - 0.1,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: '关闭',
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 18,
                            height: 18,
                          ),
                          onPressed: () => onClosed(document.id),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: foreground.withValues(
                              alpha: isActive ? 0.68 : 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
