import '../tools/project_tool_path_policy.dart';

class ProjectCharacterPathPolicy {
  ProjectCharacterPathPolicy({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String profilePath(String characterId) {
    // 中文注释: 角色主档固定落在用户可见资产目录，避免继续在旧的 characters/ 下散写重复文件。
    return 'assets/characters/${_safeId(characterId)}.md';
  }

  String latestStatePath(String characterId) {
    // 中文注释: latest 状态快照放到隐藏运行态目录，既保留调试抓手，又不污染资源树。
    return '.novel_agent/state/characters/${_safeId(characterId)}/latest.md';
  }

  String historyPath(String characterId) {
    // 中文注释: 角色历史附录单文件持续追加，避免每次更新都制造一个新碎片文件。
    return '.novel_agent/state/characters/${_safeId(characterId)}/history.md';
  }

  String legacyProfilePath(String displayName) {
    return 'characters/${_toolPathPolicy.safeFileName(displayName)}.md';
  }

  String _safeId(String value) {
    return _toolPathPolicy.safeFileName(value, fallback: 'character');
  }
}
