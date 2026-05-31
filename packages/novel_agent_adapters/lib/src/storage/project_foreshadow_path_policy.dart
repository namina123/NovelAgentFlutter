import '../tools/project_tool_path_policy.dart';

class ProjectForeshadowPathPolicy {
  ProjectForeshadowPathPolicy({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String assetPath(String recordId) {
    // 中文注释: 伏笔主档统一进入 assets/foreshadows/，兼容期仅保留旧路径回读。
    return 'assets/foreshadows/${_safeId(recordId)}.foreshadow.md';
  }

  String legacyPath(String recordId) {
    return 'world/foreshadows/${_safeId(recordId)}.foreshadow.md';
  }

  String _safeId(String value) {
    return _toolPathPolicy.safeFileName(value, fallback: 'foreshadow');
  }
}
