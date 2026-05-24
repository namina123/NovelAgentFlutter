import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/ecosystem_entry_creation_plan.dart';

class EcosystemEntryCreationPlanService {
  EcosystemEntryCreationPlanService({
    AgentMarkdownPackageBuilderService? agentBuilderService,
    SkillMarkdownPackageBuilderService? skillBuilderService,
    AgentGroupFileCodecService? agentGroupCodecService,
    SkillGroupFileCodecService? skillGroupCodecService,
  }) : _agentBuilderService =
           agentBuilderService ?? AgentMarkdownPackageBuilderService(),
       _skillBuilderService =
           skillBuilderService ?? SkillMarkdownPackageBuilderService(),
       _agentGroupCodecService =
           agentGroupCodecService ?? AgentGroupFileCodecService(),
       _skillGroupCodecService =
           skillGroupCodecService ?? SkillGroupFileCodecService();

  final AgentMarkdownPackageBuilderService _agentBuilderService;
  final SkillMarkdownPackageBuilderService _skillBuilderService;
  final AgentGroupFileCodecService _agentGroupCodecService;
  final SkillGroupFileCodecService _skillGroupCodecService;

  EcosystemEntryCreationPlan createPlan(String kind) {
    // 中文注释: 创建计划只负责决定初始文件路径和脚手架内容，不直接写文件或操纵控制器状态。
    final stamp = DateTime.now();
    final suffix =
        '${stamp.year.toString().padLeft(4, '0')}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}';
    switch (kind) {
      case 'agents':
        final id = 'custom_agent_$suffix';
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: 'agents/$id/AGENT.md',
          content: _agentBuilderService.buildMarkdown(
            name: id,
            description: '请补充这个项目内智能体的职责与边界。',
          ),
          title: id,
        );
      case 'skills':
        final id = 'custom_skill_$suffix';
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: 'skills/$id/SKILL.md',
          content: _skillBuilderService.buildMarkdown(
            name: id,
            description: '请补充这个项目内技能的触发时机与工作流程。',
          ),
          title: id,
        );
      case 'skill-groups':
        final id = 'custom_skill_group_$suffix';
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: kind,
          relativePath: 'skill_groups/$id/skill_group.json',
          content: _skillGroupCodecService.encodeSkillGroup(<String, Object?>{
            'id': id,
            'name': id,
            'description': '请补充这个技能组的用途。',
            'source': 'project',
            'skills': const <String>[],
          }),
          title: id,
        );
      case 'agent-groups':
      default:
        final id = 'custom_agent_group_$suffix';
        return EcosystemEntryCreationPlan(
          entryId: id,
          kind: 'agent-groups',
          relativePath: 'agent_groups/$id/agent_group.json',
          content: _agentGroupCodecService.encodeAgentGroup(<String, Object?>{
            'id': id,
            'name': id,
            'description': '请补充这个智能体组的用途。',
            'source': 'project',
            'enabled': false,
            'orchestration': 'supervised',
            'agents': const <String>[],
          }),
          title: id,
        );
    }
  }
}
