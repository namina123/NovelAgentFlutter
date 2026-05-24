enum DocumentToolbarAction { outline, render, save, review }

abstract class DocumentWorkspaceActionHandler {
  void onDocumentActionRequested(DocumentToolbarAction action);

  void onDocumentSelected(String documentId);

  void onDocumentClosed(String documentId);

  void onDocumentBodyChanged(String value);
}
