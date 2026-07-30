import 'package:flutter/material.dart';

import 'horizontal_overflow_scrollbar.dart';

class WorkspacePaneLayout extends StatelessWidget {
  const WorkspacePaneLayout({
    super.key,
    required this.leadingPane,
    required this.mainPane,
    this.trailingPane,
    this.breakpoint = 1180,
    this.leadingPaneWidth = 280,
    this.trailingPaneWidth = 340,
    this.leadingCompactHeight = 220,
    this.trailingCompactHeight = 260,
    this.mainFlex = 5,
    this.mainPaneMinWidth = 560,
    this.paneGap = 12,
  });

  final Widget leadingPane;
  final Widget mainPane;
  final Widget? trailingPane;
  final double breakpoint;
  final double leadingPaneWidth;
  final double trailingPaneWidth;
  final double leadingCompactHeight;
  final double trailingCompactHeight;
  final int mainFlex;
  final double mainPaneMinWidth;
  final double paneGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < breakpoint;
        // 中文注释: 短高度(Android 横屏/分屏)下固定 compact 高度之和可能超过 maxHeight，
        // 导致 Expanded 主区拿到负空间、RenderFlex 黄黑溢出。这里按可用高度给两个边栏
        // 分配预算、超出时同比缩放，保证主区 Expanded 永远拿到非负(至少 minMainExtent)空间。
        final maxH = constraints.maxHeight;
        const double minMainExtent = 120.0;
        final gapCount = trailingPane == null ? 1 : 2;
        final gapTotal = paneGap * gapCount;
        final desiredPaneTotal = trailingPane == null
            ? leadingCompactHeight
            : leadingCompactHeight + trailingCompactHeight;
        var budgetForPanes = (maxH.isFinite && maxH > 0)
            ? (maxH - gapTotal - minMainExtent)
            : desiredPaneTotal;
        if (budgetForPanes < 0) {
          budgetForPanes = 0;
        }
        // 中文注释: 当屏幕足够高时 scale=1，沿用调用方给的完整高度；屏幕短时同比缩放两个边栏。
        final scale = (desiredPaneTotal > budgetForPanes && desiredPaneTotal > 0)
            ? budgetForPanes / desiredPaneTotal
            : 1.0;
        final leadingH = leadingCompactHeight * scale;
        final trailingH = (trailingPane == null ? 0.0 : trailingCompactHeight) * scale;
        if (trailingPane == null) {
          if (isStacked) {
            return Column(
              children: [
                SizedBox(height: leadingH, child: leadingPane),
                SizedBox(height: paneGap),
                Expanded(child: mainPane),
              ],
            );
          }
          return _buildHorizontalLayout(
            context,
            constraints: constraints,
            trailingPane: null,
          );
        }
        if (isStacked) {
          return Column(
            children: [
              SizedBox(height: leadingH, child: leadingPane),
              SizedBox(height: paneGap),
              Expanded(child: mainPane),
              SizedBox(height: paneGap),
              SizedBox(height: trailingH, child: trailingPane!),
            ],
          );
        }
        return _buildHorizontalLayout(
          context,
          constraints: constraints,
          trailingPane: trailingPane,
        );
      },
    );
  }

  Widget _buildHorizontalLayout(
    BuildContext context, {
    required BoxConstraints constraints,
    required Widget? trailingPane,
  }) {
    final trailingWidth = trailingPane == null ? 0.0 : trailingPaneWidth;
    final gapCount = trailingPane == null ? 1 : 2;
    final minimumTotalWidth =
        leadingPaneWidth + mainPaneMinWidth + trailingWidth + paneGap * gapCount;
    final resolvedWidth = minimumTotalWidth > constraints.maxWidth
        ? minimumTotalWidth
        : constraints.maxWidth;
    final row = SizedBox(
      width: resolvedWidth,
      height: constraints.maxHeight,
      child: Row(
        children: [
          SizedBox(width: leadingPaneWidth, child: leadingPane),
          SizedBox(width: paneGap),
          Expanded(flex: mainFlex, child: mainPane),
          if (trailingPane != null) ...[
            SizedBox(width: paneGap),
            SizedBox(width: trailingPaneWidth, child: trailingPane),
          ],
        ],
      ),
    );
    if (minimumTotalWidth <= constraints.maxWidth) {
      return row;
    }
    return HorizontalOverflowScrollbar(
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: row,
      ),
    );
  }
}
