import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import 'information_validation_codes.dart';

const _informationSourceRefCodecService = OpenJsonContractCodecService();
const _informationSourceRefValidatorService =
    OpenJsonStructureValidatorService();

class InformationSourceRef {
  const InformationSourceRef({
    required this.sourceRef,
    this.sourceAuthority = '',
    this.roleAuthority = '',
    this.researchDepth = '',
    this.metadata = const <String, Object?>{},
  });

  final NarrativeSourceRef sourceRef;
  final String sourceAuthority;
  final String roleAuthority;
  final String researchDepth;
  final JsonMap metadata;

  InformationSourceRef copyWith({
    NarrativeSourceRef? sourceRef,
    String? sourceAuthority,
    String? roleAuthority,
    String? researchDepth,
    JsonMap? metadata,
  }) {
    // 中文注释: 信息来源合同只承载来源姿态与研究深度，不负责权限执行或证据裁决。
    return InformationSourceRef(
      sourceRef: sourceRef ?? this.sourceRef,
      sourceAuthority: sourceAuthority ?? this.sourceAuthority,
      roleAuthority: roleAuthority ?? this.roleAuthority,
      researchDepth: researchDepth ?? this.researchDepth,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationSourceRef.fromJson(JsonMap json) {
    final sourceRefJson = ValueReaders.mapValue(json['source_ref']).isNotEmpty
        ? ValueReaders.mapValue(json['source_ref'])
        : json;
    return InformationSourceRef(
      sourceRef: NarrativeSourceRef.fromJson(sourceRefJson),
      sourceAuthority: ValueReaders.stringValue(
        json['source_authority'],
      ).trim(),
      roleAuthority: ValueReaders.stringValue(json['role_authority']).trim(),
      researchDepth: ValueReaders.stringValue(json['research_depth']).trim(),
      metadata: _informationSourceRefCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: const <String>{
          'source_ref',
          'source_authority',
          'role_authority',
          'research_depth',
          'metadata',
        },
      ),
    );
  }

  JsonMap toJson() {
    return _informationSourceRefCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'source_ref': sourceRef.toJson(),
          'source_authority': sourceAuthority,
          'role_authority': roleAuthority,
          'research_depth': researchDepth,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationSourceRefValidatorService.requireNonBlankString(
        sourceRef.sourceType,
        InformationValidationCodes.missingInformationSourceType,
      ),
    );
    result.addAll(
      _informationSourceRefValidatorService.requireNonBlankString(
        sourceAuthority,
        InformationValidationCodes.missingInformationSourceAuthority,
      ),
    );
    result.addAll(
      _informationSourceRefValidatorService.requireNonBlankString(
        roleAuthority,
        InformationValidationCodes.missingInformationRoleAuthority,
      ),
    );
    result.addAll(
      _informationSourceRefValidatorService.requireNonBlankString(
        researchDepth,
        InformationValidationCodes.missingInformationResearchDepth,
      ),
    );
    return result;
  }
}
