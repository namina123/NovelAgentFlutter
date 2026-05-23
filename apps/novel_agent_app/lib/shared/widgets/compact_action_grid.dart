import 'package:flutter/material.dart';

class CompactActionGrid extends StatelessWidget {
  const CompactActionGrid({
    super.key,
    required this.children,
    this.columnCount = 2,
    this.spacing = 10,
  });

  final List<Widget> children;
  final int columnCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 紧凑动作网格统一处理窄栏里的按钮矩阵，避免每个面板自己拼一套两列布局。
    return GridView.count(
      crossAxisCount: columnCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: 2.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
