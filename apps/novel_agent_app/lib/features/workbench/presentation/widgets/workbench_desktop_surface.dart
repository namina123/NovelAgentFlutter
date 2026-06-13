import 'package:flutter/material.dart';

import 'workbench_desktop_style.dart';

class WorkbenchDesktopSurface extends StatelessWidget {
  const WorkbenchDesktopSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 桌面工作区底板改成更完整的一体化舞台，强化沉浸感但不改变栏位结构。
    final style = WorkbenchDesktopStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.surfaceBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.surfaceBackgroundColor,
            style.surfaceBackgroundColor.withValues(alpha: 0.985),
          ],
        ),
      ),
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.9, -1.06),
                      radius: 1.18,
                      colors: [
                        style.surfaceOverlayColor.withValues(alpha: 0.78),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        style.surfaceOverlayColor.withValues(alpha: 0.6),
                        style.surfaceOverlayColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(style.surfaceRadius),
                      border: Border.all(
                        color: style.paneFrameBorderColor.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
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
