import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'research_note.dart';

class ResearchNoteCodecService {
  const ResearchNoteCodecService();

  ResearchNote fromJson(JsonMap json) {
    // 中文注释: 单条 research note 的 decode 集中在这里，方便后续 repository、tool result 与测试共用同一入口。
    return ResearchNote.fromJson(json);
  }

  JsonMap toJson(ResearchNote note) {
    // 中文注释: encode 透传模型实现，避免不同调用点各自拼研究笔记壳层字段。
    return note.toJson();
  }

  List<ResearchNote> fromJsonList(Object? rawNotes) {
    // 中文注释: 空研究笔记列表是合法状态，这里必须稳定返回空列表而不是抛异常。
    return ValueReaders.mapList(
      rawNotes,
    ).map(ResearchNote.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<ResearchNote> notes) {
    // 中文注释: 列表编码统一输出紧凑 JSON 数组，供 JSON/JSONL、工具结果与测试共同复用。
    return notes.map((note) => note.toJson()).toList(growable: false);
  }
}
