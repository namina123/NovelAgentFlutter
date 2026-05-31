import 'package:flutter/material.dart';

import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../../application/controllers/book_deconstruction_controller.dart';
import '../widgets/book_deconstruction_import_panel.dart';
import '../widgets/book_deconstruction_preview_panel.dart';
import '../widgets/book_deconstruction_step_panel.dart';
import '../widgets/book_deconstruction_toolbar.dart';

class BookDeconstructionPage extends StatelessWidget {
  const BookDeconstructionPage({super.key, required this.controller});

  final BookDeconstructionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        return WorkspacePageScaffold(
          header: BookDeconstructionToolbar(
            controller: controller,
            viewData: viewData,
          ),
          statusText: viewData.status,
          isLoading: viewData.isLoading,
          body: WorkspacePaneLayout(
            breakpoint: 1240,
            leadingPaneWidth: 260,
            trailingPaneWidth: 460,
            trailingCompactHeight: 320,
            leadingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: BookDeconstructionStepPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            mainPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: BookDeconstructionImportPanel(
                viewData: viewData,
                actionHandler: controller,
              ),
            ),
            trailingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: BookDeconstructionPreviewPanel(
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
