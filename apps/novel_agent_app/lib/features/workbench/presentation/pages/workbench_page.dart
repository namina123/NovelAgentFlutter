import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../../../../../app/layout/app_layout_metrics.dart';
import '../../../../../app/layout/app_layout_scope.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../contracts/pending_research_action_handler.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../layout/workbench_surface_layout.dart';
import '../layout/workbench_surface_layout_policy.dart';
import '../layout/workbench_slot_id.dart';
import '../models/workbench_canvas_view_data.dart';
import '../models/workbench_conversation_view_data.dart';
import '../models/workbench_overlay_view_data.dart';
import '../models/workbench_resource_view_data.dart';
import '../../application/services/workbench_workspace_shell_view_data_service.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/documents_workspace_shell.dart';
import '../widgets/document_workspace_panel.dart';
import '../widgets/project_launcher_overlay.dart';
import '../widgets/project_agent_group_overlay.dart';
import '../widgets/resizable_workbench_layout.dart';
import '../widgets/resource_manager_panel.dart';
import '../widgets/workbench_canvas_workspace_shell.dart';
import '../widgets/workbench_compact_workspace_shell.dart';
import '../widgets/workbench_desktop_surface.dart';
import '../widgets/workbench_ide_shell.dart';
import '../widgets/workbench_desktop_section_id.dart';
import '../widgets/workbench_navigation_sidebar.dart';
import '../widgets/workbench_pane_shell.dart';
import '../widgets/workbench_slot_host.dart';
import '../widgets/workbench_two_pane_layout.dart';
import '../widgets/workspace_command_overlay.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({
    super.key,
    required this.resourceListenable,
    required this.canvasListenable,
    required this.conversationListenable,
    required this.overlayListenable,
    required this.resourceHandler,
    required this.documentHandler,
    required this.conversationHandler,
  });

  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchCanvasViewData> canvasListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ValueListenable<WorkbenchOverlayViewData> overlayListenable;
  final ResourceManagerActionHandler resourceHandler;
  final DocumentWorkspaceActionHandler documentHandler;
  final ConversationActionHandler conversationHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作台页面现在只负责拼接 pane host，各个 pane 自己监听自己的 slice，避免右栏流式输出拖整页重建。
    return Stack(
      children: [
        ValueListenableBuilder<WorkbenchCanvasViewData>(
          valueListenable: canvasListenable,
          builder: (context, canvasViewData, _) {
            final metrics = AppLayoutScope.of(context);
            final layout = WorkbenchSurfaceLayoutPolicy.resolve(
              metrics: metrics,
              isDocumentsWorkspaceVisible:
                  canvasViewData.isDocumentsWorkspaceVisible,
            );
            return AdaptivePageFrame(
              padding: EdgeInsets.zero,
              child: _WorkbenchLayoutHost(
                metrics: metrics,
                layout: layout,
                resourceListenable: resourceListenable,
                canvasListenable: canvasListenable,
                canvasViewData: canvasViewData,
                conversationListenable: conversationListenable,
                resourceHandler: resourceHandler,
                documentHandler: documentHandler,
                conversationHandler: conversationHandler,
              ),
            );
          },
        ),
        ValueListenableBuilder<WorkbenchOverlayViewData>(
          valueListenable: overlayListenable,
          builder: (context, overlayViewData, _) {
            return _WorkbenchOverlayHost(
              viewData: overlayViewData,
              actionHandler: resourceHandler,
            );
          },
        ),
      ],
    );
  }
}

class _WorkbenchLayoutHost extends StatelessWidget {
  const _WorkbenchLayoutHost({
    required this.metrics,
    required this.layout,
    required this.resourceListenable,
    required this.canvasListenable,
    required this.canvasViewData,
    required this.conversationListenable,
    required this.resourceHandler,
    required this.documentHandler,
    required this.conversationHandler,
  });

  static const WorkbenchWorkspaceShellViewDataService _shellViewDataService =
      WorkbenchWorkspaceShellViewDataService();

  final AppLayoutMetrics metrics;
  final WorkbenchSurfaceLayout layout;
  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchCanvasViewData> canvasListenable;
  final WorkbenchCanvasViewData canvasViewData;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ResourceManagerActionHandler resourceHandler;
  final DocumentWorkspaceActionHandler documentHandler;
  final ConversationActionHandler conversationHandler;

