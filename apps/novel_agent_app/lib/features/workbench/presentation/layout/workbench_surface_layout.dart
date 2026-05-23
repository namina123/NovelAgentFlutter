enum WorkbenchSurfaceMode {
  immersiveConversation,
  singleConversation,
  documentsWorkspace,
  twoPane,
  threePane,
}

class WorkbenchSurfaceLayout {
  const WorkbenchSurfaceLayout({
    required this.mode,
    required this.showWorkspaceShortcuts,
  });

  final WorkbenchSurfaceMode mode;
  final bool showWorkspaceShortcuts;
}
