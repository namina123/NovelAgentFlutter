import 'package:flutter/material.dart';

import 'conversation_panel_band.dart';
import 'conversation_panel_style.dart';

class ToolVisibilityToggle extends StatelessWidget {
  const ToolVisibilityToggle({
    super.key,
    required this.showDetails,
    required this.onChanged,
  });

  final bool showDetails;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工具细节显示开关保持在会话展示层，避免这类纯 UI 偏好进入控制器业务状态。
    final style = ConversationPanelStyle.of(context);
    return ConversationPanelBand(
      leadingIcon: Icons.tune_outlined,
      onTap: () => onChanged(!showDetails),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showDetails ? '已展开' : '已折叠',
            style: TextStyle(
              color: style.mutedForegroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            showDetails
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: style.accentBandForegroundColor,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '工具回显',
            style: TextStyle(
              color: style.mutedForegroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            showDetails ? '显示详细调用细节' : '仅显示工具概览',
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
