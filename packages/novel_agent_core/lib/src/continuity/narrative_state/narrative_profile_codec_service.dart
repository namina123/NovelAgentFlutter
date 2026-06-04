import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_profile.dart';
import 'narrative_profile_patch.dart';
import 'narrative_profile_proposal.dart';

class NarrativeProfileCodecService {
  const NarrativeProfileCodecService();

  NarrativeProfile profileFromJson(JsonMap json) {
    // 中文注释: profile decode 统一走这里，后续 repository 与测试可共享同一入口。
    return NarrativeProfile.fromJson(json);
  }

  JsonMap profileToJson(NarrativeProfile profile) {
    // 中文注释: 单条 profile 编码保持薄包装，避免上层重复拼字段。
    return profile.toJson();
  }

  NarrativeProfilePatch patchFromJson(JsonMap json) {
    // 中文注释: patch decode 与 profile 分开，方便未来提案校验只读取 patch。
    return NarrativeProfilePatch.fromJson(json);
  }

  JsonMap patchToJson(NarrativeProfilePatch patch) {
    // 中文注释: patch encode 统一由这里透传，减少调用点的 JSON 样板。
    return patch.toJson();
  }

  NarrativeProfileProposal proposalFromJson(JsonMap json) {
    // 中文注释: proposal decode 与 profile/patch 拆开，后续可以单独接工具输入。
    return NarrativeProfileProposal.fromJson(json);
  }

  JsonMap proposalToJson(NarrativeProfileProposal proposal) {
    // 中文注释: proposal encode 保持紧凑 JSON 合同，供测试和未来 repository 直接复用。
    return proposal.toJson();
  }

  List<NarrativeProfile> profilesFromJsonList(Object? rawProfiles) {
    // 中文注释: 空 profile 列表在创建早期或迁移过程中是合法状态，这里应稳定返回空列表。
    return ValueReaders.mapList(
      rawProfiles,
    ).map(NarrativeProfile.fromJson).toList(growable: false);
  }
}
