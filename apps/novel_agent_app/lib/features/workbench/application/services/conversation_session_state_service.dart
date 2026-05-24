import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_session_state.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/session_history_entry_view_data.dart';
import '../../presentation/models/sub_agent_run_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';

class ConversationSessionStateService {
  ConversationSessionStateService({
    SessionModeService? modeService,
    SessionMessageService? messageService,
    SessionRecordNormalizerService? normalizerService,
    SessionRecordMutationService? mutationService,
    SessionHistoryService? historyService,
    SessionContextRendererService? contextRendererService,
    ToolEventPresenterService? toolEventPresenterService,
    SessionMessageInclusionStrategy? messageInclusionStrategy,
    SessionCompressionStrategyService? compressionStrategyService,
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
             modeService: modeService ?? SessionModeService(),
           ),
       _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService(),
       _messageInclusionStrategy =
           messageInclusionStrategy ?? DefaultSessionMessageInclusionStrategy(),
       _compressionStrategyService =
           compressionStrategyService ?? SessionCompressionStrategyService();

  final SessionRecordNormalizerService _normalizerService;
  final SessionRecordMutationService _mutationService;
  final SessionHistoryService _historyService;
  final SessionContextRendererService _contextRendererService;
  final ToolEventPresenterService _toolEventPresenterService;
  final SessionMessageInclusionStrategy _messageInclusionStrategy;
  final SessionCompressionStrategyService _compressionStrategyService;

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
    );
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
      sessionRecord: _mutationService.sessionWithGoal(
        prepared,
        mode,
        now: now,
      ),
    );
  }

  ConversationSessionState stateWithUserPrompt(
    ConversationSessionState state,
    String prompt, {
    String now = '',
    String displayContent = '',
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 用户输入会同时进入会话记录与展示时间线，并清空上一轮待选项。
    final prepared = _applyCompressionStrategy(
      state.sessionRecord,
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
      body: displayContent.trim().isEmpty ? prompt.trim() : displayContent.trim(),
    );
    return state.copyWith(
      sessionRecord: record,
      entries: <ConversationEntryViewData>[...state.entries, entry],
      pendingOptions: const <UserOptionViewData>[],
    );
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
    final nextEntries = <ConversationEntryViewData>[
      ...state.entries,
      ..._toolEntriesFrom(result.executedTools),
      ..._assistantEntriesFrom(result),
    ];
    return state.copyWith(
      sessionRecord: record,
      entries: nextEntries,
      pendingOptions: _pendingOptionsFrom(result.executedTools),
      subAgentRuns: _mergeSubAgentRuns(
        state.subAgentRuns,
        result.executedTools,
      ),
    );
  }

  ConversationSessionState stateWithAssistantFailure(
    ConversationSessionState state,
    String errorMessage, {
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
        ),
      ],
      pendingOptions: const <UserOptionViewData>[],
    );
  }

  String sessionContextMarkdown(
    ConversationSessionState state, {
    String excludeLatestUserContent = '',
  }) {
    // 中文注释: 多轮交互给模型的会话上下文统一由这里渲染，避免不同入口重复拼接历史。
    return _contextRendererService.sessionContextMarkdown(
      state.sessionRecord,
      options: <String, Object?>{
        'exclude_latest_user_content': excludeLatestUserContent,
      },
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

  List<ConversationEntryViewData> _toolEntriesFrom(
    List<Object?> executedTools,
  ) {
    // 中文注释: 工具执行记录单独投影成时间线条目，方便用户理解 AI 实际做了哪些事。
    return executedTools
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(
          (entry) => ConversationEntryViewData(
            id: 'tool_${ValueReaders.stringValue(entry['id'], ValueReaders.stringValue(entry['name']))}',
            kind: ConversationEntryKind.tool,
            title: ValueReaders.stringValue(entry['name'], '工具'),
            body: _toolEventPresenterService.textForExecutedTool(entry),
            isError: !ValueReaders.boolValue(entry['ok'], true),
          ),
        )
        .toList(growable: false);
  }

  List<ConversationEntryViewData> _assistantEntriesFrom(
    DraftGenerationResult result,
  ) {
    // 中文注释: 即使正文为空，只要本轮有思考内容也保留助手条目，避免工具回合把思考信息直接吞掉。
    final content = result.draftMarkdown.trim();
    final reasoning = result.reasoningContent.trim();
    if (content.isEmpty && reasoning.isEmpty) {
      return const <ConversationEntryViewData>[];
    }
    return <ConversationEntryViewData>[
      ConversationEntryViewData(
        id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
        kind: ConversationEntryKind.assistant,
        title: '综合创作智能体',
        body: content,
        isError: false,
        detailTitle: reasoning.isEmpty ? '' : '思考',
        detailSummary: _reasoningSummary(reasoning),
        detailBody: reasoning,
        detailExpandedByDefault: false,
      ),
    ];
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

  List<UserOptionViewData> _pendingOptionsFrom(List<Object?> executedTools) {
    // 中文注释: 待选项只从 present_user_options 工具结果提取，避免普通列表误显示成点击决策。
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) != 'present_user_options') {
        continue;
      }
      final result = ValueReaders.mapValue(tool['result']);
      final question = ValueReaders.stringValue(result['question']);
      return ValueReaders.objectList(result['options'])
          .map(ValueReaders.mapValue)
          .where((entry) => entry.isNotEmpty)
          .map(
            (entry) => UserOptionViewData(
              label: ValueReaders.stringValue(entry['label'], '选项'),
              description: ValueReaders.stringValue(entry['description']),
              prompt: ValueReaders.stringValue(entry['prompt']),
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
      final run = SubAgentRunViewData(
        id: runId,
        agentName: ValueReaders.stringValue(result['agent_name'], '子智能体'),
        task: ValueReaders.stringValue(result['task']),
        status: ValueReaders.boolValue(result['ok'], true) ? '完成' : '异常',
        summary: ValueReaders.stringValue(result['summary'], '子智能体已返回。'),
        content: ValueReaders.stringValue(result['result_markdown']),
        reasoning: ValueReaders.stringValue(result['reasoning_content']),
        toolCount: ValueReaders.intValue(result['tool_count']),
        events: ValueReaders.objectList(result['sub_agent_events'])
            .map(ValueReaders.mapValue)
            .map((event) => ValueReaders.stringValue(event['summary']))
            .where((summary) => summary.trim().isNotEmpty)
            .toList(growable: false),
      );
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
    next['compression_threshold_chars'] =
        _compressionStrategyService.thresholdChars(
          strategySettings: strategySettings,
          modelProfile: modelProfile,
          fallbackThresholdChars: ValueReaders.intValue(
            sessionRecord['compression_threshold_chars'],
            SessionRecordConstants.defaultThresholdChars,
          ),
        );
    return next;
  }
}
