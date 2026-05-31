import 'package:flutter/material.dart';

import 'workbench_desktop_style.dart';

class WorkbenchDesktopSurface extends StatelessWidget {
  const WorkbenchDesktopSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 桌面工作区底板只保留整体背景与外边距，避免再套一层总边框抢走各分栏的层级。
    final style = WorkbenchDesktopStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: style.surfaceBackgroundColor),
      child: Padding(
        padding: style.surfacePadding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(style.surfaceRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: style.paneFrameColor),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 32,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: style.surfaceOverlayColor),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
