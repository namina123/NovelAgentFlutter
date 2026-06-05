import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'reference_work_record.dart';

class ReferenceWorkRecordCodecService {
  const ReferenceWorkRecordCodecService();

  ReferenceWorkRecord fromJson(JsonMap json) {
    // 中文注释: 单条 reference work 的 decode 集中在这里，方便后续 repository、tool result 与测试共用同一入口。
    return ReferenceWorkRecord.fromJson(json);
  }

  JsonMap toJson(ReferenceWorkRecord record) {
    // 中文注释: encode 透传模型实现，避免不同调用点各自拼引用作品边界壳层字段。
    return record.toJson();
  }

  List<ReferenceWorkRecord> fromJsonList(Object? rawRecords) {
    // 中文注释: 空引用作品列表是合法状态，这里必须稳定返回空列表而不是抛异常。
    return ValueReaders.mapList(
      rawRecords,
    ).map(ReferenceWorkRecord.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<ReferenceWorkRecord> records) {
    // 中文注释: 列表编码统一输出紧凑 JSON 数组，供 JSON/JSONL、工具结果与测试共同复用。
    return records.map((record) => record.toJson()).toList(growable: false);
  }
}
