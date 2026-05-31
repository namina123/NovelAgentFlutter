import 'package:flutter/material.dart';

import '../../../../../shared/widgets/section_heading.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';

class ConversationToolbar extends StatelessWidget {
  const ConversationToolbar({
    super.key,
    required this.title,
    required this.onHistoryRequested,
    required this.onNewSessionRequested,
  });

  final String title;
  final VoidCallback onHistoryRequested;
  final VoidCallback onNewSessionRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话头部工具条独立后，右栏顶部的快捷按钮增减不会拖着整块侧栏一起变重。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SectionHeading(title: title)),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.topRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                ToolbarIconButton(
                  icon: Icons.history_rounded,
                  tooltip: '会话历史',
                  onPressed: onHistoryRequested,
                ),
                ToolbarIconButton(
                  icon: Icons.add_rounded,
                  tooltip: '新会话',
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
