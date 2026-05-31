import 'package:flutter/material.dart';

import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../../application/controllers/inspiration_workbench_controller.dart';
import '../widgets/inspiration_editor_panel.dart';
import '../widgets/inspiration_mode_selector.dart';
import '../widgets/inspiration_preview_panel.dart';
import '../widgets/inspiration_stage_list_panel.dart';
import '../widgets/inspiration_workbench_toolbar.dart';

class InspirationWorkbenchPage extends StatelessWidget {
  const InspirationWorkbenchPage({super.key, required this.controller});

  final InspirationWorkbenchController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        return WorkspacePageScaffold(
          header: InspirationWorkbenchToolbar(
            viewData: viewData,
            actionHandler: controller,
          ),
          headerBottom: InspirationModeSelector(
            viewData: viewData,
            actionHandler: controller,
          ),
          statusText: viewData.status,
          isLoading: viewData.isLoading,
          body: WorkspacePaneLayout(
            breakpoint: 1180,
            leadingPaneWidth: 300,
            trailingPaneWidth: 360,
            leadingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: InspirationStageListPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            mainPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: InspirationEditorPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            trailingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: InspirationPreviewPanel(viewData: viewData),
            ),
          ),
        );
      },
    );
  }
}
