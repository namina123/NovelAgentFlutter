import 'package:flutter/material.dart';

import '../contracts/document_workspace_action_handler.dart';
import '../models/workbench_canvas_view_data.dart';
import 'workbench_primary_canvas_host.dart';

class DocumentWorkspacePanel extends StatelessWidget {
  const DocumentWorkspacePanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchCanvasViewData viewData;
  final DocumentWorkspaceActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档工作区页面本身退成薄壳，真正的主画布逻辑交给 primary canvas host。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: WorkbenchPrimaryCanvasHost(
        viewData: viewData,
        actionHandler: actionHandler,
      ),
    );
  }
}
