import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_session_state.dart';
import 'conversation_session_compaction_service.dart';
import 'conversation_session_state_service.dart';

class ConversationSessionSendPreflightResult {
  const ConversationSessionSendPreflightResult({
    required this.sessionState,
    required this.pressureSnapshot,
    required this.compactionDecision,
    required this.sessionContextMarkdown,
    required this.tokenBudgetSettings,
    required this.compactionGuidance,
    required this.compactionOutputPolicy,
    required this.compactionSourceScope,
    required this.runtimeContinuationInstruction,
  });

  final ConversationSessionState sessionState;
  final SessionContextPressureSnapshot pressureSnapshot;
  final SessionCompactionDecision compactionDecision;
  final String sessionContextMarkdown;
  final SessionTokenBudgetSettings tokenBudgetSettings;
  final CompactionGuidanceContract compactionGuidance;
  final CompactionOutputPolicy compactionOutputPolicy;
  final CompactionSourceScope compactionSourceScope;
  final RuntimeContinuationInstructionContract? runtimeContinuationInstruction;

  bool get didCompact => compactionDecision.shouldCompact;
}

class ConversationSessionPreflightService {
  ConversationSessionPreflightService({
    ConversationSessionStateService? sessionStateService,
    ConversationSessionCompactionService? compactionService,
    SessionContextPressureService? pressureService,
    SessionCompactionDecisionService? decisionService,
  }) : _sessionStateService =
           sessionStateService ?? ConversationSessionStateService(),
       _compactionService =
           compactionService ?? ConversationSessionCompactionService(),
       _pressureService =
           pressureService ?? const SessionContextPressureService(),
       _decisionService = decisionService ?? SessionCompactionDecisionService();

  final ConversationSessionStateService _sessionStateService;
  final ConversationSessionCompactionService _compactionService;
  final SessionContextPressureService _pressureService;
  final SessionCompactionDecisionService _decisionService;

  ConversationSessionSendPreflightResult prepareForSend({
    required ConversationSessionState state,
    required JsonMap runtimeProfile,
    String excludeLatestUserContent = '',
    bool retryLastFailure = false,
    String now = '',
  }) {
    // 中文注释: 发送前预检只在服务层完成压力判断、压缩与层级化注入，控制器只拿结果去发请求。
    final settings = _budgetSettingsFrom(runtimeProfile);
    final triggerKind = retryLastFailure
        ? SessionCompactionTriggerKind.preflightResume
        : SessionCompactionTriggerKind.preflightSend;
    final pressureSnapshot = _pressureService.snapshotFromSessionRecord(
      state.sessionRecord,
      settings: settings,
      baseFramingTokens: _baseFramingTokens(runtimeProfile),
    );
    final compactionDecision = _decisionService.decideFromSnapshot(
      sessionRecord: state.sessionRecord,
      pressureSnapshot: pressureSnapshot,
      triggerKind: triggerKind,
    );
    final compactionOutputPolicy = _buildOutputPolicy(pressureSnapshot);
    final compactionSourceScope = _buildSourceScope(
      triggerKind: triggerKind,
      compactionDecision: compactionDecision,
    );
    final runtimeContinuationInstruction = _runtimeContinuationInstructionFor(
      triggerKind: triggerKind,
    );
    final compactionGuidance = _buildGuidance(
      pressureSnapshot: pressureSnapshot,
      compactionDecision: compactionDecision,
      sourceScopeId: compactionSourceScope.scopeId,
      outputPolicyId: compactionOutputPolicy.policyId,
      runtimeContinuationInstruction: runtimeContinuationInstruction,
    );
    final sessionRecord = compactionDecision.shouldCompact
        ? _compactionService.compactSessionRecord(
            sessionRecord: state.sessionRecord,
            decision: compactionDecision,
            outputPolicy: compactionOutputPolicy,
            now: now,
          )
        : state.sessionRecord;
    final sessionState = state.copyWith(sessionRecord: sessionRecord);
    final renderedPressureSnapshot = _pressureService.snapshotFromSessionRecord(
      sessionState.sessionRecord,
      settings: settings,
      baseFramingTokens: _baseFramingTokens(runtimeProfile),
    );
    final sessionContextMarkdown = _sessionStateService.sessionContextMarkdown(
      sessionState,
      excludeLatestUserContent: excludeLatestUserContent,
      pressureSnapshot: renderedPressureSnapshot,
      compactionGuidance: compactionGuidance,
      compactionOutputPolicy: compactionOutputPolicy,
      compactionSourceScope: compactionSourceScope,
      runtimeContinuationInstruction: runtimeContinuationInstruction,
    );
    return ConversationSessionSendPreflightResult(
      sessionState: sessionState,
      pressureSnapshot: renderedPressureSnapshot,
      compactionDecision: compactionDecision,
      sessionContextMarkdown: sessionContextMarkdown,
      tokenBudgetSettings: settings,
      compactionGuidance: compactionGuidance,
      compactionOutputPolicy: compactionOutputPolicy,
      compactionSourceScope: compactionSourceScope,
      runtimeContinuationInstruction: runtimeContinuationInstruction,
    );
  }

