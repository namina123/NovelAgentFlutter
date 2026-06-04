import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_ledger_entry.dart';
import 'narrative_ledger_event.dart';
import 'narrative_ledger_validation_codes.dart';

const _narrativeStateLedgerCodecService = OpenJsonContractCodecService();
const _narrativeStateLedgerValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeStateLedger {
  const NarrativeStateLedger({
    required this.ledgerId,
    this.entries = const <NarrativeLedgerEntry>[],
    this.events = const <NarrativeLedgerEvent>[],
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String ledgerId;
  final List<NarrativeLedgerEntry> entries;
  final List<NarrativeLedgerEvent> events;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeStateLedger copyWith({
    String? ledgerId,
    List<NarrativeLedgerEntry>? entries,
    List<NarrativeLedgerEvent>? events,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: 顶层账本容器只承接条目和事件聚合，不在这里实现归并或投影逻辑。
    return NarrativeStateLedger(
      ledgerId: ledgerId ?? this.ledgerId,
      entries: entries ?? this.entries,
      events: events ?? this.events,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeStateLedger.fromJson(JsonMap json) {
    // 中文注释: 顶层账本允许独立持久化，也方便后续测试一次性验证不同 source 并存场景。
    return NarrativeStateLedger(
      ledgerId: ValueReaders.stringValue(json['ledger_id']).trim(),
      entries: ValueReaders.mapList(
        json['entries'],
      ).map(NarrativeLedgerEntry.fromJson).toList(growable: false),
      events: ValueReaders.mapList(
        json['events'],
      ).map(NarrativeLedgerEvent.fromJson).toList(growable: false),
      schemaVersion: _narrativeStateLedgerCodecService.readSchemaVersion(json),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 顶层账本编码保持简单 JSON 容器，留给后续 repository 决定 JSON 或 JSONL 落盘方式。
    return <String, Object?>{
      'ledger_id': ledgerId,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'events': events.map((event) => event.toJson()).toList(growable: false),
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 顶层校验只聚合子项结果，不在本轮引入冲突、覆盖或时序策略。
    final result = <String>[];
    result.addAll(
      _narrativeStateLedgerValidatorService.requireNonBlankString(
        ledgerId,
        NarrativeLedgerValidationCodes.missingLedgerId,
      ),
    );
    result.addAll(entries.expand((entry) => entry.validateBasics()));
    result.addAll(events.expand((event) => event.validateBasics()));
    return result;
  }
}
