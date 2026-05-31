import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/session_history_entry_view_data.dart';

class SessionHistoryEntryTile extends StatelessWidget {
  const SessionHistoryEntryTile({
    super.key,
    required this.entry,
    required this.onSelected,
  });

  final SessionHistoryEntryViewData entry;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 历史列表项只负责展示并回传所选会话 id，不耦合全局历史面板开关。
    final colors = context.novelThemeColors;
    return InkWell(
      borderRadius: AppChrome.surfaceBorderRadius,
      onTap: () => onSelected(entry.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: entry.isSelected
              ? colors.accentSoftColor.withValues(alpha: 0.92)
              : Colors.transparent,
          borderRadius: AppChrome.surfaceBorderRadius,
          border: Border.all(
            color: entry.isSelected ? colors.lineStrongColor : colors.lineColor,
            width: AppChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.status} · ${entry.updatedAt}',
              style: TextStyle(color: colors.mutedTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
