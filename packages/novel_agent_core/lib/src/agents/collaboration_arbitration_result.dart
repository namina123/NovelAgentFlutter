import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'collaboration_conflict_record.dart';

class CollaborationArbitrationStatuses {
  static const String autoResolved = 'auto_resolved';
  static const String needsRepair = 'needs_repair';
  static const String needsUserConfirmation = 'needs_user_confirmation';

  static const Set<String> knownValues = <String>{
    autoResolved,
    needsRepair,
    needsUserConfirmation,
  };
}

class CollaborationArbitrationResult {
  const CollaborationArbitrationResult({
    this.arbitrationId = '',
    this.groupKey = '',
    this.status = '',
    this.highestRisk = CollaborationConflictRisks.low,
    this.selectedConflictId = '',
    this.summary = '',
    this.reason = '',
    this.autoResolved = false,
    this.requiresRepair = false,
    this.requiresUserConfirmation = false,
    this.acceptedConflictIds = const <String>[],
    this.rejectedConflictIds = const <String>[],
    this.pendingConflictIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String arbitrationId;
  final String groupKey;
  final String status;
  final String highestRisk;
  final String selectedConflictId;
  final String summary;
  final String reason;
  final bool autoResolved;
  final bool requiresRepair;
  final bool requiresUserConfirmation;
  final List<String> acceptedConflictIds;
  final List<String> rejectedConflictIds;
  final List<String> pendingConflictIds;
  final JsonMap metadata;

  factory CollaborationArbitrationResult.fromJson(JsonMap json) {
    return CollaborationArbitrationResult(
      arbitrationId: ValueReaders.stringValue(
        json['arbitration_id'],
        ValueReaders.stringValue(json['id']),
      ).trim(),
      groupKey: ValueReaders.stringValue(json['group_key']).trim(),
      status: ValueReaders.stringValue(json['status']).trim(),
      highestRisk: CollaborationConflictRisks.normalize(
        ValueReaders.stringValue(json['highest_risk']),
      ),
      selectedConflictId: ValueReaders.stringValue(
        json['selected_conflict_id'],
      ).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      autoResolved: ValueReaders.boolValue(json['auto_resolved']),
      requiresRepair: ValueReaders.boolValue(json['requires_repair']),
      requiresUserConfirmation: ValueReaders.boolValue(
        json['requires_user_confirmation'],
      ),
      acceptedConflictIds: ValueReaders.stringList(
        json['accepted_conflict_ids'],
      ),
      rejectedConflictIds: ValueReaders.stringList(
        json['rejected_conflict_ids'],
      ),
      pendingConflictIds: ValueReaders.stringList(json['pending_conflict_ids']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'arbitration_id': arbitrationId,
      'group_key': groupKey,
      'status': status,
      'highest_risk': highestRisk,
      'selected_conflict_id': selectedConflictId,
      'summary': summary,
      'reason': reason,
      'auto_resolved': autoResolved,
      'requires_repair': requiresRepair,
      'requires_user_confirmation': requiresUserConfirmation,
      'accepted_conflict_ids': acceptedConflictIds,
      'rejected_conflict_ids': rejectedConflictIds,
      'pending_conflict_ids': pendingConflictIds,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (status.trim().isEmpty) {
      return result;
    }
    if (arbitrationId.trim().isEmpty) {
      result.add('missing_collaboration_arbitration_id');
    }
    if (!CollaborationArbitrationStatuses.knownValues.contains(status)) {
      result.add('invalid_collaboration_arbitration_status');
    }
    if (summary.trim().isEmpty) {
      result.add('missing_collaboration_arbitration_summary');
    }
    return result;
  }
}
