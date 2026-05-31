import 'package:flutter/material.dart';

class AppShellCompactPageFrame extends StatelessWidget {
  const AppShellCompactPageFrame({
    super.key,
    required this.bottomInset,
    required this.child,
  });

  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 紧凑页面容器只负责给主视图留出底部 dock 安全区，不参与抽拉栏和导航交互逻辑。
    return AnimatedPadding(
      key: const ValueKey('app-shell-compact-page-frame'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: child,
    );
  }
}
