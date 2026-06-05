import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_validation_codes.dart';

const _informationLifecycleStatusCodecService = OpenJsonContractCodecService();
const _informationLifecycleStatusValidatorService =
    OpenJsonStructureValidatorService();
const _informationLifecycleStatusKnownFields = <String>{
  'subject_ref',
  'lifecycle_status',
  'last_event_id',
  'related_link_ids',
  'superseded_by_ref',
  'schema_version',
  'metadata',
};

class InformationLifecycleStatus {
  const InformationLifecycleStatus({
    required this.subjectRef,
    required this.lifecycleStatus,
    this.lastEventId = '',
    this.relatedLinkIds = const <String>[],
    this.supersededByRef,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final NarrativeRef subjectRef;
  final String lifecycleStatus;
  final String lastEventId;
  final List<String> relatedLinkIds;
  final NarrativeRef? supersededByRef;
  final String schemaVersion;
  final JsonMap metadata;

  InformationLifecycleStatus copyWith({
    NarrativeRef? subjectRef,
    String? lifecycleStatus,
    String? lastEventId,
    List<String>? relatedLinkIds,
    NarrativeRef? supersededByRef,
    bool clearSupersededByRef = false,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 生命周期状态由 reducer 纯粹推进，这里只负责稳定 copy，不引入语义或权限判断。
    return InformationLifecycleStatus(
      subjectRef: subjectRef ?? this.subjectRef,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      lastEventId: lastEventId ?? this.lastEventId,
      relatedLinkIds: relatedLinkIds ?? this.relatedLinkIds,
      supersededByRef: clearSupersededByRef
          ? null
          : supersededByRef ?? this.supersededByRef,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationLifecycleStatus.fromJson(JsonMap json) {
    final supersededByRefJson = ValueReaders.mapValue(
      json['superseded_by_ref'],
    );
    return InformationLifecycleStatus(
      subjectRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['subject_ref']),
      ),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      lastEventId: ValueReaders.stringValue(json['last_event_id']).trim(),
      relatedLinkIds: ValueReaders.stringList(json['related_link_ids']),
      supersededByRef: supersededByRefJson.isEmpty
          ? null
          : NarrativeRef.fromJson(supersededByRefJson),
      schemaVersion: _informationLifecycleStatusCodecService.readSchemaVersion(
        json,
      ),
      metadata: _informationLifecycleStatusCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _informationLifecycleStatusKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _informationLifecycleStatusCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'subject_ref': subjectRef.toJson(),
          'lifecycle_status': lifecycleStatus,
          'last_event_id': lastEventId,
          'related_link_ids': relatedLinkIds,
          'superseded_by_ref': supersededByRef?.toJson(),
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationLifecycleStatusValidatorService.requireCondition(
        subjectRef.refType.trim().isNotEmpty &&
            subjectRef.refId.trim().isNotEmpty,
        InformationValidationCodes.missingInformationLifecycleSubjectRef,
      ),
    );
    result.addAll(
      _informationLifecycleStatusValidatorService.requireNonBlankString(
        lifecycleStatus,
        InformationValidationCodes.missingInformationLifecycleStatus,
      ),
    );
    return result;
  }
}
