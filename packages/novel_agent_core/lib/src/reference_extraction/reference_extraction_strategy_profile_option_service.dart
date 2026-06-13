import '../reference_substrate/reference_substrate_constants.dart';
import 'reference_extraction_strategy_profile.dart';
import 'reference_extraction_strategy_profile_catalog_service.dart';
import 'reference_extraction_strategy_profile_option.dart';

class ReferenceExtractionStrategyProfileOptionService {
  const ReferenceExtractionStrategyProfileOptionService({
    ReferenceExtractionStrategyProfileCatalogService? catalogService,
  }) : _catalogService =
           catalogService ??
           const ReferenceExtractionStrategyProfileCatalogService();

  final ReferenceExtractionStrategyProfileCatalogService _catalogService;

  List<ReferenceExtractionStrategyProfileOption> listOptions({
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    return _catalogService
        .allProfiles(additionalProfiles: additionalProfiles)
        .map(_toOption)
        .toList(growable: false);
  }

  ReferenceExtractionStrategyProfileOption? optionById(
    String profileId, {
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    final profile = _catalogService.byId(
      profileId,
      additionalProfiles: additionalProfiles,
    );
    if (profile == null) {
      return null;
    }
    return _toOption(profile);
  }

  ReferenceExtractionStrategyProfileOption _toOption(
    ReferenceExtractionStrategyProfile profile,
  ) {
    return ReferenceExtractionStrategyProfileOption(
      profileId: profile.profileId,
      displayName: _displayName(profile),
      summary: _summary(profile),
      proposalCountLabel:
          '${profile.proposalPolicy.minProposalCount}-${profile.proposalPolicy.maxProposalCount} 条候选',
      entryKindsLabel: profile.proposalPolicy.allowedEntryKinds
          .map(_entryKindLabel)
          .join('、'),
      reviewPolicyLabel: _reviewPolicyLabel(profile),
      isBuiltin: _catalogService.isBuiltinProfileId(profile.profileId),
    );
  }

  String _displayName(ReferenceExtractionStrategyProfile profile) {
    final metadataValue =
        profile.metadata['display_name']?.toString().trim() ?? '';
    if (metadataValue.isNotEmpty) {
      return metadataValue;
    }
    switch (profile.profileId) {
      case ReferenceExtractionBuiltinStrategyProfileIds.standard:
        return '标准提取';
      case ReferenceExtractionBuiltinStrategyProfileIds.bulkLongContext:
        return '长上下文整书';
      case ReferenceExtractionBuiltinStrategyProfileIds.factFocused:
        return '事实优先';
      case ReferenceExtractionBuiltinStrategyProfileIds.exploratory:
        return '探索扩展';
      default:
        return profile.profileId;
    }
  }

  String _summary(ReferenceExtractionStrategyProfile profile) {
    final metadataValue = profile.metadata['summary']?.toString().trim() ?? '';
    if (metadataValue.isNotEmpty) {
      return metadataValue;
    }
    switch (profile.profileId) {
      case ReferenceExtractionBuiltinStrategyProfileIds.standard:
        return '兼顾知识、设计和引用边界，适合作为默认提取策略。';
      case ReferenceExtractionBuiltinStrategyProfileIds.bulkLongContext:
        return '面向高上下文模型的长文档提取，尽量减少整书级批次数，同时保持结构优先与单路执行。';
      case ReferenceExtractionBuiltinStrategyProfileIds.factFocused:
        return '收紧候选范围，优先沉淀可核对的事实和引用边界。';
      case ReferenceExtractionBuiltinStrategyProfileIds.exploratory:
        return '放宽候选范围，鼓励挖掘结构、笔法和更多潜在线索。';
      default:
        return '使用自定义提取策略。';
    }
  }

  String _reviewPolicyLabel(ReferenceExtractionStrategyProfile profile) {
    final evidenceLabel = profile.reviewPolicy.requireEvidence
        ? '要求证据'
        : '证据可放宽';
    final accepted = profile.reviewPolicy.acceptanceThreshold.toStringAsFixed(
      2,
    );
    final candidate = profile.reviewPolicy.candidateThreshold.toStringAsFixed(
      2,
    );
    return '接纳 >= $accepted，候选 >= $candidate，$evidenceLabel';
  }

  String _entryKindLabel(String entryKind) {
    switch (entryKind) {
      case ReferenceEntryKinds.knowledgeFact:
        return '知识事实';
      case ReferenceEntryKinds.designElement:
        return '设计元素';
      case ReferenceEntryKinds.styleTechnique:
        return '风格技法';
      case ReferenceEntryKinds.referenceWorkBoundary:
        return '引用边界';
      case ReferenceEntryKinds.researchNote:
        return '研究笔记';
      case ReferenceEntryKinds.processDependency:
        return '流程依赖';
      case ReferenceEntryKinds.divergenceSnapshot:
        return '分歧快照';
      case ReferenceEntryKinds.microReferenceShard:
        return '微型参考片段';
      default:
        return entryKind;
    }
  }
}
