import 'dart:convert';

import '../agents/agent_group_file_codec_service.dart';
import '../agents/agent_group_normalizer_service.dart';
import '../agents/skill_group_file_codec_service.dart';
import '../agents/skill_group_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../customization/customization_root_catalog_service.dart';
import '../packages/agent_markdown_package_renderer_service.dart';
import '../packages/skill_markdown_package_renderer_service.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import '../ecosystem/ecosystem_asset_kind.dart';
import '../ecosystem/ecosystem_asset_path_service.dart';
import '../ecosystem/ecosystem_asset_proposal.dart';
import '../ecosystem/ecosystem_asset_proposal_service.dart';
import 'generate_customization_indexes_use_case.dart';

class ImportCustomizationBundleUseCase {
  ImportCustomizationBundleUseCase({
    required ProjectToolHostPort projectToolHostPort,
    required GenerateCustomizationIndexesUseCase
    generateCustomizationIndexesUseCase,
    AgentMarkdownPackageRendererService? agentRendererService,
    SkillMarkdownPackageRendererService? skillRendererService,
    AgentGroupFileCodecService? agentGroupCodecService,
    SkillGroupFileCodecService? skillGroupCodecService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
    EcosystemAssetProposalService? proposalService,
    EcosystemAssetPathService? pathService,
  }) : _projectToolHostPort = projectToolHostPort,
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService(),
       _proposalService = proposalService ?? EcosystemAssetProposalService(),
       _pathService = pathService ?? EcosystemAssetPathService();

