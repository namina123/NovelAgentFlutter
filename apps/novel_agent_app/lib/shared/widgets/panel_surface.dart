import 'package:flutter/material.dart';

import '../../app/theme/app_chrome.dart';
import '../../app/theme/app_palette.dart';

class PanelSurface extends StatelessWidget {
  const PanelSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppChrome.surfaceRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 通用面板容器统一处理边框和表面风格，方便后续整体切换工作区视觉语言。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.panel,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
        boxShadow: AppChrome.noShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
