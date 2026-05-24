import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';

class PaneResizeDivider extends StatelessWidget {
  const PaneResizeDivider({
    super.key,
    required this.onDragUpdate,
    required this.cursor,
  });

  final ValueChanged<double> onDragUpdate;
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 分隔条只处理拖拽手势和视觉反馈，不关心具体是哪两栏在参与尺寸变化。
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
        child: SizedBox(
          width: 10,
          child: Center(
            child: Container(
              width: 1,
              color: isDark ? theme.colorScheme.outline : AppPalette.line,
            ),
          ),
        ),
      ),
    );
  }
}
