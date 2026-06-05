import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/value_readers.dart';
import 'design_element_card.dart';
import 'information_link.dart';
import 'information_permission_decision.dart';
import 'information_permission_dispositions.dart';
import 'information_policy_constants.dart';
import 'information_source_ref.dart';
import 'information_usage_policy.dart';
import 'project_knowledge_card.dart';
import 'reference_work_record.dart';
import 'research_note.dart';

class InformationPermissionPolicyService {
  const InformationPermissionPolicyService();

  InformationPermissionDecision decideKnowledgeCard(ProjectKnowledgeCard card) {
    if (_containsForbiddenScriptPayload(card.contentPayload) ||
        _containsForbiddenScriptPayload(card.metadata) ||
        _isForbiddenUsage(card.usagePolicy)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动应用带有脚本型 payload 或 blocked 引用风险的信息规则。',
        policyRef: 'policy.information_forbidden_auto_apply',
      );
    }
    if (_modifiesLongTermRule(card.metadata) ||
        _requiresUserConfirmationByUsage(card.usagePolicy)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.needsUserConfirmation,
        reason: '长期规则修改或高风险使用边界必须用户确认。',
        policyRef: 'policy.knowledge_card_requires_user_confirmation',
      );
    }
    if (_hasSourceAuthority(
      card.sourceRefs,
      InformationSourceAuthorities.externalResearched,
    )) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.proposed,
        reason: '外部研究产出的知识规则先进入 proposal，不直接自动接受。',
        policyRef: 'policy.external_research_knowledge_proposed',
      );
    }
    if (_hasAnyUntrustedRuleSource(card.sourceRefs)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.proposed,
        reason: 'AI 推断、拆书抽取或解释性来源的长期规则默认先进入 proposal。',
        policyRef: 'policy.knowledge_card_auto_proposed',
      );
    }
    return const InformationPermissionDecision(
      disposition: InformationPermissionDispositions.autoAccept,
      reason: '用户声明或项目内置资料的低风险知识卡可自动接受。',
      policyRef: 'policy.knowledge_card_auto_accept',
    );
  }

  InformationPermissionDecision decideDesignElement(DesignElementCard card) {
    if (_containsForbiddenScriptPayload(card.designPayload) ||
        _containsForbiddenScriptPayload(card.metadata) ||
        _isForbiddenUsage(card.usagePolicy)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动应用带有脚本型 payload 或 blocked 引用风险的设计元素。',
        policyRef: 'policy.design_element_forbidden_auto_apply',
      );
    }
    if (_modifiesLongTermRule(card.metadata) ||
        _requiresUserConfirmationByUsage(card.usagePolicy)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.needsUserConfirmation,
        reason: '高风险设计规则或长期结构修改必须用户确认。',
        policyRef: 'policy.design_element_requires_user_confirmation',
      );
    }
    if (_hasSourceAuthority(
      card.sourceRefs,
      InformationSourceAuthorities.externalResearched,
    )) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.proposed,
        reason: '外部研究启发的设计元素先进入 proposal，不直接自动接受。',
        policyRef: 'policy.external_research_design_proposed',
      );
    }
    if (_hasAnyUntrustedRuleSource(card.sourceRefs)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.proposed,
        reason: 'AI 推断、拆书抽取或解释性设计元素默认先进入 proposal。',
        policyRef: 'policy.design_element_auto_proposed',
      );
    }
    return const InformationPermissionDecision(
      disposition: InformationPermissionDispositions.autoAccept,
      reason: '用户声明的低风险设计元素可自动接受。',
      policyRef: 'policy.design_element_auto_accept',
    );
  }

  InformationPermissionDecision decideResearchNote(ResearchNote note) {
    if (_containsForbiddenScriptPayload(note.metadata) ||
        _containsForbiddenScriptPayload(<String, Object?>{
          'query': note.query,
          'source_url_or_ref': note.sourceUrlOrRef,
          'citation': note.citation,
        })) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动保存带有脚本型 payload 的研究笔记。',
        policyRef: 'policy.research_note_forbidden_auto_apply',
      );
    }
    return InformationPermissionDecision(
      disposition: InformationPermissionDispositions.autoAccept,
      reason: '研究结果可自动保存为 research note，但提升为项目规则需后续 proposal。',
      policyRef: 'policy.research_note_auto_accept',
      metadata: <String, Object?>{
        'promotion_disposition': InformationPermissionDispositions.proposed,
      },
    );
  }

  InformationPermissionDecision decideReferenceWork(
    ReferenceWorkRecord record,
  ) {
    if (_containsForbiddenScriptPayload(record.metadata) ||
        _containsForbiddenScriptPayload(<String, Object?>{
          'risk_notes': record.riskNotes,
        })) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动应用带有脚本型 payload 的引用作品边界记录。',
        policyRef: 'policy.reference_work_forbidden_auto_apply',
      );
    }
    if (record.requiresConfirmation ||
        _isHighRiskReferenceRelationship(record.relationshipToProject)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.needsUserConfirmation,
        reason: '高风险外部作品、同人/穿书/跨作品引用必须用户确认。',
        policyRef: 'policy.reference_work_requires_user_confirmation',
      );
    }
    if (_isAutoAcceptableReferenceRelationship(record.relationshipToProject) &&
        _allSourceAuthoritiesIn(record.sourceRefs, const <String>{
          InformationSourceAuthorities.userDeclared,
          InformationSourceAuthorities.sourceDocument,
        })) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
        reason: '低风险 inspiration 或虚构内嵌作品边界可自动接受。',
        policyRef: 'policy.reference_work_auto_accept',
      );
    }
    return const InformationPermissionDecision(
      disposition: InformationPermissionDispositions.proposed,
      reason: '其余引用作品边界默认先进入 proposal。',
      policyRef: 'policy.reference_work_auto_proposed',
    );
  }

  InformationPermissionDecision decideInformationLink(InformationLink link) {
    if (_containsForbiddenScriptPayload(link.metadata) ||
        _containsForbiddenScriptPayload(<String, Object?>{
          'summary': link.summary,
          'created_by': link.createdBy,
        })) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动应用带有脚本型 payload 的信息链路。',
        policyRef: 'policy.information_link_forbidden_auto_apply',
      );
    }
    return const InformationPermissionDecision(
      disposition: InformationPermissionDispositions.autoAccept,
      reason: '信息链路只建立结构化证据关系，可自动接受。',
      policyRef: 'policy.information_link_auto_accept',
    );
  }

  InformationPermissionDecision decideExternalResearchRequest({
    required String query,
    String requestedBy = '',
    bool userGrantedNetworkAccess = false,
    JsonMap metadata = const <String, Object?>{},
  }) {
    if (_containsForbiddenScriptPayload(<String, Object?>{
      'query': query,
      'requested_by': requestedBy,
      ...metadata,
    })) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动执行带有脚本型 payload 的外部研究请求。',
        policyRef: 'policy.external_research_forbidden_auto_apply',
      );
    }
    final relationshipHint = ValueReaders.stringValue(
      metadata['reference_relationship'],
    ).trim();
    if (!userGrantedNetworkAccess) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.needsUserConfirmation,
        reason: '默认不自动联网，外部研究请求必须先得到用户明确授权。',
        policyRef: 'policy.external_research_requires_user_confirmation',
      );
    }
    if (_isHighRiskReferenceRelationship(relationshipHint)) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.needsUserConfirmation,
        reason: '涉及高风险外部作品或同人/穿书边界的研究请求仍需用户确认。',
        policyRef:
            'policy.external_research_high_risk_reference_requires_confirmation',
      );
    }
    return const InformationPermissionDecision(
      disposition: InformationPermissionDispositions.autoAccept,
      reason: '已显式授权的低风险外部研究请求可自动接受。',
      policyRef: 'policy.external_research_auto_accept',
    );
  }

  bool _hasAnyUntrustedRuleSource(List<InformationSourceRef> sourceRefs) {
    const untrustedAuthorities = <String>{
      InformationSourceAuthorities.aiInferred,
      InformationSourceAuthorities.deconstructionExtracted,
      InformationSourceAuthorities.analysisInterpreted,
    };
    return sourceRefs.any(
      (entry) => untrustedAuthorities.contains(entry.sourceAuthority),
    );
  }

  bool _hasSourceAuthority(
    List<InformationSourceRef> sourceRefs,
    String authority,
  ) {
    return sourceRefs.any((entry) => entry.sourceAuthority == authority);
  }

  bool _allSourceAuthoritiesIn(
    List<InformationSourceRef> sourceRefs,
    Set<String> allowedAuthorities,
  ) {
    if (sourceRefs.isEmpty) {
      return false;
    }
    return sourceRefs.every(
      (entry) => allowedAuthorities.contains(entry.sourceAuthority),
    );
  }

  bool _requiresUserConfirmationByUsage(InformationUsagePolicy usagePolicy) {
    return usagePolicy.requiresConfirmation ||
        usagePolicy.citationRiskLevel ==
            InformationCitationRiskLevels.highRisk ||
        usagePolicy.citationRiskLevel ==
            InformationCitationRiskLevels.blocked ||
        !usagePolicy.allowsDerivativeUse;
  }

  bool _isForbiddenUsage(InformationUsagePolicy usagePolicy) {
    return usagePolicy.citationRiskLevel ==
        InformationCitationRiskLevels.blocked;
  }

  bool _modifiesLongTermRule(JsonMap metadata) {
    final unknownFields = ValueReaders.mapValue(
      metadata[OpenJsonContractCodecService.unknownFieldsMetadataKey],
    );
    return ValueReaders.boolValue(metadata['modifies_long_term_rule']) ||
        ValueReaders.boolValue(metadata['updates_existing_rule']) ||
        ValueReaders.boolValue(metadata['overrides_active_information']) ||
        ValueReaders.boolValue(unknownFields['modifies_long_term_rule']) ||
        ValueReaders.boolValue(unknownFields['updates_existing_rule']) ||
        ValueReaders.boolValue(unknownFields['overrides_active_information']);
  }

  bool _isHighRiskReferenceRelationship(String relationshipToProject) {
    final normalized = relationshipToProject.trim().toLowerCase();
    return normalized.contains('fanfic') ||
        normalized.contains('crossover') ||
        normalized.contains('deconstructed_source') ||
        normalized.contains('transmigration') ||
        normalized.contains('real_world_novel') ||
        normalized.contains('source_work');
  }

  bool _isAutoAcceptableReferenceRelationship(String relationshipToProject) {
    final normalized = relationshipToProject.trim().toLowerCase();
    return normalized == 'inspiration' ||
        normalized == 'fictional_in_world_work';
  }

  bool _containsForbiddenScriptPayload(JsonMap payload) {
    const forbiddenKeys = <String>{
      'script',
      'script_path',
      'command',
      'shell_command',
      'executable_path',
    };
    for (final entry in payload.entries) {
      final key = entry.key.trim().toLowerCase();
      if (forbiddenKeys.contains(key) &&
          ValueReaders.stringValue(entry.value).trim().isNotEmpty) {
        return true;
      }
      final nestedMap = ValueReaders.mapValue(entry.value);
      if (nestedMap.isNotEmpty && _containsForbiddenScriptPayload(nestedMap)) {
        return true;
      }
      for (final item in ValueReaders.objectList(entry.value)) {
        final nestedItemMap = ValueReaders.mapValue(item);
        if (nestedItemMap.isNotEmpty &&
            _containsForbiddenScriptPayload(nestedItemMap)) {
          return true;
        }
      }
    }
    return false;
  }
}
