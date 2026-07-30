import 'package:flutter/material.dart';

import '../layout/workbench_pane_layout_policy.dart';
import 'workbench_desktop_style.dart';

class PaneResizeDivider extends StatefulWidget {
  const PaneResizeDivider({
    super.key,
    required this.onDragUpdate,
    required this.cursor,
    this.onResetRequested,
  });

  final ValueChanged<double> onDragUpdate;
  final MouseCursor cursor;

  /// 双击分隔条时的回调（通常把分栏宽度重置为默认）。为空时不绑定双击重置。
  final VoidCallback? onResetRequested;

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
    return Tooltip(
      message: widget.onResetRequested == null
          ? '拖动调整分栏宽度'
          : '拖动调整分栏宽度，双击恢复默认',
      waitDuration: const Duration(milliseconds: 400),
      child: SizedBox(
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
                    onDoubleTap: widget.onResetRequested,
                    onHorizontalDragUpdate: (details) =>
                        widget.onDragUpdate(details.delta.dx),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
