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
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: panelSurface.backgroundColor.withValues(alpha: 0.06),
          border: Border(
            bottom: BorderSide(
              color: panelSurface.borderColor.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
          itemCount: documents.length,
          separatorBuilder: (_, index) => const SizedBox(width: 2),
          itemBuilder: (context, index) {
            final document = documents[index];
            final isActive = document.isActive;
            final background = isActive
                ? panelSurface.backgroundColor.withValues(alpha: 0.96)
                : Colors.transparent;
            final foreground = isActive
                ? panelSurface.foregroundColor
                : panelSurface.mutedForegroundColor;
            final descriptor = document.relativePath.trim().isEmpty
                ? document.title
                : document.relativePath;
            return Tooltip(
              message: descriptor,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(document.id),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(visual.sectionRadius),
                    topRight: Radius.circular(visual.sectionRadius),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 112,
                      maxWidth: 224,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(visual.sectionRadius),
                        topRight: Radius.circular(visual.sectionRadius),
                      ),
                      border: isActive
                          ? Border(
                              top: BorderSide(
                                color: panelSurface.borderColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              left: BorderSide(
                                color: panelSurface.borderColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              right: BorderSide(
                                color: panelSurface.borderColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            )
                          : Border(
                              top: BorderSide(
                                color: panelSurface.borderColor.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 9, right: 5, top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 12,
                            color: foreground.withValues(
                              alpha: isActive ? 0.88 : 0.64,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: document.isDirty
                                  ? colors.accentColor
                                  : foreground.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              document.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: visual.compactLabelFontSize - 0.05,
                                letterSpacing: 0.01,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
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
                                alpha: isActive ? 0.74 : 0.56,
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
      ),
    );
  }
}
