class ModeGuidanceWorkspacePathService {
  const ModeGuidanceWorkspacePathService();

  String summaryMarkdownPath(String modeId) {
    final cleanModeId = _safeModeId(modeId);
    return 'tracking/modes/$cleanModeId/guidance.md';
  }

  String hiddenStateJsonPath(String modeId) {
    final cleanModeId = _safeModeId(modeId);
    return '.novel_agent/modes/$cleanModeId/guidance_state.json';
  }

  String _safeModeId(String modeId) {
    final clean = modeId.trim().replaceAll('\\', '_').replaceAll('/', '_');
    return clean.isEmpty ? 'unknown_mode' : clean;
  }
}
