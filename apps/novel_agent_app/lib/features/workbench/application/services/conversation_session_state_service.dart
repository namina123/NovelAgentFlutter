import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_attachment_draft.dart';
import '../models/conversation_retry_request.dart';
import '../models/conversation_session_state.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/session_history_entry_view_data.dart';
import '../../presentation/models/sub_agent_run_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';
import 'conversation_session_restore_projection_service.dart';
import 'conversation_tool_entry_projection_service.dart';
import 'sub_agent_run_projection_service.dart';

class ConversationSessionStateService {
  ConversationSessionStateService({
    SessionModeService? modeService,
    SessionMessageService? messageService,
    SessionRecordNormalizerService? normalizerService,
    SessionRecordMutationService? mutationService,
    SessionHistoryService? historyService,
    SessionContextRendererService? contextRendererService,
    ConversationSessionRestoreProjectionService? restoreProjectionService,
    ToolEventPresenterService? toolEventPresenterService,
    ConversationToolEntryProjectionService? toolEntryProjectionService,
    SubAgentRunProjectionService? subAgentRunProjectionService,
    SessionMessageInclusionStrategy? messageInclusionStrategy,
    SessionCompressionStrategyService? compressionStrategyService,
    SessionPromptContextService? promptContextService,
  }) : _normalizerService =
           normalizerService ??
           SessionRecordNormalizerService(
             modeService: modeService ?? SessionModeService(),
             messageService: messageService ?? SessionMessageService(),
           ),
       _mutationService =
           mutationService ??
           SessionRecordMutationService(
             normalizerService:
                 normalizerService ??
                 SessionRecordNormalizerService(
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
       _restoreProjectionService =
           restoreProjectionService ??
           ConversationSessionRestoreProjectionService(
             messageService: messageService ?? SessionMessageService(),
           ),
       _contextRendererService =
           contextRendererService ??
           SessionContextRendererService(
             normalizerService:
                 normalizerService ??
                 SessionRecordNormalizerService(
                   modeService: modeService ?? SessionModeService(),
                   messageService: messageService ?? SessionMessageService(),
                 ),
             messageService: messageService ?? SessionMessageService(),
           ),
       _toolEntryProjectionService =
           toolEntryProjectionService ??
           ConversationToolEntryProjectionService(
             toolEventPresenterService:
                 toolEventPresenterService ?? ToolEventPresenterService(),
           ),
       _subAgentRunProjectionService =
           subAgentRunProjectionService ?? const SubAgentRunProjectionService(),
       _messageInclusionStrategy =
           messageInclusionStrategy ?? DefaultSessionMessageInclusionStrategy(),
       _compressionStrategyService =
           compressionStrategyService ?? SessionCompressionStrategyService(),
       _promptContextService =
           promptContextService ??
           SessionPromptContextService(
             normalizerService:
                 normalizerService ??
                 SessionRecordNormalizerService(
                   modeService: modeService ?? SessionModeService(),
                   messageService: messageService ?? SessionMessageService(),
                 ),
             messageService: messageService ?? SessionMessageService(),
             contextRendererService:
                 contextRendererService ??
                 SessionContextRendererService(
                   normalizerService:
                       normalizerService ??
                       SessionRecordNormalizerService(
                         modeService: modeService ?? SessionModeService(),
                         messageService:
                             messageService ?? SessionMessageService(),
                       ),
                   messageService: messageService ?? SessionMessageService(),
                 ),
           );

  final SessionRecordNormalizerService _normalizerService;
  final SessionRecordMutationService _mutationService;
  final SessionHistoryService _historyService;
  final ConversationSessionRestoreProjectionService _restoreProjectionService;
  final SessionContextRendererService _contextRendererService;
  final ConversationToolEntryProjectionService _toolEntryProjectionService;
  final SubAgentRunProjectionService _subAgentRunProjectionService;
  final SessionMessageInclusionStrategy _messageInclusionStrategy;
  final SessionCompressionStrategyService _compressionStrategyService;
  final SessionPromptContextService _promptContextService;

  ConversationSessionState createSession({
    required String sessionId,
    String title = '',
    String now = '',
    bool needsGoalSelection = true,
    String initialMode = SessionRecordConstants.modeSmartOpening,
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 新会话初始状态统一在这里生成，避免控制器和不同宿主各自产生不同骨架。
    final timestamp = now.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : now;
    final record = _normalizerService.makeSessionRecord(
      mode: SessionRecordConstants.modeUnselected,
      title: title,
      sessionId: sessionId,
      createdAt: timestamp,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
    final seededRecord = _applyCompressionStrategy(
      needsGoalSelection
          ? record
          : _mutationService.sessionWithGoal(
              record,
              initialMode,
              now: timestamp,
            ),
      strategySettings: strategySettings,
      modelProfile: modelProfile,
    );
    return ConversationSessionState(
      sessionRecord: seededRecord,
      entries: const <ConversationEntryViewData>[],
      pendingOptions: const <UserOptionViewData>[],
      subAgentRuns: const <SubAgentRunViewData>[],
      attachmentDrafts: const <ConversationAttachmentDraft>[],
      retryRequest: null,
    );
  }

  ConversationSessionState restoreSession(JsonMap sessionRecord) {
    // 中文注释: 项目重载时从已持久化的 sessionRecord 恢复稳定展示状态，包括工具调用结果。
    final normalized = _normalizerService.normalizeSessionRecord(
      sessionRecord,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
    return ConversationSessionState(
      sessionRecord: normalized,
      entries: _restoreProjectionService.build(normalized),
      pendingOptions: const <UserOptionViewData>[],
      subAgentRuns: const <SubAgentRunViewData>[],
      attachmentDrafts: const <ConversationAttachmentDraft>[],
      retryRequest: null,
    );
  }

  SessionRestoreResult restoreResult({
    required List<ConversationSessionState> sessions,
    required String activeSessionId,
    bool showSessionHistory = false,
    SessionRestoreScrollTarget defaultScrollTarget =
        SessionRestoreScrollTarget.latest,
  }) {
    // 中文注释: 恢复结果统一在这里形成，避免 controller 和 sidebar 各自猜测恢复是否完成。
    final restoredSessionIds = sessions
        .map((state) => _sessionIdOfState(state))
        .where((sessionId) => sessionId.isNotEmpty)
        .toList(growable: false);
    return SessionRestoreResult(
      restoredSessionIds: restoredSessionIds,
      activeSessionId: activeSessionId.trim(),
      showSessionHistory: showSessionHistory,
      defaultScrollTarget: defaultScrollTarget,
    );
  }

  List<UserOptionViewData> pendingOptionsFromRecords(List<JsonMap> records) {
    return _pendingOptionsFromRecords(records);
  }

  ConversationSessionState stateWithGoalSelection(
    ConversationSessionState state,
    String mode, {
    String now = '',
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 会话目标切换统一通过这里推进，避免控制器直接修改 sessionRecord 内部字段。
    final prepared = _applyCompressionStrategy(
      state.sessionRecord,
      strategySettings: strategySettings,
      modelProfile: modelProfile,
    );
    return state.copyWith(
      sessionRecord: _mutationService.sessionWithGoal(prepared, mode, now: now),
    );
  }

  ConversationSessionState stateWithUserPrompt(
    ConversationSessionState state,
    String prompt, {
    String now = '',
    String displayContent = '',
    bool clearRetryableFailure = true,
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 用户输入会同时进入会话记录与展示时间线，并清空上一轮待选项。
    final cleanedState = clearRetryableFailure
        ? stateAfterRetryCleanup(state)
        : state;
    final prepared = _applyCompressionStrategy(
      cleanedState.sessionRecord,
      strategySettings: strategySettings,
      modelProfile: modelProfile,
    );
    final record = _mutationService.sessionWithMessage(
      prepared,
      'user',
      prompt,
      createdAt: now,
    );
    final entry = ConversationEntryViewData(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      kind: ConversationEntryKind.user,
      title: '你',
      body: displayContent.trim().isEmpty
          ? prompt.trim()
          : displayContent.trim(),
    );
    return state.copyWith(
      sessionRecord: record,
      entries: <ConversationEntryViewData>[...cleanedState.entries, entry],
      pendingOptions: const <UserOptionViewData>[],
      attachmentDrafts: const <ConversationAttachmentDraft>[],
      retryRequest: null,
    );
  }

  ConversationSessionState stateWithAttachmentDrafts(
    ConversationSessionState state,
    List<ConversationAttachmentDraft> attachmentDrafts,
  ) {
    // 中文注释: 会话附件暂存独立挂在 session state 上，避免和项目导入文件或文本框局部状态混在一起。
    return state.copyWith(attachmentDrafts: attachmentDrafts);
  }

  ConversationSessionState stateWithAssistantResult(
    ConversationSessionState state,
    DraftGenerationResult result, {
    String now = '',
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 助手结果会投影成普通回复、工具事件、待选项和子智能体活动四种展示状态。
    var record = state.sessionRecord;
    if (_messageInclusionStrategy.includeInContext(role: 'assistant')) {
      final prepared = _applyCompressionStrategy(
        state.sessionRecord,
        strategySettings: strategySettings,
        modelProfile: modelProfile,
      );
      record = _mutationService.sessionWithMessage(
        prepared,
        'assistant',
        result.draftMarkdown,
        createdAt: now,
      );
    }
    final stableEntries = _entriesWithoutCurrentRoundAppendix(state.entries);
    final nextEntries = <ConversationEntryViewData>[
      ...stableEntries,
      ..._toolEntriesFrom(result.executedTools),
      ..._assistantEntriesFrom(result),
      ..._runtimeNoticeEntriesFrom(result),
    ];
    return state.copyWith(
      sessionRecord: record,
      entries: nextEntries,
      pendingOptions: _pendingOptionsFrom(result.executedTools),
      subAgentRuns: _mergeSubAgentRuns(
        state.subAgentRuns,
        result.executedTools,
      ),
      retryRequest: _retryRequestFromCancelledResult(
        baseState: state,
        result: result,
      ),
    );
  }

  List<ConversationEntryViewData> _entriesWithoutCurrentRoundAppendix(
    List<ConversationEntryViewData> entries,
  ) {
    // 中文注释: 最终结果落地时，先剥掉当前轮流式过程的临时助手条目和尾部工具区，避免完成瞬间整块时间线抖动。
    var end = entries.length;
    while (end > 0) {
      final entry = entries[end - 1];
      if (entry.id == 'assistant_streaming' ||
          entry.kind == ConversationEntryKind.tool) {
        end -= 1;
        continue;
      }
      break;
    }
    return entries.take(end).toList(growable: false);
  }

  ConversationSessionState stateWithAssistantFailure(
    ConversationSessionState state,
    String errorMessage, {
    ConversationRetryRequest? retryRequest,
    String now = '',
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 失败是否进入上下文由策略层决定；默认只保留展示条目，不污染后续模型输入。
    var record = state.sessionRecord;
    if (_messageInclusionStrategy.includeInContext(
      role: 'assistant',
      outcome: 'failure',
      metadata: <String, Object?>{'error_message': errorMessage},
    )) {
      final prepared = _applyCompressionStrategy(
        state.sessionRecord,
        strategySettings: strategySettings,
        modelProfile: modelProfile,
      );
      record = _mutationService.sessionWithMessage(
        prepared,
        'assistant',
        errorMessage,
        createdAt: now,
      );
    }
    return state.copyWith(
      sessionRecord: record,
      entries: <ConversationEntryViewData>[
        ...state.entries,
        ConversationEntryViewData(
          id: 'assistant_error_${DateTime.now().microsecondsSinceEpoch}',
          kind: ConversationEntryKind.system,
          title: '本轮失败',
          body: errorMessage.trim(),
          isError: true,
          isRetryableFailure: retryRequest != null,
        ),
      ],
      pendingOptions: const <UserOptionViewData>[],
      retryRequest: retryRequest,
    );
  }

  ConversationSessionState stateAfterRetryCleanup(
    ConversationSessionState state,
  ) {
    // 中文注释: 重新执行上一轮失败请求前，只清掉尾部可重试错误展示与重试状态，不碰真实用户消息历史。
    if (state.retryRequest == null) {
      return state;
    }
    final nextEntries = _entriesWithoutTrailingRetryableFailure(state.entries);
    return state.copyWith(entries: nextEntries, retryRequest: null);
  }

  String sessionContextMarkdown(
    ConversationSessionState state, {
    String excludeLatestUserContent = '',
    SessionContextPressureSnapshot? pressureSnapshot,
    CompactionGuidanceContract? compactionGuidance,
    CompactionOutputPolicy? compactionOutputPolicy,
    CompactionSourceScope? compactionSourceScope,
    RuntimeContinuationInstructionContract? runtimeContinuationInstruction,
  }) {
    // 中文注释: 多轮交互给模型的会话上下文统一由这里渲染，避免不同入口重复拼接历史。
    final options = <String, Object?>{
      'exclude_latest_user_content': excludeLatestUserContent,
    };
    if (pressureSnapshot != null) {
      options['pressure_snapshot'] = pressureSnapshot;
    }
    if (compactionGuidance != null) {
      options['compaction_guidance'] = compactionGuidance;
    }
    if (compactionOutputPolicy != null) {
      options['compaction_output_policy'] = compactionOutputPolicy;
    }
    if (compactionSourceScope != null) {
      options['compaction_source_scope'] = compactionSourceScope;
    }
    if (runtimeContinuationInstruction != null) {
      options['runtime_continuation_instruction'] =
          runtimeContinuationInstruction;
    }
    return _contextRendererService.sessionContextMarkdown(
      state.sessionRecord,
      options: options,
    );
  }

  SessionPromptContext promptContext(
    ConversationSessionState state, {
    String excludeLatestUserContent = '',
    SessionContextPressureSnapshot? pressureSnapshot,
    CompactionGuidanceContract? compactionGuidance,
    CompactionOutputPolicy? compactionOutputPolicy,
    CompactionSourceScope? compactionSourceScope,
    RuntimeContinuationInstructionContract? runtimeContinuationInstruction,
  }) {
    // 中文注释: 真实历史消息和运行时摘要在这里统一拆分，避免控制器自己拼双轨合同。
    return _promptContextService.buildFromSessionRecord(
      state.sessionRecord,
      excludeLatestUserContent: excludeLatestUserContent,
      pressureSnapshot: pressureSnapshot,
      compactionGuidance: compactionGuidance,
      compactionOutputPolicy: compactionOutputPolicy,
      compactionSourceScope: compactionSourceScope,
      runtimeContinuationInstruction: runtimeContinuationInstruction,
    );
  }

  String publicSummary(ConversationSessionState state) {
    // 中文注释: 会话公开摘要给状态栏和历史列表复用，统一来自 core 的会话压缩规则。
    return _contextRendererService.sessionPublicSummary(state.sessionRecord);
  }

  List<SessionHistoryEntryViewData> historyEntries(
    Iterable<ConversationSessionState> states,
    String activeSessionId,
  ) {
    // 中文注释: 历史面板只接收轻量条目，避免把整段会话内容塞进列表视图。
    final index = _historyService.sessionIndexFromSessions(
      states.map((state) => state.sessionRecord).toList(growable: false),
      currentSessionId: activeSessionId,
    );
    return ValueReaders.objectList(index['sessions'])
        .map(ValueReaders.mapValue)
        .map(
          (entry) => SessionHistoryEntryViewData(
            id: ValueReaders.stringValue(entry['id']),
            title: ValueReaders.stringValue(entry['title'], '未命名会话'),
            status: ValueReaders.stringValue(entry['public_status'], '准备中'),
            updatedAt: ValueReaders.stringValue(entry['updated_at']),
            isSelected:
                ValueReaders.stringValue(entry['id']) == activeSessionId,
          ),
        )
        .toList(growable: false);
  }

  String _sessionIdOfState(ConversationSessionState state) {
    final id = ValueReaders.stringValue(state.sessionRecord['session_id']).trim();
    return id.isNotEmpty
        ? id
        : ValueReaders.stringValue(state.sessionRecord['id']).trim();
  }

  List<ConversationEntryViewData> _toolEntriesFrom(
    List<Object?> executedTools, {
    bool includeDetailBodies = true,
  }) {
    // 中文注释: 工具执行记录交给独立投影服务处理，以便继续压缩重复调用并保持时间线轻量。
    return _toolEntryProjectionService.buildWithOptions(
      executedTools,
      includeDetailBodies: includeDetailBodies,
    );
  }

  List<ConversationEntryViewData> _assistantEntriesFrom(
    DraftGenerationResult result,
  ) {
    // 中文注释: 即使正文为空，只要本轮有思考内容也保留助手条目，避免工具回合把思考信息直接吞掉。
    final entry = assistantEntryFromContent(
      content: result.draftMarkdown,
      reasoning: result.reasoningContent,
    );
    if (entry == null) {
      return const <ConversationEntryViewData>[];
    }
    return <ConversationEntryViewData>[entry];
  }

  List<ConversationEntryViewData> _runtimeNoticeEntriesFrom(
    DraftGenerationResult result,
  ) {
    // 中文注释: 取消等运行期状态以 system notice 单独落入时间线，避免把“停止”伪装成正文或失败消息。
    if (!result.cancelledByUser) {
      return const <ConversationEntryViewData>[];
    }
    final body = result.partialContentAccepted
        ? '已停止当前生成，并保留已完成的阶段内容。'
        : '已停止当前生成，本轮未保留可用内容。';
    return <ConversationEntryViewData>[
      ConversationEntryViewData(
        id: 'assistant_cancelled_${DateTime.now().microsecondsSinceEpoch}',
        kind: ConversationEntryKind.system,
        title: '本轮已停止',
        body: body,
      ),
    ];
  }

  ConversationRetryRequest? _retryRequestFromCancelledResult({
    required ConversationSessionState baseState,
    required DraftGenerationResult result,
  }) {
    // 中文注释: 用户主动停止且没有保留内容时，给出“重试这次已停止请求”的入口；保留内容时不再额外弹重试横幅。
    if (!result.cancelledByUser || result.partialContentAccepted) {
      return null;
    }
    final prompt = result.userPrompt.trim();
    if (prompt.isEmpty) {
      return null;
    }
    return ConversationRetryRequest(
      prompt: prompt,
      visibleText: () {
        final visibleText = _latestUserVisibleText(baseState);
        return visibleText.isEmpty ? prompt : visibleText;
      }(),
      label: '重试这次已停止请求',
    );
  }

  String _latestUserVisibleText(ConversationSessionState state) {
    for (final entry in state.entries.reversed) {
      if (entry.kind == ConversationEntryKind.user) {
        final body = entry.body.trim();
        if (body.isNotEmpty) {
          return body;
        }
      }
    }
    return '';
  }

  String _reasoningSummary(String reasoning) {
    // 中文注释: 思考折叠态只展示一小段预览，避免长思考把会话时间线撑得过重。
    final singleLine = reasoning
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .trim();
    if (singleLine.isEmpty) {
      return '';
    }
    const maxChars = 28;
    if (singleLine.length <= maxChars) {
      return singleLine;
    }
    return '${singleLine.substring(0, maxChars)}...';
  }

  List<ConversationEntryViewData> toolEntriesFromExecutedTools(
    List<Object?> executedTools, {
    bool includeDetailBodies = true,
  }) {
    // 中文注释: 已执行工具的时间线投影对最终结果和流式过程复用同一规则，避免两套展示口径。
    return _toolEntriesFrom(
      executedTools,
      includeDetailBodies: includeDetailBodies,
    );
  }

  List<ConversationEntryViewData> toolEntriesFromPendingCalls(
    List<Object?> pendingToolCalls,
  ) {
    return _toolEntryProjectionService.buildPendingCallEntries(
      pendingToolCalls,
    );
  }

  List<SubAgentRunViewData> mergeSubAgentRunsFromExecutedTools(
    List<SubAgentRunViewData> currentRuns,
    List<Object?> executedTools,
  ) {
    // 中文注释: 流式过程也复用同一子智能体投影，保证缩略卡在工具结果落地后立即可见。
    return _mergeSubAgentRuns(currentRuns, executedTools);
  }

  ConversationEntryViewData? assistantEntryFromContent({
    required String content,
    required String reasoning,
    String entryId = '',
    String title = '综合创作智能体',
  }) {
    // 中文注释: 助手正文和思考的展示骨架抽成公共入口，方便流式过程和最终结果共享。
    final trimmedContent = content.trim();
    final trimmedReasoning = reasoning.trim();
    if (trimmedContent.isEmpty && trimmedReasoning.isEmpty) {
      return null;
    }
    return ConversationEntryViewData(
      id: entryId.isEmpty
          ? 'assistant_${DateTime.now().microsecondsSinceEpoch}'
          : entryId,
      kind: ConversationEntryKind.assistant,
      title: title,
      body: trimmedContent,
      isError: false,
      detailTitle: trimmedReasoning.isEmpty ? '' : '思考',
      detailSummary: _reasoningSummary(trimmedReasoning),
      detailBody: trimmedReasoning,
      detailExpandedByDefault: false,
    );
  }

  List<UserOptionViewData> _pendingOptionsFrom(List<Object?> executedTools) {
    // 中文注释: 待选项默认来自 present_user_options；权限确认等受控等待结果只要显式带 options 也允许进入同一 UI 通道。
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      final options = ValueReaders.objectList(result['options']);
      if (options.isEmpty) {
        continue;
      }
      final toolName = ValueReaders.stringValue(tool['name']);
      final supportsPendingSurface =
          toolName == 'present_user_options' ||
          ValueReaders.boolValue(result['waiting_for_user_choice']);
      if (!supportsPendingSurface) {
        continue;
      }
      final question = ValueReaders.stringValue(result['question']);
      return options
          .map(ValueReaders.mapValue)
          .where((entry) => entry.isNotEmpty)
          .map(
            (entry) => _userOptionFromEntry(
              entry,
              sourceQuestion: question,
              allOptions: ValueReaders.objectList(
                result['options'],
              ).map(ValueReaders.mapValue).toList(growable: false),
            ),
          )
          .toList(growable: false);
    }
    return const <UserOptionViewData>[];
  }

  List<UserOptionViewData> _pendingOptionsFromRecords(List<JsonMap> records) {
    return records
        .map(
          (entry) => _userOptionFromEntry(
            entry,
            sourceQuestion: ValueReaders.stringValue(entry['source_question']),
            allOptions: records,
          ),
        )
        .toList(growable: false);
  }

  UserOptionViewData _userOptionFromEntry(
    JsonMap entry, {
    required String sourceQuestion,
    required List<JsonMap> allOptions,
  }) {
    return UserOptionViewData(
      label: ValueReaders.stringValue(
        entry['label'],
        ValueReaders.stringValue(
          entry['title'],
          ValueReaders.stringValue(entry['name'], '选项'),
        ),
      ),
      description: ValueReaders.stringValue(
        entry['description'],
        ValueReaders.stringValue(
          entry['detail'],
          ValueReaders.stringValue(entry['summary']),
        ),
      ),
      prompt: ValueReaders.stringValue(
        entry['prompt'],
        ValueReaders.stringValue(
          entry['value'],
          ValueReaders.stringValue(
            entry['title'],
            ValueReaders.stringValue(entry['label']),
          ),
        ),
      ),
      sourceQuestion: sourceQuestion,
      allOptions: allOptions,
      optionId: ValueReaders.stringValue(entry['id']).trim(),
      permissionApprovalId: ValueReaders.stringValue(
        entry['approval_record_id'],
      ).trim(),
      permissionApprovalOptionId: ValueReaders.stringValue(
        entry['approval_option_id'],
      ).trim(),
    );
  }

  List<SubAgentRunViewData> _mergeSubAgentRuns(
    List<SubAgentRunViewData> currentRuns,
    List<Object?> executedTools,
  ) {
    // 中文注释: 子智能体运行列表按 run id 覆盖更新，让主智能体多次委派时历史顺序保持稳定。
    final byId = <String, SubAgentRunViewData>{
      for (final run in currentRuns) run.id: run,
    };
    final orderedIds = currentRuns.map((run) => run.id).toList(growable: true);
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'call_sub_agent') {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final runId = ValueReaders.stringValue(
        result['sub_agent_run_id'],
        ValueReaders.stringValue(result['sub_session_id']),
      ).trim();
      if (runId.isEmpty) {
        continue;
      }
      final run = _subAgentRunProjectionService.projectFromToolResult(result);
      if (run == null) {
        continue;
      }
      byId[runId] = run;
      if (!orderedIds.contains(runId)) {
        orderedIds.add(runId);
      }
    }
    return orderedIds
        .map((runId) => byId[runId])
        .whereType<SubAgentRunViewData>()
        .toList(growable: false);
  }

  JsonMap _applyCompressionStrategy(
    JsonMap sessionRecord, {
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 会话服务只应用策略产出的阈值，不在这里固化阈值计算规则。
    final next = ValueReaders.deepCopyMap(sessionRecord);
    next['compression_threshold_chars'] = _compressionStrategyService
        .thresholdChars(
          strategySettings: strategySettings,
          modelProfile: modelProfile,
          fallbackThresholdChars: ValueReaders.intValue(
            sessionRecord['compression_threshold_chars'],
            SessionRecordConstants.defaultThresholdChars,
          ),
        );
    return next;
  }

  List<ConversationEntryViewData> _entriesWithoutTrailingRetryableFailure(
    List<ConversationEntryViewData> entries,
  ) {
    final next = List<ConversationEntryViewData>.from(entries);
    while (next.isNotEmpty && next.last.isRetryableFailure) {
      next.removeLast();
    }
    return next;
  }
}
