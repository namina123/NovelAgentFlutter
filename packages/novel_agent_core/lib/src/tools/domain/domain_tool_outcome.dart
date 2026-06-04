import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import '../../runtime/tool_round_evidence.dart';
import 'domain_tool_contract_typedefs.dart';
import 'domain_tool_error.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_validation_codes.dart';

const _domainToolOutcomeCodecService = OpenJsonContractCodecService();
const _domainToolOutcomeValidatorService = OpenJsonStructureValidatorService();

class DomainToolOutcome {
  const DomainToolOutcome({
    required this.outcomeId,
    required this.callId,
    required this.toolName,
    required this.outcomeStatus,
    this.permissionDecision,
    this.error,
    this.outcomePayload = const <String, Object?>{},
    this.toolRoundEvidence,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String outcomeId;
  final DomainToolCallId callId;
  final DomainToolName toolName;
  final String outcomeStatus;
  final DomainToolPermissionDecision? permissionDecision;
  final DomainToolError? error;
  final JsonMap outcomePayload;
  final ToolRoundEvidence? toolRoundEvidence;
  final DomainToolSchemaVersion schemaVersion;
  final JsonMap metadata;

  DomainToolOutcome copyWith({
    String? outcomeId,
    DomainToolCallId? callId,
    DomainToolName? toolName,
    String? outcomeStatus,
    DomainToolPermissionDecision? permissionDecision,
    DomainToolError? error,
    JsonMap? outcomePayload,
    ToolRoundEvidence? toolRoundEvidence,
    DomainToolSchemaVersion? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: outcome 合同统一收口工具结果，让 runtime/supervisor 后续只消费结构化状态而非宿主特例。
    return DomainToolOutcome(
      outcomeId: outcomeId ?? this.outcomeId,
      callId: callId ?? this.callId,
      toolName: toolName ?? this.toolName,
      outcomeStatus: outcomeStatus ?? this.outcomeStatus,
      permissionDecision: permissionDecision ?? this.permissionDecision,
      error: error ?? this.error,
      outcomePayload: outcomePayload ?? this.outcomePayload,
      toolRoundEvidence: toolRoundEvidence ?? this.toolRoundEvidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DomainToolOutcome.fromJson(JsonMap json) {
    return DomainToolOutcome(
      outcomeId: ValueReaders.stringValue(json['outcome_id']).trim(),
      callId: ValueReaders.stringValue(json['call_id']).trim(),
      toolName: ValueReaders.stringValue(json['tool_name']).trim(),
      outcomeStatus: ValueReaders.stringValue(json['outcome_status']).trim(),
      permissionDecision:
          ValueReaders.mapValue(json['permission_decision']).isEmpty
          ? null
          : DomainToolPermissionDecision.fromJson(
              ValueReaders.mapValue(json['permission_decision']),
            ),
      error: ValueReaders.mapValue(json['error']).isEmpty
          ? null
          : DomainToolError.fromJson(ValueReaders.mapValue(json['error'])),
      outcomePayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['outcome_payload']),
      ),
      toolRoundEvidence:
          ValueReaders.mapValue(json['tool_round_evidence']).isEmpty
          ? null
          : ToolRoundEvidence.fromJson(
              ValueReaders.mapValue(json['tool_round_evidence']),
            ),
      schemaVersion: _domainToolOutcomeCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'outcome_id': outcomeId,
      'call_id': callId,
      'tool_name': toolName,
      'outcome_status': outcomeStatus,
      'permission_decision': permissionDecision?.toJson(),
      'error': error?.toJson(),
      'outcome_payload': ValueReaders.deepCopyMap(outcomePayload),
      'tool_round_evidence': toolRoundEvidence?.toJson(),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _domainToolOutcomeValidatorService.requireNonBlankString(
        outcomeId,
        DomainToolValidationCodes.missingOutcomeId,
      ),
    );
    result.addAll(
      _domainToolOutcomeValidatorService.requireNonBlankString(
        callId,
        DomainToolValidationCodes.missingCallId,
      ),
    );
    result.addAll(
      _domainToolOutcomeValidatorService.requireNonBlankString(
        toolName,
        DomainToolValidationCodes.missingToolName,
      ),
    );
    result.addAll(
      _domainToolOutcomeValidatorService.requireNonBlankString(
        outcomeStatus,
        DomainToolValidationCodes.missingOutcomeStatus,
      ),
    );
    result.addAll(
      _domainToolOutcomeValidatorService.requireCondition(
        outcomeStatus != DomainToolOutcomeStatuses.needsUserConfirmation ||
            permissionDecision != null,
        DomainToolValidationCodes.missingPermissionDecisionForWaitingStatus,
      ),
    );
    result.addAll(
      _domainToolOutcomeValidatorService.requireCondition(
        !<String>{
              DomainToolOutcomeStatuses.invalidPayload,
              DomainToolOutcomeStatuses.executionFailed,
            }.contains(outcomeStatus) ||
            error != null,
        DomainToolValidationCodes.missingErrorForFailureStatus,
      ),
    );
    if (permissionDecision != null) {
      result.addAll(permissionDecision!.validateBasics());
    }
    if (error != null) {
      result.addAll(error!.validateBasics());
    }
    return result;
  }
}
