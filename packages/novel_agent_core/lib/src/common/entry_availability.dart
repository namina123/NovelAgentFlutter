import 'json_types.dart';

enum EntryAvailabilityState { hidden, disabledWithUserReason, available }

class EntryAvailabilityDecision {
  const EntryAvailabilityDecision._({
    required this.entryId,
    required this.state,
    required this.userReason,
    required this.diagnosticReason,
  });

  factory EntryAvailabilityDecision.hidden({
    required String entryId,
    String diagnosticReason = '',
  }) {
    // 中文注释: 隐藏态只保留诊断原因，不把宿主未接线或不适用信息泄露给普通用户。
    return EntryAvailabilityDecision._(
      entryId: entryId.trim(),
      state: EntryAvailabilityState.hidden,
      userReason: '',
      diagnosticReason: diagnosticReason.trim(),
    );
  }

  const EntryAvailabilityDecision.hiddenContract({
    required this.entryId,
    this.diagnosticReason = '',
  }) : state = EntryAvailabilityState.hidden,
       userReason = '';

  factory EntryAvailabilityDecision.disabledWithUserReason({
    required String entryId,
    required String userReason,
    String diagnosticReason = '',
  }) {
    // 中文注释: 禁用态必须给出用户可理解的原因，同时允许附带更细的诊断说明供日志消费。
    return EntryAvailabilityDecision._(
      entryId: entryId.trim(),
      state: EntryAvailabilityState.disabledWithUserReason,
      userReason: userReason.trim(),
      diagnosticReason: diagnosticReason.trim(),
    );
  }

  factory EntryAvailabilityDecision.available({
    required String entryId,
    String diagnosticReason = '',
  }) {
    // 中文注释: 可用态不需要用户原因，但仍允许挂载诊断说明方便后续排查和回归。
    return EntryAvailabilityDecision._(
      entryId: entryId.trim(),
      state: EntryAvailabilityState.available,
      userReason: '',
      diagnosticReason: diagnosticReason.trim(),
    );
  }

  final String entryId;
  final EntryAvailabilityState state;
  final String userReason;
  final String diagnosticReason;

  bool get isHidden => state == EntryAvailabilityState.hidden;

  bool get isDisabledWithUserReason =>
      state == EntryAvailabilityState.disabledWithUserReason;

  bool get isAvailable => state == EntryAvailabilityState.available;

  bool get shouldShowUserReason =>
      isDisabledWithUserReason && userReason.trim().isNotEmpty;

  bool get hasDiagnosticReason => diagnosticReason.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EntryAvailabilityDecision &&
            other.entryId == entryId &&
            other.state == state &&
            other.userReason == userReason &&
            other.diagnosticReason == diagnosticReason;
  }

  @override
  int get hashCode => Object.hash(entryId, state, userReason, diagnosticReason);

  JsonMap toJson() {
    // 中文注释: 可用性决策需要在 tool / view data / diagnostics 之间稳定透传时，统一走 JSON 投影。
    return <String, Object?>{
      'entry_id': entryId,
      'state': state.name,
      'user_reason': userReason,
      'diagnostic_reason': diagnosticReason,
    };
  }
}
