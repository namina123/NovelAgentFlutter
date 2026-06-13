import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentSkillToolExecutor', () {
    late Directory tempRoot;
    late Directory workspaceRoot;
    late ProjectDescriptor project;
    late ProjectAgentSkillLoadoutRepository loadoutRepository;
    late ProjectAgentSkillRuntimeLoadoutService runtimeLoadoutService;
    late ProjectAgentSkillToolExecutor Function() buildExecutor;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('novel-agent-skill-');
      workspaceRoot = Directory(
        '${tempRoot.path}${Platform.pathSeparator}workspace',
      )..createSync(recursive: true);
      File(
        '${workspaceRoot.path}${Platform.pathSeparator}agent.md',
      ).writeAsStringSync('# marker');
      final builtinSkillDir = Directory(
        '${workspaceRoot.path}${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skills${Platform.pathSeparator}generate_outline',
      )..createSync(recursive: true);
      File(
        '${builtinSkillDir.path}${Platform.pathSeparator}SKILL.md',
      ).writeAsStringSync('''---
name: generate-outline
description: 用于搭建结构化大纲
activation_hints:
  - 需要先搭结构再写正文
preferred_output: 多层级大纲
---

# 大纲生成

先搭结构，再写正文。
''');
      final projectRoot = Directory(
        '${tempRoot.path}${Platform.pathSeparator}project',
      )..createSync(recursive: true);
      final customSkillDir = Directory(
        '${projectRoot.path}${Platform.pathSeparator}skills${Platform.pathSeparator}custom_style_review',
      )..createSync(recursive: true);
      File(
        '${customSkillDir.path}${Platform.pathSeparator}SKILL.md',
      ).writeAsStringSync('''---
name: custom-style-review
description: 检查风格一致性
activation_hints:
  - 需要检查文风时使用
---

# 风格审稿

给出文风问题和修改建议。
''');
      project = ProjectDescriptor(
        id: 'demo',
        name: 'Demo',
        rootPath: projectRoot.path,
        projectType: 'novel',
      );
      loadoutRepository = ProjectAgentSkillLoadoutRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
      runtimeLoadoutService = ProjectAgentSkillRuntimeLoadoutService(
        loadoutRepository: loadoutRepository,
      );
      buildExecutor = () {
        return ProjectAgentSkillToolExecutor(
          skillPackageCatalog: LocalSkillPackageCatalog(
            packageRootPathResolver: PackageRootPathResolver(
              workspaceRootPath: workspaceRoot.path,
            ),
          ),
          runtimeLoadoutService: runtimeLoadoutService,
        );
      };
    });

    tearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('loads allowed skill package and supports query fallback', () async {
      // 中文注释: 这里验证技能读取会合并内置与项目目录，并按当前智能体的声明范围过滤结果。
      final executor = buildExecutor();

      final result = await executor.loadAgentSkill(project, <String, Object?>{
        'query': '先搭好章纲结构',
        '_agent': <String, Object?>{
          'id': 'default_generalist',
          'skills': <String>['generate_outline'],
        },
      });

      expect(result['ok'], isTrue);
      expect(result['skill_id'], 'generate_outline');
      expect(result['instructions'], contains('先搭结构'));
      expect(result['detail_level'], 'summary');
      expect(result.containsKey('instruction_markdown'), isFalse);
      expect(
        result['entry_file_path'],
        'builtin://skills/generate_outline/SKILL.md',
      );
      expect(
        ValueReaders.stringValue(result['entry_file_path']),
        isNot(contains(tempRoot.path)),
      );
    });

    test(
      'blocks skills outside current agent scope and returns summaries',
      () async {
        // 中文注释: 这里验证越权读取会以可恢复结果返回，并附带当前允许的技能摘要列表。
        final executor = buildExecutor();

        final result = await executor.loadAgentSkill(project, <String, Object?>{
          'skill_id': 'custom_style_review',
          '_agent': <String, Object?>{
            'id': 'default_generalist',
            'skills': <String>['generate_outline'],
          },
        });

        expect(result['ok'], isFalse);
        expect(result['not_executed'], isTrue);
        expect((result['available_skills'] as List<Object?>), hasLength(1));
      },
    );

    test(
      'supports explicit full skill loading for long instructions',
      () async {
        // 中文注释: 默认摘要模式省上下文，但调用方仍可在确实需要时请求 full 版本正文。
        final executor = buildExecutor();

        final result = await executor.loadAgentSkill(project, <String, Object?>{
          'skill_id': 'generate_outline',
          'detail_level': 'full',
          '_agent': <String, Object?>{
            'id': 'default_generalist',
            'skills': <String>['generate_outline'],
          },
        });

        expect(result['ok'], isTrue);
        expect(result['detail_level'], 'full');
        expect(result['instruction_markdown'], contains('# 大纲生成'));
        expect(
          ValueReaders.intValue(result['instruction_character_count']),
          greaterThan(10),
        );
        expect(
          result['entry_file_path'],
          'builtin://skills/generate_outline/SKILL.md',
        );
      },
    );

    test(
      'returns project-relative locator for project skill packages',
      () async {
        await loadoutRepository.saveLoadouts(project, const <AgentSkillLoadout>[
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            extraSkillIds: <String>['custom_style_review'],
          ),
        ]);
        final executor = buildExecutor();

        final result = await executor.loadAgentSkill(project, <String, Object?>{
          'skill_id': 'custom_style_review',
          '_agent': <String, Object?>{
            'id': 'default_generalist',
            'skills': const <String>[],
          },
        });

        expect(result['ok'], isTrue);
        expect(
          result['entry_file_path'],
          'skills/custom_style_review/SKILL.md',
        );
        expect(
          ValueReaders.stringValue(result['entry_file_path']),
          isNot(contains(tempRoot.path)),
        );
      },
    );

    test('supports reading declared skill references on demand', () async {
      // 中文注释: 这里验证 skill 的 reference 文件会按声明清单开放，而不是只能读摘要或整份正文。
      final builtinSkillDir = Directory(
        '${workspaceRoot.path}${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skills${Platform.pathSeparator}novel_control',
      )..createSync(recursive: true);
      File(
        '${builtinSkillDir.path}${Platform.pathSeparator}SKILL.md',
      ).writeAsStringSync('''---
id: novel-control
name: novel-control
description: 长篇控制技能
resource_hints:
  references:
    - references/method.md
---

# 控制技能

摘要正文。
''');
      final referenceDir = Directory(
        '${builtinSkillDir.path}${Platform.pathSeparator}references',
      )..createSync(recursive: true);
      File(
        '${referenceDir.path}${Platform.pathSeparator}method.md',
      ).writeAsStringSync('# 方法\n\n先检查结构，再修正文风。');
      final executor = buildExecutor();

      final result = await executor.loadAgentSkill(project, <String, Object?>{
        'skill_id': 'novel-control',
        'reference_path': 'references/method.md',
        '_agent': <String, Object?>{
          'id': 'default_generalist',
          'skills': <String>['novel-control'],
        },
      });

      expect(result['ok'], isTrue);
      expect(result['detail_level'], 'reference');
      expect(result['reference_path'], 'references/method.md');
      expect(result['reference_content'], contains('先检查结构'));
    });

    test(
      'uses project loadout to override agent default available skills',
      () async {
        await loadoutRepository.saveLoadouts(project, const <AgentSkillLoadout>[
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            extraSkillIds: <String>['custom_style_review'],
            disabledSkillIds: <String>['generate_outline'],
          ),
        ]);
        final executor = buildExecutor();

        final preview = await executor.loadAgentSkill(
          project,
          <String, Object?>{
            '_agent': <String, Object?>{
              'id': 'default_generalist',
              'skills': <String>['generate_outline'],
            },
          },
        );
        final availableSkills = (preview['available_skills'] as List<Object?>)
            .map(ValueReaders.mapValue)
            .toList(growable: false);

        expect(preview['ok'], isFalse);
        expect(preview['resolved_loadout_source'], 'project_selection');
        expect(preview['resolved_skill_ids'], <String>['custom_style_review']);
        expect(availableSkills, hasLength(1));
        expect(availableSkills.single['id'], 'custom_style_review');
      },
    );
  });
}
