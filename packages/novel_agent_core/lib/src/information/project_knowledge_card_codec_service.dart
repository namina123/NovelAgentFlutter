import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_knowledge_card.dart';

class ProjectKnowledgeCardCodecService {
  const ProjectKnowledgeCardCodecService();

  ProjectKnowledgeCard fromJson(JsonMap json) {
    // 中文注释: 单条知识卡 decode 集中在这里，方便后续 repository、tool result 和测试复用同一入口。
    return ProjectKnowledgeCard.fromJson(json);
  }

  JsonMap toJson(ProjectKnowledgeCard card) {
    // 中文注释: encode 透传模型实现，避免不同调用点各自拼壳层字段。
    return card.toJson();
  }

  List<ProjectKnowledgeCard> fromJsonList(Object? rawCards) {
    // 中文注释: 空知识卡列表是合法状态，这里必须稳定返回空列表而不是抛异常。
    return ValueReaders.mapList(
      rawCards,
    ).map(ProjectKnowledgeCard.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<ProjectKnowledgeCard> cards) {
    // 中文注释: 列表编码统一输出紧凑 JSON 数组，供 JSON/JSONL、工具结果与测试共同复用。
    return cards.map((card) => card.toJson()).toList(growable: false);
  }
}