  @override
  Widget build(BuildContext context) {
    final shellViewData = _shellViewDataService.build(
      resource: resourceListenable.value,
      canvas: canvasViewData,
      conversation: conversationListenable.value,
    );
    switch (layout.mode) {
      case WorkbenchSurfaceMode.immersiveConversation:
        return WorkbenchSlotHost(
          entries: _slotEntries(),
          builder: (context, slots) {
            return PanelSurface(
              role: PanelSurfaceRole.sidebar,
              child: slots.require(WorkbenchSlotId.conversationPane),
            );
          },
        );
      case WorkbenchSurfaceMode.compactWorkbench:
        return WorkbenchCompactWorkspaceShell(
          viewData: shellViewData,
          workspacePane: _CompactWorkspacePaneHost(
            resourceListenable: resourceListenable,
            canvasListenable: canvasListenable,
            conversationListenable: conversationListenable,
            resourceHandler: resourceHandler,
          ),
          documentPane: _CompactDocumentPaneHost(
            viewData: canvasViewData,
            resourceListenable: resourceListenable,
            conversationListenable: conversationListenable,
            actionHandler: documentHandler,
            resourceHandler: resourceHandler,
            conversationHandler: conversationHandler,
          ),
          conversationPane: _ConversationPaneHost(
            conversationListenable: conversationListenable,
            actionHandler: conversationHandler,
            showWorkspaceShortcuts: false,
          ),
          isDocumentsWorkspaceVisible:
              canvasViewData.isDocumentsWorkspaceVisible,
          onDocumentViewRequested:
              conversationHandler.onDocumentsWorkspaceRequested,
          onNonDocumentViewRequested:
              conversationHandler.onDocumentsWorkspaceDismissRequested,
        );
      case WorkbenchSurfaceMode.singleConversation:
        return WorkbenchSlotHost(
          entries: _slotEntries(),
          builder: (context, slots) {
            return PanelSurface(
              role: PanelSurfaceRole.sidebar,
              child: slots.require(WorkbenchSlotId.conversationPane),
            );
          },
        );
      case WorkbenchSurfaceMode.documentsWorkspace:
        return WorkbenchSlotHost(
          entries: _slotEntries(),
          builder: (context, slots) {
            return DocumentsWorkspaceShell(
              navigationPane: slots.require(WorkbenchSlotId.resourcePane),
              documentPane: slots.require(WorkbenchSlotId.canvasPane),
              onCloseRequested:
                  conversationHandler.onDocumentsWorkspaceDismissRequested,
            );
          },
        );
      case WorkbenchSurfaceMode.twoPane:
        return WorkbenchSlotHost(
          entries: _slotEntries(
            documentShowLeftOuterBorder: true,
            conversationDesktopShowRightOuterBorder: true,
          ),
          builder: (context, slots) {
            return WorkbenchIdeShell(
              metrics: metrics,
              viewData: shellViewData,
              child: WorkbenchDesktopSurface(
                child: WorkbenchTwoPaneLayout(
                  metrics: metrics,
                  documentPane: slots.require(WorkbenchSlotId.canvasPane),
                  conversationPane: slots.require(
                    WorkbenchSlotId.conversationPane,
                  ),
                ),
              ),
            );
          },
        );
      case WorkbenchSurfaceMode.threePane:
        return WorkbenchSlotHost(
          entries: _slotEntries(
            resourceDesktopShowLeftOuterBorder: true,
            conversationDesktopShowRightOuterBorder: true,
          ),
          builder: (context, slots) {
            return WorkbenchIdeShell(
              metrics: metrics,
              viewData: shellViewData,
              child: WorkbenchDesktopSurface(
                child: ResizableWorkbenchLayout(
                  metrics: metrics,
                  leftPane: slots.require(WorkbenchSlotId.resourcePane),
                  documentPane: slots.require(WorkbenchSlotId.canvasPane),
                  conversationPane: slots.require(
                    WorkbenchSlotId.conversationPane,
                  ),
                ),
              ),
            );
          },
        );
    }
  }

