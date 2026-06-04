import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_state_claim.dart';

class NarrativeStateClaimCodecService {
  const NarrativeStateClaimCodecService();

  NarrativeStateClaim fromJson(JsonMap json) {
    // 中文注释: 单条 claim 的 decode 集中在这里，方便后续 repository 和工具层共用同一入口。
    return NarrativeStateClaim.fromJson(json);
  }

  JsonMap toJson(NarrativeStateClaim claim) {
    // 中文注释: 单条 claim 的 encode 保持透传模型实现，避免不同调用点各自拼字段。
    return claim.toJson();
  }

  List<NarrativeStateClaim> fromJsonList(Object? rawClaims) {
    // 中文注释: 空 claims 在 ONS 里是合法状态，这里必须稳定返回空列表而不是报错或伪造占位值。
    return ValueReaders.mapList(
      rawClaims,
    ).map(NarrativeStateClaim.fromJson).toList(growable: false);
  }

  List<JsonMap> toJsonList(List<NarrativeStateClaim> claims) {
    // 中文注释: 列表编码统一输出为紧凑 JSON 数组，供 JSONL/工具结果/测试共同复用。
    return claims.map((claim) => claim.toJson()).toList(growable: false);
  }
}
