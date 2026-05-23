import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
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
    return InkWell(
      borderRadius: AppChrome.surfaceBorderRadius,
      onTap: () => onSelected(entry.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: entry.isSelected ? AppPalette.accentSoft : Colors.transparent,
          borderRadius: AppChrome.surfaceBorderRadius,
          border: Border.all(
            color: entry.isSelected ? AppPalette.lineStrong : AppPalette.line,
            width: AppChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.status} · ${entry.updatedAt}',
              style: const TextStyle(color: AppPalette.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
