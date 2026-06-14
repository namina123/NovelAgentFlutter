import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_context_pressure_contracts.dart';
import 'session_context_pressure_enums.dart';
import 'session_message_service.dart';
import 'session_record_constants.dart';

enum SessionCompactionTriggerKind {
  preflightSend,
  preflightToolRound,
  preflightResume;

  String toJsonValue() {
    // 中文注释: 触发类型是协议的一部分，需要稳定的 JSON 字符串，方便未来 preflight 接口复用。
    return switch (this) {
      SessionCompactionTriggerKind.preflightSend => 'preflight_send',
      SessionCompactionTriggerKind.preflightToolRound => 'preflight_tool_round',
      SessionCompactionTriggerKind.preflightResume => 'preflight_resume',
    };
  }

  static SessionCompactionTriggerKind fromJsonValue(Object? raw) {
    // 中文注释: 未识别的触发类型默认按发送前处理，保证协议读回时的保守性。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'preflight_tool_round' => SessionCompactionTriggerKind.preflightToolRound,
      'preflight_resume' => SessionCompactionTriggerKind.preflightResume,
      _ => SessionCompactionTriggerKind.preflightSend,
    };
  }
}

class SessionCompactionPlan {
  const SessionCompactionPlan({
    required this.triggerKind,
    required this.pressureLevel,
    required this.workingMessageCount,
    required this.keepRecentMessageCount,
    required this.compactionMessageIndices,
    required this.retainedMessageIndices,
    this.pinnedContextRefs = const <String>[],
    this.reason = '',
  });

  final SessionCompactionTriggerKind triggerKind;
  final SessionContextPressureLevel pressureLevel;
  final int workingMessageCount;
  final int keepRecentMessageCount;
  final List<int> compactionMessageIndices;
  final List<int> retainedMessageIndices;
  final List<String> pinnedContextRefs;
  final String reason;

  bool get hasCompactionCandidates => compactionMessageIndices.isNotEmpty;

  int get compactionMessageCount => compactionMessageIndices.length;

  int get retainedMessageCount => retainedMessageIndices.length;

  JsonMap toJson() {
    // 中文注释: compaction plan 作为可审计结果输出，便于后续 preflight 与恢复逻辑复用。
    return <String, Object?>{
      'trigger_kind': triggerKind.toJsonValue(),
      'pressure_level': pressureLevel.toJsonValue(),
      'working_message_count': workingMessageCount,
      'keep_recent_message_count': keepRecentMessageCount,
      'compaction_message_indices': compactionMessageIndices,
      'retained_message_indices': retainedMessageIndices,
      'pinned_context_refs': pinnedContextRefs,
      'reason': reason,
      'has_compaction_candidates': hasCompactionCandidates,
    };
  }

