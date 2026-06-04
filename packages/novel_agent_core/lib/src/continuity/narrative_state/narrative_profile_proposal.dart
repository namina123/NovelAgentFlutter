import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_profile_lifecycle_status.dart';
import 'narrative_profile_patch.dart';
import 'narrative_source_ref.dart';
import 'narrative_profile_validation_codes.dart';

const _narrativeProfileProposalCodecService = OpenJsonContractCodecService();
const _narrativeProfileProposalValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeProfileProposal {
  const NarrativeProfileProposal({
    required this.proposalId,
    required this.proposalStatus,
    required this.profilePatch,
    required this.source,
    this.targetProfileId = '',
    this.baseProfileId = '',
    this.requiresUserConfirmation = false,
    this.reason = '',
    this.confidence = 0,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String proposalId;
  final NarrativeProfileLifecycleStatus proposalStatus;
  final NarrativeProfilePatch profilePatch;
  final NarrativeSourceRef source;
  final String targetProfileId;
  final String baseProfileId;
  final bool requiresUserConfirmation;
  final String reason;
  final double confidence;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeProfileProposal copyWith({
    String? proposalId,
    NarrativeProfileLifecycleStatus? proposalStatus,
    NarrativeProfilePatch? profilePatch,
    NarrativeSourceRef? source,
    String? targetProfileId,
    String? baseProfileId,
    bool? requiresUserConfirmation,
    String? reason,
    double? confidence,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 提案合同只描述“建议如何改”，不直接承担应用或流转逻辑。
    return NarrativeProfileProposal(
      proposalId: proposalId ?? this.proposalId,
      proposalStatus: proposalStatus ?? this.proposalStatus,
      profilePatch: profilePatch ?? this.profilePatch,
      source: source ?? this.source,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      baseProfileId: baseProfileId ?? this.baseProfileId,
      requiresUserConfirmation:
          requiresUserConfirmation ?? this.requiresUserConfirmation,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeProfileProposal.fromJson(JsonMap json) {
    // 中文注释: 提案状态保留单独字段，用于表达“草稿/提议/驳回”等提案阶段，而不是直接覆盖长期规则。
    return NarrativeProfileProposal(
      proposalId: ValueReaders.stringValue(json['proposal_id']).trim(),
      proposalStatus: NarrativeProfileLifecycleStatus.fromId(
        ValueReaders.stringValue(json['proposal_status']),
      ),
      profilePatch: NarrativeProfilePatch.fromJson(
        ValueReaders.mapValue(json['profile_patch']),
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      targetProfileId: ValueReaders.stringValue(
        json['target_profile_id'],
      ).trim(),
      baseProfileId: ValueReaders.stringValue(json['base_profile_id']).trim(),
      requiresUserConfirmation: ValueReaders.boolValue(
        json['requires_user_confirmation'],
      ),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      schemaVersion: _narrativeProfileProposalCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 提案输出不包含“立即生效”一类隐式动作字段，避免 accepted 规则被绕过。
    return <String, Object?>{
      'proposal_id': proposalId,
      'proposal_status': proposalStatus.id,
      'profile_patch': profilePatch.toJson(),
      'source': source.toJson(),
      'target_profile_id': targetProfileId,
      'base_profile_id': baseProfileId,
      'requires_user_confirmation': requiresUserConfirmation,
      'reason': reason,
      'confidence': confidence,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里显式禁止 proposal 伪装成 accepted/active 的直接覆盖动作，把收口权留给后续 reducer 和权限策略。
    final result = <String>[];
    result.addAll(
      _narrativeProfileProposalValidatorService.requireNonBlankString(
        proposalId,
        NarrativeProfileValidationCodes.missingProposalId,
      ),
    );
    result.addAll(
      _narrativeProfileProposalValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeProfileValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeProfileProposalValidatorService.validateConfidence(
        confidence,
        NarrativeProfileValidationCodes.invalidConfidence,
      ),
    );
    result.addAll(profilePatch.validateBasics());
    if (proposalStatus == NarrativeProfileLifecycleStatus.accepted ||
        proposalStatus == NarrativeProfileLifecycleStatus.active) {
      result.add(
        NarrativeProfileValidationCodes.invalidProposalStatusForDirectApply,
      );
    }
    return result;
  }
}
