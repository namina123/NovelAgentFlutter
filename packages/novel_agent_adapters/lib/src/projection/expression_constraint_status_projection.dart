import 'package:novel_agent_core/novel_agent_core.dart';

class ExpressionConstraintStatusProjection {
  const ExpressionConstraintStatusProjection({
    this.present = false,
    this.status = '',
    this.statusLabel = '',
    this.summary = '',
    this.policyMode = '',
    this.active = false,
    this.applied = false,
    this.suggestStrengthen = false,
    this.blocksRepair = false,
    this.disabled = false,
    this.reviewRequired = false,
    this.reviewProvided = false,
    this.evidenceMissing = false,
    this.runtimeEscalated = false,
    this.technicalTurnExcluded = false,
    this.appliedReasons = const <String>[],
    this.skippedReasons = const <String>[],
  });

  final bool present;
  final String status;
  final String statusLabel;
  final String summary;
  final String policyMode;
  final bool active;
  final bool applied;
  final bool suggestStrengthen;
  final bool blocksRepair;
  final bool disabled;
  final bool reviewRequired;
  final bool reviewProvided;
  final bool evidenceMissing;
  final bool runtimeEscalated;
  final bool technicalTurnExcluded;
  final List<String> appliedReasons;
  final List<String> skippedReasons;

  factory ExpressionConstraintStatusProjection.fromJson(JsonMap json) {
    return ExpressionConstraintStatusProjection(
      present: ValueReaders.boolValue(json['present']),
      status: ValueReaders.stringValue(json['status']).trim(),
      statusLabel: ValueReaders.stringValue(json['status_label']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      policyMode: ValueReaders.stringValue(json['policy_mode']).trim(),
      active: ValueReaders.boolValue(json['active']),
      applied: ValueReaders.boolValue(json['applied']),
      suggestStrengthen: ValueReaders.boolValue(json['suggest_strengthen']),
      blocksRepair: ValueReaders.boolValue(json['blocks_repair']),
      disabled: ValueReaders.boolValue(json['disabled']),
      reviewRequired: ValueReaders.boolValue(json['review_required']),
      reviewProvided: ValueReaders.boolValue(json['review_provided']),
      evidenceMissing: ValueReaders.boolValue(json['evidence_missing']),
      runtimeEscalated: ValueReaders.boolValue(json['runtime_escalated']),
      technicalTurnExcluded: ValueReaders.boolValue(
        json['technical_turn_excluded'],
      ),
      appliedReasons: ValueReaders.stringList(json['applied_reasons']),
      skippedReasons: ValueReaders.stringList(json['skipped_reasons']),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'present': present,
      'status': status,
      'status_label': statusLabel,
      'summary': summary,
      'policy_mode': policyMode,
      'active': active,
      'applied': applied,
      'suggest_strengthen': suggestStrengthen,
      'blocks_repair': blocksRepair,
      'disabled': disabled,
      'review_required': reviewRequired,
      'review_provided': reviewProvided,
      'evidence_missing': evidenceMissing,
      'runtime_escalated': runtimeEscalated,
      'technical_turn_excluded': technicalTurnExcluded,
      'applied_reasons': ValueReaders.deepCopyList(
        appliedReasons.cast<Object?>(),
      ),
      'skipped_reasons': ValueReaders.deepCopyList(
        skippedReasons.cast<Object?>(),
      ),
    };
  }
}
