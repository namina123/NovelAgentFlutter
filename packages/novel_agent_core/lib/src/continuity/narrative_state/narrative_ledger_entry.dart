import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_claim_disposition.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ledger_event.dart';
import 'narrative_ledger_validation_codes.dart';
import 'narrative_source_ref.dart';
import 'narrative_state_claim.dart';

const _narrativeLedgerEntryCodecService = OpenJsonContractCodecService();
const _narrativeLedgerEntryValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeLedgerEntry {
  const NarrativeLedgerEntry({
    required this.entryId,
    required this.claim,
    required this.disposition,
    required this.source,
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.supersedesEntryIds = const <String>[],
    this.replacementEntryIds = const <String>[],
    this.events = const <NarrativeLedgerEvent>[],
    this.recordedAt = '',
    this.note = '',
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String entryId;
  final NarrativeStateClaim claim;
  final NarrativeClaimDisposition disposition;
  final NarrativeSourceRef source;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final List<String> supersedesEntryIds;
  final List<String> replacementEntryIds;
  final List<NarrativeLedgerEvent> events;
  final String recordedAt;
  final String note;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeLedgerEntry copyWith({
    String? entryId,
    NarrativeStateClaim? claim,
    NarrativeClaimDisposition? disposition,
    NarrativeSourceRef? source,
    List<NarrativeEvidenceRef>? evidenceRefs,
    List<String>? supersedesEntryIds,
    List<String>? replacementEntryIds,
    List<NarrativeLedgerEvent>? events,
    String? recordedAt,
    String? note,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: ledger entry 用于承接 claim 的账本状态和审计关联，不在这里做冲突归并。
    return NarrativeLedgerEntry(
      entryId: entryId ?? this.entryId,
      claim: claim ?? this.claim,
      disposition: disposition ?? this.disposition,
      source: source ?? this.source,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      supersedesEntryIds: supersedesEntryIds ?? this.supersedesEntryIds,
      replacementEntryIds: replacementEntryIds ?? this.replacementEntryIds,
      events: events ?? this.events,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeLedgerEntry.fromJson(JsonMap json) {
    // 中文注释: 条目里同时保留 claim 快照和账本 source，避免不同来源的同一事实在审计时被覆盖。
    return NarrativeLedgerEntry(
      entryId: ValueReaders.stringValue(json['entry_id']).trim(),
      claim: NarrativeStateClaim.fromJson(ValueReaders.mapValue(json['claim'])),
      disposition: NarrativeClaimDisposition.fromId(
        ValueReaders.stringValue(json['disposition']),
      ),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      supersedesEntryIds: ValueReaders.stringList(json['supersedes_entry_ids']),
      replacementEntryIds: ValueReaders.stringList(
        json['replacement_entry_ids'],
      ),
      events: ValueReaders.mapList(
        json['events'],
      ).map(NarrativeLedgerEvent.fromJson).toList(growable: false),
      recordedAt: ValueReaders.stringValue(json['recorded_at']).trim(),
      note: ValueReaders.stringValue(json['note']).trim(),
      schemaVersion: _narrativeLedgerEntryCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 条目输出时显式保留 supersedes/replacement 引用，供后续 reducer 和投影层接管解释。
    return <String, Object?>{
      'entry_id': entryId,
      'claim': claim.toJson(),
      'disposition': disposition.id,
      'source': source.toJson(),
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'supersedes_entry_ids': supersedesEntryIds,
      'replacement_entry_ids': replacementEntryIds,
      'events': events.map((event) => event.toJson()).toList(growable: false),
      'recorded_at': recordedAt,
      'note': note,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 本轮只做最小结构校验，保证 entry/source/claim 都具备基础身份字段。
    final result = <String>[];
    result.addAll(
      _narrativeLedgerEntryValidatorService.requireNonBlankString(
        entryId,
        NarrativeLedgerValidationCodes.missingEntryId,
      ),
    );
    result.addAll(
      _narrativeLedgerEntryValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeLedgerValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeLedgerEntryValidatorService.requireNonBlankString(
        claim.claimId,
        NarrativeLedgerValidationCodes.missingClaimId,
      ),
    );
    result.addAll(events.expand((event) => event.validateBasics()));
    return result;
  }
}
