import 'package:flutter/material.dart';

import '../models/conversation_entry_view_data.dart';
import 'conversation_entry_palette.dart';
import 'conversation_message_entry_tile.dart';
import 'conversation_tool_entry_row.dart';

class ConversationEntryTile extends StatelessWidget {
  const ConversationEntryTile({
    super.key,
    required this.entry,
    this.showToolDetails = false,
  });

  final ConversationEntryViewData entry;
  final bool showToolDetails;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单条会话记录只负责展示一种时间线条目，不处理列表排序和会话状态切换。
    final entry = this.entry;
    final palette = ConversationEntryPalette.resolve(context, entry);
    if (entry.kind == ConversationEntryKind.tool) {
      return ConversationToolEntryRow(
        entry: entry,
        palette: palette,
        showDetails: showToolDetails,
      );
    }
    return ConversationMessageEntryTile(entry: entry, palette: palette);
  }
}
