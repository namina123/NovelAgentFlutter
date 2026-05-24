import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentSkillToolExecutor', () {
    late Directory tempRoot;
    late Directory workspaceRoot;
    late ProjectDescriptor project;

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
    });

    tearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('loads allowed skill package and supports query fallback', () async {
      // 中文注释: 这里验证技能读取会合并内置与项目目录，并按当前智能体的声明范围过滤结果。
      final executor = ProjectAgentSkillToolExecutor(
        skillPackageCatalog: LocalSkillPackageCatalog(
          packageRootPathResolver: PackageRootPathResolver(
            workspaceRootPath: workspaceRoot.path,
          ),
        ),
      );

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
    });

    test(
      'blocks skills outside current agent scope and returns summaries',
      () async {
        // 中文注释: 这里验证越权读取会以可恢复结果返回，并附带当前允许的技能摘要列表。
        final executor = ProjectAgentSkillToolExecutor(
          skillPackageCatalog: LocalSkillPackageCatalog(
            packageRootPathResolver: PackageRootPathResolver(
              workspaceRootPath: workspaceRoot.path,
            ),
          ),
        );

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
  });
}
