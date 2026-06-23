import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Agent skill services', () {
    test(
      'expands direct skills and skill groups while filtering builtin tools',
      () {
        // 中文注释: 这里验证兼容入口仍会返回最终技能集合，并把工具 ID 过滤掉。
        final scopeService = AgentSkillScopeService();
        final declared = scopeService.declaredSkillIds(<String, Object?>{
          'skills': <String>['chapter_drafting_method', 'read_project_file'],
          'skill_groups': <String>['memory_tools'],
        });

        expect(declared, <String>[
          'chapter_drafting_method',
          'summarize_chapter',
          'memory_maintenance',
          'check_continuity',
        ]);
      },
    );

    test('filters unavailable skills through resolver-backed facade', () {
      final scopeService = AgentSkillScopeService();
      final enabled = scopeService.enabledSkillIds(
        <String, Object?>{
          'skills': <String>['chapter_drafting_method', 'generate_outline'],
          'skill_groups': <String>['memory_tools'],
        },
        availableSkillIds: const <String>[
          'generate_outline',
          'memory_maintenance',
          'check_continuity',
        ],
      );

      expect(
        enabled,
        <String>['generate_outline', 'memory_maintenance', 'check_continuity'],
      );
    });

    test('builds available summaries and matches query in Chinese', () {
      // 中文注释: 这里验证摘要列表与查询匹配都能在中文任务描述下选中最合适的技能。
      final summaryService = AgentSkillSummaryService();
      final summaries = summaryService.buildAvailableSkillSummaries(
        agent: <String, Object?>{
          'skills': <String>['chapter_drafting_method', 'generate_outline'],
        },
        allSkills: <Object?>[
          <String, Object?>{
            'id': 'chapter_drafting_method',
            'name': '章节拟写',
            'description': '用于正文草稿写作。',
            'activation_hints': <String>['需要写章节正文时使用'],
          },
          <String, Object?>{
            'id': 'generate_outline',
            'name': '大纲生成',
            'description': '用于总纲、卷纲、章纲整理。',
            'activation_hints': <String>['需要先搭结构再写正文'],
          },
        ],
      );

      expect(summaries, hasLength(2));
      expect(
        summaryService.selectSkillIdForQuery('先整理章纲结构', summaries),
        'generate_outline',
      );
    });

    test(
      'resolves snake_case skill references against kebab-case package catalog',
      () {
        // 中文注释: 生产环境里包经 SKILL.md 解析得到 kebab id（如 generate-outline），
        // 而智能体文档/技能组/路由策略历史上用 snake_case 引用（如 generate_outline）。
        // 这里直接复现这个跨形态场景，确认归一化后技能不会被错误判成 unavailable。
        final summaryService = AgentSkillSummaryService();
        final summaries = summaryService.buildAvailableSkillSummaries(
          agent: <String, Object?>{
            'skills': <String>['generate_outline', 'chapter_drafting_method'],
          },
          allSkills: <Object?>[
            <String, Object?>{
              'id': 'generate-outline',
              'name': '大纲生成',
              'description': '用于总纲、卷纲、章纲整理。',
            },
            <String, Object?>{
              'id': 'chapter-drafting-method',
              'name': '章节拟写',
              'description': '用于正文草稿写作。',
            },
          ],
        );

        // 两个技能都必须出现在摘要里——修复前它们会被 availableSet 过滤掉。
        expect(summaries, hasLength(2));
        final ids = summaries
            .map((summary) => ValueReaders.stringValue(summary['id']))
            .toSet();
        expect(ids, contains('generate_outline'));
        expect(ids, contains('chapter_drafting_method'));
      },
    );

    test(
      'conflict policy keeps snake_case entry enabled when catalog is kebab-case',
      () {
        // 中文注释: 直接验证冲突策略层：snake 引用 + kebab 已安装集合，不应产生 unavailableSkill。
        final resolver = AgentSkillLoadoutResolverService();
        final resolved = resolver.resolveAgentDocument(
          <String, Object?>{
            'skills': <String>['check_continuity', 'summarize_chapter'],
          },
          availableSkillIds: const <String>[
            'check-continuity',
            'summarize-chapter',
          ],
        );
        final issueCodes = resolved.issues.map((issue) => issue.code).toSet();
        expect(issueCodes, isNot(contains(AgentSkillLoadoutIssueCode.unavailableSkill)));
        expect(resolved.finalSkillIds.toSet(), {
          'check_continuity',
          'summarize_chapter',
        });
      },
    );
  });
}
