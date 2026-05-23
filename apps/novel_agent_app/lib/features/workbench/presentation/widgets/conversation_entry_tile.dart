import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/conversation_entry_view_data.dart';

class ConversationEntryTile extends StatelessWidget {
  const ConversationEntryTile({super.key, required this.entry});

  final ConversationEntryViewData entry;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单条会话记录只负责展示一种时间线条目，不处理列表排序和会话状态切换。
    final palette = _paletteFor(entry);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: palette.border, width: AppChrome.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(palette.icon, size: 16, color: palette.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (entry.body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              entry.body,
              style: TextStyle(
                color: entry.isError
                    ? const Color(0xFF8A2E24)
                    : AppPalette.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _EntryPalette _paletteFor(ConversationEntryViewData entry) {
    // 中文注释: 不同来源的消息使用统一颜色语义，方便用户一眼区分用户、助手和工具轨迹。
    if (entry.isError) {
      return const _EntryPalette(
        background: AppPalette.dangerSoft,
        border: Color(0xFFE2A39B),
        foreground: Color(0xFF9C3C30),
        icon: Icons.error_outline_rounded,
      );
    }
    switch (entry.kind) {
      case ConversationEntryKind.user:
        return const _EntryPalette(
          background: AppPalette.accentSoft,
          border: AppPalette.line,
          foreground: AppPalette.lineStrong,
          icon: Icons.person_outline_rounded,
        );
      case ConversationEntryKind.assistant:
        return const _EntryPalette(
          background: Color(0xFFF4EFD9),
          border: Color(0xFFD8C790),
          foreground: AppPalette.text,
          icon: Icons.auto_awesome_rounded,
        );
      case ConversationEntryKind.tool:
        return const _EntryPalette(
          background: Color(0xFFF7F7F2),
          border: Color(0xFFC5D4D9),
          foreground: AppPalette.mutedText,
          icon: Icons.build_circle_outlined,
        );
      case ConversationEntryKind.system:
        return const _EntryPalette(
          background: Color(0xFFF2F3F6),
          border: Color(0xFFC5CDD4),
          foreground: AppPalette.mutedText,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _EntryPalette {
  const _EntryPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
