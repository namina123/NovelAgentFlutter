import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Agent services', () {
    final profileCatalog = AgentProfileCatalogService();
    final groupCatalog = AgentGroupCatalogService();
    final planService = AgentDelegationPlanService();
    final packageService = SubAgentRunPackageService();
    final briefService = AgentCollaborationBriefService();

    test('normalizes builtin profiles and groups from json', () {
      // 中文注释: 这里验证旧项目 JSON 文本迁入后仍会得到稳定 id、列表和默认字段。
      final profiles = profileCatalog.builtinProfilesFromJson('''
{
  "profiles": [
    {
      "id": " writer ",
      "name": "作者",
      "role": "负责正文",
      "skills": "draft, polish，draft",
      "temperature": 5
    }
  ]
}
''');
      final groups = groupCatalog.builtinGroupsFromJson('''
{
  "groups": [
    {
      "id": "room",
      "name": "房间",
      "orchestration": "unknown",
      "agents": ["writer", "writer"]
    }
  ]
}
''');

      expect(profiles.single['id'], 'writer');
      expect(profiles.single['skills'], <String>['draft', 'polish']);
      expect(profiles.single['temperature'], 2.0);
      expect(groups.single['orchestration'], 'supervised');
      expect(groups.single['agents'], <String>['writer']);
    });

    test('builds delegation plan and sub-agent package', () {
      // 中文注释: 这里验证编排规则只输出可审计计划和运行包，不泄露完整主会话。
      final agents = <Object?>[
        <String, Object?>{
          'id': 'writer',
          'name': '作者',
          'role': '作者',
          'skills': <String>['chapter_drafting_method'],
          'skill_groups': <String>['project_io'],
        },
      ];
      final group = <String, Object?>{
        'id': 'room',
        'name': '房间',
        'orchestration': 'supervised',
        'agents': <String>['writer'],
      };
      final plan = planService.buildDelegationPlan(
        group,
        agents,
        request: <String, Object?>{'intent': 'draft', 'prompt': '写一段追逐戏'},
        createdAt: '2026-05-23T10:00:00Z',
      );
      final package = packageService.buildSubAgentRunPackage(
        group,
        agents,
        <String, Object?>{
          'task': '写一段追逐戏',
          'source_paths': <String>['chapters/ch01.md'],
        },
        mainContext: <String, Object?>{
          'project_title': '测试项目',
          'intent': 'draft',
        },
        createdAt: '2026-05-23T10:00:00Z',
      );
      final brief = briefService.collaborationBrief(group, agents);

      expect(plan['ok'], isTrue);
      expect((plan['tasks'] as List<Object?>).length, 1);
      expect(package['ok'], isTrue);
      expect((package['messages'] as List<Object?>).length, 3);
      expect(brief, contains('writer'));
    });
  });
}