  final ProjectToolHostPort _projectToolHostPort;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;
  final EcosystemAssetProposalService _proposalService;
  final EcosystemAssetPathService _pathService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required String bundleContent,
    bool overwrite = true,
    bool allowBuiltinShadow = true,
    List<String> builtinAgentIds = const <String>[],
    List<String> builtinSkillIds = const <String>[],
    List<String> builtinSkillGroupIds = const <String>[],
    List<String> builtinAgentGroupIds = const <String>[],
  }) async {
    // 中文注释: 生态包导入统一从结构化 bundle 文本进入，保证 GUI 和 CLI 使用同一导入规则。
    final bundle = _parseBundle(bundleContent);
    if (bundle.isEmpty) {
      return _error('生态包内容无效。');
    }
    final kind = ValueReaders.stringValue(bundle['kind']);
    if (kind.trim().isNotEmpty &&
        kind.trim() != 'novel_agent_customization_bundle') {
      return _error('不支持的生态包类型：$kind');
    }
    final changedPaths = <String>[];
    final skippedPaths = <String>[];
    await _importSkills(
      project: project,
      bundle: bundle,
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      builtinIds: builtinSkillIds,
      changedPaths: changedPaths,
      skippedPaths: skippedPaths,
    );
    await _importSkillGroups(
      project: project,
      bundle: bundle,
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      builtinIds: builtinSkillGroupIds,
      changedPaths: changedPaths,
      skippedPaths: skippedPaths,
    );
    await _importAgents(
      project: project,
      bundle: bundle,
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      builtinIds: builtinAgentIds,
      changedPaths: changedPaths,
      skippedPaths: skippedPaths,
    );
    await _importAgentGroups(
      project: project,
      bundle: bundle,
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      builtinIds: builtinAgentGroupIds,
      changedPaths: changedPaths,
      skippedPaths: skippedPaths,
    );
    return <String, Object?>{
      'ok': changedPaths.isNotEmpty,
      'summary': changedPaths.isEmpty
          ? '没有导入任何生态 proposal。'
          : '已导入 ${changedPaths.length} 个生态 proposal 文件。',
      'changed_paths': changedPaths,
      'skipped_paths': skippedPaths,
    };
  }

  JsonMap _parseBundle(String bundleContent) {
    try {
      return ValueReaders.mapValue(jsonDecode(bundleContent));
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  Future<void> _importSkills({
    required ProjectDescriptor project,
    required JsonMap bundle,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<String> builtinIds,
    required List<String> changedPaths,
    required List<String> skippedPaths,
  }) async {
    for (final rawItem in ValueReaders.mapList(bundle['skills'])) {
      final item = ValueReaders.mapValue(rawItem);
      final id = ValueReaders.stringValue(item['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      if (!allowBuiltinShadow &&
          builtinIds.contains(id) &&
          !await _projectToolHostPort.entryExists(
            project.rootPath,
            '${CustomizationRootCatalogService.skillsRoot}/$id/SKILL.md',
          )) {
        skippedPaths.add(
          '${CustomizationRootCatalogService.skillsRoot}/$id/SKILL.md',
        );
        continue;
      }
      await _writeCanonicalEntry(
        project: project,
        relativePath: _pathService.proposalPath(
          kind: EcosystemAssetKind.skill,
          proposalId: _pathService.defaultProposalId(
            kind: EcosystemAssetKind.skill,
            assetId: id,
          ),
        ),
        content: _encodeProposal(
          _proposalService
              .review(
                _proposalService.createDraft(
                  assetKind: EcosystemAssetKind.skill,
                  assetId: id,
                  version: ValueReaders.stringValue(item['version'], '1'),
                  summary: _summaryFor(item, fallbackLabel: '技能 $id'),
                  riskNote: _riskNoteFor(
                    label: '技能',
                    capabilityIds: ValueReaders.stringList(
                      item['required_capabilities'],
                    ),
                  ),
                  assetPayload: item,
                  requiredCapabilities: ValueReaders.stringList(
                    item['required_capabilities'],
                  ),
                ),
              )
              .proposal,
        ),
        overwrite: overwrite,
        changedPaths: changedPaths,
        skippedPaths: skippedPaths,
      );
    }
  }

  Future<void> _importSkillGroups({
    required ProjectDescriptor project,
    required JsonMap bundle,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<String> builtinIds,
    required List<String> changedPaths,
    required List<String> skippedPaths,
  }) async {
    for (final rawItem in ValueReaders.mapList(bundle['skill_groups'])) {
      final item = _skillGroupNormalizerService.normalizeSkillGroup(
        ValueReaders.mapValue(rawItem),
      );
      final id = ValueReaders.stringValue(item['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      final relativePath =
          '${CustomizationRootCatalogService.skillGroupsRoot}/$id/skill_group.json';
      if (!allowBuiltinShadow &&
          builtinIds.contains(id) &&
          !await _projectToolHostPort.entryExists(
            project.rootPath,
            relativePath,
          )) {
        skippedPaths.add(relativePath);
        continue;
      }
      await _writeCanonicalEntry(
        project: project,
        relativePath: _pathService.proposalPath(
          kind: EcosystemAssetKind.skillGroup,
          proposalId: _pathService.defaultProposalId(
            kind: EcosystemAssetKind.skillGroup,
            assetId: id,
          ),
        ),
        content: _encodeProposal(
          _proposalService
              .review(
                _proposalService.createDraft(
                  assetKind: EcosystemAssetKind.skillGroup,
                  assetId: id,
                  version: ValueReaders.stringValue(item['version'], '1'),
                  summary: _summaryFor(item, fallbackLabel: '技能组 $id'),
                  riskNote: _riskNoteFor(label: '技能组'),
                  assetPayload: item,
                ),
              )
              .proposal,
        ),
        overwrite: overwrite,
        changedPaths: changedPaths,
        skippedPaths: skippedPaths,
      );
    }
  }

  Future<void> _importAgents({
    required ProjectDescriptor project,
    required JsonMap bundle,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<String> builtinIds,
    required List<String> changedPaths,
    required List<String> skippedPaths,
  }) async {
    for (final rawItem in ValueReaders.mapList(bundle['agents'])) {
      final item = ValueReaders.mapValue(rawItem);
      final id = ValueReaders.stringValue(item['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      final relativePath =
          '${CustomizationRootCatalogService.agentsRoot}/$id/AGENT.md';
      if (!allowBuiltinShadow &&
          builtinIds.contains(id) &&
          !await _projectToolHostPort.entryExists(
            project.rootPath,
            relativePath,
          )) {
        skippedPaths.add(relativePath);
        continue;
      }
      await _writeCanonicalEntry(
        project: project,
        relativePath: _pathService.proposalPath(
          kind: EcosystemAssetKind.agent,
          proposalId: _pathService.defaultProposalId(
            kind: EcosystemAssetKind.agent,
            assetId: id,
          ),
        ),
        content: _encodeProposal(
          _proposalService
              .review(
                _proposalService.createDraft(
                  assetKind: EcosystemAssetKind.agent,
                  assetId: id,
                  version: ValueReaders.stringValue(item['version'], '1'),
                  summary: _summaryFor(item, fallbackLabel: '智能体 $id'),
                  riskNote: _riskNoteFor(
                    label: '智能体',
                    capabilityIds: ValueReaders.stringList(
                      item['required_capabilities'],
                    ),
                  ),
                  assetPayload: item,
                  requiredCapabilities: ValueReaders.stringList(
                    item['required_capabilities'],
                  ),
                ),
              )
              .proposal,
        ),
        overwrite: overwrite,
        changedPaths: changedPaths,
        skippedPaths: skippedPaths,
      );
    }
  }

  Future<void> _importAgentGroups({
    required ProjectDescriptor project,
    required JsonMap bundle,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<String> builtinIds,
    required List<String> changedPaths,
    required List<String> skippedPaths,
  }) async {
    for (final rawItem in ValueReaders.mapList(bundle['agent_groups'])) {
      final item = _agentGroupNormalizerService.normalizeAgentGroup(
        ValueReaders.mapValue(rawItem),
      );
      final id = ValueReaders.stringValue(item['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      final relativePath =
          '${CustomizationRootCatalogService.agentGroupsRoot}/$id/agent_group.json';
      if (!allowBuiltinShadow &&
          builtinIds.contains(id) &&
          !await _projectToolHostPort.entryExists(
            project.rootPath,
            relativePath,
          )) {
        skippedPaths.add(relativePath);
        continue;
      }
      await _writeCanonicalEntry(
        project: project,
        relativePath: _pathService.proposalPath(
          kind: EcosystemAssetKind.agentGroup,
          proposalId: _pathService.defaultProposalId(
            kind: EcosystemAssetKind.agentGroup,
            assetId: id,
          ),
        ),
        content: _encodeProposal(
          _proposalService
              .review(
                _proposalService.createDraft(
                  assetKind: EcosystemAssetKind.agentGroup,
                  assetId: id,
                  version: ValueReaders.stringValue(item['version'], '1'),
                  summary: _summaryFor(item, fallbackLabel: '智能体组 $id'),
                  riskNote: _riskNoteFor(label: '智能体组'),
                  assetPayload: item,
                ),
              )
              .proposal,
        ),
        overwrite: overwrite,
        changedPaths: changedPaths,
        skippedPaths: skippedPaths,
      );
    }
  }

  Future<void> _writeCanonicalEntry({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
    required bool overwrite,
    required List<String> changedPaths,
    required List<String> skippedPaths,
  }) async {
    final exists = await _projectToolHostPort.entryExists(
      project.rootPath,
      relativePath,
    );
    if (exists && !overwrite) {
      skippedPaths.add(relativePath);
      return;
    }
    await _projectToolHostPort.writeTextFile(
      project.rootPath,
      relativePath,
      content,
    );
    changedPaths.add(relativePath);
  }

  JsonMap _error(String error) {
    return <String, Object?>{'ok': false, 'error': error};
  }

  String _encodeProposal(EcosystemAssetProposal proposal) {
    return const JsonEncoder.withIndent('  ').convert(proposal.toJson());
  }

  String _summaryFor(JsonMap item, {required String fallbackLabel}) {
    final description = ValueReaders.stringValue(item['description']).trim();
    if (description.isNotEmpty) {
      return description;
    }
    final name = ValueReaders.stringValue(item['name']).trim();
    if (name.isNotEmpty) {
      return name;
    }
    return fallbackLabel;
  }

  String _riskNoteFor({
    required String label,
    List<String> capabilityIds = const <String>[],
  }) {
    final capabilityLabel = capabilityIds.isEmpty
        ? '未声明额外能力需求'
        : '声明能力需求：${capabilityIds.join('、')}';
    return '导入的非内置$label会先进入 proposal 生命周期，安装前需要人工确认；$capabilityLabel，且不会自动授予高风险权限。';
  }
}
