import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedAgentGroupProfileBuilderService', () {
    test(
      'builds resolved profile with default primary and required members',
      () {
        final builder = ResolvedAgentGroupProfileBuilderService();

        final group = builder.buildFromDocument(
          <String, Object?>{
            'id': 'room',
            'name': '房间',
            'orchestration': 'supervised',
            'agents': <String>['writer', 'reviewer'],
          },
          <AgentProfile>[
            const AgentProfile(id: 'writer', name: '作者', description: '负责正文'),
            const AgentProfile(id: 'reviewer', name: '审稿', description: '负责审稿'),
          ],
        );

        expect(group.id, 'room');
        expect(group.orchestration, 'supervised');
        expect(group.members.length, 2);
        expect(group.primaryMember?.profile.id, 'writer');
        expect(group.requiredMembers.length, 2);
        expect(group.optionalMembers, isEmpty);
      },
    );

    test('respects explicit primary and optional members from metadata', () {
      final builder = ResolvedAgentGroupProfileBuilderService();

      final group = builder.buildFromDocument(
        <String, Object?>{
          'id': 'room',
          'name': '房间',
          'agents': <String>['writer', 'reviewer', 'reader'],
          'metadata': <String, Object?>{
            'primary_agent_id': 'reviewer',
            'optional_agent_ids': <String>['reader'],
          },
        },
        <AgentProfile>[
          const AgentProfile(id: 'writer', name: '作者', description: '负责正文'),
          const AgentProfile(id: 'reviewer', name: '审稿', description: '负责审稿'),
          const AgentProfile(id: 'reader', name: '读者', description: '负责读者反馈'),
        ],
      );

      expect(group.primaryMember?.profile.id, 'reviewer');
      expect(group.optionalMembers.map((item) => item.profile.id), <String>[
        'reader',
      ]);
      expect(group.requiredMembers.map((item) => item.profile.id), <String>[
        'writer',
        'reviewer',
      ]);
    });
  });
}
