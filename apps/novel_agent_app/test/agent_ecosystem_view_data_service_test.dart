import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/models/agent_ecosystem_snapshot.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'prefers display_name aliases for skill-group and agent-group members',
    () {
      const service = AgentEcosystemViewDataService();
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
      expect(viewData.entries.single.memberLabels, <String>['综合创作智能体', '读者视角']);
    },
  );
}
