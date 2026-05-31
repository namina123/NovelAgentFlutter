import 'package:flutter/material.dart';

import '../layout/workbench_pane_layout_policy.dart';
import 'workbench_desktop_style.dart';

class PaneResizeDivider extends StatefulWidget {
  const PaneResizeDivider({
    super.key,
    required this.onDragUpdate,
    required this.cursor,
  });

  final ValueChanged<double> onDragUpdate;
  final MouseCursor cursor;

  static const shellKey = ValueKey<String>('pane_resize_divider_shell');
  static const lineKey = ValueKey<String>('pane_resize_divider_line');
  static const hitAreaKey = ValueKey<String>('pane_resize_divider_hit_area');

  @override
  State<PaneResizeDivider> createState() => _PaneResizeDividerState();
}

class _PaneResizeDividerState extends State<PaneResizeDivider> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 分隔条只处理桌面分栏拖拽与悬停反馈，不介入三栏宽度策略本身。
    final style = WorkbenchDesktopStyle.of(context);
    return SizedBox(
      key: PaneResizeDivider.shellKey,
      width: WorkbenchPaneLayoutPolicy.dividerWidth,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  key: PaneResizeDivider.lineKey,
                  duration: const Duration(milliseconds: 140),
                  width: WorkbenchPaneLayoutPolicy.dividerWidth,
                  color: _isHovered
                      ? style.dividerActiveHandleColor
                      : style.dividerHandleColor,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: OverflowBox(
              minWidth: WorkbenchPaneLayoutPolicy.dividerHitWidth,
              maxWidth: WorkbenchPaneLayoutPolicy.dividerHitWidth,
              alignment: Alignment.center,
              child: MouseRegion(
                cursor: widget.cursor,
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  key: PaneResizeDivider.hitAreaKey,
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) =>
                      widget.onDragUpdate(details.delta.dx),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