  List<WorkbenchSlotEntry> _slotEntries({
    bool resourceDesktopShowLeftOuterBorder = false,
    bool documentShowLeftOuterBorder = false,
    bool conversationDesktopShowRightOuterBorder = false,
  }) {
    return [
      WorkbenchSlotEntry(
        slotId: WorkbenchSlotId.resourcePane,
        child:
            layout.mode == WorkbenchSurfaceMode.threePane ||
                layout.mode == WorkbenchSurfaceMode.documentsWorkspace
            ? _DesktopResourcePaneHost(
                resourceListenable: resourceListenable,
                canvasListenable: canvasListenable,
                conversationListenable: conversationListenable,
                actionHandler: resourceHandler,
                showLeftOuterBorder: resourceDesktopShowLeftOuterBorder,
              )
            : _ResourcePaneHost(
                resourceListenable: resourceListenable,
                actionHandler: resourceHandler,
              ),
      ),
      WorkbenchSlotEntry(
        slotId: WorkbenchSlotId.canvasPane,
        child: layout.mode == WorkbenchSurfaceMode.documentsWorkspace
            ? DocumentWorkspacePanel(
                viewData: canvasViewData,
                actionHandler: documentHandler,
              )
            : _DocumentPaneHost(
                viewData: canvasViewData,
                resourceListenable: resourceListenable,
                conversationListenable: conversationListenable,
                actionHandler: documentHandler,
                resourceHandler: resourceHandler,
                conversationHandler: conversationHandler,
                showLeftOuterBorder: documentShowLeftOuterBorder,
              ),
      ),
      WorkbenchSlotEntry(
        slotId: WorkbenchSlotId.conversationPane,
        child:
            layout.mode == WorkbenchSurfaceMode.immersiveConversation ||
                layout.mode == WorkbenchSurfaceMode.singleConversation
            ? _ConversationPaneHost(
                conversationListenable: conversationListenable,
                actionHandler: conversationHandler,
                showWorkspaceShortcuts: layout.showWorkspaceShortcuts,
              )
            : _DesktopConversationPaneHost(
                conversationListenable: conversationListenable,
                actionHandler: conversationHandler,
                showRightOuterBorder: conversationDesktopShowRightOuterBorder,
                showWorkspaceShortcuts: layout.showWorkspaceShortcuts,
              ),
      ),
    ];
  }
}

class _ResourcePaneHost extends StatelessWidget {
  const _ResourcePaneHost({
    required this.resourceListenable,
    required this.actionHandler,
  });

  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ResourceManagerActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WorkbenchResourceViewData>(
      valueListenable: resourceListenable,
      builder: (context, viewData, _) {
        final pendingResearchActionHandler =
            actionHandler is PendingResearchActionHandler
            ? actionHandler as PendingResearchActionHandler
            : null;
        return ResourceManagerPanel(
          viewData: viewData,
          actionHandler: actionHandler,
          pendingResearchActionHandler: pendingResearchActionHandler,
        );
      },
    );
  }
}

class _DesktopResourcePaneHost extends StatelessWidget {
  const _DesktopResourcePaneHost({
    required this.resourceListenable,
    required this.canvasListenable,
    required this.conversationListenable,
    required this.actionHandler,
    this.showLeftOuterBorder = false,
  });

  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchCanvasViewData> canvasListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ResourceManagerActionHandler actionHandler;
  final bool showLeftOuterBorder;

  @override
  Widget build(BuildContext context) {
    return WorkbenchPaneShell(
      sectionId: WorkbenchDesktopSectionId.navigation,
      showLeftOuterBorder: showLeftOuterBorder,
      child: WorkbenchNavigationSidebar(
        resourceListenable: resourceListenable,
        canvasListenable: canvasListenable,
        conversationListenable: conversationListenable,
        resourceHandler: actionHandler,
      ),
    );
  }
}

class _CompactWorkspacePaneHost extends StatelessWidget {
  const _CompactWorkspacePaneHost({
    required this.resourceListenable,
    required this.canvasListenable,
    required this.conversationListenable,
    required this.resourceHandler,
  });

  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchCanvasViewData> canvasListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ResourceManagerActionHandler resourceHandler;

  @override
  Widget build(BuildContext context) {
    return WorkbenchNavigationSidebar(
      resourceListenable: resourceListenable,
      canvasListenable: canvasListenable,
      conversationListenable: conversationListenable,
      resourceHandler: resourceHandler,
    );
  }
}

