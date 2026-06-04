import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'constraint_binding_policy.dart';
import 'constraint_binding_scope.dart';
import 'narrative_constraint_binding_proposal.dart';

class NarrativeConstraintBindingCodecService {
  const NarrativeConstraintBindingCodecService();

  NarrativeConstraintBindingProposal proposalFromJson(JsonMap json) {
    // 中文注释: constraint binding proposal decode 统一走这里，后续 repository/tool 输入可共用。
    return NarrativeConstraintBindingProposal.fromJson(json);
  }

  JsonMap proposalToJson(NarrativeConstraintBindingProposal proposal) {
    // 中文注释: 编码保持薄包装，避免调用点重复拼 binding/scope/policy 字段。
    return proposal.toJson();
  }

  ConstraintBindingScope scopeFromJson(JsonMap json) {
    return ConstraintBindingScope.fromJson(json);
  }

  JsonMap scopeToJson(ConstraintBindingScope scope) {
    return scope.toJson();
  }

  ConstraintBindingPolicy policyFromJson(JsonMap json) {
    return ConstraintBindingPolicy.fromJson(json);
  }

  JsonMap policyToJson(ConstraintBindingPolicy policy) {
    return policy.toJson();
  }

  List<NarrativeConstraintBindingProposal> proposalsFromJsonList(
    Object? rawProposals,
  ) {
    return ValueReaders.mapList(
      rawProposals,
    ).map(NarrativeConstraintBindingProposal.fromJson).toList(growable: false);
  }
}
