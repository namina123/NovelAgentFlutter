import 'package:flutter/material.dart';

import 'app_layout_scope.dart';

class AdaptivePageFrame extends StatelessWidget {
  const AdaptivePageFrame({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutScope.of(context);
    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          metrics.isCompact ? 12 : 18,
          metrics.isCompact ? 12 : 18,
          metrics.isCompact ? 12 : 18,
          metrics.isCompact ? 12 : 18,
        );

    // 中文注释: 页面外框统一承接安全区、边距和键盘底部 inset，避免每个页面自己拼一套输入法回避逻辑。
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: metrics.viewInsetsBottom),
      child: SafeArea(
        bottom: false,
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
