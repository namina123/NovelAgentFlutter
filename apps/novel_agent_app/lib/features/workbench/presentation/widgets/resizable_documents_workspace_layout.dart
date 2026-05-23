import 'package:flutter/material.dart';

import '../layout/documents_workspace_layout_policy.dart';
import 'pane_resize_divider.dart';

class ResizableDocumentsWorkspaceLayout extends StatefulWidget {
  const ResizableDocumentsWorkspaceLayout({
    super.key,
    required this.navigationPane,
    required this.documentPane,
  });

  final Widget navigationPane;
  final Widget documentPane;

  @override
  State<ResizableDocumentsWorkspaceLayout> createState() =>
      _ResizableDocumentsWorkspaceLayoutState();
}

class _ResizableDocumentsWorkspaceLayoutState
    extends State<ResizableDocumentsWorkspaceLayout> {
  double? _navigationWidth;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档退化页只维护两栏比例，避免把宽屏三栏的尺寸状态带到这里。
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final minWidth = DocumentsWorkspaceLayoutPolicy.minNavigationWidth(
          totalWidth,
        );
        final maxWidth = DocumentsWorkspaceLayoutPolicy.maxNavigationWidth(
          totalWidth,
        );
        final leftWidth =
            _navigationWidth ??
            DocumentsWorkspaceLayoutPolicy.defaultNavigationWidth(totalWidth);
        final resolvedWidth = leftWidth.clamp(minWidth, maxWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: resolvedWidth, child: widget.navigationPane),
            PaneResizeDivider(
              cursor: SystemMouseCursors.resizeColumn,
              onDragUpdate: (delta) {
                setState(() {
                  _navigationWidth = (resolvedWidth + delta).clamp(
                    minWidth,
                    maxWidth,
                  );
                });
              },
            ),
            Expanded(child: widget.documentPane),
          ],
        );
      },
    );
  }
}
