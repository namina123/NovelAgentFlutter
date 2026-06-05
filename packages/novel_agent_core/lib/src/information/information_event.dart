import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_ref.dart';
import 'information_validation_codes.dart';

const _informationEventCodecService = OpenJsonContractCodecService();
const _informationEventValidatorService = OpenJsonStructureValidatorService();
const _informationEventKnownFields = <String>{
  'event_id',
  'event_type',
  'subject_ref',
  'lifecycle_status',
  'actor_ref',
  'related_refs',
  'related_link_ids',
  'summary',
  'occurred_at',
  'schema_version',
  'metadata',
};

class InformationEvent {
  const InformationEvent({
    required this.eventId,
    required this.eventType,
    required this.subjectRef,
    required this.lifecycleStatus,
    required this.actorRef,
    this.relatedRefs = const <NarrativeRef>[],
    this.relatedLinkIds = const <String>[],
    this.summary = '',
    this.occurredAt = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String eventId;
  final String eventType;
  final NarrativeRef subjectRef;
  final String lifecycleStatus;
  final NarrativeRef actorRef;
  final List<NarrativeRef> relatedRefs;
  final List<String> relatedLinkIds;
  final String summary;
  final String occurredAt;
  final String schemaVersion;
  final JsonMap metadata;

  InformationEvent copyWith({
    String? eventId,
    String? eventType,
    NarrativeRef? subjectRef,
    String? lifecycleStatus,
    NarrativeRef? actorRef,
    List<NarrativeRef>? relatedRefs,
    List<String>? relatedLinkIds,
    String? summary,
    String? occurredAt,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 生命周期事件会在 reducer 和审计层反复传递，这里提供统一 copy 入口，避免散落字典浅拷贝。
    return InformationEvent(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      subjectRef: subjectRef ?? this.subjectRef,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      actorRef: actorRef ?? this.actorRef,
      relatedRefs: relatedRefs ?? this.relatedRefs,
      relatedLinkIds: relatedLinkIds ?? this.relatedLinkIds,
      summary: summary ?? this.summary,
      occurredAt: occurredAt ?? this.occurredAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationEvent.fromJson(JsonMap json) {
    return InformationEvent(
      eventId: ValueReaders.stringValue(json['event_id']).trim(),
      eventType: ValueReaders.stringValue(json['event_type']).trim(),
      subjectRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['subject_ref']),
      ),
      lifecycleStatus: ValueReaders.stringValue(
        json['lifecycle_status'],
      ).trim(),
      actorRef: NarrativeRef.fromJson(ValueReaders.mapValue(json['actor_ref'])),
      relatedRefs: ValueReaders.mapList(
        json['related_refs'],
      ).map(NarrativeRef.fromJson).toList(growable: false),
      relatedLinkIds: ValueReaders.stringList(json['related_link_ids']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      occurredAt: ValueReaders.stringValue(json['occurred_at']).trim(),
      schemaVersion: _informationEventCodecService.readSchemaVersion(json),
      metadata: _informationEventCodecService.readMetadataWithUnknownFields(
        json,
        knownFields: _informationEventKnownFields,
      ),
    );
  }

  JsonMap toJson() {
    return _informationEventCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'event_id': eventId,
          'event_type': eventType,
          'subject_ref': subjectRef.toJson(),
          'lifecycle_status': lifecycleStatus,
          'actor_ref': actorRef.toJson(),
          'related_refs': relatedRefs
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'related_link_ids': relatedLinkIds,
          'summary': summary,
          'occurred_at': occurredAt,
          'schema_version': schemaVersion,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationEventValidatorService.requireNonBlankString(
        eventId,
        InformationValidationCodes.missingInformationEventId,
      ),
    );
    result.addAll(
      _informationEventValidatorService.requireNonBlankString(
        eventType,
        InformationValidationCodes.missingInformationEventType,
      ),
    );
    result.addAll(
      _informationEventValidatorService.requireCondition(
        subjectRef.refType.trim().isNotEmpty &&
            subjectRef.refId.trim().isNotEmpty,
        InformationValidationCodes.missingInformationEventSubjectRef,
      ),
    );
    result.addAll(
      _informationEventValidatorService.requireNonBlankString(
        lifecycleStatus,
        InformationValidationCodes.missingInformationEventLifecycleStatus,
      ),
    );
    result.addAll(
      _informationEventValidatorService.requireCondition(
        actorRef.refType.trim().isNotEmpty && actorRef.refId.trim().isNotEmpty,
        InformationValidationCodes.missingInformationEventActorRef,
      ),
    );
    return result;
  }
}
