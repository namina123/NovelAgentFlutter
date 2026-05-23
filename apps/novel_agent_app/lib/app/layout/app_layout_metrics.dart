import 'package:flutter/widgets.dart';

import 'app_layout_mode.dart';

class AppLayoutMetrics {
  const AppLayoutMetrics({
    required this.size,
    required this.shortestSide,
    required this.orientation,
    required this.viewInsetsBottom,
    required this.devicePixelRatio,
    required this.mode,
    required this.isTabletLike,
  });

  final Size size;
  final double shortestSide;
  final Orientation orientation;
  final double viewInsetsBottom;
  final double devicePixelRatio;
  final AppLayoutMode mode;
  final bool isTabletLike;

  bool get isCompact => mode == AppLayoutMode.compact;

  bool get isMedium => mode == AppLayoutMode.medium;

  bool get isExpanded => mode == AppLayoutMode.expanded;

  bool get isKeyboardVisible => viewInsetsBottom > 0;

  bool get isLandscape => orientation == Orientation.landscape;

  bool get preferOverlayKeyboard => isCompact && isLandscape && !isTabletLike;

  factory AppLayoutMetrics.fromMediaQuery(MediaQueryData mediaQuery) {
    // 中文注释: 布局指标统一从 MediaQuery 推导，优先复用 Flutter 内建的尺寸和键盘 inset 能力，不重复造平台判断轮子。
    final size = mediaQuery.size;
    final shortestSide = mediaQuery.size.shortestSide;
    final orientation = mediaQuery.orientation;
    final viewInsetsBottom = mediaQuery.viewInsets.bottom;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final isTabletLike = shortestSide >= 600;

    final mode = _resolveMode(
      width: size.width,
      height: size.height,
      isTabletLike: isTabletLike,
      isLandscape: orientation == Orientation.landscape,
      devicePixelRatio: devicePixelRatio,
    );

    return AppLayoutMetrics(
      size: size,
      shortestSide: shortestSide,
      orientation: orientation,
      viewInsetsBottom: viewInsetsBottom,
      devicePixelRatio: devicePixelRatio,
      mode: mode,
      isTabletLike: isTabletLike,
    );
  }

  static AppLayoutMode _resolveMode({
    required double width,
    required double height,
    required bool isTabletLike,
    required bool isLandscape,
    required double devicePixelRatio,
  }) {
    // 中文注释: 布局分档延续旧项目的三档策略，并把高 DPI 窄屏横屏设备从过密布局里保守拉回来。
    if (width <= 0 || height <= 0) {
      return AppLayoutMode.compact;
    }
    final aspect = width / height;
    final compactWide = !isTabletLike && isLandscape;

    if (aspect >= (2 / 3) && aspect <= (3 / 2)) {
      var threshold = 840.0;
      if (compactWide && devicePixelRatio >= 2.2) {
        threshold += 40.0;
      }
      return width >= threshold ? AppLayoutMode.medium : AppLayoutMode.compact;
    }

    if (aspect > (3 / 2)) {
      final wideThreshold = compactWide ? 1186.0 : 1136.0;
      if (width >= wideThreshold) {
        return AppLayoutMode.expanded;
      }
      return AppLayoutMode.compact;
    }

    return AppLayoutMode.compact;
  }
}
