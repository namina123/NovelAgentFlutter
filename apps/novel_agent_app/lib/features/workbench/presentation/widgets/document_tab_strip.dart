import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_view_data.dart';

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
    // 中文注释: 文档标签独立成组件，后续如果切换为可关闭标签或滚动标签条时不动外层页面。
    final panelSurface = context.novelThemeSurfaces.panel;
    final optionSurface = context.novelThemeSurfaces.optionTile;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: documents.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final document = documents[index];
          final background = document.isActive
              ? optionSurface.highlightBackgroundColor
              : panelSurface.backgroundColor.withValues(alpha: 0.72);
          final foreground = document.isActive
              ? optionSurface.highlightForegroundColor
              : panelSurface.foregroundColor;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(document.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(optionSurface.radius),
                  border: document.isActive
                      ? Border.all(color: optionSurface.highlightBorderColor)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (document.isDirty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.circle, size: 8, color: foreground),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          document.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: document.isActive
                                ? FontWeight.w800
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
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () => onClosed(document.id),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: foreground,
                        ),
                      ),
                    ],
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
