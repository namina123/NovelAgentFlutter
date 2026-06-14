import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_compaction_decision_service.dart';
import 'session_compaction_prompt_contracts.dart';
import 'session_compaction_planner_service.dart';
import 'session_context_renderer_service.dart';
import 'session_context_pressure_contracts.dart';
import 'session_record_constants.dart';
import 'session_record_normalizer_service.dart';

enum SessionContextActionKind {
  inspectContext,
  compactNow,
  clearWorkingContext,
  pinContextSegment,
  unpinContextSegment,
  inspectCompactionGuidance;

  String toJsonValue() {
    // 中文注释: 动作面也要有稳定字符串，未来命令系统才能直接做协议映射。
    return switch (this) {
      SessionContextActionKind.inspectContext => 'inspect_context',
      SessionContextActionKind.compactNow => 'compact_now',
      SessionContextActionKind.clearWorkingContext => 'clear_working_context',
      SessionContextActionKind.pinContextSegment => 'pin_context_segment',
      SessionContextActionKind.unpinContextSegment => 'unpin_context_segment',
      SessionContextActionKind.inspectCompactionGuidance =>
        'inspect_compaction_guidance',
    };
  }

  static SessionContextActionKind fromJsonValue(Object? raw) {
    // 中文注释: 未识别动作默认回落到 inspect，避免误把命令协议解释成破坏性动作。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'compact_now' => SessionContextActionKind.compactNow,
      'clear_working_context' => SessionContextActionKind.clearWorkingContext,
      'pin_context_segment' => SessionContextActionKind.pinContextSegment,
      'unpin_context_segment' => SessionContextActionKind.unpinContextSegment,
      'inspect_compaction_guidance' =>
        SessionContextActionKind.inspectCompactionGuidance,
      _ => SessionContextActionKind.inspectContext,
    };
  }
}

class SessionContextActionResult {
  const SessionContextActionResult({
    required this.actionKind,
    required this.ok,
    required this.reason,
    required this.note,
    required this.payload,
  });

  final SessionContextActionKind actionKind;
  final bool ok;
  final String reason;
  final String note;
  final JsonMap payload;

  JsonMap toJson() {
    // 中文注释: 结果合同只承载稳定动作信息和 payload，不把内部服务对象泄露出去。
    return <String, Object?>{
      'action_kind': actionKind.toJsonValue(),
      'ok': ok,
      'reason': reason,
      'note': note,
      'payload': ValueReaders.deepCopyMap(payload),
    };
  }

