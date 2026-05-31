import 'package:flutter/material.dart';

import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../../application/controllers/project_assets_controller.dart';
import '../widgets/project_assets_detail_panel.dart';
import '../widgets/project_assets_entry_list_panel.dart';
import '../widgets/project_assets_sidebar_panel.dart';
import '../widgets/project_assets_toolbar.dart';

class ProjectAssetsPage extends StatelessWidget {
  const ProjectAssetsPage({super.key, required this.controller});

  final ProjectAssetsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        return WorkspacePageScaffold(
          header: ProjectAssetsToolbar(
            controller: controller,
            viewData: viewData,
          ),
          statusText: viewData.status,
          isLoading: viewData.isLoading,
          body: WorkspacePaneLayout(
            breakpoint: 1180,
            leadingPaneWidth: 280,
            trailingPaneWidth: 340,
            leadingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: ProjectAssetsEntryListPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            mainPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: ProjectAssetsDetailPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            trailingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: ProjectAssetsSidebarPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
          ),
        );
      },
    );
  }
}
