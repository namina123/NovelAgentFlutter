import 'package:flutter/material.dart';

import '../../../../../shared/widgets/section_heading.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';

class ConversationToolbar extends StatelessWidget {
  const ConversationToolbar({
    super.key,
    required this.onQuickThemeRequested,
    required this.onScreenModeRequested,
    required this.onHistoryRequested,
    required this.onNewSessionRequested,
  });

  final VoidCallback onQuickThemeRequested;
  final VoidCallback onScreenModeRequested;
  final VoidCallback onHistoryRequested;
  final VoidCallback onNewSessionRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话头部工具条独立后，右栏顶部的快捷按钮增减不会拖着整块侧栏一起变重。
    return Row(
      children: [
        const Expanded(
          child: SectionHeading(title: '主智能体', subtitle: '会话与编排侧栏'),
        ),
        ToolbarIconButton(
          icon: Icons.light_mode_outlined,
          tooltip: '快速主题',
          tone: ToolbarIconTone.warm,
          onPressed: onQuickThemeRequested,
        ),
        const SizedBox(width: 8),
        ToolbarIconButton(
          icon: Icons.open_in_full_rounded,
          tooltip: '屏幕模式',
          tone: ToolbarIconTone.accent,
          onPressed: onScreenModeRequested,
        ),
        const SizedBox(width: 8),
        ToolbarIconButton(
          icon: Icons.history_rounded,
          tooltip: '会话历史',
          onPressed: onHistoryRequested,
        ),
        const SizedBox(width: 8),
        ToolbarIconButton(
          icon: Icons.add_rounded,
          tooltip: '新会话',
          onPressed: onNewSessionRequested,
        ),
      ],
    );
  }
}
