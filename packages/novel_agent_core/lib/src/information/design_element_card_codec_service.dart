import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'design_element_card.dart';

class DesignElementCardCodecService {
  const DesignElementCardCodecService();

  DesignElementCard fromJson(JsonMap json) {
    // 中文注释: 单条 design card 的 decode 集中在这里，方便后续 repository、tool result 与测试共用同一入口。
    return DesignElementCard.fromJson(json);
  }

  JsonMap toJson(DesignElementCard card) {
    // 中文注释: encode 透传模型实现，避免不同调用点各自拼壳层字段。
    return card.toJson();
  }

  List<DesignElementCard> fromJsonList(Object? rawCards) {
    // 中文注释: 空 design card 列表是合法状态，这里必须稳定返回空列表而不是抛异常。
    return ValueReaders.mapList(
      rawCards,
    ).map(DesignElementCard.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<DesignElementCard> cards) {
    // 中文注释: 列表编码统一输出紧凑 JSON 数组，供 JSON/JSONL、工具结果与测试共同复用。
    return cards.map((card) => card.toJson()).toList(growable: false);
  }
}
