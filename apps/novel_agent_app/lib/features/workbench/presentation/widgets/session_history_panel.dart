import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/session_history_entry_view_data.dart';
import 'session_history_entry_tile.dart';
import 'workbench_visual_style.dart';

class SessionHistoryPanel extends StatelessWidget {
  const SessionHistoryPanel({
    super.key,
    required this.entries,
    required this.onSelected,
  });

  final List<SessionHistoryEntryViewData> entries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话历史视觉上也收成更像 IDE 侧栏列表，而不是一组独立信息卡片。
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(
            color: surface.borderColor.withValues(alpha: 0.32),
            width: AppChrome.borderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: colors.accentColor),
              const SizedBox(width: 6),
              Text(
                '会话记录',
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: visual.metaFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: AppChrome.borderWidth,
            color: surface.borderColor.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 6),
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == entries.length - 1 ? 0 : 4,
              ),
              child: SessionHistoryEntryTile(
                entry: value,
                onSelected: onSelected,
              ),
            );
          }),
        ],
      ),
    );
  }
}
