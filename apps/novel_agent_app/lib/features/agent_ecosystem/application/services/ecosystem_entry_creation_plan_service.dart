import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/ecosystem_entry_creation_plan.dart';

class EcosystemEntryCreationPlanService {
  EcosystemEntryCreationPlanService({
    EcosystemAssetProposalService? proposalService,
    EcosystemAssetPathService? pathService,
  }) : _proposalService = proposalService ?? EcosystemAssetProposalService(),
       _pathService = pathService ?? EcosystemAssetPathService();

  final EcosystemAssetProposalService _proposalService;
  final EcosystemAssetPathService _pathService;

  EcosystemEntryCreationPlan createPlan(String kind) {
    // 中文注释: 创建计划只负责决定初始文件路径和脚手架内容，不直接写文件或操纵控制器状态。
    final stamp = DateTime.now();
    final suffix =
        '${stamp.year.toString().padLeft(4, '0')}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}';
    switch (kind) {
      case 'agents':
        final id = 'custom_agent_$suffix';
        final review = _proposalService.review(
          _proposalService.createDraft(
            assetKind: EcosystemAssetKind.agent,
            assetId: id,
            version: '1',
            summary: '项目内智能体草案：$id',
            riskNote: '非内置智能体必须先作为 proposal 保存，再经过确认后安装；不会自动授予高风险权限。',
            assetPayload: <String, Object?>{
              'id': id,
              'name': id,
              'description': '请补充这个项目内智能体的职责与边界。',
              'role': '请补充角色定位',
              'objective': '请补充目标',
              'can_do': const <String>[],
              'must_not_do': const <String>[],
              'knowledge_sources': const <String>[],
              'required_capabilities': const <String>[],
              'optional_capabilities': const <String>[],
              'preferred_output': '',
              'operating_manual_markdown': '# $id\n\n请补充这个项目内智能体的操作手册。\n',
              'system_prompt': '# $id\n\n请补充这个项目内智能体的操作手册。\n',
              'source': 'project_package',
              'source_scope': 'proposal',
            },
          ),
        );
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: _pathService.proposalPath(
            kind: EcosystemAssetKind.agent,
            proposalId: review.proposal.proposalId,
          ),
          content: const JsonEncoder.withIndent(
            '  ',
          ).convert(review.proposal.toJson()),
          title: id,
        );
      case 'skills':
        final id = 'custom_skill_$suffix';
        final review = _proposalService.review(
          _proposalService.createDraft(
            assetKind: EcosystemAssetKind.skill,
            assetId: id,
            version: '1',
            summary: '项目内技能草案：$id',
            riskNote: '非内置技能必须先作为 proposal 保存，再经过确认后安装；不会自动授予高风险权限。',
            assetPayload: <String, Object?>{
              'id': id,
              'name': id,
              'description': '请补充这个项目内技能的触发时机与工作流程。',
              'instruction_markdown': '# $id\n\n请补充这个技能的说明。\n',
              'activation_hints': const <String>[],
              'inputs': const <String>[],
              'outputs': const <String>[],
              'required_capabilities': const <String>[],
              'optional_capabilities': const <String>[],
              'source': 'project_package',
              'source_scope': 'proposal',
            },
          ),
        );
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: _pathService.proposalPath(
            kind: EcosystemAssetKind.skill,
            proposalId: review.proposal.proposalId,
          ),
          content: const JsonEncoder.withIndent(
            '  ',
          ).convert(review.proposal.toJson()),
          title: id,
        );
      case 'skill-groups':
        final id = 'custom_skill_group_$suffix';
        final review = _proposalService.review(
          _proposalService.createDraft(
            assetKind: EcosystemAssetKind.skillGroup,
            assetId: id,
            version: '1',
            summary: '项目内技能组草案：$id',
            riskNote: '非内置技能组必须先作为 proposal 保存，再经过确认后安装。',
            assetPayload: <String, Object?>{
              'id': id,
              'name': id,
              'description': '请补充这个技能组的用途。',
              'version': '1',
              'source': 'proposal',
              'skills': const <String>[],
            },
          ),
        );
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: _pathService.proposalPath(
            kind: EcosystemAssetKind.skillGroup,
            proposalId: review.proposal.proposalId,
          ),
          content: const JsonEncoder.withIndent(
            '  ',
          ).convert(review.proposal.toJson()),
          title: id,
        );
      case 'agent-groups':
      default:
        final id = 'custom_agent_group_$suffix';
        final review = _proposalService.review(
          _proposalService.createDraft(
            assetKind: EcosystemAssetKind.agentGroup,
            assetId: id,
            version: '1',
            summary: '项目内智能体组草案：$id',
            riskNote: '非内置智能体组必须先作为 proposal 保存，再经过确认后安装。',
            assetPayload: <String, Object?>{
              'id': id,
              'name': id,
              'description': '请补充这个智能体组的用途。',
              'version': '1',
              'source': 'proposal',
              'enabled': false,
              'orchestration': 'supervised',
              'agents': const <String>[],
            },
          ),
        );
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: 'agent-groups',
          relativePath: _pathService.proposalPath(
            kind: EcosystemAssetKind.agentGroup,
            proposalId: review.proposal.proposalId,
          ),
          content: const JsonEncoder.withIndent(
            '  ',
          ).convert(review.proposal.toJson()),
          title: id,
        );
    }
  }
}
