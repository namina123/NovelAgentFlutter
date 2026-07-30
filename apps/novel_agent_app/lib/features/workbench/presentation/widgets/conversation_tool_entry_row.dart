import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/theme_color_tokens.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/models/conversation_tool_lifecycle_status.dart';
import '../models/conversation_entry_view_data.dart';
import 'conversation_detail_section.dart';
import 'conversation_entry_palette.dart';
import 'conversation_panel_style.dart';

class ConversationToolEntryRow extends StatelessWidget {
  const ConversationToolEntryRow({
    super.key,
    required this.entry,
    required this.palette,
    required this.showDetails,
  });

  final ConversationEntryViewData entry;
  final ConversationEntryPalette palette;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final mutedText = context.novelThemeColors.mutedTextColor;
    final colors = context.novelThemeColors;
    final lifecycleStatus = _lifecycleStatus();
    final statusColor = _statusColor(lifecycleStatus, colors, palette);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConversationToolGutter(
              dotColor: statusColor,
              dividerColor: colors.lineColor.withValues(alpha: 0.34),
            ),
            SizedBox(width: style.gap(-0.75, min: 3)),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  padding: style.inset(top: -0.25, bottom: -0.25),
                  decoration: BoxDecoration(
                    color: palette.background.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(style.sectionRadius),
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.08),
                      width: AppChrome.borderWidth,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(lifecycleStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: style.metaFontSize - 1.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.14,
                              ),
                            ),
                          ),
                          SizedBox(width: style.sectionGap),
                          // 中文注释: 执行中用真实旋转指示器（与运行时状态条一致），避免长任务里静态图标
                          // 让用户误以为卡死；其余状态沿用对应静态图标。
                          if (lifecycleStatus ==
                              ConversationToolLifecycleStatus.running)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  statusColor,
                                ),
                              ),
                            )
                          else
                            Icon(
                              _statusIcon(lifecycleStatus),
                              size: 12,
                              color: statusColor,
                            ),
                          SizedBox(width: style.gap(-1.5, min: 2.5)),
                          Expanded(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.foreground,
                                fontSize: style.metaFontSize - 0.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (entry.body.trim().isNotEmpty) ...[
                        SizedBox(height: style.gap(-1.2, min: 4)),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            entry.body.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: entry.isError
                                  ? palette.foreground.withValues(alpha: 0.88)
                                  : mutedText,
                              fontSize: style.metaFontSize - 0.25,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showDetails && entry.detailBody.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: style.gap(-1.5, min: 2.5),
              left: 18 + style.gap(-0.75, min: 3),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ConversationDetailSection(
                title: entry.detailTitle,
                summary: entry.detailSummary,
                body: entry.detailBody,
                expandedByDefault: false,
                palette: palette,
              ),
            ),
          ),
      ],
    );
  }

  ConversationToolLifecycleStatus _lifecycleStatus() {
    return entry.toolLifecycleStatus ??
        (entry.isError
            ? ConversationToolLifecycleStatus.failed
            : ConversationToolLifecycleStatus.completed);
  }

  String _statusLabel(ConversationToolLifecycleStatus status) {
    return switch (status) {
      ConversationToolLifecycleStatus.running => '执行中',
      ConversationToolLifecycleStatus.completed => '已完成',
      ConversationToolLifecycleStatus.pendingConfirmation => '待确认',
      ConversationToolLifecycleStatus.failed => '失败',
    };
  }

  IconData _statusIcon(ConversationToolLifecycleStatus status) {
    return switch (status) {
      ConversationToolLifecycleStatus.running => Icons.sync_rounded,
      ConversationToolLifecycleStatus.completed =>
        Icons.check_circle_outline_rounded,
      ConversationToolLifecycleStatus.pendingConfirmation =>
        Icons.help_outline_rounded,
      ConversationToolLifecycleStatus.failed => Icons.error_outline_rounded,
    };
  }

  Color _statusColor(
    ConversationToolLifecycleStatus status,
    ThemeColorTokens colors,
    ConversationEntryPalette palette,
  ) {
    return switch (status) {
      ConversationToolLifecycleStatus.running => colors.accentColor,
      ConversationToolLifecycleStatus.completed => palette.foreground,
      ConversationToolLifecycleStatus.pendingConfirmation =>
        colors.warmStrongColor,
      ConversationToolLifecycleStatus.failed => colors.dangerStrongColor,
    };
  }
}

class _ConversationToolGutter extends StatelessWidget {
  const _ConversationToolGutter({
    required this.dotColor,
    required this.dividerColor,
  });

  final Color dotColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Container(
            width: 1,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            color: dividerColor,
          ),
        ],
      ),
    );
  }
}
