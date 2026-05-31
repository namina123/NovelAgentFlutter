import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_character_path_policy.dart';

class ProjectCharacterRuntimeStateRepository {
  ProjectCharacterRuntimeStateRepository({
    required ProjectToolHostPort hostPort,
    ProjectCharacterPathPolicy? pathPolicy,
    CharacterStageStateRecordMarkdownCodecService? latestStateCodecService,
    CharacterStateHistoryMarkdownRenderer? historyRenderer,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectCharacterPathPolicy(),
       _latestStateCodecService =
           latestStateCodecService ??
           CharacterStageStateRecordMarkdownCodecService(),
       _historyRenderer =
           historyRenderer ?? const CharacterStateHistoryMarkdownRenderer();

  final ProjectToolHostPort _hostPort;
  final ProjectCharacterPathPolicy _pathPolicy;
  final CharacterStageStateRecordMarkdownCodecService _latestStateCodecService;
  final CharacterStateHistoryMarkdownRenderer _historyRenderer;

  Future<void> saveLatestState(
    ProjectDescriptor project, {
    required CharacterStageStateRecord record,
  }) {
    final path = _pathPolicy.latestStatePath(record.characterId);
    // 中文注释: latest 快照每次覆盖同一路径，给排查和恢复留下最新一份确定状态。
    return _hostPort.writeTextFile(
      project.rootPath,
      path,
      _latestStateCodecService.encode(record),
    );
  }

  Future<void> appendHistory(
    ProjectDescriptor project, {
    required CharacterStageStateRecord record,
  }) async {
    // 中文注释: 历史附录单独维护，避免把追加记录掺进主档或 latest 快照里。
    final path = _pathPolicy.historyPath(record.characterId);
    final existing = await _hostPort.readTextFile(project.rootPath, path) ?? '';
    final next = _historyRenderer.appendEntry(
      existingContent: existing,
      record: record,
    );
    await _hostPort.writeTextFile(project.rootPath, path, next);
  }
}
