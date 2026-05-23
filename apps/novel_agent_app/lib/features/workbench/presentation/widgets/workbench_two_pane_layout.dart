import 'package:flutter/material.dart';

import '../../../../../app/layout/app_layout_metrics.dart';
import '../layout/workbench_two_pane_layout_policy.dart';

class WorkbenchTwoPaneLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 中文注释: 双栏布局组件只关心正文栏和会话栏的横向装配，宽度决策交给策略层处理。
    return LayoutBuilder(
      builder: (context, constraints) {
        final conversationWidth = WorkbenchTwoPaneLayoutPolicy
            .conversationWidth(metrics, constraints.maxWidth);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: documentPane),
            const VerticalDivider(width: 1),
            SizedBox(width: conversationWidth, child: conversationPane),
          ],
        );
      },
    );
  }
}