  factory SessionCompactionPlan.fromJson(JsonMap json) {
    // 中文注释: 计划反序列化保留索引列表和保留窗口，确保恢复或探针测试能直接对齐计划结果。
    return SessionCompactionPlan(
      triggerKind: SessionCompactionTriggerKind.fromJsonValue(
        json['trigger_kind'],
      ),
      pressureLevel: SessionContextPressureLevel.fromJsonValue(
        json['pressure_level'],
      ),
      workingMessageCount: ValueReaders.intValue(json['working_message_count']),
      keepRecentMessageCount: ValueReaders.intValue(
        json['keep_recent_message_count'],
      ),
      compactionMessageIndices: ValueReaders.objectList(
        json['compaction_message_indices'],
      ).map((item) => ValueReaders.intValue(item)).toList(growable: false),
      retainedMessageIndices: ValueReaders.objectList(
        json['retained_message_indices'],
      ).map((item) => ValueReaders.intValue(item)).toList(growable: false),
      pinnedContextRefs: ValueReaders.stringList(json['pinned_context_refs']),
      reason: ValueReaders.stringValue(json['reason']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 计划校验只关注索引边界与保留窗口，避免无效计划继续流向 mutation。
    final issues = <String>[];
    if (keepRecentMessageCount < 0) {
      issues.add('negative_keep_recent_message_count');
    }
    if (workingMessageCount < 0) {
      issues.add('negative_working_message_count');
    }
    if (compactionMessageIndices.any((value) => value < 0)) {
      issues.add('negative_compaction_message_index');
    }
    if (retainedMessageIndices.any((value) => value < 0)) {
      issues.add('negative_retained_message_index');
    }
    return issues;
  }
}

class SessionCompactionPlannerService {
  SessionCompactionPlannerService({SessionMessageService? messageService})
    : _messageService = messageService ?? SessionMessageService();

  final SessionMessageService _messageService;

  SessionCompactionPlan plan({
    required JsonMap sessionRecord,
    required SessionContextPressureSnapshot pressureSnapshot,
    SessionCompactionTriggerKind triggerKind =
        SessionCompactionTriggerKind.preflightSend,
  }) {
    // 中文注释: 这里把“压哪些、保留哪些”正式算成计划，但不直接改写 sessionRecord。
    final workingMessages = _workingMessages(sessionRecord);
    final workingCount = workingMessages.length;
    final keepRecentCount = _keepRecentMessageCount(
      triggerKind: triggerKind,
      pressureLevel: pressureSnapshot.pressureLevel,
      workingMessageCount: workingCount,
    );
    final compactionCount = workingCount <= keepRecentCount
        ? 0
        : workingCount - keepRecentCount;
    final compactionIndices = List<int>.generate(
      compactionCount,
      (index) => index,
      growable: false,
    );
    final retainedIndices = List<int>.generate(
      workingCount - compactionCount,
      (index) => compactionCount + index,
      growable: false,
    );
    final pinnedContextRefs = ValueReaders.stringList(
      sessionRecord[SessionRecordConstants.pinnedContextRefsField],
    );
    return SessionCompactionPlan(
      triggerKind: triggerKind,
      pressureLevel: pressureSnapshot.pressureLevel,
      workingMessageCount: workingCount,
      keepRecentMessageCount: keepRecentCount,
      compactionMessageIndices: compactionIndices,
      retainedMessageIndices: retainedIndices,
      pinnedContextRefs: pinnedContextRefs,
      reason: _buildReason(
        triggerKind: triggerKind,
        pressureLevel: pressureSnapshot.pressureLevel,
        workingMessageCount: workingCount,
        keepRecentCount: keepRecentCount,
      ),
    );
  }

  bool shouldPlanCompaction(SessionCompactionPlan plan) {
    // 中文注释: 计划里有候选消息，并不代表一定要压缩；真正是否执行由决策层结合压力等级判断。
    return plan.hasCompactionCandidates;
  }

  List<Object?> _workingMessages(JsonMap sessionRecord) {
    // 中文注释: 规划只消费 working context，旧字段仅作为兼容桥，不让 planner 自己重造历史。
    return ValueReaders.objectList(
      sessionRecord[SessionRecordConstants.workingContextMessagesField] ??
          sessionRecord[SessionRecordConstants.legacyContextMessagesField] ??
          sessionRecord[SessionRecordConstants.transcriptMessagesField],
    );
  }

  int _keepRecentMessageCount({
    required SessionCompactionTriggerKind triggerKind,
    required SessionContextPressureLevel pressureLevel,
    required int workingMessageCount,
  }) {
    // 中文注释: 不同触发点保留窗口不同，但最终都服从 pressure level，避免压缩过猛或过轻。
    final base = switch (triggerKind) {
      SessionCompactionTriggerKind.preflightSend => switch (pressureLevel) {
        SessionContextPressureLevel.safe => 8,
        SessionContextPressureLevel.warning => 6,
        SessionContextPressureLevel.critical => 4,
        SessionContextPressureLevel.overLimit => 4,
      },
      SessionCompactionTriggerKind.preflightToolRound =>
        switch (pressureLevel) {
          SessionContextPressureLevel.safe => 10,
          SessionContextPressureLevel.warning => 8,
          SessionContextPressureLevel.critical => 6,
          SessionContextPressureLevel.overLimit => 4,
        },
      SessionCompactionTriggerKind.preflightResume => switch (pressureLevel) {
        SessionContextPressureLevel.safe => 12,
        SessionContextPressureLevel.warning => 8,
        SessionContextPressureLevel.critical => 6,
        SessionContextPressureLevel.overLimit => 4,
      },
    };
    if (workingMessageCount <= 0) {
      return 0;
    }
    return base.clamp(0, workingMessageCount).toInt();
  }

  String _buildReason({
    required SessionCompactionTriggerKind triggerKind,
    required SessionContextPressureLevel pressureLevel,
    required int workingMessageCount,
    required int keepRecentCount,
  }) {
    // 中文注释: 原因文案只用于审计与测试，说明这是哪个 preflight 触发、压力处于什么等级、保留了多少最近消息。
    return 'trigger=${triggerKind.toJsonValue()}, pressure=${pressureLevel.toJsonValue()}, working=$workingMessageCount, keep_recent=$keepRecentCount';
  }
}
