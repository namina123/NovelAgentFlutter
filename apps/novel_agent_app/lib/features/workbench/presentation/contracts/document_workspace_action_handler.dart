enum DocumentToolbarAction { outline, preview, save, review }

abstract class DocumentWorkspaceActionHandler {
  void onDocumentActionRequested(DocumentToolbarAction action);

  void onDocumentBodyChanged(String value);
}
