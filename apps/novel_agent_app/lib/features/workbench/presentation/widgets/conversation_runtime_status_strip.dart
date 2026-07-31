import 'package:flutter/material.dart';

import '../../../../../app/theme/theme_color_tokens.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/models/conversation_tool_lifecycle_status.dart';
import 'conversation_panel_style.dart';

class ConversationRuntimeStatusStrip extends StatelessWidget {
  const ConversationRuntimeStatusStrip({
    super.key,
    required this.text,
    this.status = ConversationToolLifecycleStatus.completed,
  });

  final String text;
  final ConversationToolLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 运行状态条继续变轻，只保留一行必要信号，不和日志时间线抢层级。
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }
    final style = ConversationPanelStyle.of(context);
    final colors = context.novelThemeColors;
    final tone = _toneColor(colors, style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(_leadingIcon(), size: 13, color: tone),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusLabel(),
            style: TextStyle(
              color: tone,
              fontSize: style.metaFontSize - 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cleanText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.foregroundColor,
              fontSize: style.metaFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        status == ConversationToolLifecycleStatus.running
            ? SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(strokeWidth: 2, color: tone),
              )
            : Icon(_trailingIcon(), size: 13, color: tone),
      ],
    );
  }

  String _statusLabel() {
    return switch (status) {
      ConversationToolLifecycleStatus.running => '执行中',
      ConversationToolLifecycleStatus.completed => '已完成',
      ConversationToolLifecycleStatus.pendingConfirmation => '待确认',
      ConversationToolLifecycleStatus.failed => '失败',
    };
  }

  IconData _leadingIcon() {
    return switch (status) {
      ConversationToolLifecycleStatus.running => Icons.cloud_sync_outlined,
      ConversationToolLifecycleStatus.completed => Icons.task_alt_rounded,
      ConversationToolLifecycleStatus.pendingConfirmation =>
        Icons.pending_actions_rounded,
      ConversationToolLifecycleStatus.failed => Icons.error_outline_rounded,
    };
  }

  IconData _trailingIcon() {
    return switch (status) {
      ConversationToolLifecycleStatus.running => Icons.more_horiz_rounded,
      ConversationToolLifecycleStatus.completed =>
        Icons.check_circle_outline_rounded,
      ConversationToolLifecycleStatus.pendingConfirmation =>
        Icons.help_outline_rounded,
      ConversationToolLifecycleStatus.failed => Icons.error_outline_rounded,
    };
  }

  Color _toneColor(ThemeColorTokens colors, ConversationPanelStyle style) {
    return switch (status) {
      ConversationToolLifecycleStatus.running => colors.accentColor,
      ConversationToolLifecycleStatus.completed =>
        style.accentBandForegroundColor,
      ConversationToolLifecycleStatus.pendingConfirmation =>
        colors.warmStrongColor,
      ConversationToolLifecycleStatus.failed => colors.dangerStrongColor,
    };
  }
}
