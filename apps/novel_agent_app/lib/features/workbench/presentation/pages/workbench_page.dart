import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../../../../../app/layout/app_layout_metrics.dart';
import '../../../../../app/layout/app_layout_scope.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../layout/workbench_surface_layout.dart';
import '../layout/workbench_surface_layout_policy.dart';
import '../models/workbench_view_data.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/documents_workspace_shell.dart';
import '../widgets/document_workspace_panel.dart';
import '../widgets/project_launcher_overlay.dart';
import '../widgets/resizable_workbench_layout.dart';
import '../widgets/resource_manager_panel.dart';
import '../widgets/workspace_command_overlay.dart';
import '../widgets/workbench_two_pane_layout.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({
    super.key,
    required this.viewData,
    required this.resourceHandler,
    required this.documentHandler,
    required this.conversationHandler,
  });

  final WorkbenchViewData viewData;
  final ResourceManagerActionHandler resourceHandler;
  final DocumentWorkspaceActionHandler documentHandler;
  final ConversationActionHandler conversationHandler;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutScope.of(context);
    final layout = WorkbenchSurfaceLayoutPolicy.resolve(
      metrics: metrics,
      isDocumentsWorkspaceVisible: viewData.isDocumentsWorkspaceVisible,
    );
    final body = AdaptivePageFrame(
      padding: EdgeInsets.zero,
      child: _buildLayout(metrics, layout),
    );

    // 中文注释: 页面主体和项目弹层通过 Stack 组合，这样项目入口不会侵入各个栏位组件自己的职责。
    return Stack(
      children: [
        body,
        if (viewData.projectLauncher != null)
          ProjectLauncherOverlay(
            viewData: viewData.projectLauncher!,
            actionHandler: resourceHandler,
          ),
        if (viewData.workspaceCommand != null)
          WorkspaceCommandOverlay(
            viewData: viewData.workspaceCommand!,
            actionHandler: resourceHandler,
          ),
      ],
    );
  }

  Widget _buildLayout(AppLayoutMetrics metrics, WorkbenchSurfaceLayout layout) {
    switch (layout.mode) {
      case WorkbenchSurfaceMode.immersiveConversation:
      case WorkbenchSurfaceMode.singleConversation:
        return PanelSurface(
          child: ConversationSidebar(
            viewData: viewData,
            actionHandler: conversationHandler,
            showWorkspaceShortcuts: layout.showWorkspaceShortcuts,
          ),
        );
      case WorkbenchSurfaceMode.documentsWorkspace:
        return DocumentsWorkspaceShell(
          navigationPane: ResourceManagerPanel(
            viewData: viewData,
            actionHandler: resourceHandler,
          ),
          documentPane: DocumentWorkspacePanel(
            viewData: viewData,
            actionHandler: documentHandler,
          ),
          onCloseRequested:
              conversationHandler.onDocumentsWorkspaceDismissRequested,
        );
      case WorkbenchSurfaceMode.twoPane:
        return WorkbenchTwoPaneLayout(
          metrics: metrics,
          documentPane: PanelSurface(
            child: DocumentWorkspacePanel(
              viewData: viewData,
              actionHandler: documentHandler,
            ),
          ),
          conversationPane: PanelSurface(
            child: ConversationSidebar(
              viewData: viewData,
              actionHandler: conversationHandler,
              showWorkspaceShortcuts: layout.showWorkspaceShortcuts,
            ),
          ),
        );
      case WorkbenchSurfaceMode.threePane:
        return ResizableWorkbenchLayout(
          metrics: metrics,
          leftPane: PanelSurface(
            child: ResourceManagerPanel(
              viewData: viewData,
              actionHandler: resourceHandler,
            ),
          ),
          documentPane: PanelSurface(
            child: DocumentWorkspacePanel(
              viewData: viewData,
              actionHandler: documentHandler,
            ),
          ),
          conversationPane: PanelSurface(
            child: ConversationSidebar(
              viewData: viewData,
              actionHandler: conversationHandler,
            ),
          ),
        );
    }
  }
}
