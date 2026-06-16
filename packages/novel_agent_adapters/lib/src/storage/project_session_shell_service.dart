import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_session_compaction_service.dart';
import 'project_session_workspace_service.dart';

class ProjectSessionShellService {
  ProjectSessionShellService({
    required ProjectSessionWorkspaceService sessionWorkspaceService,
    ProjectSessionCompactionService? compactionService,
    SessionMessageService? messageService,
    SessionModeService? modeService,
    SessionRecordMutationService? mutationService,
    SessionHistoryService? historyService,
    SessionContextRendererService? rendererService,
    SessionPromptContextService? promptContextService,
    SessionContextPressureService? pressureService,
    SessionCompactionDecisionService? compactionDecisionService,
  }) : _sessionWorkspaceService = sessionWorkspaceService,
       _compactionService =
           compactionService ?? ProjectSessionCompactionService(),
       _modeService = modeService ?? SessionModeService(),
       _mutationService =
           mutationService ??
           SessionRecordMutationService(
             normalizerService: SessionRecordNormalizerService(
               modeService: modeService ?? SessionModeService(),
               messageService: messageService ?? SessionMessageService(),
             ),
             modeService: modeService ?? SessionModeService(),
             messageService: messageService ?? SessionMessageService(),
           ),
       _historyService =
           historyService ??
           SessionHistoryService(
             messageService: messageService ?? SessionMessageService(),
           ),
       _rendererService =
           rendererService ??
           SessionContextRendererService(
             normalizerService: SessionRecordNormalizerService(
               modeService: modeService ?? SessionModeService(),
               messageService: messageService ?? SessionMessageService(),
             ),
             messageService: messageService ?? SessionMessageService(),
           ),
       _promptContextService =
           promptContextService ??
           SessionPromptContextService(
             normalizerService: SessionRecordNormalizerService(
               modeService: modeService ?? SessionModeService(),
               messageService: messageService ?? SessionMessageService(),
             ),
             messageService: messageService ?? SessionMessageService(),
             contextRendererService:
                 rendererService ??
                 SessionContextRendererService(
                   normalizerService: SessionRecordNormalizerService(
                     modeService: modeService ?? SessionModeService(),
                     messageService: messageService ?? SessionMessageService(),
                   ),
                   messageService: messageService ?? SessionMessageService(),
                 ),
           ),
       _pressureService =
           pressureService ?? const SessionContextPressureService(),
       _compactionDecisionService =
           compactionDecisionService ?? SessionCompactionDecisionService();

  final ProjectSessionWorkspaceService _sessionWorkspaceService;
  final ProjectSessionCompactionService _compactionService;
  final SessionModeService _modeService;
  final SessionRecordMutationService _mutationService;
  final SessionHistoryService _historyService;
  final SessionContextRendererService _rendererService;
  final SessionPromptContextService _promptContextService;
  final SessionContextPressureService _pressureService;
  final SessionCompactionDecisionService _compactionDecisionService;

  Future<JsonMap> listSessions(
    ProjectDescriptor project, {
    int limit = 20,
  }) async {
    // 中文注释: 列表面只投影轻量摘要，不把整段会话内容塞回 CLI。
    final snapshot = await _sessionWorkspaceService.loadSessions(project);
    final index = _historyService.sessionIndexFromSessions(
      snapshot.sessionRecords,
      currentSessionId: snapshot.activeSessionId,
      limit: limit,
    );
    final recordsById = <String, JsonMap>{
      for (final record in snapshot.sessionRecords)
        ValueReaders.stringValue(record['id']).trim(): record,
    };
    final sessions = ValueReaders.objectList(index['sessions'])
        .map(ValueReaders.mapValue)
        .map(
          (entry) => _sessionSummaryFromRecord(
            recordsById[ValueReaders.stringValue(entry['id']).trim()] ?? entry,
            fallbackEntry: entry,
          ),
        )
        .toList(growable: false);
    return <String, Object?>{
      'ok': true,
      'current_session_id': snapshot.activeSessionId,
      'sessions': sessions,
      'total_count': ValueReaders.intValue(index['total_count']),
      'omitted_count': ValueReaders.intValue(index['omitted_count']),
    };
  }

