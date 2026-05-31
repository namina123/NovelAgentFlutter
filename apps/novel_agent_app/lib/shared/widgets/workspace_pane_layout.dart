import 'package:flutter/material.dart';

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
                const SizedBox(height: 12),
                Expanded(child: mainPane),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: leadingPaneWidth, child: leadingPane),
              const SizedBox(width: 12),
              Expanded(child: mainPane),
            ],
          );
        }
        if (isStacked) {
          return Column(
            children: [
              SizedBox(height: leadingCompactHeight, child: leadingPane),
              const SizedBox(height: 12),
              Expanded(child: mainPane),
              const SizedBox(height: 12),
              SizedBox(height: trailingCompactHeight, child: trailingPane!),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: leadingPaneWidth, child: leadingPane),
            const SizedBox(width: 12),
            Expanded(flex: mainFlex, child: mainPane),
            const SizedBox(width: 12),
            SizedBox(width: trailingPaneWidth, child: trailingPane!),
          ],
        );
      },
    );
  }
}
