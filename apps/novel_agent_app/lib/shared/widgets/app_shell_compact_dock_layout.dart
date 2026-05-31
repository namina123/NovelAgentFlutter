import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class AppShellCompactDockLayout {
  const AppShellCompactDockLayout({
    required this.keyboardVisible,
    required this.pageBottomInset,
    required this.launcherBottomInset,
    required this.panelBottomInset,
    required this.panelWidth,
  });

  static const double launcherHeight = 44;
  static const double screenEdgePadding = 12;
  static const double launcherMinWidth = 120;
  static const double launcherMaxWidth = 220;
  static const double baseBottomGap = 12;
  static const double panelGap = 10;
  static const double dockHeight =
      launcherHeight + baseBottomGap + screenEdgePadding;

  final bool keyboardVisible;
  final double pageBottomInset;
  final double launcherBottomInset;
  final double panelBottomInset;
  final double panelWidth;

  bool get allowExpandedPanel => !keyboardVisible;

  factory AppShellCompactDockLayout.fromMediaQuery(MediaQueryData mediaQuery) {
    // 中文注释: 紧凑模式底部入口的避让策略统一集中在这里，避免 launcher、页面 padding、键盘规则散落到多个 widget 中。
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final launcherBottomInset = keyboardVisible
        ? mediaQuery.viewInsets.bottom + baseBottomGap
        : baseBottomGap;
    final pageBottomInset = 0.0;
    final panelBottomInset = launcherBottomInset + launcherHeight + panelGap;
    final panelWidth = math.min(
      mediaQuery.size.width - (screenEdgePadding * 2),
      296.0,
    );
    return AppShellCompactDockLayout(
      keyboardVisible: keyboardVisible,
      pageBottomInset: pageBottomInset,
      launcherBottomInset: launcherBottomInset,
      panelBottomInset: panelBottomInset,
      panelWidth: panelWidth,
    );
  }
}
