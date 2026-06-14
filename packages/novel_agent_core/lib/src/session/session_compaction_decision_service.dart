import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_compaction_planner_service.dart';
import 'session_context_pressure_contracts.dart';
import 'session_context_pressure_enums.dart';
import 'session_context_pressure_service.dart';

enum SessionCompactionActionKind {
  noCompaction,
  compactNow;

  String toJsonValue() {
    // 中文注释: 决策动作也需要稳定字符串，方便 preflight 日志、快照和测试复用。
    return switch (this) {
      SessionCompactionActionKind.noCompaction => 'no_compaction',
      SessionCompactionActionKind.compactNow => 'compact_now',
    };
  }

  static SessionCompactionActionKind fromJsonValue(Object? raw) {
    // 中文注释: 未识别动作默认回落到不压缩，保持预判保守性。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'compact_now' => SessionCompactionActionKind.compactNow,
      _ => SessionCompactionActionKind.noCompaction,
    };
  }
}

class SessionCompactionDecision {
  const SessionCompactionDecision({
    required this.actionKind,
    required this.triggerKind,
    required this.pressureSnapshot,
    required this.plan,
    required this.reason,
  });

  final SessionCompactionActionKind actionKind;
  final SessionCompactionTriggerKind triggerKind;
  final SessionContextPressureSnapshot pressureSnapshot;
  final SessionCompactionPlan plan;
  final String reason;

  bool get shouldCompact =>
      actionKind == SessionCompactionActionKind.compactNow;

  JsonMap toJson() {
    // 中文注释: 决策结果把 snapshot 和 plan 一起打包，确保 preflight 入口有完整审计材料。
    return <String, Object?>{
      'action_kind': actionKind.toJsonValue(),
      'trigger_kind': triggerKind.toJsonValue(),
      'pressure_snapshot': pressureSnapshot.toJson(),
      'plan': plan.toJson(),
      'reason': reason,
      'should_compact': shouldCompact,
    };
  }

  factory SessionCompactionDecision.fromJson(JsonMap json) {
    // 中文注释: 决策反序列化保留 snapshot 和 plan 的嵌套结构，便于恢复或探针验证。
    return SessionCompactionDecision(
      actionKind: SessionCompactionActionKind.fromJsonValue(
        json['action_kind'],
      ),
      triggerKind: SessionCompactionTriggerKind.fromJsonValue(
        json['trigger_kind'],
      ),
      pressureSnapshot: SessionContextPressureSnapshot.fromJson(
        ValueReaders.mapValue(json['pressure_snapshot']),
      ),
      plan: SessionCompactionPlan.fromJson(ValueReaders.mapValue(json['plan'])),
      reason: ValueReaders.stringValue(json['reason']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 决策层只检查是否存在有效的 snapshot 和 plan，避免空决策进入后续执行链。
    final issues = <String>[];
    issues.addAll(pressureSnapshot.validateBasics());
    issues.addAll(plan.validateBasics());
    if (reason.trim().isEmpty) {
      issues.add('missing_compaction_decision_reason');
    }
    return issues;
  }
}

class SessionCompactionDecisionService {
  SessionCompactionDecisionService({
    SessionContextPressureService? pressureService,
    SessionCompactionPlannerService? plannerService,
  }) : _pressureService =
           pressureService ?? const SessionContextPressureService(),
       _plannerService = plannerService ?? SessionCompactionPlannerService();

  final SessionContextPressureService _pressureService;
  final SessionCompactionPlannerService _plannerService;

  SessionCompactionDecision decide({
    required JsonMap sessionRecord,
    required SessionTokenBudgetSettings settings,
    SessionCompactionTriggerKind triggerKind =
        SessionCompactionTriggerKind.preflightSend,
    String systemPrompt = '',
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 这里先算压力快照，再交给 planner 做保守规划，最后只在需要时给出 compactNow。
    final snapshot = _pressureService.snapshotFromSessionRecord(
      sessionRecord,
      settings: settings,
      systemPrompt: systemPrompt,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    );
    return decideFromSnapshot(
      sessionRecord: sessionRecord,
      pressureSnapshot: snapshot,
      triggerKind: triggerKind,
    );
  }

  SessionCompactionDecision decideFromSnapshot({
    required JsonMap sessionRecord,
    required SessionContextPressureSnapshot pressureSnapshot,
    SessionCompactionTriggerKind triggerKind =
        SessionCompactionTriggerKind.preflightSend,
  }) {
    // 中文注释: 决策层只管“现在压不压缩”，不替 planner 写保留窗口，也不替 mutation 执行具体裁剪。
    final plan = _plannerService.plan(
      sessionRecord: sessionRecord,
      pressureSnapshot: pressureSnapshot,
      triggerKind: triggerKind,
    );
    final shouldCompact =
        pressureSnapshot.pressureLevel != SessionContextPressureLevel.safe &&
        plan.hasCompactionCandidates;
    final actionKind = shouldCompact
        ? SessionCompactionActionKind.compactNow
        : SessionCompactionActionKind.noCompaction;
    final reason = shouldCompact
        ? plan.reason
        : 'pressure=${pressureSnapshot.pressureLevel.toJsonValue()}, trigger=${triggerKind.toJsonValue()}, compact_deferred';
    return SessionCompactionDecision(
      actionKind: actionKind,
      triggerKind: triggerKind,
      pressureSnapshot: pressureSnapshot,
      plan: plan,
      reason: reason,
    );
  }
}
