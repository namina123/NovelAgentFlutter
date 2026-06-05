import 'dart:convert';

import '../agents/agent_group_file_codec_service.dart';
import '../agents/agent_group_normalizer_service.dart';
import '../agents/agent_profile_normalizer_service.dart';
import '../agents/skill_capability_catalog_service.dart';
import '../agents/skill_group_file_codec_service.dart';
import '../agents/skill_group_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/agent_markdown_package_renderer_service.dart';
import '../packages/agent_package_validator_service.dart';
import '../packages/skill_markdown_package_parser_service.dart';
import '../packages/skill_markdown_package_renderer_service.dart';
import '../packages/skill_package_validator_service.dart';
import 'agent_group_validator_service.dart';
import 'ecosystem_asset_kind.dart';
import 'ecosystem_asset_lifecycle_status.dart';
import 'ecosystem_asset_path_service.dart';
import 'ecosystem_asset_proposal.dart';
import 'ecosystem_asset_source_kind.dart';
import 'skill_group_validator_service.dart';

class EcosystemAssetProposalReview {
  const EcosystemAssetProposalReview({
    required this.proposal,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final EcosystemAssetProposal proposal;
  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

class EcosystemAssetInstallationPlan {
  const EcosystemAssetInstallationPlan({
    required this.proposal,
    required this.relativePath,
    required this.content,
  });

  final EcosystemAssetProposal proposal;
  final String relativePath;
  final String content;
}

class EcosystemAssetProposalService {
  EcosystemAssetProposalService({
    SkillPackageValidatorService? skillPackageValidatorService,
    AgentPackageValidatorService? agentPackageValidatorService,
    SkillGroupValidatorService? skillGroupValidatorService,
    AgentGroupValidatorService? agentGroupValidatorService,
    SkillMarkdownPackageParserService? skillParserService,
    AgentProfileNormalizerService? agentProfileNormalizerService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    SkillMarkdownPackageRendererService? skillRendererService,
    AgentMarkdownPackageRendererService? agentRendererService,
    SkillGroupFileCodecService? skillGroupCodecService,
    AgentGroupFileCodecService? agentGroupCodecService,
    SkillCapabilityCatalogService? capabilityCatalogService,
    EcosystemAssetPathService? pathService,
  }) : _skillPackageValidatorService =
           skillPackageValidatorService ?? SkillPackageValidatorService(),
       _agentPackageValidatorService =
           agentPackageValidatorService ?? AgentPackageValidatorService(),
       _skillGroupValidatorService =
           skillGroupValidatorService ?? SkillGroupValidatorService(),
       _agentGroupValidatorService =
           agentGroupValidatorService ?? AgentGroupValidatorService(),
       _skillParserService =
           skillParserService ?? SkillMarkdownPackageParserService(),
       _agentProfileNormalizerService =
           agentProfileNormalizerService ?? AgentProfileNormalizerService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService(),
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _skillRendererService =
           skillRendererService ?? SkillMarkdownPackageRendererService(),
       _agentRendererService =
           agentRendererService ?? AgentMarkdownPackageRendererService(),
       _skillGroupCodecService =
           skillGroupCodecService ?? SkillGroupFileCodecService(),
       _agentGroupCodecService =
           agentGroupCodecService ?? AgentGroupFileCodecService(),
       _capabilityCatalogService =
           capabilityCatalogService ?? const SkillCapabilityCatalogService(),
       _pathService = pathService ?? EcosystemAssetPathService();

  final SkillPackageValidatorService _skillPackageValidatorService;
  final AgentPackageValidatorService _agentPackageValidatorService;
  final SkillGroupValidatorService _skillGroupValidatorService;
  final AgentGroupValidatorService _agentGroupValidatorService;
  final SkillMarkdownPackageParserService _skillParserService;
  final AgentProfileNormalizerService _agentProfileNormalizerService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final SkillMarkdownPackageRendererService _skillRendererService;
  final AgentMarkdownPackageRendererService _agentRendererService;
  final SkillGroupFileCodecService _skillGroupCodecService;
  final AgentGroupFileCodecService _agentGroupCodecService;
  final SkillCapabilityCatalogService _capabilityCatalogService;
  final EcosystemAssetPathService _pathService;

  EcosystemAssetProposal createDraft({
    required EcosystemAssetKind assetKind,
    required String assetId,
    required String version,
    required String summary,
    required String riskNote,
    required JsonMap assetPayload,
    List<String> requiredCapabilities = const <String>[],
    String proposalId = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final cleanAssetId = assetId.trim();
    return EcosystemAssetProposal(
      proposalId: proposalId.trim().isNotEmpty
          ? proposalId.trim()
          : _pathService.defaultProposalId(
              kind: assetKind,
              assetId: cleanAssetId,
            ),
      assetKind: assetKind,
      assetId: cleanAssetId,
      proposalStatus: EcosystemAssetLifecycleStatus.proposal,
      sourceKind: EcosystemAssetSourceKind.nonBuiltin,
      version: version.trim(),
      summary: summary.trim(),
      riskNote: riskNote.trim(),
      requiredCapabilities: _normalizeCapabilities(requiredCapabilities),
      assetPayload: ValueReaders.deepCopyMap(assetPayload),
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  EcosystemAssetProposalReview review(EcosystemAssetProposal proposal) {
    final normalizedPayload = _normalizePayload(proposal);
    final normalizedProposal = proposal.copyWith(
      assetPayload: normalizedPayload,
      assetId: ValueReaders.stringValue(
        normalizedPayload['id'],
        proposal.assetId,
      ).trim(),
      version: ValueReaders.stringValue(
        normalizedPayload['version'],
        proposal.version,
      ).trim(),
      requiredCapabilities: _normalizeCapabilities(
        proposal.requiredCapabilities,
      ),
    );
    final proposalErrors = normalizedProposal.validateBasics();
    final validation = _validatePayload(
      normalizedProposal.assetKind,
      normalizedPayload,
    );
    final capabilityWarnings = _capabilityWarnings(
      normalizedProposal.requiredCapabilities,
    );
    final errors = <String>[
      ...proposalErrors,
      ...ValueReaders.stringList(validation['errors']),
    ];
    final warnings = <String>[
      ...ValueReaders.stringList(validation['warnings']),
      ...capabilityWarnings,
    ];
    final status = errors.isEmpty
        ? EcosystemAssetLifecycleStatus.validated
        : EcosystemAssetLifecycleStatus.proposal;
    return EcosystemAssetProposalReview(
      proposal: normalizedProposal.copyWith(
        proposalStatus: status,
        validationErrors: errors,
        validationWarnings: warnings,
      ),
      errors: errors,
      warnings: warnings,
    );
  }

  EcosystemAssetProposal confirm(EcosystemAssetProposal proposal) {
    if (proposal.proposalStatus != EcosystemAssetLifecycleStatus.validated) {
      throw StateError('只有 validated 状态的生态 proposal 才能被确认。');
    }
    if (proposal.validationErrors.isNotEmpty) {
      throw StateError('存在未解决的校验错误，不能确认安装。');
    }
    return proposal.copyWith(
      proposalStatus: EcosystemAssetLifecycleStatus.confirmed,
    );
  }

  EcosystemAssetInstallationPlan install(EcosystemAssetProposal proposal) {
    if (proposal.proposalStatus != EcosystemAssetLifecycleStatus.confirmed) {
      throw StateError('只有 confirmed 状态的生态 proposal 才能安装。');
    }
    final relativePath = _pathService.installPath(
      kind: proposal.assetKind,
      assetId: proposal.assetId,
    );
    final content = _renderInstalledContent(proposal);
    return EcosystemAssetInstallationPlan(
      proposal: proposal.copyWith(
        proposalStatus: EcosystemAssetLifecycleStatus.installed,
        metadata: <String, Object?>{
          ...proposal.metadata,
          'installed_relative_path': relativePath,
        },
      ),
      relativePath: relativePath,
      content: content,
    );
  }

  EcosystemAssetProposal reject(
    EcosystemAssetProposal proposal, {
    String reason = '',
  }) {
    return proposal.copyWith(
      proposalStatus: EcosystemAssetLifecycleStatus.rejected,
      metadata: <String, Object?>{
        ...proposal.metadata,
        if (reason.trim().isNotEmpty) 'rejection_reason': reason.trim(),
      },
    );
  }

  JsonMap _normalizePayload(EcosystemAssetProposal proposal) {
    switch (proposal.assetKind) {
      case EcosystemAssetKind.skill:
        return _skillParserService.parsePackage(
          jsonEncode(proposal.assetPayload),
          fallbackId: proposal.assetId,
        );
      case EcosystemAssetKind.skillGroup:
        return _skillGroupNormalizerService.normalizeSkillGroup(
          proposal.assetPayload,
        );
      case EcosystemAssetKind.agent:
        return _agentProfileNormalizerService.normalizeAgentProfile(
          proposal.assetPayload,
        );
      case EcosystemAssetKind.agentGroup:
        return _agentGroupNormalizerService.normalizeAgentGroup(
          proposal.assetPayload,
        );
    }
  }

  JsonMap _validatePayload(EcosystemAssetKind kind, JsonMap payload) {
    switch (kind) {
      case EcosystemAssetKind.skill:
        return _skillPackageValidatorService.validate(payload);
      case EcosystemAssetKind.skillGroup:
        return _skillGroupValidatorService.validate(payload);
      case EcosystemAssetKind.agent:
        return _agentPackageValidatorService.validate(payload);
      case EcosystemAssetKind.agentGroup:
        return _agentGroupValidatorService.validate(payload);
    }
  }

  String _renderInstalledContent(EcosystemAssetProposal proposal) {
    switch (proposal.assetKind) {
      case EcosystemAssetKind.skill:
        return _skillRendererService.renderPackage(proposal.assetPayload);
      case EcosystemAssetKind.skillGroup:
        return _skillGroupCodecService.encodeSkillGroup(proposal.assetPayload);
      case EcosystemAssetKind.agent:
        return _agentRendererService.renderPackage(proposal.assetPayload);
      case EcosystemAssetKind.agentGroup:
        return _agentGroupCodecService.encodeAgentGroup(proposal.assetPayload);
    }
  }

  List<String> _normalizeCapabilities(List<String> rawValues) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in rawValues) {
      final clean = value.trim();
      if (clean.isEmpty || !seen.add(clean)) {
        continue;
      }
      result.add(clean);
    }
    return result;
  }

  List<String> _capabilityWarnings(List<String> capabilityIds) {
    return capabilityIds
        .where(
          (capabilityId) =>
              !_capabilityCatalogService.isKnownCapability(capabilityId),
        )
        .map(
          (capabilityId) =>
              'proposal 声明了未识别的 capability requirement：$capabilityId。',
        )
        .toList(growable: false);
  }
}
