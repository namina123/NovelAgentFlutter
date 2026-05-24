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
            ),
            SizedBox(width: conversationWidth, child: widget.conversationPane),
          ],
        );
      },
    );
  }
}
