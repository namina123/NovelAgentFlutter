import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'writing_execution_result.dart';

class WritingExecutionResultCodecService {
  const WritingExecutionResultCodecService();

  WritingExecutionResult fromJson(JsonMap json) {
    // 中文注释: 单条共享结果 decode 入口集中在这里，方便 repository、probe 和后续 runtime 薄接线复用。
    return WritingExecutionResult.fromJson(json);
  }

  JsonMap toJson(WritingExecutionResult result) {
    // 中文注释: encode 统一透传聚合合同，避免调用点继续手工拼接五段子摘要。
    return result.toJson();
  }

  List<WritingExecutionResult> fromJsonList(Object? rawResults) {
    // 中文注释: 空结果列表同样是合法状态，这里必须稳定返回空集合供宿主后续聚合。
    return ValueReaders.mapList(
      rawResults,
    ).map(WritingExecutionResult.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<WritingExecutionResult> results) {
    // 中文注释: 列表编码保持紧凑数组格式，供 JSON 文档、测试夹具和 probe 产物统一复用。
    return results.map((entry) => entry.toJson()).toList(growable: false);
  }
}
