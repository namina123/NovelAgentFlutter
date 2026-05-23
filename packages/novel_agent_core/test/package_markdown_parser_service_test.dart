import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Package entry file names', () {
    test('agent and skill entry files are case-insensitive', () {
      // 中文注释: 这里验证包入口识别不受大小写影响，符合用户对跨平台包结构的要求。
      final service = PackageEntryFileNameService();
      expect(service.isAgentEntryFile('AGENT.md'), isTrue);
      expect(service.isAgentEntryFile('agent.MD'), isTrue);
      expect(service.isSkillEntryFile('SKILL.md'), isTrue);
      expect(service.isSkillEntryFile('skill.md'), isTrue);
    });
  });

  group('Markdown package parsers', () {
    test('agent parser reads metadata block and body', () {
      // 中文注释: 智能体 Markdown 包会把首个 agent/json 代码块视为元数据，剩余正文作为 system prompt。
      final parser = AgentMarkdownPackageParserService();
      final parsed = parser.parsePackage('''
```agent
{"id":"demo_agent","name":"示例智能体","role":"负责章节草稿"}
```
# 示例智能体

你要按需读取技能，并把真实写入交给工具。
''');
      expect(parsed['id'], 'demo_agent');
      expect(parsed['name'], '示例智能体');
      expect(parsed['system_prompt'].toString(), contains('真实写入交给工具'));
    });

    test('agent parser supports yaml frontmatter and standard fields', () {
      // 中文注释: 项目标准智能体包使用 frontmatter 表达目标、边界和能力，正文作为操作说明。
      final parser = AgentMarkdownPackageParserService();
      final parsed = parser.parsePackage('''
---
name: planner-agent
description: 此智能体应在需要规划章节任务时使用。
role: 章节规划者
objective: 把复杂任务拆成可执行章节计划。
kpis:
  - 计划清晰
  - 阶段完整
can_do:
  - 生成章节计划
must_not_do:
  - 直接伪造已经读取过的项目内容
knowledge_sources:
  - references/planning.md
required_capabilities:
  - conversation_context
optional_capabilities:
  - project_read
output_schema_path: schemas/plan.schema.json
preferred_output: JSON 计划对象
reflection_mode: before_commit
resource_hints:
  references:
    - references/planning.md
  schemas:
    - schemas/plan.schema.json
---
# 章节规划者

先收束目标，再拆步骤，最后检查阶段依赖。
''', fallbackId: 'planner-agent');
      expect(parsed['id'], 'planner-agent');
      expect(parsed['objective'], contains('拆成可执行章节计划'));
      expect(parsed['must_not_do'], contains('直接伪造已经读取过的项目内容'));
      expect(parsed['output_schema_path'], 'schemas/plan.schema.json');
      expect(parsed['reflection_mode'], 'before_commit');
      final resourceHints = parsed['resource_hints'] as Map<String, Object?>;
      expect(
        (resourceHints['schemas'] as List<Object?>),
        contains('schemas/plan.schema.json'),
      );
    });

    test('skill parser supports raw json and markdown body', () {
      // 中文注释: 技能包既支持 JSON，也支持 Markdown 包结构，便于旧资源平滑迁移。
      final parser = SkillMarkdownPackageParserService();
      final jsonParsed = parser.parsePackage(
        '{"id":"demo_skill","name":"示例技能","description":"说明"}',
      );
      final markdownParsed = parser.parsePackage('''
```skill
{"id":"demo_markdown_skill","name":"Markdown 技能"}
```
# Markdown 技能

请先判断用户是否在要方案，再决定是否列选项。
''');
      expect(jsonParsed['id'], 'demo_skill');
      expect(markdownParsed['id'], 'demo_markdown_skill');
      expect(
        markdownParsed['instruction_markdown'].toString(),
        contains('请先判断用户是否在要方案'),
      );
    });

    test('skill parser supports yaml frontmatter and capability fields', () {
      // 中文注释: 这里验证标准技能包 frontmatter 能被解析，并保留能力依赖和资源提示信息。
      final parser = SkillMarkdownPackageParserService();
      final parsed = parser.parsePackage('''
---
name: example-skill
description: 此技能应在需要稳态规划时使用。
activation_hints:
  - 用户要方案
  - 用户要计划
required_capabilities:
  - project_read
optional_capabilities:
  - present_user_options
safe_without_tools: true
resource_hints:
  references:
    - references/patterns.md
  scripts:
    - scripts/plan_builder.py
---
# 示例技能

先识别目标，再按阶段输出方案。
''');
      expect(parsed['id'], 'example-skill');
      expect(parsed['activation_hints'], contains('用户要方案'));
      expect(parsed['required_capabilities'], contains('project_read'));
      final resourceHints = parsed['resource_hints'] as Map<String, Object?>;
      expect(
        (resourceHints['references'] as List<Object?>),
        contains('references/patterns.md'),
      );
    });

    test('skill validator warns on risky coupling', () {
      // 中文注释: 技能校验会提醒“看起来绑死工具”的结构，帮助我们提前发现生态兼容风险。
      final validator = SkillPackageValidatorService();
      final result = validator.validate(<String, Object?>{
        'id': 'Demo Skill',
        'name': '示例技能',
        'description': '说明',
        'instruction_markdown': '正文',
        'required_capabilities': <String>['edit_file'],
        'optional_capabilities': <String>['edit_file'],
        'safe_without_tools': false,
      });
      expect(result['ok'], isFalse);
      expect((result['errors'] as List<Object?>).join('\n'), contains('不能重复'));
    });

    test('agent validator requires role objective and prompt', () {
      // 中文注释: 智能体校验会拒绝只有名字却没有目标、边界和操作说明的空壳包。
      final validator = AgentPackageValidatorService();
      final result = validator.validate(<String, Object?>{
        'name': '示例智能体',
        'description': '说明',
        'role': '',
        'objective': '',
        'system_prompt': '',
      });
      expect(result['ok'], isFalse);
      final errors = (result['errors'] as List<Object?>).join('\n');
      expect(errors, contains('role'));
      expect(errors, contains('objective'));
      expect(errors, contains('system_prompt'));
    });
  });
}
