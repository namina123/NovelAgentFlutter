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
    // 中文注释: 历史列表项继续朝导航列表项收紧，而不是内容卡片。
    final colors = context.novelThemeColors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelected(entry.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: entry.isSelected
              ? colors.accentSoftColor.withValues(alpha: 0.72)
              : colors.panelBackground.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(
              color:
                  (entry.isSelected ? colors.lineStrongColor : colors.lineColor)
                      .withValues(alpha: entry.isSelected ? 0.72 : 0.28),
              width: AppChrome.borderWidth,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.status} · ${entry.updatedAt}',
              style: TextStyle(
                color: colors.mutedTextColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
