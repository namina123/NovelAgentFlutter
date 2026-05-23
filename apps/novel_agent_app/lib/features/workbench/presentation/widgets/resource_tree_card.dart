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
    if (entries.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.66),
          borderRadius: AppChrome.surfaceBorderRadius,
          border: Border.all(
            color: AppPalette.line,
            width: AppChrome.borderWidth,
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              '当前项目还没有目录内容。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.mutedText,
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: entries.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
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
                left: 10 + (entry.depth * 16),
                right: 10,
              ),
              leading: Icon(
                entry.isDirectory
                    ? Icons.folder_outlined
                    : Icons.description_outlined,
                size: 16,
                color: entry.isSelected
                    ? AppPalette.lineStrong
                    : AppPalette.mutedText,
              ),
              title: Text(
                entry.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: entry.isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: entry.isSelected
                      ? AppPalette.lineStrong
                      : AppPalette.text,
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
