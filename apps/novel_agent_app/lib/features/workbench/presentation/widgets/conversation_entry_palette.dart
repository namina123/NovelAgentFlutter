import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_entry_view_data.dart';

class ConversationEntryPalette {
  const ConversationEntryPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    required this.detailBackground,
    required this.detailForeground,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
  final Color detailBackground;
  final Color detailForeground;

  static ConversationEntryPalette resolve(
    BuildContext context,
    ConversationEntryViewData entry,
  ) {
    final colors = context.novelThemeColors;
    final surfaces = context.novelThemeSurfaces;
    if (entry.isError) {
      return ConversationEntryPalette(
        background: colors.dangerSoftColor,
        border: colors.dangerStrongColor.withValues(alpha: 0.45),
        foreground: colors.dangerStrongColor,
        icon: Icons.error_outline_rounded,
        detailBackground: colors.panelBackground.withValues(alpha: 0.82),
        detailForeground: colors.mutedTextColor,
      );
    }
    switch (entry.kind) {
      case ConversationEntryKind.user:
        return ConversationEntryPalette(
          background: colors.accentSoftColor,
          border: colors.lineColor,
          foreground: colors.lineStrongColor,
          icon: Icons.person_outline_rounded,
          detailBackground: colors.panelBackground.withValues(alpha: 0.72),
          detailForeground: colors.mutedTextColor,
        );
      case ConversationEntryKind.assistant:
        return ConversationEntryPalette(
          background: colors.warmColor.withValues(alpha: 0.56),
          border: colors.warmStrongColor.withValues(alpha: 0.48),
          foreground: colors.textColor,
          icon: Icons.auto_awesome_rounded,
          detailBackground: colors.panelBackground.withValues(alpha: 0.78),
          detailForeground: colors.mutedTextColor,
        );
      case ConversationEntryKind.tool:
        return ConversationEntryPalette(
          background: surfaces.toolRow.backgroundColor,
          border: surfaces.toolRow.borderColor,
          foreground: surfaces.toolRow.mutedForegroundColor,
          icon: Icons.build_circle_outlined,
          detailBackground: colors.panelBackground,
          detailForeground: colors.mutedTextColor,
        );
      case ConversationEntryKind.system:
        return ConversationEntryPalette(
          background: colors.panelBackground.withValues(alpha: 0.82),
          border: colors.lineColor.withValues(alpha: 0.7),
          foreground: colors.mutedTextColor,
          icon: Icons.info_outline_rounded,
          detailBackground: colors.panelBackground.withValues(alpha: 0.74),
          detailForeground: colors.mutedTextColor,
        );
    }
  }
}
