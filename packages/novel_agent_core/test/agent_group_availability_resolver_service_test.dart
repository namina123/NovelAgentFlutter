import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentGroupAvailabilityResolverService', () {
    test('supports group when only optional member is pruned', () {
      final resolver = AgentGroupAvailabilityResolverService();
      final builder = ResolvedAgentGroupProfileBuilderService();
      final group = builder.buildFromDocument(
        <String, Object?>{
          'id': 'room',
          'name': '房间',
          'agents': <String>['writer', 'reader'],
          'metadata': <String, Object?>{
            'optional_agent_ids': <String>['reader'],
          },
        },
        <AgentProfile>[
          const AgentProfile(id: 'writer', name: '作者', description: '正文'),
          const AgentProfile(id: 'reader', name: '读者', description: '反馈'),
        ],
      );
      final assessment = resolver.resolve(
        group: group,
        context: AgentAvailabilityContext(
          projectTypeId: 'novel',
          projectTraits: ProjectTraitSet.fromIds(const <String>[
            'opening_guided',
          ]),
        ),
        memberAssessments: const <AgentAvailabilityAssessment>[
          AgentAvailabilityAssessment(
            profile: AgentProfile(id: 'writer', name: '作者', description: '正文'),
            isSupported: true,
          ),
          AgentAvailabilityAssessment(
            profile: AgentProfile(id: 'reader', name: '读者', description: '反馈'),
            isSupported: false,
            reasons: <AgentAvailabilityReason>[
              AgentAvailabilityReason(
                code: AgentAvailabilityReasonCode.modeMismatch,
              ),
            ],
          ),
        ],
      );

      expect(assessment.isSupported, isTrue);
      expect(assessment.isDegraded, isFalse);
      expect(
        assessment.prunedMembers.map((member) => member.profile.id),
        <String>['reader'],
      );
    });

    test('allows degraded run only when metadata enables it', () {
      final resolver = AgentGroupAvailabilityResolverService();
      final builder = ResolvedAgentGroupProfileBuilderService();
      final group = builder.buildFromDocument(
        <String, Object?>{
          'id': 'room',
          'name': '房间',
          'agents': <String>['writer', 'reviewer'],
          'metadata': <String, Object?>{
            'allow_degraded_run': true,
            'require_primary_member': false,
            'required_agent_ids': <String>['writer', 'reviewer'],
          },
        },
        <AgentProfile>[
          const AgentProfile(id: 'writer', name: '作者', description: '正文'),
          const AgentProfile(id: 'reviewer', name: '审稿', description: '审稿'),
        ],
      );
      final assessment = resolver.resolve(
        group: group,
        context: AgentAvailabilityContext(
          projectTypeId: 'novel',
          projectTraits: ProjectTraitSet.fromIds(const <String>[
            'opening_guided',
          ]),
        ),
        memberAssessments: const <AgentAvailabilityAssessment>[
          AgentAvailabilityAssessment(
            profile: AgentProfile(id: 'writer', name: '作者', description: '正文'),
            isSupported: true,
          ),
          AgentAvailabilityAssessment(
            profile: AgentProfile(
              id: 'reviewer',
              name: '审稿',
              description: '审稿',
            ),
            isSupported: false,
          ),
        ],
      );

      expect(assessment.isSupported, isTrue);
      expect(assessment.isDegraded, isTrue);
    });
  });
}
