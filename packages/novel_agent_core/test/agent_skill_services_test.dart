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
  });
}
