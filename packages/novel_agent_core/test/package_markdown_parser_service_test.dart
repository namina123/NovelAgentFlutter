import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';
import 'dart:io';

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

    test('skill parser reads novel_agent extensions from metadata block', () {
      // 中文注释: 新规范下的技能扩展字段会放进 metadata.novel_agent，解析后仍应回到统一平面结构。
      final parser = SkillMarkdownPackageParserService();
      final parsed = parser.parsePackage('''
---
name: compact-skill
description: 用来验证扩展块解析。
resource_hints:
  references:
    - references/compact.md
metadata:
  novel_agent:
    activation_hints:
      - 用户要压缩上下文
    preferred_output: 精简执行摘要
    safe_without_tools: true
---
# Compact Skill

先给简短摘要。
''');
      expect(parsed['activation_hints'], contains('用户要压缩上下文'));
      expect(parsed['preferred_output'], '精简执行摘要');
      final extensions = ValueReaders.mapValue(
        parsed['novel_agent_extensions'],
      );
      expect(extensions['preferred_output'], '精简执行摘要');
    });

    test(
      'agent renderer writes novel_agent extensions into metadata block',
      () {
        // 中文注释: 智能体渲染应把宿主私有配置折叠进 metadata.novel_agent，减少顶层私有字段泄漏。
        final renderer = AgentMarkdownPackageRendererService();
        final markdown = renderer.renderPackage(<String, Object?>{
          'id': 'portable-agent',
          'name': 'Portable Agent',
          'description': '测试智能体',
          'role': '规划',
          'objective': '给出可执行计划',
          'system_prompt': '# Portable Agent\n\n先计划，再执行。',
          'skills': <String>['generate_outline'],
          'provider_profile': 'default',
        });
        expect(markdown, contains('metadata:'));
        expect(markdown, contains('novel_agent:'));
        expect(markdown, contains('skills:'));
        expect(
          markdown,
          isNot(contains('source_scope: project\nsource_scope: project')),
        );
      },
    );

    test(
      'builtin novel control station skill parses as a valid markdown package',
      () {
        // 中文注释: 这里直接冒烟仓库内置技能，防止真实 SKILL.md 因 frontmatter 或兼容说明改动后悄悄失效。
        final parser = SkillMarkdownPackageParserService();
        final workspaceRoot = _findWorkspaceRoot();
        final skillFile = File(
          '${workspaceRoot.path}${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skills${Platform.pathSeparator}novel-control-station${Platform.pathSeparator}SKILL.md',
        );
        final parsed = parser.parsePackage(
          skillFile.readAsStringSync(),
          fallbackId: 'novel-control-station',
        );
        expect(parsed['id'], 'novel-control-station');
        expect(parsed['name'], 'novel-control-station');
        expect(parsed['activation_hints'], contains('用户要写长篇小说'));
        final resourceHints = parsed['resource_hints'] as Map<String, Object?>;
        expect(
          (resourceHints['references'] as List<Object?>),
          contains('references/upstream-attribution.md'),
        );
        expect(
          parsed['instruction_markdown'].toString(),
          contains('## NovelAgent Compatibility'),
        );
      },
    );

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

Directory _findWorkspaceRoot() {
  // 中文注释: 测试运行目录可能在包目录或仓库根目录，这里向上回溯到包含 builtin_packages 的工作区根。
  var current = Directory.current.absolute;
  while (true) {
    final marker = Directory(
      '${current.path}${Platform.pathSeparator}builtin_packages',
    );
    if (marker.existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('未找到包含 builtin_packages 的仓库根目录。');
    }
    current = parent;
  }
}
