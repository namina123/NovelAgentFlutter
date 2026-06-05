import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'ecosystem_asset_kind.dart';
import 'ecosystem_asset_lifecycle_status.dart';
import 'ecosystem_asset_source_kind.dart';

const _ecosystemAssetProposalCodecService = OpenJsonContractCodecService();
const _ecosystemAssetProposalValidatorService =
    OpenJsonStructureValidatorService();

class EcosystemAssetProposal {
  const EcosystemAssetProposal({
    required this.proposalId,
    required this.assetKind,
    required this.assetId,
    required this.proposalStatus,
    required this.sourceKind,
    required this.version,
    required this.summary,
    required this.riskNote,
    required this.assetPayload,
    this.requiredCapabilities = const <String>[],
    this.requiresUserConfirmation = true,
    this.validationErrors = const <String>[],
    this.validationWarnings = const <String>[],
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String proposalId;
  final EcosystemAssetKind assetKind;
  final String assetId;
  final EcosystemAssetLifecycleStatus proposalStatus;
  final EcosystemAssetSourceKind sourceKind;
  final String version;
  final String summary;
  final String riskNote;
  final List<String> requiredCapabilities;
  final bool requiresUserConfirmation;
  final JsonMap assetPayload;
  final List<String> validationErrors;
  final List<String> validationWarnings;
  final String schemaVersion;
  final JsonMap metadata;

  EcosystemAssetProposal copyWith({
    String? proposalId,
    EcosystemAssetKind? assetKind,
    String? assetId,
    EcosystemAssetLifecycleStatus? proposalStatus,
    EcosystemAssetSourceKind? sourceKind,
    String? version,
    String? summary,
    String? riskNote,
    List<String>? requiredCapabilities,
    bool? requiresUserConfirmation,
    JsonMap? assetPayload,
    List<String>? validationErrors,
    List<String>? validationWarnings,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    return EcosystemAssetProposal(
      proposalId: proposalId ?? this.proposalId,
      assetKind: assetKind ?? this.assetKind,
      assetId: assetId ?? this.assetId,
      proposalStatus: proposalStatus ?? this.proposalStatus,
      sourceKind: sourceKind ?? this.sourceKind,
      version: version ?? this.version,
      summary: summary ?? this.summary,
      riskNote: riskNote ?? this.riskNote,
      requiredCapabilities: requiredCapabilities ?? this.requiredCapabilities,
      requiresUserConfirmation:
          requiresUserConfirmation ?? this.requiresUserConfirmation,
      assetPayload: assetPayload ?? this.assetPayload,
      validationErrors: validationErrors ?? this.validationErrors,
      validationWarnings: validationWarnings ?? this.validationWarnings,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory EcosystemAssetProposal.fromJson(JsonMap json) {
    return EcosystemAssetProposal(
      proposalId: ValueReaders.stringValue(json['proposal_id']).trim(),
      assetKind: EcosystemAssetKind.fromId(
        ValueReaders.stringValue(json['asset_kind']),
      ),
      assetId: ValueReaders.stringValue(json['asset_id']).trim(),
      proposalStatus: EcosystemAssetLifecycleStatus.fromId(
        ValueReaders.stringValue(json['proposal_status']),
      ),
      sourceKind: EcosystemAssetSourceKind.fromId(
        ValueReaders.stringValue(json['source_kind']),
      ),
      version: ValueReaders.stringValue(json['version']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      riskNote: ValueReaders.stringValue(json['risk_note']).trim(),
      requiredCapabilities: ValueReaders.stringList(
        json['required_capabilities'],
      ),
      requiresUserConfirmation: ValueReaders.boolValue(
        json['requires_user_confirmation'],
        true,
      ),
      assetPayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['asset_payload']),
      ),
      validationErrors: ValueReaders.stringList(json['validation_errors']),
      validationWarnings: ValueReaders.stringList(json['validation_warnings']),
      schemaVersion: _ecosystemAssetProposalCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'proposal_id': proposalId,
      'asset_kind': assetKind.id,
      'asset_id': assetId,
      'proposal_status': proposalStatus.id,
      'source_kind': sourceKind.id,
      'version': version,
      'summary': summary,
      'risk_note': riskNote,
      'required_capabilities': List<String>.from(requiredCapabilities),
      'requires_user_confirmation': requiresUserConfirmation,
      'asset_payload': ValueReaders.deepCopyMap(assetPayload),
      'validation_errors': List<String>.from(validationErrors),
      'validation_warnings': List<String>.from(validationWarnings),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final errors = <String>[];
    errors.addAll(
      _ecosystemAssetProposalValidatorService.requireNonBlankString(
        proposalId,
        'missing_ecosystem_asset_proposal_id',
      ),
    );
    errors.addAll(
      _ecosystemAssetProposalValidatorService.requireNonBlankString(
        assetId,
        'missing_ecosystem_asset_id',
      ),
    );
    errors.addAll(
      _ecosystemAssetProposalValidatorService.requireNonBlankString(
        version,
        'missing_ecosystem_asset_version',
      ),
    );
    errors.addAll(
      _ecosystemAssetProposalValidatorService.requireNonBlankString(
        summary,
        'missing_ecosystem_asset_summary',
      ),
    );
    errors.addAll(
      _ecosystemAssetProposalValidatorService.requireNonBlankString(
        riskNote,
        'missing_ecosystem_asset_risk_note',
      ),
    );
    if (assetPayload.isEmpty) {
      errors.add('missing_ecosystem_asset_payload');
    }
    if (sourceKind != EcosystemAssetSourceKind.nonBuiltin) {
      errors.add('invalid_ecosystem_asset_source_kind');
    }
    return errors;
  }
}
