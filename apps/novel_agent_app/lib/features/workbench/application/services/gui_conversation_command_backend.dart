import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

/// GUI 侧的 [ConversationCommandBackend] 实现。
///
/// 与 CLI 的 [ProjectSessionShellCommandBackend] 不同，GUI 后端**直接在传入的 sessionRecord
/// 上做纯算法操作**（pressure / compaction / mutation），不调 load/save——持久化由
/// [WorkbenchConversationController] 经 `_replaceConversationSession` 负责。这样命令结果
/// 写回 GUI 的 `ConversationSessionState` 而不是裸 record。
class GuiConversationCommandBackend implements ConversationCommandBackend {
  GuiConversationCommandBackend({SessionTokenBudgetSettings? budgetSettings})
    : _budgetSettings = budgetSettings ?? _defaultBudget(),
      _modeService = SessionModeService(),
      _messageService = SessionMessageService(),
      _compactionService = ProjectSessionCompactionService(),
      _pressureService = const SessionContextPressureService(),
      _compactionDecisionService = SessionCompactionDecisionService();

  final SessionTokenBudgetSettings _budgetSettings;
  final SessionModeService _modeService;
  final SessionMessageService _messageService;
  final ProjectSessionCompactionService _compactionService;
  final SessionContextPressureService _pressureService;
  final SessionCompactionDecisionService _compactionDecisionService;

  // 中文注释: normalizer/mutation/renderer 依赖 mode+message service，用 late final 延迟到构造后组装，避免初始化列表里重复构造。
  late final SessionRecordNormalizerService _normalizerService =
      SessionRecordNormalizerService(
        modeService: _modeService,
        messageService: _messageService,
      );
  late final SessionRecordMutationService _mutationService =
      SessionRecordMutationService(
        normalizerService: _normalizerService,
        modeService: _modeService,
        messageService: _messageService,
      );
  late final SessionContextRendererService _rendererService =
      SessionContextRendererService(
        normalizerService: _normalizerService,
        messageService: _messageService,
      );

  JsonMap _normalized(JsonMap record) {
    return _normalizerService.normalizeSessionRecord(
      record,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
  }

  @override
  Future<ConversationCommandBackendOutcome> compact(JsonMap sessionRecord) async {
    final record = _normalized(sessionRecord);
    final pressure = _pressureService.snapshotFromSessionRecord(
      record,
      settings: _budgetSettings,
    );
    final decision = _compactionDecisionService.decideFromSnapshot(
      sessionRecord: record,
      pressureSnapshot: pressure,
      triggerKind: SessionCompactionTriggerKind.preflightResume,
    );
    final compacted = _compactionService.compactSessionRecord(
      sessionRecord: record,
      decision: decision,
      outputPolicy: const CompactionOutputPolicy(
        policyId: 'policy.session.gui_compact',
        title: 'GUI 会话压缩输出策略',
      ),
      now: '',
    );
    return _outcome(compacted, pressure: pressure, decision: decision);
  }

  @override
  Future<ConversationCommandBackendOutcome> stats(JsonMap sessionRecord) async {
    final record = _normalized(sessionRecord);
    final pressure = _pressureService.snapshotFromSessionRecord(
      record,
      settings: _budgetSettings,
    );
    final decision = _compactionDecisionService.decideFromSnapshot(
      sessionRecord: record,
      pressureSnapshot: pressure,
    );
    return _outcome(record, pressure: pressure, decision: decision, persist: false);
  }

  @override
  Future<ConversationCommandBackendOutcome> setMode(
    JsonMap sessionRecord,
    String mode,
  ) async {
    final updated = _mutationService.sessionWithGoal(sessionRecord, mode);
    return _outcome(updated);
  }

  @override
  Future<ConversationCommandBackendOutcome> setGoalText(
    JsonMap sessionRecord,
    String text,
  ) async {
    final updated = ValueReaders.deepCopyMap(sessionRecord)
      ..[SessionRecordConstants.conversationGoalField] = text.trim();
    return _outcome(updated);
  }

  @override
  Future<ConversationCommandBackendOutcome> clearContext(
    JsonMap sessionRecord,
  ) async {
    final updated = ValueReaders.deepCopyMap(sessionRecord)
      ..[SessionRecordConstants.workingContextMessagesField] = <Object?>[]
      ..[SessionRecordConstants.legacyContextMessagesField] = <Object?>[];
    return _outcome(updated);
  }

  @override
  Future<ConversationCommandBackendOutcome> exitSession(
    JsonMap sessionRecord,
  ) async {
    // 中文注释: GUI 没有"退出 REPL"语义；exit 仅作为信号返回，controller 可据结束当前会话或忽略。
    return ConversationCommandBackendOutcome(
      updatedSessionRecord: sessionRecord,
      exitSession: true,
    );
  }

  ConversationCommandBackendOutcome _outcome(
    JsonMap record, {
    SessionContextPressureSnapshot? pressure,
    SessionCompactionDecision? decision,
    bool persist = true,
    bool exitSession = false,
  }) {
    final detail = <String, Object?>{
      'public_summary': _rendererService.sessionPublicSummary(record),
    };
    if (pressure != null) {
      detail['pressure_snapshot'] = pressure.toJson();
    }
    if (decision != null) {
      detail['compaction_decision'] = decision.toJson();
    }
    return ConversationCommandBackendOutcome(
      updatedSessionRecord: record,
      persist: persist,
      detail: detail,
      exitSession: exitSession,
    );
  }

  static SessionTokenBudgetSettings _defaultBudget() {
    return SessionTokenBudgetSettings(
      modelContextWindowTokens: 100000,
      reservedOutputTokens: 2048,
      warningThresholdRatio: 0.8,
      criticalThresholdRatio: 0.95,
    );
  }
}
