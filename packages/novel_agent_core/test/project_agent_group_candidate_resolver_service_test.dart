import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentGroupCandidateResolverService', () {
    test('prefers explicit supported project group selection', () {
      final resolver = ProjectAgentGroupCandidateResolverService();
      final group = ResolvedAgentGroupProfile(
        id: 'room',
        name: '房间',
        description: '描述',
        orchestration: 'supervised',
        members: const <ResolvedAgentGroupMemberProfile>[
          ResolvedAgentGroupMemberProfile(
            profile: AgentProfile(id: 'writer', name: '作者', description: '正文'),
            isPrimary: true,
            isRequired: true,
          ),
        ],
      );

      final resolution = resolver.resolve(
        groupSelections: const <ProjectAgentGroupSelection>[
          ProjectAgentGroupSelection(groupId: 'room', selectedByDefault: true),
        ],
        groupAssessments: <AgentGroupAvailabilityAssessment>[
          AgentGroupAvailabilityAssessment(
            group: group,
            isSupported: true,
            isDegraded: false,
            supportedMembers: group.members,
          ),
        ],
        agentBindings: const <ProjectAgentBinding>[],
        agentAssessments: const <AgentAvailabilityAssessment>[],
      );

      expect(resolution.currentSelection?.groupId, 'room');
      expect(resolution.currentGroup?.id, 'room');
      expect(resolution.derivedFromAgentBinding, isFalse);
    });

    test(
      'falls back to derived single-agent group from preferred agent binding',
      () {
        final resolver = ProjectAgentGroupCandidateResolverService();

        final resolution = resolver.resolve(
          groupSelections: const <ProjectAgentGroupSelection>[],
          groupAssessments: const <AgentGroupAvailabilityAssessment>[],
          agentBindings: const <ProjectAgentBinding>[
            ProjectAgentBinding(agentId: 'writer', selectedByDefault: true),
          ],
          agentAssessments: const <AgentAvailabilityAssessment>[
            AgentAvailabilityAssessment(
              profile: AgentProfile(
                id: 'writer',
                name: '作者',
                description: '正文',
              ),
              isSupported: true,
            ),
          ],
        );

        expect(resolution.currentGroup, isNotNull);
        expect(resolution.currentGroup!.id, 'derived_project_agent_writer');
        expect(resolution.derivedFromAgentBinding, isTrue);
      },
    );
  });
}
