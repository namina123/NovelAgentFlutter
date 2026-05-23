import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChapterAtomicEventService {
  List<JsonMap> appendEvent(
    List<Object?> eventsValue,
    String eventType,
    String note,
    JsonMap data, {
    String? createdAt,
  }) {
    // 中文注释: 事件历史是恢复执行包时的重要审计线索，这里统一维护其结构。
    final events = List<JsonMap>.from(ValueReaders.mapList(eventsValue));
    events.add(<String, Object?>{
      'type': eventType,
      'note': note,
      'data': ValueReaders.deepCopyMap(data),
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    });
    return events;
  }
}
