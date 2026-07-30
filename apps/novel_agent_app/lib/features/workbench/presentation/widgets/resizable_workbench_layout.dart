import 'package:flutter/material.dart';

import '../../../../../app/layout/app_layout_metrics.dart';
import '../layout/workbench_pane_layout_policy.dart';
import 'pane_resize_divider.dart';

class ResizableWorkbenchLayout extends StatefulWidget {
  const ResizableWorkbenchLayout({
    super.key,
    required this.metrics,
    required this.leftPane,
    required this.documentPane,
    required this.conversationPane,
  });

  final AppLayoutMetrics metrics;
  final Widget leftPane;
  final Widget documentPane;
  final Widget conversationPane;

  @override
  State<ResizableWorkbenchLayout> createState() =>
      _ResizableWorkbenchLayoutState();
}

class _ResizableWorkbenchLayoutState extends State<ResizableWorkbenchLayout> {
  double? _leftWidth;
  double? _conversationWidth;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 三栏布局的宽度计算和拖拽状态都收束在这里，避免页面层混入尺寸数学和手势细节。
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final normalized = _normalizedWidths(totalWidth);
        final leftWidth = normalized.leftWidth;
        final conversationWidth = normalized.conversationWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: leftWidth, child: widget.leftPane),
            PaneResizeDivider(
              cursor: SystemMouseCursors.resizeColumn,
              onDragUpdate: (delta) => _resizeLeft(delta, totalWidth),
              onResetRequested: _resetWidths,
            ),
            Expanded(child: widget.documentPane),
            PaneResizeDivider(
              cursor: SystemMouseCursors.resizeColumn,
              onDragUpdate: (delta) => _resizeConversation(delta, totalWidth),
              onResetRequested: _resetWidths,
            ),
            SizedBox(width: conversationWidth, child: widget.conversationPane),
          ],
        );
      },
    );
  }

  // 中文注释: 双击任一分隔条：清空两栏自定义宽度，_normalizedWidths 会按当前总宽重算默认值。
  void _resetWidths() {
    setState(() {
      _leftWidth = null;
      _conversationWidth = null;
    });
  }

  void _resizeLeft(double delta, double totalWidth) {
    // 中文注释: 左栏拖拽只更新左栏宽度，正文区通过剩余空间自然变化，状态边界由策略类裁剪。
    final currentLeftWidth =
        _leftWidth ??
        WorkbenchPaneLayoutPolicy.defaultLeftWidth(totalWidth, widget.metrics);
    final currentConversationWidth =
        _conversationWidth ??
        WorkbenchPaneLayoutPolicy.defaultConversationWidth(
          totalWidth,
          widget.metrics,
        );
    setState(() {
      _leftWidth = WorkbenchPaneLayoutPolicy.clampLeftWidth(
        currentLeftWidth + delta,
        totalWidth,
        widget.metrics,
        rightWidth: currentConversationWidth,
      );
    });
  }

  void _resizeConversation(double delta, double totalWidth) {
    // 中文注释: 右栏拖拽只更新会话栏宽度，向右拖时减小右栏，向左拖时增大右栏。
    final currentLeftWidth =
        _leftWidth ??
        WorkbenchPaneLayoutPolicy.defaultLeftWidth(totalWidth, widget.metrics);
    final currentConversationWidth =
        _conversationWidth ??
        WorkbenchPaneLayoutPolicy.defaultConversationWidth(
          totalWidth,
          widget.metrics,
        );
    setState(() {
      _conversationWidth = WorkbenchPaneLayoutPolicy.clampConversationWidth(
        currentConversationWidth - delta,
        totalWidth,
        widget.metrics,
        leftWidth: currentLeftWidth,
      );
    });
  }

  _NormalizedPaneWidths _normalizedWidths(double totalWidth) {
    // 中文注释: 每次布局前统一校准左右栏宽度，确保窗口缩放后仍满足最小正文宽度和分栏约束。
    var leftWidth =
        _leftWidth ??
        WorkbenchPaneLayoutPolicy.defaultLeftWidth(totalWidth, widget.metrics);
    var conversationWidth =
        _conversationWidth ??
        WorkbenchPaneLayoutPolicy.defaultConversationWidth(
          totalWidth,
          widget.metrics,
        );

    leftWidth = WorkbenchPaneLayoutPolicy.clampLeftWidth(
      leftWidth,
      totalWidth,
      widget.metrics,
      rightWidth: conversationWidth,
    );
    conversationWidth = WorkbenchPaneLayoutPolicy.clampConversationWidth(
      conversationWidth,
      totalWidth,
      widget.metrics,
      leftWidth: leftWidth,
    );

    final minDocumentWidth = WorkbenchPaneLayoutPolicy.minDocumentWidth(
      widget.metrics,
    );
    final availableDocumentWidth =
        totalWidth -
        leftWidth -
        conversationWidth -
        WorkbenchPaneLayoutPolicy.dividerWidth * 2;
    if (availableDocumentWidth < minDocumentWidth) {
      final missingWidth = minDocumentWidth - availableDocumentWidth;
      final rightReductionRoom =
          conversationWidth -
          WorkbenchPaneLayoutPolicy.minConversationWidth(widget.metrics);
      final rightReduction = rightReductionRoom <= 0
          ? 0.0
          : rightReductionRoom < missingWidth
          ? rightReductionRoom
          : missingWidth;
      conversationWidth -= rightReduction;

      final remainingMissing = missingWidth - rightReduction;
      if (remainingMissing > 0) {
        final leftReductionRoom =
            leftWidth - WorkbenchPaneLayoutPolicy.minLeftWidth(widget.metrics);
        final leftReduction = leftReductionRoom <= 0
            ? 0.0
            : leftReductionRoom < remainingMissing
            ? leftReductionRoom
            : remainingMissing;
        leftWidth -= leftReduction;
      }
    }

    _leftWidth = leftWidth;
    _conversationWidth = conversationWidth;
    return _NormalizedPaneWidths(
      leftWidth: leftWidth,
      conversationWidth: conversationWidth,
    );
  }
}

class _NormalizedPaneWidths {
  const _NormalizedPaneWidths({
    required this.leftWidth,
    required this.conversationWidth,
  });

  final double leftWidth;
  final double conversationWidth;
}
