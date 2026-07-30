import 'package:flutter/material.dart';

import '../../../../../app/layout/app_layout_metrics.dart';
import '../layout/workbench_two_pane_layout_policy.dart';
import 'pane_resize_divider.dart';

class WorkbenchTwoPaneLayout extends StatefulWidget {
  const WorkbenchTwoPaneLayout({
    super.key,
    required this.metrics,
    required this.documentPane,
    required this.conversationPane,
  });

  final AppLayoutMetrics metrics;
  final Widget documentPane;
  final Widget conversationPane;

  @override
  State<WorkbenchTwoPaneLayout> createState() => _WorkbenchTwoPaneLayoutState();
}

class _WorkbenchTwoPaneLayoutState extends State<WorkbenchTwoPaneLayout> {
  double? _conversationWidth;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 双栏布局也保留可拖拽分隔，避免中等宽度设备退化后失去基本的栏宽调节能力。
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final minConversationWidth =
            widget.metrics.isTabletLike ? 336.0 : 316.0;
        // 中文注释: 总宽不足以并排（会话栏最低宽度 × 2）时改成上下堆叠：文档在上、会话在下，
        // 避免窄屏下会话栏吃掉大半屏、编辑区被挤到无法使用。
        if (totalWidth < minConversationWidth * 2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: widget.documentPane),
              const Divider(height: 1),
              SizedBox(
                height: totalWidth < 360 ? 220 : 300,
                child: widget.conversationPane,
              ),
            ],
          );
        }
        final conversationWidth =
            WorkbenchTwoPaneLayoutPolicy.conversationWidth(
              widget.metrics,
              totalWidth,
              preferredWidth: _conversationWidth,
            );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.documentPane),
            PaneResizeDivider(
              cursor: SystemMouseCursors.resizeColumn,
              onDragUpdate: (delta) {
                setState(() {
                  _conversationWidth =
                      WorkbenchTwoPaneLayoutPolicy.conversationWidth(
                        widget.metrics,
                        totalWidth,
                        preferredWidth: (conversationWidth - delta),
                      );
                });
              },
              // 中文注释: 双击恢复默认会话栏宽（清空自定义值，policy 会按总宽重算默认）。
              onResetRequested: () => setState(() => _conversationWidth = null),
            ),
            SizedBox(width: conversationWidth, child: widget.conversationPane),
          ],
        );
      },
    );
  }
}
