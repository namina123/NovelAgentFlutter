import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_claim_disposition.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ledger_validation_codes.dart';
import 'narrative_source_ref.dart';

const _narrativeLedgerEventCodecService = OpenJsonContractCodecService();
const _narrativeLedgerEventValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeLedgerEvent {
  const NarrativeLedgerEvent({
    required this.eventId,
    required this.eventType,
    required this.disposition,
    required this.source,
    this.entryId = '',
    this.relatedEntryIds = const <String>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.summary = '',
    this.occurredAt = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String eventId;
  final String eventType;
  final NarrativeClaimDisposition disposition;
  final NarrativeSourceRef source;
  final String entryId;
  final List<String> relatedEntryIds;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final String summary;
  final String occurredAt;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeLedgerEvent copyWith({
    String? eventId,
    String? eventType,
    NarrativeClaimDisposition? disposition,
    NarrativeSourceRef? source,
    String? entryId,
    List<String>? relatedEntryIds,
    List<NarrativeEvidenceRef>? evidenceRefs,
    String? summary,
    String? occurredAt,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 账本事件只承接审计事实，不承担状态流转算法，因此只提供轻量 copyWith。
    return NarrativeLedgerEvent(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      disposition: disposition ?? this.disposition,
      source: source ?? this.source,
      entryId: entryId ?? this.entryId,
      relatedEntryIds: relatedEntryIds ?? this.relatedEntryIds,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      summary: summary ?? this.summary,
      occurredAt: occurredAt ?? this.occurredAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeLedgerEvent.fromJson(JsonMap json) {
    // 中文注释: eventType 保持开放字符串，避免把未来账本事件过早锁成固定少量内置类别。
    return NarrativeLedgerEvent(
      eventId: ValueReaders.stringValue(json['event_id']).trim(),
      eventType: ValueReaders.stringValue(json['event_type']).trim(),
      disposition: NarrativeClaimDisposition.fromId(
        ValueReaders.stringValue(json['disposition']),
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      entryId: ValueReaders.stringValue(json['entry_id']).trim(),
      relatedEntryIds: ValueReaders.stringList(json['related_entry_ids']),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      occurredAt: ValueReaders.stringValue(json['occurred_at']).trim(),
      schemaVersion: _narrativeLedgerEventCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 事件输出独立于条目，便于未来 JSONL 审计流或事件窗口直接复用。
    return <String, Object?>{
      'event_id': eventId,
      'event_type': eventType,
      'disposition': disposition.id,
      'source': source.toJson(),
      'entry_id': entryId,
      'related_entry_ids': relatedEntryIds,
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'summary': summary,
      'occurred_at': occurredAt,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 本轮只做最小身份与来源校验，不引入事件时序或流转合法性检查。
    final result = <String>[];
    result.addAll(
      _narrativeLedgerEventValidatorService.requireNonBlankString(
        eventId,
        NarrativeLedgerValidationCodes.missingEventId,
      ),
    );
    result.addAll(
      _narrativeLedgerEventValidatorService.requireNonBlankString(
        eventType,
        NarrativeLedgerValidationCodes.missingEventType,
      ),
    );
    result.addAll(
      _narrativeLedgerEventValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeLedgerValidationCodes.missingSourceType,
      ),
    );
    return result;
  }
}
