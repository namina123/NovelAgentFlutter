import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../models/session_history_entry_view_data.dart';
import 'session_history_entry_tile.dart';

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
    // 中文注释: 会话历史面板独立后，后续替换成更重的检索或分组列表也不会波及会话时间线。
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '会话历史',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SessionHistoryEntryTile(
              entry: entry,
              onSelected: onSelected,
            ),
          ),
        ),
      ],
    );
  }
}