  SessionTokenBudgetSettings _budgetSettingsFrom(JsonMap runtimeProfile) {
    // 中文注释: 预算设置优先从模型执行 profile 取窗口与输出保留量，避免把 token 判定重新绑回字符口径。
    final modelContextWindowTokens = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    final reservedOutputTokens = _reservedOutputTokensFrom(runtimeProfile);
    return SessionTokenBudgetSettings(
      modelContextWindowTokens: modelContextWindowTokens <= 0
          ? 100000
          : modelContextWindowTokens,
      reservedOutputTokens: reservedOutputTokens,
      warningThresholdRatio: 0.8,
      criticalThresholdRatio: 0.95,
    );
  }

  int _reservedOutputTokensFrom(JsonMap runtimeProfile) {
    // 中文注释: 输出保留量只做保守近似，既不依赖旧字符设置，也不把整个模型窗口都留给输出。
    final maxOutputTokens = ValueReaders.intValue(
      runtimeProfile['max_output_tokens'],
      2048,
    );
    final contextWindow = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    final fallbackReserve = contextWindow <= 0
        ? 2048
        : ((contextWindow / 10).round().clamp(1024, 16384)).toInt();
    final reserve = maxOutputTokens < fallbackReserve
        ? maxOutputTokens
        : fallbackReserve;
    return reserve < 0 ? 0 : reserve;
  }

  int _baseFramingTokens(JsonMap runtimeProfile) {
    // 中文注释: 这里预留一点固定 framing 开销，覆盖系统提示和 prompt 外壳的保守估计。
    final contextWindow = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    if (contextWindow <= 0) {
      return 128;
    }
    final framed = (contextWindow / 100).round();
    return framed.clamp(64, 512).toInt();
  }

  CompactionOutputPolicy _buildOutputPolicy(
    SessionContextPressureSnapshot pressureSnapshot,
  ) {
    // 中文注释: 输出策略单独建模，控制压缩段长度而不掺入 source scope 或续跑指令。
    final maxBulletCount = switch (pressureSnapshot.pressureLevel) {
      SessionContextPressureLevel.safe => 4,
      SessionContextPressureLevel.warning => 6,
      SessionContextPressureLevel.critical => 8,
      SessionContextPressureLevel.overLimit => 8,
    };
    return CompactionOutputPolicy(
      policyId: 'policy.session.preflight_send',
      title: '发送前压缩输出策略',
      outputFormat: 'structured_bullets',
      maxCharacters: 1200,
      maxBulletCount: maxBulletCount,
      preservePinnedFacts: true,
      preserveSourceAttribution: true,
      preferUnknownMarkers: true,
      metadata: <String, Object?>{
        'pressure_level': pressureSnapshot.pressureLevel.toJsonValue(),
      },
    );
  }

