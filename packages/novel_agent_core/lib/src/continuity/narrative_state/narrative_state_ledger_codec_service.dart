import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_ledger_entry.dart';
import 'narrative_ledger_event.dart';
import 'narrative_state_ledger.dart';

class NarrativeStateLedgerCodecService {
  const NarrativeStateLedgerCodecService();

  NarrativeStateLedger ledgerFromJson(JsonMap json) {
    // 中文注释: 顶层账本 decode 集中在这里，方便后续 repository 与测试共享同一入口。
    return NarrativeStateLedger.fromJson(json);
  }

  JsonMap ledgerToJson(NarrativeStateLedger ledger) {
    // 中文注释: 顶层账本 encode 保持薄包装，避免调用点重复拼装容器字段。
    return ledger.toJson();
  }

  NarrativeLedgerEntry entryFromJson(JsonMap json) {
    // 中文注释: 单条 entry decode 也单独开放，便于未来 JSONL 仓储按行读取。
    return NarrativeLedgerEntry.fromJson(json);
  }

  JsonMap entryToJson(NarrativeLedgerEntry entry) {
    // 中文注释: 单条 entry encode 同样抽离，减少后续工具结果与存储层样板代码。
    return entry.toJson();
  }

  NarrativeLedgerEvent eventFromJson(JsonMap json) {
    // 中文注释: event decode 单独暴露，方便后续事件流和事件窗口合同复用。
    return NarrativeLedgerEvent.fromJson(json);
  }

  JsonMap eventToJson(NarrativeLedgerEvent event) {
    // 中文注释: event encode 统一走这里，保持 JSON 字段名稳定。
    return event.toJson();
  }

  List<NarrativeLedgerEntry> entriesFromJsonList(Object? rawEntries) {
    // 中文注释: 空账本在项目初始阶段是合法状态，这里必须稳定返回空列表。
    return ValueReaders.mapList(
      rawEntries,
    ).map(NarrativeLedgerEntry.fromJson).toList(growable: false);
  }
}
