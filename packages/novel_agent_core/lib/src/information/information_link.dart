import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_validation_codes.dart';

const _informationLinkCodecService = OpenJsonContractCodecService();
const _informationLinkValidatorService = OpenJsonStructureValidatorService();
const _informationLinkKnownFields = <String>{
  'link_id',
  'link_type',
  'source_ref',
  'target_ref',
  'summary',
  'created_by',
  'schema_version',
  'metadata',
};

class InformationLink {
  const InformationLink({
    required this.linkId,
    required this.linkType,
    required this.sourceRef,
    required this.targetRef,
    this.summary = '',
    this.createdBy = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String linkId;
  final String linkType;
  final NarrativeRef sourceRef;
  final NarrativeRef targetRef;
  final String summary;
  final String createdBy;
  final String schemaVersion;
  final JsonMap metadata;

  InformationLink copyWith({
    String? linkId,
    String? linkType,
    NarrativeRef? sourceRef,
    NarrativeRef? targetRef,
    String? summary,
    String? createdBy,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 信息链路会在后续投影、持久化和审计阶段被局部修补，这里统一提供稳定 copy 入口。
    return InformationLink(
      linkId: linkId ?? this.linkId,
      linkType: linkType ?? this.linkType,
      sourceRef: sourceRef ?? this.sourceRef,
      targetRef: targetRef ?? this.targetRef,
      summary: summary ?? this.summary,
      createdBy: createdBy ?? this.createdBy,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationLink.fromJson(JsonMap json) {
    return InformationLink(
      linkId: ValueReaders.stringValue(json['link_id']).trim(),
      linkType: ValueReaders.stringValue(json['link_type']).trim(),
      sourceRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['source_ref']),
      ),
      targetRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['target_ref']),
      ),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      createdBy: ValueReaders.stringValue(json['created_by']).trim(),
      schemaVersion: _informationLinkCodecService.readSchemaVersion(json),
      metadata: _informationLinkCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _informationLinkKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _informationLinkCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'link_id': linkId,
          'link_type': linkType,
          'source_ref': sourceRef.toJson(),
          'target_ref': targetRef.toJson(),
          'summary': summary,
          'created_by': createdBy,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationLinkValidatorService.requireNonBlankString(
        linkId,
        InformationValidationCodes.missingInformationLinkId,
      ),
    );
    result.addAll(
      _informationLinkValidatorService.requireNonBlankString(
        linkType,
        InformationValidationCodes.missingInformationLinkType,
      ),
    );
    result.addAll(
      _informationLinkValidatorService.requireCondition(
        sourceRef.refType.trim().isNotEmpty &&
            sourceRef.refId.trim().isNotEmpty,
        InformationValidationCodes.missingInformationLinkSourceRef,
      ),
    );
    result.addAll(
      _informationLinkValidatorService.requireCondition(
        targetRef.refType.trim().isNotEmpty &&
            targetRef.refId.trim().isNotEmpty,
        InformationValidationCodes.missingInformationLinkTargetRef,
      ),
    );
    return result;
  }
}
