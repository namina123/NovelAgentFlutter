import 'package:flutter/material.dart';

import 'conversation_panel_band.dart';
import 'conversation_panel_style.dart';

class ConversationRuntimeStatusStrip extends StatelessWidget {
  const ConversationRuntimeStatusStrip({
    super.key,
    required this.text,
    this.busy = false,
  });

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 运行状态条只承接瞬时执行态提示，避免把短暂工具状态塞回会话正文时间线。
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }
    final style = ConversationPanelStyle.of(context);
    return ConversationPanelBand(
      leadingIcon: Icons.cloud_sync_outlined,
      trailing: busy
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: style.accentBandForegroundColor,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '运行状态',
            style: TextStyle(
              color: style.mutedForegroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cleanText,
            style: TextStyle(
              color: style.foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