  CompactionSourceScope _buildSourceScope({
    required SessionCompactionTriggerKind triggerKind,
    required SessionCompactionDecision compactionDecision,
  }) {
    // 中文注释: source scope 只声明可参与本轮 preflight 的事实来源，不替 prompt 组装层决定文案。
    return CompactionSourceScope(
      scopeId: 'scope.session.preflight_send',
      sourceKinds: const <String>[
        SessionRecordConstants.transcriptMessagesField,
        SessionRecordConstants.workingContextMessagesField,
        SessionRecordConstants.compactionSegmentsField,
        SessionRecordConstants.pinnedContextRefsField,
      ],
      excludedSourceKinds: const <String>[],
      allowLegacyContextBridge: true,
      allowCurrentUserPrompt: false,
      allowRuntimeContinuationInstruction:
          triggerKind != SessionCompactionTriggerKind.preflightSend ||
          compactionDecision.shouldCompact,
      metadata: <String, Object?>{'trigger_kind': triggerKind.toJsonValue()},
    );
  }

  CompactionGuidanceContract _buildGuidance({
    required SessionContextPressureSnapshot pressureSnapshot,
    required SessionCompactionDecision compactionDecision,
    required String sourceScopeId,
    required String outputPolicyId,
    RuntimeContinuationInstructionContract? runtimeContinuationInstruction,
  }) {
    // 中文注释: guidance 只负责说明“怎么压”，不把真实用户提示词或运行时 continuation 塞进同一层。
    final shouldCompact = compactionDecision.shouldCompact;
    final rules = <String>[
      '只压缩 working context，不修改 full transcript。',
      '保留 pinned context refs。',
      if (shouldCompact)
        '本轮保留最近 ${compactionDecision.plan.keepRecentMessageCount} 条工作消息。',
      if (pressureSnapshot.hasOverflow) '当输入预算已经越界时，优先收束最近对话窗口。',
    ];
    return CompactionGuidanceContract(
      guidanceId: 'guidance.session.preflight_send',
      title: '发送前压缩指导',
      summary: shouldCompact
          ? '当前上下文压力已触发发送前压缩，先收束工作窗口再发送。'
          : '当前上下文未触发压缩，仍按分层协议渲染工作上下文。',
      rules: rules,
      sourceScopeId: sourceScopeId,
      outputPolicyId: outputPolicyId,
      metadata: <String, Object?>{
        'pressure_level': pressureSnapshot.pressureLevel.toJsonValue(),
        'trigger_kind': compactionDecision.triggerKind.toJsonValue(),
        if (runtimeContinuationInstruction != null)
          'runtime_continuation_instruction_id':
              runtimeContinuationInstruction.instructionId,
      },
    );
  }

  RuntimeContinuationInstructionContract? _runtimeContinuationInstructionFor({
    required SessionCompactionTriggerKind triggerKind,
  }) {
    // 中文注释: 续跑指令只在恢复或工具轮连续推进时注入，平常发送仍然只保留真实用户提示词。
    if (triggerKind == SessionCompactionTriggerKind.preflightSend) {
      return null;
    }
    final title = triggerKind == SessionCompactionTriggerKind.preflightResume
        ? '恢复续跑指令'
        : '工具轮续跑指令';
    final instruction =
        triggerKind == SessionCompactionTriggerKind.preflightResume
        ? '这是恢复执行，请延续当前用户意图和已压缩的工作窗口继续推进，不要把压缩指导写进真实用户提示词。'
        : '这是工具轮继续，请基于当前工作窗口延续上一轮工具结果，不要把压缩指导写进真实用户提示词。';
    return RuntimeContinuationInstructionContract(
      instructionId: triggerKind.toJsonValue(),
      title: title,
      instruction: instruction,
      triggerKinds: <String>[triggerKind.toJsonValue()],
      metadata: <String, Object?>{'trigger_kind': triggerKind.toJsonValue()},
    );
  }
}
