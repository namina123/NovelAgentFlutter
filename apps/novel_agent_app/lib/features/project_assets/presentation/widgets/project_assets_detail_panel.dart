import 'package:flutter/material.dart';

import '../../application/models/project_assets_tab_id.dart';
import '../contracts/project_assets_action_handler.dart';
import '../models/project_assets_view_data.dart';
import 'project_rag_extraction_panel.dart';
import 'expression_constraint_binding_editor_panel.dart';
import 'foreshadow_record_editor_panel.dart';
import 'project_assets_inspector_panel.dart';
import 'style_profile_editor_panel.dart';

class ProjectAssetsDetailPanel extends StatelessWidget {
  const ProjectAssetsDetailPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectAssetsViewData viewData;
  final ProjectAssetsActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    switch (viewData.activeTabId) {
      case ProjectAssetsTabId.styles:
        return StyleProfileEditorPanel(
          viewData: viewData.styleEditor,
          onSaveRequested: actionHandler.onProjectAssetsSaveStyleRequested,
          onDeleteRequested: (id) => actionHandler
              .onProjectAssetsDeleteRequested(kind: 'style', id: id),
        );
      case ProjectAssetsTabId.expressionConstraints:
        return ExpressionConstraintBindingEditorPanel(
          viewData: viewData.expressionConstraintEditor,
          onSaveRequested: actionHandler
              .onProjectAssetsSaveExpressionConstraintBindingRequested,
          onRemoveRequested: actionHandler
              .onProjectAssetsRemoveExpressionConstraintBindingRequested,
        );
      case ProjectAssetsTabId.ragExtraction:
        return ProjectRagExtractionPanel(
          viewData: viewData.ragExtraction,
          actionHandler: actionHandler,
        );
      case ProjectAssetsTabId.foreshadows:
        return ForeshadowRecordEditorPanel(
          viewData: viewData.foreshadowEditor,
          onSaveRequested: actionHandler.onProjectAssetsSaveForeshadowRequested,
          onDeleteRequested: (id) => actionHandler
              .onProjectAssetsDeleteRequested(kind: 'foreshadow', id: id),
        );
      default:
        return ProjectAssetsInspectorPanel(
          viewData: viewData.inspector,
          onReferenceSelected: actionHandler.onProjectAssetsReferenceSelected,
        );
    }
  }
}