  factory SessionContextActionResult.fromJson(JsonMap json) {
    // 中文注释: 结果反序列化要保持和 toJson 对称，方便 future probe 或恢复流程直接读回。
    return SessionContextActionResult(
      actionKind: SessionContextActionKind.fromJsonValue(json['action_kind']),
      ok: ValueReaders.boolValue(json['ok'], true),
      reason: ValueReaders.stringValue(json['reason']),
      note: ValueReaders.stringValue(json['note']),
      payload: ValueReaders.mapValue(json['payload']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 结果层至少要有动作类型和理由，避免空结果被误当成成功动作。
    final issues = <String>[];
    if (reason.trim().isEmpty) {
      issues.add('missing_session_context_action_reason');
    }
    if (note.trim().isEmpty) {
      issues.add('missing_session_context_action_note');
    }
    issues.addAll(_validatePayload());
    return issues;
  }

  List<String> _validatePayload() {
    // 中文注释: payload 不能为空壳，否则动作面只会给出一个名字而没有任何可消费事实。
    if (payload.isEmpty) {
      return <String>['missing_session_context_action_payload'];
    }
    return const <String>[];
  }
}

class SessionContextActionService {
  SessionContextActionService({
    required SessionRecordNormalizerService normalizerService,
    required SessionContextRendererService rendererService,
    required SessionCompactionDecisionService compactionDecisionService,
  }) : _normalizerService = normalizerService,
       _rendererService = rendererService,
       _compactionDecisionService = compactionDecisionService;

  final SessionRecordNormalizerService _normalizerService;
  final SessionContextRendererService _rendererService;
  final SessionCompactionDecisionService _compactionDecisionService;

  SessionContextActionResult inspectContext(
    JsonMap session, {
    JsonMap options = const <String, Object?>{},
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: inspect 只做投影，把上下文、摘要和可选压力快照组装成稳定检查包。
    final normalized = _normalize(session, defaultThresholdChars: defaultThresholdChars);
    final markdown = _rendererService.sessionContextMarkdown(
      normalized,
      options: options,
    );
    final summary = _rendererService.sessionPublicSummary(
      normalized,
      defaultThresholdChars: defaultThresholdChars,
      options: options,
    );
    return _result(
      SessionContextActionKind.inspectContext,
      reason: 'context_inspected',
      note: '已生成上下文检查包。',
      payload: <String, Object?>{
        'session_id': ValueReaders.stringValue(normalized['id']),
        'public_summary': summary,
        'context_markdown': markdown,
        'working_message_count': ValueReaders.objectList(
          normalized[SessionRecordConstants.workingContextMessagesField],
        ).length,
        'pinned_context_refs': ValueReaders.stringList(
          normalized[SessionRecordConstants.pinnedContextRefsField],
        ),
        'pressure_snapshot': _pressureSnapshotJson(options['pressure_snapshot']),
        'session_record': normalized,
      },
    );
  }

  SessionContextActionResult compactNow(
    JsonMap sessionRecord, {
    required SessionTokenBudgetSettings settings,
    SessionCompactionTriggerKind triggerKind =
        SessionCompactionTriggerKind.preflightSend,
    String systemPrompt = '',
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: compactNow 动作面先复用正式决策服务，不在这里偷偷引入新的压缩算法。
    final decision = _compactionDecisionService.decide(
      sessionRecord: sessionRecord,
      settings: settings,
      triggerKind: triggerKind,
      systemPrompt: systemPrompt,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    );
    return _result(
      SessionContextActionKind.compactNow,
      reason: decision.reason,
      note: decision.shouldCompact
          ? '压缩决策已生成，当前压力允许进入 compact_now。'
          : '当前压力不需要立即压缩，已返回保守决策包。',
      payload: <String, Object?>{
        'decision': decision.toJson(),
        'should_compact': decision.shouldCompact,
        'pressure_snapshot': decision.pressureSnapshot.toJson(),
        'plan': decision.plan.toJson(),
      },
    );
  }

  SessionContextActionResult clearWorkingContext(
    JsonMap session, {
    String now = '',
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: clear working context 只清当前送入模型的窗口，不动完整历史和压缩归档。
    final timestamp = _timestamp(now);
    final normalized = _normalize(
      session,
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    );
    final cleared = ValueReaders.deepCopyMap(normalized);
    final removedCount = ValueReaders.objectList(
      cleared[SessionRecordConstants.workingContextMessagesField],
    ).length;
    cleared[SessionRecordConstants.workingContextMessagesField] =
        <Object?>[];
    cleared[SessionRecordConstants.legacyContextMessagesField] = <Object?>[];
    cleared['updated_at'] = timestamp;
    final result = _normalize(
      cleared,
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    )..['updated_at'] = timestamp;
    return _result(
      SessionContextActionKind.clearWorkingContext,
      reason: 'working_context_cleared',
      note: removedCount == 0
          ? '工作上下文已经是空的。'
          : '已清空工作上下文，但完整历史与压缩归档保持不变。',
      payload: <String, Object?>{
        'cleared_message_count': removedCount,
        'session_record': result,
      },
    );
  }

  SessionContextActionResult pinContextSegment(
    JsonMap session,
    String contextRef, {
    String now = '',
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: pin 动作只维护稳定字符串引用列表，不把 segment 内容本身塞进动作面。
    final cleanRef = contextRef.trim();
    final timestamp = _timestamp(now);
    final normalized = _normalize(
      session,
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    );
    if (cleanRef.isEmpty) {
      return _result(
        SessionContextActionKind.pinContextSegment,
        reason: 'missing_context_ref',
        note: '未提供可固定的上下文引用。',
        payload: <String, Object?>{
          'session_record': normalized,
          'pinned_context_refs': ValueReaders.stringList(
            normalized[SessionRecordConstants.pinnedContextRefsField],
          ),
        },
        ok: false,
      );
    }
    final pinned = ValueReaders.stringList(
      normalized[SessionRecordConstants.pinnedContextRefsField],
    );
    final before = List<String>.from(pinned);
    if (!pinned.contains(cleanRef)) {
      pinned.add(cleanRef);
    }
    final updated = _normalize(
      <String, Object?>{
        ...normalized,
        SessionRecordConstants.pinnedContextRefsField: pinned,
        'updated_at': timestamp,
      },
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    )..['updated_at'] = timestamp;
    return _result(
      SessionContextActionKind.pinContextSegment,
      reason: before.length == pinned.length && before.contains(cleanRef)
          ? 'context_ref_already_pinned'
          : 'context_ref_pinned',
      note: before.length == pinned.length && before.contains(cleanRef)
          ? '该引用已处于固定状态。'
          : '已将上下文引用加入固定列表。',
      payload: <String, Object?>{
        'pinned_context_ref': cleanRef,
        'session_record': updated,
        'pinned_context_refs': ValueReaders.stringList(
          updated[SessionRecordConstants.pinnedContextRefsField],
        ),
      },
    );
  }

  SessionContextActionResult unpinContextSegment(
    JsonMap session,
    String contextRef, {
    String now = '',
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: unpin 只移除稳定引用，保证完整历史和工作窗口的其它结构不被波及。
    final cleanRef = contextRef.trim();
    final timestamp = _timestamp(now);
    final normalized = _normalize(
      session,
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    );
    if (cleanRef.isEmpty) {
      return _result(
        SessionContextActionKind.unpinContextSegment,
        reason: 'missing_context_ref',
        note: '未提供可取消固定的上下文引用。',
        payload: <String, Object?>{
          'session_record': normalized,
          'pinned_context_refs': ValueReaders.stringList(
            normalized[SessionRecordConstants.pinnedContextRefsField],
          ),
        },
        ok: false,
      );
    }
    final pinned = ValueReaders.stringList(
      normalized[SessionRecordConstants.pinnedContextRefsField],
    );
    final removed = pinned.remove(cleanRef);
    final updated = _normalize(
      <String, Object?>{
        ...normalized,
        SessionRecordConstants.pinnedContextRefsField: pinned,
        'updated_at': timestamp,
      },
      defaultThresholdChars: defaultThresholdChars,
      now: timestamp,
    )..['updated_at'] = timestamp;
    return _result(
      SessionContextActionKind.unpinContextSegment,
      reason: removed ? 'context_ref_unpinned' : 'context_ref_not_found',
      note: removed
          ? '已从固定列表移除该上下文引用。'
          : '固定列表中没有找到该上下文引用。',
      payload: <String, Object?>{
        'unpinned_context_ref': cleanRef,
        'session_record': updated,
        'pinned_context_refs': ValueReaders.stringList(
          updated[SessionRecordConstants.pinnedContextRefsField],
        ),
      },
    );
  }

  SessionContextActionResult inspectCompactionGuidance({
    required CompactionPromptInjectionFrame frame,
    bool useRuntimeContinuationInstruction = false,
  }) {
    // 中文注释: guidance inspect 只投影正式合同和分层顺序，不把它和真实用户提示词搅在一起。
    final orderedSectionKinds = frame
        .orderedSectionKinds(
          useRuntimeContinuationInstruction: useRuntimeContinuationInstruction,
        )
        .map((kind) => kind.toJsonValue())
        .toList(growable: false);
    return _result(
      SessionContextActionKind.inspectCompactionGuidance,
      reason: 'compaction_guidance_inspected',
      note: '已生成压缩指导检查包。',
      payload: <String, Object?>{
        'frame': frame.toJson(),
        'ordered_section_kinds': orderedSectionKinds,
        'validation_issues': frame.validateBasics(),
      },
    );
  }

  SessionContextActionResult _result(
    SessionContextActionKind actionKind, {
    required String reason,
    required String note,
    required JsonMap payload,
    bool ok = true,
  }) {
    // 中文注释: 统一结果封装避免每个动作各自拼 JSON，未来命令系统也更容易消费。
    return SessionContextActionResult(
      actionKind: actionKind,
      ok: ok,
      reason: reason,
      note: note,
      payload: payload,
    );
  }

  JsonMap _normalize(
    JsonMap session, {
    required int defaultThresholdChars,
    String now = '',
  }) {
    // 中文注释: 动作面修改 session 前后都先走 normalizer，确保 contract 字段和兼容桥同时更新。
    return _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: defaultThresholdChars,
      now: now,
    );
  }

  String _timestamp(String now) {
    // 中文注释: 统一时间戳来源，避免每个动作自己产生不同格式的更新字段。
    final timestamp = now.trim();
    return timestamp.isEmpty ? DateTime.now().toIso8601String() : timestamp;
  }

  JsonMap _pressureSnapshotJson(Object? raw) {
    // 中文注释: inspect 结果尽量支持压力快照对象和 JSON 两种输入，方便 app 与测试共用。
    if (raw is SessionContextPressureSnapshot) {
      return raw.toJson();
    }
    return ValueReaders.mapValue(raw);
  }
}
