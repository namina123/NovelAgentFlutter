import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_session_shell_service.dart';

/// CLI 侧的 [ConversationCommandBackend] 实现：包装 [ProjectSessionShellService]，
/// 把 core 命令的抽象动作映射到 shell service 的 (project, sessionId) 方法。
///
/// 命令层传入的 sessionRecord 仅用作失败时的回退；真正改写以 shell service 从磁盘
/// 加载并保存后的 session_record 为准，保证 CLI REPL 与持久化真相一致。
class ProjectSessionShellCommandBackend implements ConversationCommandBackend {
  ProjectSessionShellCommandBackend({
    required ProjectSessionShellService shellService,
    required ProjectDescriptor project,
    required String sessionId,
    SessionTokenBudgetSettings? budgetSettings,
  }) : _shellService = shellService,
       _project = project,
       _sessionId = sessionId,
       _budgetSettings = budgetSettings;

  final ProjectSessionShellService _shellService;
  final ProjectDescriptor _project;
  final String _sessionId;
  final SessionTokenBudgetSettings? _budgetSettings;

  @override
  Future<ConversationCommandBackendOutcome> compact(
    JsonMap sessionRecord,
  ) async {
    final result = await _shellService.compactSession(
      _project,
      _sessionId,
      settings: _budgetSettings,
    );
    return _toOutcome(result, fallback: sessionRecord, persist: true);
  }

  @override
  Future<ConversationCommandBackendOutcome> stats(JsonMap sessionRecord) async {
    final result = await _shellService.statsSession(
      _project,
      _sessionId,
      settings: _budgetSettings,
    );
    return _toOutcome(result, fallback: sessionRecord, persist: false);
  }

  @override
  Future<ConversationCommandBackendOutcome> setMode(
    JsonMap sessionRecord,
    String mode,
  ) async {
    final result = await _shellService.setMode(_project, _sessionId, mode);
    return _toOutcome(result, fallback: sessionRecord, persist: true);
  }

  @override
  Future<ConversationCommandBackendOutcome> setGoalText(
    JsonMap sessionRecord,
    String text,
  ) async {
    final result = await _shellService.setGoalText(_project, _sessionId, text);
    return _toOutcome(result, fallback: sessionRecord, persist: true);
  }

  @override
  Future<ConversationCommandBackendOutcome> clearContext(
    JsonMap sessionRecord,
  ) async {
    final result = await _shellService.clearWorkingContext(
      _project,
      _sessionId,
    );
    return _toOutcome(result, fallback: sessionRecord, persist: true);
  }

  @override
  Future<ConversationCommandBackendOutcome> exitSession(
    JsonMap sessionRecord,
  ) async {
    // 中文注释: 退出是宿主层动作（CLI 退出 REPL），后端不改会话记录，只回报 exitSession 标志。
    return ConversationCommandBackendOutcome(
      updatedSessionRecord: sessionRecord,
      exitSession: true,
    );
  }

  ConversationCommandBackendOutcome _toOutcome(
    JsonMap shellResult, {
    required JsonMap fallback,
    required bool persist,
    bool exitSession = false,
  }) {
    if (!ValueReaders.boolValue(shellResult['ok'], true)) {
      return ConversationCommandBackendOutcome(
        updatedSessionRecord: fallback,
        persist: false,
        detail: <String, Object?>{
          'error': ValueReaders.stringValue(shellResult['error'], '会话操作失败。'),
        },
      );
    }
    final detail = <String, Object?>{
      'public_summary': ValueReaders.stringValue(shellResult['public_summary']),
    };
    if (shellResult.containsKey('pressure_snapshot')) {
      detail['pressure_snapshot'] = shellResult['pressure_snapshot'];
    }
    if (shellResult.containsKey('compaction_decision')) {
      detail['compaction_decision'] = shellResult['compaction_decision'];
    }
    return ConversationCommandBackendOutcome(
      updatedSessionRecord: ValueReaders.mapValue(
        shellResult['session_record'],
      ),
      persist: persist,
      detail: detail,
      exitSession: exitSession,
    );
  }
}
