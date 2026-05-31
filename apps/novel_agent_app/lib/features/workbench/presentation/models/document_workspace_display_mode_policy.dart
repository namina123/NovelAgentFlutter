import '../widgets/document_workspace_display_mode.dart';

class DocumentWorkspaceDisplayModePolicy {
  const DocumentWorkspaceDisplayModePolicy({
    required this.selectedMode,
    required this.hasDocument,
    required this.canRender,
    required this.canInspectStructure,
  });

  final DocumentWorkspaceDisplayMode selectedMode;
  final bool hasDocument;
  final bool canRender;
  final bool canInspectStructure;
}
