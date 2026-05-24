import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Customization services', () {
    test('skill markdown renderer preserves id and name after round trip', () {
      // 中文注释: 这里验证技能包渲染后再解析，不会把显示名误丢成目录 id。
      final renderer = SkillMarkdownPackageRendererService();
      final parser = SkillMarkdownPackageParserService();

      final markdown = renderer.renderPackage(<String, Object?>{
        'id': 'outline-maker',
        'name': '大纲师',
        'description': '用于整理总纲和章纲。',
        'instruction_markdown': '# 大纲师\n\n先整理结构，再补充细节。',
      });
      final parsed = parser.parsePackage(markdown, fallbackId: 'outline-maker');

      expect(parsed['id'], 'outline-maker');
      expect(parsed['name'], '大纲师');
    });

    test(
      'preview customization bundle import reports project and builtin conflicts',
      () {
        // 中文注释: 这里验证预检结果会区分项目冲突和内置遮蔽，供 GUI/CLI 在导入前统一提示。
        final useCase = PreviewCustomizationBundleImportUseCase();
        final preview = useCase.execute(
          bundleContent: jsonEncode(<String, Object?>{
            'kind': 'novel_agent_customization_bundle',
            'title': '测试生态包',
            'skills': <Object?>[
              <String, Object?>{'id': 'project-skill', 'name': '项目技能'},
            ],
            'agents': <Object?>[
              <String, Object?>{'id': 'builtin-agent', 'name': '内置智能体覆盖'},
            ],
          }),
          overwrite: false,
          allowBuiltinShadow: false,
          projectSkills: const <JsonMap>[
            <String, Object?>{'id': 'project-skill', 'name': '已有项目技能'},
          ],
          builtinAgents: const <JsonMap>[
            <String, Object?>{'id': 'builtin-agent', 'name': '内置智能体'},
          ],
        );

        expect(preview['ok'], true);
        final items = ValueReaders.objectList(
          preview['items'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(items, hasLength(2));
        expect(items.first['status'], 'project_conflict');
        expect(items.first['action'], 'skip');
        expect(items.last['status'], 'builtin_override');
        expect(items.last['action'], 'skip_builtin');
      },
    );

    test('market index document service summarizes exported bundles', () {
      // 中文注释: 这里验证市场索引只保留摘要字段，且能正确统计四类生态条目数量。
      final service = CustomizationMarketIndexDocumentService();
      final index = service.buildLocalIndex(const <JsonMap>[
        <String, Object?>{
          'relative_path': 'exports/demo.customization.json',
          'title': '演示包',
          'description': '一个简单测试包。',
          'agents': <Object?>[
            <String, Object?>{'id': 'a'},
          ],
          'skills': <Object?>[
            <String, Object?>{'id': 's1'},
            <String, Object?>{'id': 's2'},
          ],
          'skill_groups': <Object?>[
            <String, Object?>{'id': 'sg'},
          ],
          'agent_groups': const <Object?>[],
        },
      ]);

      final entries = ValueReaders.objectList(
        index['entries'],
      ).map(ValueReaders.mapValue).toList(growable: false);
      expect(entries, hasLength(1));
      expect(entries.first['agent_count'], 1);
      expect(entries.first['skill_count'], 2);
      expect(entries.first['skill_group_count'], 1);
      expect(entries.first['agent_group_count'], 0);
    });
  });
}
