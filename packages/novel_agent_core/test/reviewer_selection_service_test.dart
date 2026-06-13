import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewerSelectionService', () {
    test('prefers reviewer-like member inside group', () {
      const service = ReviewerSelectionService();
      final group = ResolvedAgentGroupProfile(
        id: 'room',
        name: 'room',
        description: 'test',
        orchestration: 'supervised',
        members: <ResolvedAgentGroupMemberProfile>[
          _member(
            id: 'writer',
            name: '作者',
            role: '负责正文写作',
            isPrimary: true,
          ),
          _member(
            id: 'prose_reviewer',
            name: '文风审稿',
            role: '负责审稿与结构化 review',
          ),
          _member(
            id: 'editor_in_chief',
            name: '主编',
            role: '负责编辑建议',
          ),
        ],
      );

      final selection = service.selectReviewer(group);

      expect(selection.mode, ReviewerSelectionModes.delegatedReviewer);
      expect(selection.agentId, 'prose_reviewer');
      expect(selection.isSelfReview, isFalse);
      expect(selection.rationale, 'group_reviewer_preferred');
    });

    test('falls back to critic or editor when no reviewer exists', () {
      const service = ReviewerSelectionService();
      final group = ResolvedAgentGroupProfile(
        id: 'room',
        name: 'room',
        description: 'test',
        orchestration: 'supervised',
        members: <ResolvedAgentGroupMemberProfile>[
          _member(
            id: 'writer',
            name: '作者',
            role: '负责正文写作',
            isPrimary: true,
          ),
          _member(
            id: 'editor_in_chief',
            name: '主编',
            role: '负责编辑与审核建议',
          ),
        ],
      );

      final selection = service.selectReviewer(group);

      expect(selection.mode, ReviewerSelectionModes.delegatedCriticOrEditor);
      expect(selection.agentId, 'editor_in_chief');
      expect(selection.isSelfReview, isFalse);
      expect(selection.rationale, 'critic_or_editor_fallback');
    });

    test('falls back to primary writer self-review last', () {
      const service = ReviewerSelectionService();
      final group = ResolvedAgentGroupProfile(
        id: 'room',
        name: 'room',
        description: 'test',
        orchestration: 'supervised',
        members: <ResolvedAgentGroupMemberProfile>[
          _member(
            id: 'writer',
            name: '作者',
            role: '负责正文写作',
            isPrimary: true,
          ),
          _member(
            id: 'reader',
            name: '读者',
            role: '负责读者反馈',
          ),
        ],
      );

      final selection = service.selectReviewer(group);

      expect(selection.mode, ReviewerSelectionModes.primaryWriterSelfReview);
      expect(selection.agentId, 'writer');
      expect(selection.isSelfReview, isTrue);
      expect(selection.rationale, 'primary_writer_self_review_fallback');
    });

    test('returns unavailable when group has no primary or members', () {
      const service = ReviewerSelectionService();
      const group = ResolvedAgentGroupProfile(
        id: 'room',
        name: 'room',
        description: 'test',
        orchestration: 'supervised',
        members: <ResolvedAgentGroupMemberProfile>[],
      );

      final selection = service.selectReviewer(group);

      expect(selection.mode, ReviewerSelectionModes.unavailable);
      expect(selection.agentId, isEmpty);
      expect(selection.isAvailable, isFalse);
      expect(selection.rationale, 'missing_primary_member');
    });
  });
}

ResolvedAgentGroupMemberProfile _member({
  required String id,
  required String name,
  required String role,
  bool isPrimary = false,
}) {
  return ResolvedAgentGroupMemberProfile(
    profile: AgentProfile(
      id: id,
      name: name,
      description: role,
      role: role,
    ),
    isPrimary: isPrimary,
    isRequired: true,
  );
}
