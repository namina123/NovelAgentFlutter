import '../../presentation/models/document_workspace_display_mode_policy.dart';
import '../../presentation/models/workbench_canvas_view_data.dart';
import '../../presentation/widgets/document_workspace_display_mode.dart';

class DocumentWorkspaceDisplayModePolicyService {
  const DocumentWorkspaceDisplayModePolicyService();

  DocumentWorkspaceDisplayModePolicy resolve({
    required WorkbenchCanvasViewData viewData,
    required bool prefersStructureMode,
  }) {
    final hasDocument = viewData.documents.isNotEmpty;
    final canRender = hasDocument && viewData.activeDocumentCanRender;
    final canInspectStructure = hasDocument;
    final selectedMode = _selectedMode(
      viewData: viewData,
      prefersStructureMode: prefersStructureMode,
      hasDocument: hasDocument,
    );
    return DocumentWorkspaceDisplayModePolicy(
      selectedMode: selectedMode,
      hasDocument: hasDocument,
      canRender: canRender,
      canInspectStructure: canInspectStructure,
    );
  }

  bool prefersStructureModeAfterSelection(DocumentWorkspaceDisplayMode mode) {
    return mode == DocumentWorkspaceDisplayMode.structure;
  }

  bool shouldRequestRenderToggle({
    required DocumentWorkspaceDisplayMode requestedMode,
    required bool isActiveDocumentRendered,
  }) {
    final shouldRender = requestedMode == DocumentWorkspaceDisplayMode.render;
    return shouldRender != isActiveDocumentRendered;
  }

  DocumentWorkspaceDisplayMode _selectedMode({
    required WorkbenchCanvasViewData viewData,
    required bool prefersStructureMode,
    required bool hasDocument,
  }) {
    if (prefersStructureMode && hasDocument) {
      return DocumentWorkspaceDisplayMode.structure;
    }
    return viewData.isActiveDocumentRendered
        ? DocumentWorkspaceDisplayMode.render
        : DocumentWorkspaceDisplayMode.source;
  }
}
