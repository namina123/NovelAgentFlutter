import 'package:flutter/material.dart';

import '../theme/novel_theme_context.dart';

enum PanelSurfaceRole { panel, sidebar, inputDock }

class PanelSurface extends StatelessWidget {
  const PanelSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.showBorder = true,
    this.role = PanelSurfaceRole.panel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final bool showBorder;
  final PanelSurfaceRole role;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 通用面板容器统一处理边框和表面风格，方便后续整体切换工作区视觉语言。
    final spec = switch (role) {
      PanelSurfaceRole.panel => context.novelThemeSurfaces.panel,
      PanelSurfaceRole.sidebar => context.novelThemeSurfaces.sidebar,
      PanelSurfaceRole.inputDock => context.novelThemeSurfaces.inputDock,
    };
    final chrome = context.novelPanelChrome;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? chrome.radius),
        border: showBorder
            ? Border.all(color: spec.borderColor, width: chrome.borderWidth)
            : null,
        boxShadow: chrome.shadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
