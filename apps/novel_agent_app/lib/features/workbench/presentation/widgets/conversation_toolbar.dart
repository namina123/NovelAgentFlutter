import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';
import 'conversation_panel_style.dart';

class ConversationToolbar extends StatelessWidget {
  const ConversationToolbar({
    super.key,
    required this.title,
    required this.onHistoryRequested,
    required this.onNewSessionRequested,
    this.historyOpen = false,
    this.minimal = false,
  });

  final String title;
  final VoidCallback onHistoryRequested;
  final VoidCallback onNewSessionRequested;
  final bool historyOpen;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final style = ConversationPanelStyle.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: surface.foregroundColor,
              fontSize: minimal
                  ? style.titleFontSize - 0.8
                  : style.titleFontSize - 0.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.05,
            ),
          ),
        ),
        SizedBox(width: style.gap(-0.75, min: 4)),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: Wrap(
              spacing: style.gap(-1.5, min: 2.5),
              runSpacing: style.gap(-1.5, min: 2.5),
              alignment: WrapAlignment.end,
              children: [
                ToolbarIconButton(
                  icon: Icons.history_rounded,
                  tooltip: '会话历史',
                  tone: historyOpen
                      ? ToolbarIconTone.accent
                      : ToolbarIconTone.neutral,
                  dense: true,
                  onPressed: onHistoryRequested,
                ),
                ToolbarIconButton(
                  icon: Icons.add_rounded,
                  tooltip: '新会话',
                  tone: ToolbarIconTone.accent,
                  dense: true,
                  onPressed: onNewSessionRequested,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
