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
        if (trailingPane == null) {
          if (isStacked) {
            return Column(
              children: [
                SizedBox(height: leadingCompactHeight, child: leadingPane),
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
              SizedBox(height: leadingCompactHeight, child: leadingPane),
              SizedBox(height: paneGap),
              Expanded(child: mainPane),
              SizedBox(height: paneGap),
              SizedBox(height: trailingCompactHeight, child: trailingPane!),
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
