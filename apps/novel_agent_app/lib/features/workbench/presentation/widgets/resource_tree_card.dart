import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/workbench_view_data.dart';

class ResourceTreeCard extends StatelessWidget {
  const ResourceTreeCard({
    super.key,
    required this.entries,
    required this.onEntrySelected,
  });

  final List<ResourceEntryViewData> entries;
  final ValueChanged<String> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文件树列表单独封装后，后续切到树控件或虚拟滚动时不需要碰资源面板外层结构。
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.66);
    final lineColor = isDark ? theme.colorScheme.outline : AppPalette.line;
    final textColor = isDark ? theme.colorScheme.onSurface : AppPalette.text;
    final mutedTextColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.72)
        : AppPalette.mutedText;
    final accentColor = isDark
        ? theme.colorScheme.primary
        : AppPalette.lineStrong;
    if (entries.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppChrome.surfaceBorderRadius,
          border: Border.all(color: lineColor, width: AppChrome.borderWidth),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              '当前项目还没有目录内容。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: mutedTextColor,
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: lineColor, width: AppChrome.borderWidth),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: entries.length,
        separatorBuilder: (_, index) => Divider(height: 1, color: lineColor),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              minTileHeight: 34,
              minLeadingWidth: 18,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
              contentPadding: EdgeInsets.only(
                left: 10 + (entry.depth * 14),
                right: 10,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.isDirectory)
                    Icon(
                      entry.hasChildren
                          ? (entry.isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded)
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: entry.isSelected ? accentColor : mutedTextColor,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 2),
                  Icon(
                    entry.isDirectory
                        ? Icons.folder_outlined
                        : Icons.description_outlined,
                    size: 16,
                    color: entry.isSelected ? accentColor : mutedTextColor,
                  ),
                ],
              ),
              title: Text(
                entry.isDirectory
                    ? '${entry.title}(${entry.childCount})'
                    : entry.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: entry.isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: entry.isSelected ? accentColor : textColor,
                ),
              ),
              onTap: () {
                // 中文注释: 条目点击只上报 id，让外层决定是展开目录还是打开文档。
                onEntrySelected(entry.id);
              },
            ),
          );
        },
      ),
    );
  }
}
