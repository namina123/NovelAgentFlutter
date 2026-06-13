import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionAgentGroupResolverService', () {
    test(
      'ordinary project still prefers extraction group for extraction task family',
      () {
        final resolver = ReferenceExtractionAgentGroupResolverService();
        final writingGroup = _group(id: 'writing-room', name: '写作组');
        final extractionGroup = _group(
          id: 'extraction-room',
          name: '提取组',
          metadata: const <String, Object?>{
            'task_family_ids': <String>[AgentTaskFamilies.referenceExtraction],
          },
        );

        final resolution = resolver.resolve(
          groupSelections: const <ProjectAgentGroupSelection>[
            ProjectAgentGroupSelection(
              groupId: 'writing-room',
              selectedByDefault: true,
            ),
            ProjectAgentGroupSelection(
              groupId: 'extraction-room',
              taskFamilyIds: <String>[AgentTaskFamilies.referenceExtraction],
            ),
          ],
          groupAssessments: <AgentGroupAvailabilityAssessment>[
            AgentGroupAvailabilityAssessment(
              group: writingGroup,
              isSupported: true,
              isDegraded: false,
              supportedMembers: writingGroup.members,
            ),
            AgentGroupAvailabilityAssessment(
              group: extractionGroup,
              isSupported: true,
              isDegraded: false,
              supportedMembers: extractionGroup.members,
            ),
          ],
          agentBindings: const <ProjectAgentBinding>[],
          agentAssessments: const <AgentAvailabilityAssessment>[],
        );

        expect(resolution.selectedGroup.id, 'extraction-room');
        expect(
          resolution.resolutionKind,
          ReferenceExtractionResolutionKinds.taskFamilyOverride,
        );
        expect(
          resolution.executionProfile.taskFamilyId,
          AgentTaskFamilies.referenceExtraction,
        );
        expect(
          resolution.executionProfile.instructionProfileId,
          ReferenceExtractionPromptProfiles.group,
        );
      },
    );

    test(
      'falls back to extraction single-agent mode instead of writing prompt',
      () {
        final resolver = ReferenceExtractionAgentGroupResolverService();

        final resolution = resolver.resolve(
          groupSelections: const <ProjectAgentGroupSelection>[
            ProjectAgentGroupSelection(
              groupId: 'writing-room',
              selectedByDefault: true,
            ),
          ],
          groupAssessments: const <AgentGroupAvailabilityAssessment>[],
          agentBindings: const <ProjectAgentBinding>[
            ProjectAgentBinding(agentId: 'writer', selectedByDefault: true),
          ],
          agentAssessments: const <AgentAvailabilityAssessment>[
            AgentAvailabilityAssessment(
              profile: AgentProfile(
                id: 'writer',
                name: '写作智能体',
                description: '默认写作者',
              ),
              isSupported: true,
            ),
          ],
        );

        expect(
          resolution.resolutionKind,
          ReferenceExtractionResolutionKinds.singleAgentFallback,
        );
        expect(
          resolution.executionProfile.executionMode,
          ReferenceExtractionExecutionModes.singleAgentFallback,
        );
        expect(
          resolution.executionProfile.instructionProfileId,
          ReferenceExtractionPromptProfiles.singleAgent,
        );
        expect(
          resolution.executionProfile.toolPermissionProfileId,
          ReferenceExtractionToolPermissionProfiles.standard,
        );
        expect(resolution.selectedGroup.metadata['task_family_ids'], <String>[
          AgentTaskFamilies.referenceExtraction,
        ]);
      },
    );
  });
}

ResolvedAgentGroupProfile _group({
  required String id,
  required String name,
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  return ResolvedAgentGroupProfile(
    id: id,
    name: name,
    description: '$name 描述',
    orchestration: 'supervised',
    metadata: metadata,
    members: const <ResolvedAgentGroupMemberProfile>[
      ResolvedAgentGroupMemberProfile(
        profile: AgentProfile(
          id: 'lead',
          name: 'Lead',
          description: 'Lead agent',
        ),
        isPrimary: true,
        isRequired: true,
      ),
    ],
  );
}
