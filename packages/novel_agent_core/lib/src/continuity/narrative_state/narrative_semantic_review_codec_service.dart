import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_semantic_review.dart';

class NarrativeSemanticReviewCodecService {
  const NarrativeSemanticReviewCodecService();

  NarrativeSemanticReview fromJson(JsonMap json) {
    // 中文注释: semantic review decode 统一走这里，方便后续 tool 输入与 repository 共用。
    return NarrativeSemanticReview.fromJson(json);
  }

  JsonMap toJson(NarrativeSemanticReview review) {
    // 中文注释: semantic review encode 保持薄包装，减少调用点重复拼字段。
    return review.toJson();
  }

  List<NarrativeSemanticReview> fromJsonList(Object? rawReviews) {
    // 中文注释: 空 review 列表在项目初始阶段是合法状态，这里稳定返回空数组。
    return ValueReaders.mapList(
      rawReviews,
    ).map(NarrativeSemanticReview.fromJson).toList(growable: false);
  }
}
