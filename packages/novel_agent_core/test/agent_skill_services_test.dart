import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Agent skill services', () {
    test(
      'expands direct skills and skill groups while filtering builtin tools',
      () {
        // 中文注释: 这里验证智能体技能作用域会展开技能组，但不会把工具 ID 混成技能。
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
