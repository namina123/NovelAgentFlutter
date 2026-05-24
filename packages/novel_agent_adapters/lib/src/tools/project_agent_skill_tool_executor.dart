import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import 'project_tool_result_factory.dart';

class ProjectAgentSkillToolExecutor {
  ProjectAgentSkillToolExecutor({
    LocalSkillPackageCatalog? skillPackageCatalog,
    LocalSkillGroupCatalog? skillGroupCatalog,
    ProjectToolResultFactory? resultFactory,
    AgentSkillSummaryService? skillSummaryService,
    AgentProfileCatalogService? agentProfileCatalogService,
  }) : _skillPackageCatalog = skillPackageCatalog ?? LocalSkillPackageCatalog(),
       _skillGroupCatalog = skillGroupCatalog ?? LocalSkillGroupCatalog(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _skillSummaryService = skillSummaryService ?? AgentSkillSummaryService(),
       _agentProfileCatalogService =
           agentProfileCatalogService ?? AgentProfileCatalogService();

  final LocalSkillPackageCatalog _skillPackageCatalog;
  final LocalSkillGroupCatalog _skillGroupCatalog;
  final ProjectToolResultFactory _resultFactory;
  final AgentSkillSummaryService _skillSummaryService;
  final AgentProfileCatalogService _agentProfileCatalogService;

  Future<JsonMap> loadAgentSkill(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 技能读取执行器只处理技能包发现、作用域过滤和结果拼装，不触碰主循环或 UI 状态。
    final agent = _resolvedAgent(arguments);
    final allSkills = await _skillPackageCatalog.loadSkillPackages(project);
    final projectSkillGroups = await _skillGroupCatalog.loadSkillGroups(project);
    final availableSkills = _skillSummaryService.buildAvailableSkillSummaries(
      agent: agent,
      allSkills: allSkills,
      availableSkillGroups: projectSkillGroups,
    );
    var skillId = ValueReaders.stringValue(arguments['skill_id']).trim();
    final query = ValueReaders.stringValue(arguments['query']).trim();
    if (skillId.isEmpty && query.isNotEmpty) {
      skillId = _skillSummaryService.selectSkillIdForQuery(
        query,
        availableSkills,
      );
    }
    final agentId = ValueReaders.stringValue(agent['id'], 'default_generalist');
    if (skillId.isEmpty) {
      return _resultFactory.notExecuted(
        '请先从 available_skills 选择与当前任务最相关的 skill_id，再调用 load_agent_skill 读取完整说明。',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
        },
      );
    }
    final allowedIds = availableSkills
        .map((skill) => ValueReaders.stringValue(skill['id']).trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!allowedIds.contains(skillId)) {
      return _resultFactory.notExecuted(
        '当前智能体不可读取该技能：$skillId',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
        },
      );
    }
    JsonMap? skillPackage;
    for (final rawSkill in allSkills) {
      final skill = ValueReaders.mapValue(rawSkill);
      if (ValueReaders.stringValue(skill['id']).trim() == skillId) {
        skillPackage = skill;
        break;
      }
    }
    if (skillPackage == null || skillPackage.isEmpty) {
      return _resultFactory.notExecuted(
        '技能包尚未安装或尚未同步到当前目录：$skillId',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
        },
      );
    }
    final instructionMarkdown = ValueReaders.stringValue(
      skillPackage['instruction_markdown'],
    ).trim();
    final instructionText = instructionMarkdown.isNotEmpty
        ? instructionMarkdown
        : _fallbackInstructionText(skillPackage);
    return _resultFactory.success(
      '已读取技能说明：${ValueReaders.stringValue(skillPackage['name'], skillId)}',
      data: <String, Object?>{
        'agent_id': agentId,
        'skill_id': skillId,
        'name': ValueReaders.stringValue(skillPackage['name'], skillId),
        'description': ValueReaders.stringValue(skillPackage['description']),
        'instructions': instructionText,
        'instruction_markdown': instructionMarkdown,
        'activation_hints': ValueReaders.stringList(
          skillPackage['activation_hints'],
        ),
        'inputs': ValueReaders.stringList(skillPackage['inputs']),
        'outputs': ValueReaders.stringList(skillPackage['outputs']),
        'required_capabilities': ValueReaders.stringList(
          skillPackage['required_capabilities'],
        ),
        'optional_capabilities': ValueReaders.stringList(
          skillPackage['optional_capabilities'],
        ),
        'preferred_output': ValueReaders.stringValue(
          skillPackage['preferred_output'],
        ),
        'safe_without_tools': ValueReaders.boolValue(
          skillPackage['safe_without_tools'],
          true,
        ),
        'resource_hints': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillPackage['resource_hints']),
        ),
        'tool_schema': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillPackage['tool_schema']),
        ),
        'source': ValueReaders.stringValue(skillPackage['source']),
        'source_scope': ValueReaders.stringValue(skillPackage['source_scope']),
        'entry_file_path': ValueReaders.stringValue(
          skillPackage['entry_file_path'],
        ),
      },
    );
  }

  JsonMap _resolvedAgent(JsonMap arguments) {
    final rawAgent = ValueReaders.mapValue(arguments['_agent']);
    if (rawAgent.isNotEmpty) {
      return rawAgent;
    }
    return _agentProfileCatalogService.fallbackDefaultAgent();
  }

  String _fallbackInstructionText(JsonMap skillPackage) {
    // 中文注释: 缺正文时仍给模型一个可执行的技能摘要，避免包格式小问题直接让流程中断。
    final lines = <String>[
      '技能名称：${ValueReaders.stringValue(skillPackage['name'], ValueReaders.stringValue(skillPackage['id']))}',
      '技能说明：${ValueReaders.stringValue(skillPackage['description'])}',
    ];
    final hints = ValueReaders.stringList(skillPackage['activation_hints']);
    if (hints.isNotEmpty) {
      lines.add('适用时机：${hints.join('；')}');
    }
    final preferredOutput = ValueReaders.stringValue(
      skillPackage['preferred_output'],
    ).trim();
    if (preferredOutput.isNotEmpty) {
      lines.add('优先输出：$preferredOutput');
    }
    return lines.join('\n');
  }
}