  Future<JsonMap> loadSession(
    ProjectDescriptor project,
    String sessionId,
  ) async {
    // 中文注释: 详情面只返回单个 session 的正式记录和上下文投影，供 CLI/GUI 共享。
    final record = await _sessionWorkspaceService.loadSession(project, sessionId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    return <String, Object?>{'ok': true, ..._sessionPayload(record)};
  }

  Future<JsonMap> sendSession(
    ProjectDescriptor project,
    String sessionId,
    String message, {
    String now = '',
    SessionTokenBudgetSettings? settings,
  }) async {
    // 中文注释: 发送支持先把用户输入落回正式会话记录，再输出可送入模型的 prompt context。
    final existing = await _sessionWorkspaceService.loadSession(
      project,
      sessionId,
    );
    if (existing.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    final prepared = _mutationService.sessionWithMessage(
      existing,
      'user',
      message,
      createdAt: now,
    );
    final pressureSnapshot = _pressureService.snapshotFromSessionRecord(
      prepared,
      settings: settings ?? _defaultBudgetSettings(),
    );
    final compactionDecision = _compactionDecisionService.decideFromSnapshot(
      sessionRecord: prepared,
      pressureSnapshot: pressureSnapshot,
      triggerKind: SessionCompactionTriggerKind.preflightSend,
    );
    final compacted = _compactionService.compactSessionRecord(
      sessionRecord: prepared,
      decision: compactionDecision,
      outputPolicy: const CompactionOutputPolicy(
        policyId: 'policy.session.shell_send',
        title: 'CLI 发送前压缩输出策略',
      ),
      now: now,
    );
    final promptContext = _promptContextService.buildFromSessionRecord(
      compacted,
      excludeLatestUserContent: message.trim(),
      pressureSnapshot: pressureSnapshot,
    );
    await _sessionWorkspaceService.saveSession(
      project,
      compacted,
      activeSessionId: sessionId.trim(),
    );
    return <String, Object?>{
      'ok': true,
      ..._sessionPayload(compacted),
      'user_message': message.trim(),
      'pressure_snapshot': pressureSnapshot.toJson(),
      'compaction_decision': compactionDecision.toJson(),
      'session_prompt_context': <String, Object?>{
        'context_markdown': promptContext.contextMarkdown,
        'history_messages': promptContext.historyMessages,
      },
    };
  }

  Future<JsonMap> resumeSession(
    ProjectDescriptor project, {
    String sessionId = '',
    String now = '',
  }) async {
    // 中文注释: resume 负责把当前会话重新置为可继续状态，并返回后续一轮可直接消费的 prompt context。
    final snapshot = await _sessionWorkspaceService.loadSessions(project);
    final resolvedSessionId = _resolveResumeSessionId(
      sessionId,
      snapshot.activeSessionId,
      snapshot.sessionRecords,
    );
    if (resolvedSessionId.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    final record = await _sessionWorkspaceService.loadSession(
      project,
      resolvedSessionId,
    );
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': resolvedSessionId,
      };
    }
    final timestamp = now.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : now.trim();
    final resumed = ValueReaders.deepCopyMap(record);
    final currentStage = ValueReaders.stringValue(resumed['workflow_stage']);
    if (currentStage == 'stopped') {
      final mode = _modeService.cleanMode(
        ValueReaders.stringValue(resumed['mode']),
      );
      final reopenedStage = _modeService.initialStage(mode);
      resumed['workflow_stage'] = reopenedStage;
      resumed['public_status'] = _modeService.publicStatus(
        mode,
        reopenedStage,
        ValueReaders.boolValue(resumed['is_creative']),
      );
    }
    resumed['updated_at'] = timestamp;
    await _sessionWorkspaceService.saveSession(
      project,
      resumed,
      activeSessionId: resolvedSessionId,
    );
    final promptContext = _promptContextService.buildFromSessionRecord(
      resumed,
      excludeLatestUserContent: '',
    );
    return <String, Object?>{
      'ok': true,
      'resume_source': sessionId.trim().isEmpty
          ? 'active_session'
          : 'session_id',
      ..._sessionPayload(resumed),
      'session_prompt_context': <String, Object?>{
        'context_markdown': promptContext.contextMarkdown,
        'history_messages': promptContext.historyMessages,
      },
    };
  }

  Future<JsonMap> statsSession(
    ProjectDescriptor project,
    String sessionId, {
    SessionTokenBudgetSettings? settings,
  }) async {
    // 中文注释: stats 只做压力与消息规模投影，不会偷偷改写会话记录。
    final record = await _sessionWorkspaceService.loadSession(project, sessionId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    final pressureSnapshot = _pressureService.snapshotFromSessionRecord(
      record,
      settings: settings ?? _defaultBudgetSettings(),
    );
    final compactionDecision = _compactionDecisionService.decideFromSnapshot(
      sessionRecord: record,
      pressureSnapshot: pressureSnapshot,
    );
    return <String, Object?>{
      'ok': true,
      ..._sessionPayload(record),
      'pressure_snapshot': pressureSnapshot.toJson(),
      'compaction_decision': compactionDecision.toJson(),
    };
  }

  Future<JsonMap> compactSession(
    ProjectDescriptor project,
    String sessionId, {
    SessionTokenBudgetSettings? settings,
    String now = '',
  }) async {
    // 中文注释: compact 直接调用正式决策和压缩合同，不在 CLI 壳层重写压缩算法。
    final record = await _sessionWorkspaceService.loadSession(project, sessionId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    final pressureSnapshot = _pressureService.snapshotFromSessionRecord(
      record,
      settings: settings ?? _defaultBudgetSettings(),
    );
    final compactionDecision = _compactionDecisionService.decideFromSnapshot(
      sessionRecord: record,
      pressureSnapshot: pressureSnapshot,
      triggerKind: SessionCompactionTriggerKind.preflightResume,
    );
    final compacted = _compactionService.compactSessionRecord(
      sessionRecord: record,
      decision: compactionDecision,
      outputPolicy: const CompactionOutputPolicy(
        policyId: 'policy.session.shell_compact',
        title: 'CLI 会话压缩输出策略',
      ),
      now: now,
    );
    await _sessionWorkspaceService.saveSession(
      project,
      compacted,
      activeSessionId: sessionId.trim(),
    );
    return <String, Object?>{
      'ok': true,
      ..._sessionPayload(compacted),
      'pressure_snapshot': pressureSnapshot.toJson(),
      'compaction_decision': compactionDecision.toJson(),
    };
  }

  Future<JsonMap> stopSession(
    ProjectDescriptor project,
    String sessionId, {
    String now = '',
  }) async {
    // 中文注释: stop 只把会话收束为停止态，不删除历史消息，也不重建另一套结束语义。
    final record = await _sessionWorkspaceService.loadSession(project, sessionId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Session not found.',
        'session_id': sessionId.trim(),
      };
    }
    final timestamp = now.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : now.trim();
    final stopped = ValueReaders.deepCopyMap(record)
      ..['workflow_stage'] = 'stopped'
      ..['public_status'] = _modeService.publicStatus(
        ValueReaders.stringValue(record['mode']),
        'stopped',
        ValueReaders.boolValue(record['is_creative']),
      )
      ..['updated_at'] = timestamp;
    await _sessionWorkspaceService.saveSession(
      project,
      stopped,
      activeSessionId: sessionId.trim(),
    );
    return <String, Object?>{'ok': true, ..._sessionPayload(stopped)};
  }

  JsonMap _sessionPayload(JsonMap record) {
    // 中文注释: 会话通用 payload 只做一层稳定投影，CLI/测试都能直接消费。
    final normalized = ValueReaders.deepCopyMap(record);
    return <String, Object?>{
      'session_record': normalized,
      'session_id': ValueReaders.stringValue(normalized['id']),
      'title': ValueReaders.stringValue(normalized['title'], '未命名会话'),
      'mode': ValueReaders.stringValue(normalized['mode']),
      'workflow_stage': ValueReaders.stringValue(normalized['workflow_stage']),
      'public_status': ValueReaders.stringValue(normalized['public_status']),
      'transcript_message_count': ValueReaders.objectList(
        normalized[SessionRecordConstants.transcriptMessagesField],
      ).length,
      'working_message_count': ValueReaders.objectList(
        normalized[SessionRecordConstants.workingContextMessagesField],
      ).length,
      'compaction_segment_count': ValueReaders.objectList(
        normalized[SessionRecordConstants.compactionSegmentsField],
      ).length,
      'public_summary': _rendererService.sessionPublicSummary(normalized),
      'context_markdown': _rendererService.sessionContextMarkdown(normalized),
    };
  }

  String _resolveResumeSessionId(
    String requestedSessionId,
    String activeSessionId,
    List<JsonMap> sessionRecords,
  ) {
    // 中文注释: resume 默认优先回到显式指定会话，其次回到当前活跃会话，最后才回到最新一条记录。
    final requested = requestedSessionId.trim();
    if (requested.isNotEmpty) {
      return requested;
    }
    final active = activeSessionId.trim();
    if (active.isNotEmpty) {
      return active;
    }
    for (final record in sessionRecords) {
      final sessionId = ValueReaders.stringValue(record['id']).trim();
      if (sessionId.isNotEmpty) {
        return sessionId;
      }
    }
    return '';
  }

  JsonMap _sessionSummaryFromRecord(
    JsonMap record, {
    required JsonMap fallbackEntry,
  }) {
    // 中文注释: 列表摘要只保留轻量字段，并补上 public summary，避免 CLI 再去读整份记录。
    final base = ValueReaders.deepCopyMap(fallbackEntry);
    final payload = _sessionPayload(record);
    final payloadRecord = ValueReaders.mapValue(payload['session_record']);
    return <String, Object?>{
      'id': ValueReaders.stringValue(base['id'], ValueReaders.stringValue(payload['session_id'])),
      'title': ValueReaders.stringValue(base['title'], ValueReaders.stringValue(payload['title'], '未命名会话')),
      'mode': ValueReaders.stringValue(base['mode'], ValueReaders.stringValue(payload['mode'])),
      'workflow_stage': ValueReaders.stringValue(
        base['workflow_stage'],
        ValueReaders.stringValue(payload['workflow_stage']),
      ),
      'public_status': ValueReaders.stringValue(
        base['public_status'],
        ValueReaders.stringValue(payload['public_status']),
      ),
      'updated_at': ValueReaders.stringValue(
        base['updated_at'],
        ValueReaders.stringValue(payloadRecord['updated_at']),
      ),
      'created_at': ValueReaders.stringValue(
        base['created_at'],
        ValueReaders.stringValue(payloadRecord['created_at']),
      ),
      'message_count': ValueReaders.intValue(payload['transcript_message_count']),
      'public_summary': ValueReaders.stringValue(payload['public_summary']),
    };
  }

  SessionTokenBudgetSettings _defaultBudgetSettings() {
    // 中文注释: CLI 会话统计先采用保守默认窗口，后续若接入 runtime profile 再替换来源即可。
    return SessionTokenBudgetSettings(
      modelContextWindowTokens: 100000,
      reservedOutputTokens: 2048,
      warningThresholdRatio: 0.8,
      criticalThresholdRatio: 0.95,
    );
  }
}
