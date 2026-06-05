import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/models/agent_ecosystem_snapshot.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart';
import 'package:novel_agent_app/shared/services/runtime_exposure_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'prefers display_name aliases for skill-group and agent-group members',
    () {
      final service = AgentEcosystemViewDataService();
      final snapshot = AgentEcosystemSnapshot(
        activeTabId: 'agent-groups',
        selectedEntryIds: const <String, String>{'agent-groups': 'group_1'},
        agents: const <JsonMap>[],
        skills: const <JsonMap>[],
        skillGroups: const <JsonMap>[
          <String, Object?>{
            'id': 'project_io',
            'display_name': '项目资料与归档方法',
            'skills': <String>['artifact_routing'],
          },
        ],
        agentGroups: const <JsonMap>[
          <String, Object?>{
            'id': 'group_1',
            'display_name': '可选审稿室',
            'agents': <String>['default_generalist', 'reader_lens'],
            'members': <Object?>[
              <String, Object?>{
                'agent_id': 'default_generalist',
                'display_name': '综合创作智能体',
              },
              <String, Object?>{
                'agent_id': 'reader_lens',
                'display_name': '读者视角',
              },
            ],
          },
        ],
      );

      final viewData = service.build(snapshot);

      expect(viewData.entries.single.title, '可选审稿室');
      expect(viewData.entries.single.memberLabels, <String>[
        '综合创作智能体 · 主智能体',
        '读者视角',
      ]);
      expect(viewData.entries.single.canDuplicateBuiltin, isTrue);
      expect(viewData.entries.single.badge, '内置资产');
      expect(
        viewData.entries.single.validationIssues,
        contains('还没有显式设置主智能体，当前只会回退到首成员。'),
      );
    },
  );

  test('projects public and diagnostic ecosystem entry exposure', () {
    final snapshot = AgentEcosystemSnapshot(
      activeTabId: 'agents',
      selectedEntryIds: const <String, String>{'agents': 'agent_editor'},
      agents: const <JsonMap>[
        <String, Object?>{
          'id': 'agent_editor',
          'display_name': '审阅智能体',
          'description': '负责结构审阅与表达修订。',
          'source_scope': 'project',
          'entry_file_path': r'D:\workspace\agent_editor\AGENT.md',
          'project_relative_path': r'packages/agents/agent_editor/AGENT.md',
        },
      ],
      skills: const <JsonMap>[],
      skillGroups: const <JsonMap>[],
      agentGroups: const <JsonMap>[],
    );

    final standard = AgentEcosystemViewDataService().build(snapshot);
    final diagnostic = AgentEcosystemViewDataService(
      exposureTier: RuntimeExposureTier.diagnostic,
    ).build(snapshot);

    expect(standard.entries.single.subtitle, isEmpty);
    expect(
      standard.entries.single.metadataRows.map((row) => row.label),
      isNot(contains('项目内路径')),
    );
    expect(
      standard.entries.single.metadataRows.map((row) => row.label),
      isNot(contains('源文件')),
    );

    expect(diagnostic.entries.single.subtitle, 'agent_editor');
    expect(
      diagnostic.entries.single.metadataRows.map((row) => row.label),
      containsAll(<String>['项目内路径', '源文件']),
    );
  });

  test(
    'projects proposal source labels and validation summaries for skill groups',
    () {
      final snapshot = AgentEcosystemSnapshot(
        activeTabId: 'skill-groups',
        selectedEntryIds: const <String, String>{
          'skill-groups': 'custom_group',
        },
        agents: const <JsonMap>[],
        skills: const <JsonMap>[],
        skillGroups: const <JsonMap>[
          <String, Object?>{
            'id': 'custom_group',
            'name': '自定义技能组',
            'description': '',
            'source': 'proposal',
            'project_relative_path':
                '.novel_agent/ecosystem/proposals/skill-group/custom_group.json',
            'skills': <String>[],
          },
        ],
        agentGroups: const <JsonMap>[],
      );

      final entry = AgentEcosystemViewDataService()
          .build(snapshot)
          .entries
          .single;

      expect(entry.badge, '项目草案');
      expect(entry.isEditable, isTrue);
      expect(entry.canDuplicateBuiltin, isFalse);
      expect(entry.permissionBoundarySummary, contains('技能组只定义一组可复用技能'));
      expect(
        entry.validationIssues,
        contains('建议至少声明一个 skill，避免空技能组进入 proposal 流程。'),
      );
    },
  );
}