class _DocumentPaneHost extends StatelessWidget {
  const _DocumentPaneHost({
    required this.viewData,
    required this.resourceListenable,
    required this.conversationListenable,
    required this.actionHandler,
    required this.resourceHandler,
    required this.conversationHandler,
    this.showLeftOuterBorder = false,
  });

  final WorkbenchCanvasViewData viewData;
  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final DocumentWorkspaceActionHandler actionHandler;
  final ResourceManagerActionHandler resourceHandler;
  final ConversationActionHandler conversationHandler;
  final bool showLeftOuterBorder;

  @override
  Widget build(BuildContext context) {
    return WorkbenchPaneShell(
      sectionId: WorkbenchDesktopSectionId.primaryCanvas,
      showLeftOuterBorder: showLeftOuterBorder,
      child: WorkbenchCanvasWorkspaceShell(
        canvasViewData: viewData,
        resourceListenable: resourceListenable,
        conversationListenable: conversationListenable,
        documentHandler: actionHandler,
        resourceHandler: resourceHandler,
        conversationHandler: conversationHandler,
      ),
    );
  }
}

class _CompactDocumentPaneHost extends StatelessWidget {
  const _CompactDocumentPaneHost({
    required this.viewData,
    required this.resourceListenable,
    required this.conversationListenable,
    required this.actionHandler,
    required this.resourceHandler,
    required this.conversationHandler,
  });

  final WorkbenchCanvasViewData viewData;
  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final DocumentWorkspaceActionHandler actionHandler;
  final ResourceManagerActionHandler resourceHandler;
  final ConversationActionHandler conversationHandler;

  @override
  Widget build(BuildContext context) {
    return WorkbenchCanvasWorkspaceShell(
      canvasViewData: viewData,
      resourceListenable: resourceListenable,
      conversationListenable: conversationListenable,
      documentHandler: actionHandler,
      resourceHandler: resourceHandler,
      conversationHandler: conversationHandler,
    );
  }
}

class _ConversationPaneHost extends StatelessWidget {
  const _ConversationPaneHost({
    required this.conversationListenable,
    required this.actionHandler,
    required this.showWorkspaceShortcuts,
  });

  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ConversationActionHandler actionHandler;
  final bool showWorkspaceShortcuts;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WorkbenchConversationViewData>(
      valueListenable: conversationListenable,
      builder: (context, viewData, _) {
        return ConversationSidebar(
          viewData: viewData,
          actionHandler: actionHandler,
          showWorkspaceShortcuts: showWorkspaceShortcuts,
        );
      },
    );
  }
}

class _DesktopConversationPaneHost extends StatelessWidget {
  const _DesktopConversationPaneHost({
    required this.conversationListenable,
    required this.actionHandler,
    required this.showRightOuterBorder,
    required this.showWorkspaceShortcuts,
  });

  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ConversationActionHandler actionHandler;
  final bool showRightOuterBorder;
  final bool showWorkspaceShortcuts;

  @override
  Widget build(BuildContext context) {
    return WorkbenchPaneShell(
      sectionId: WorkbenchDesktopSectionId.collaboration,
      showRightOuterBorder: showRightOuterBorder,
      child: _ConversationPaneHost(
        conversationListenable: conversationListenable,
        actionHandler: actionHandler,
        showWorkspaceShortcuts: showWorkspaceShortcuts,
      ),
    );
  }
}

class _WorkbenchOverlayHost extends StatelessWidget {
  const _WorkbenchOverlayHost({
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchOverlayViewData viewData;
  final ResourceManagerActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 浮层宿主单独监听 overlay slice，这样会话流式与资源树变化都不会把弹层一起拖着重建。
    return Stack(
      children: [
        if (viewData.projectLauncher != null)
          ProjectLauncherOverlay(
            viewData: viewData.projectLauncher!,
            actionHandler: actionHandler,
          ),
        if (viewData.projectAgentGroupWorkspace != null)
          ProjectAgentGroupOverlay(
            viewData: viewData.projectAgentGroupWorkspace!,
            actionHandler: actionHandler,
          ),
        if (viewData.workspaceCommand != null)
          WorkspaceCommandOverlay(
            viewData: viewData.workspaceCommand!,
            actionHandler: actionHandler,
          ),
      ],
    );
  }
}
