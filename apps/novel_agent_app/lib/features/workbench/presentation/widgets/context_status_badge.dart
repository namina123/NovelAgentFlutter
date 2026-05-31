import 'package:flutter/material.dart';

import 'conversation_panel_band.dart';
import 'conversation_panel_style.dart';

class ContextStatusBadge extends StatelessWidget {
  const ContextStatusBadge({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 上下文状态徽标独立后，后续压缩策略、token 预算等展示可单独演化。
    final style = ConversationPanelStyle.of(context);
    return ConversationPanelBand(
      leadingIcon: Icons.analytics_outlined,
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '上下文概览',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: style.accentBandForegroundColor.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.accentBandForegroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
