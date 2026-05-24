import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import 'resizable_documents_workspace_layout.dart';

class DocumentsWorkspaceShell extends StatelessWidget {
  const DocumentsWorkspaceShell({
    super.key,
    required this.navigationPane,
    required this.documentPane,
    required this.onCloseRequested,
  });

  final Widget navigationPane;
  final Widget documentPane;
  final VoidCallback onCloseRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档工作区壳层只负责提供返回会话的顶栏和两栏内容容器，不直接理解资源树或正文细节。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                tooltip: '返回会话',
                onPressed: onCloseRequested,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                '文档工作区',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: ResizableDocumentsWorkspaceLayout(
            navigationPane: PanelSurface(
              showBorder: false,
              padding: EdgeInsets.zero,
              child: navigationPane,
            ),
            documentPane: PanelSurface(
              showBorder: false,
              padding: EdgeInsets.zero,
              child: documentPane,
            ),
          ),
        ),
      ],
    );
  }
}
