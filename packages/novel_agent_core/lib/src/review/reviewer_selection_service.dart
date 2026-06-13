import '../agents/resolved_agent_group_member_profile.dart';
import '../agents/resolved_agent_group_profile.dart';
import 'reviewer_selection.dart';

class ReviewerSelectionService {
  const ReviewerSelectionService();

  ReviewerSelection selectReviewer(ResolvedAgentGroupProfile group) {
    final reviewer = _firstMatchingMember(group.members, _isReviewerLike);
    if (reviewer != null) {
      return ReviewerSelection(
        mode: ReviewerSelectionModes.delegatedReviewer,
        member: reviewer,
        rationale: 'group_reviewer_preferred',
      );
    }

    final criticOrEditor = _firstMatchingMember(
      group.members,
      _isCriticOrEditorLike,
    );
    if (criticOrEditor != null) {
      return ReviewerSelection(
        mode: ReviewerSelectionModes.delegatedCriticOrEditor,
        member: criticOrEditor,
        rationale: 'critic_or_editor_fallback',
      );
    }

    final primaryMember = group.primaryMember;
    if (primaryMember != null) {
      return ReviewerSelection(
        mode: ReviewerSelectionModes.primaryWriterSelfReview,
        member: primaryMember,
        rationale: 'primary_writer_self_review_fallback',
      );
    }

    return const ReviewerSelection(
      mode: ReviewerSelectionModes.unavailable,
      rationale: 'missing_primary_member',
    );
  }

  ResolvedAgentGroupMemberProfile? _firstMatchingMember(
    List<ResolvedAgentGroupMemberProfile> members,
    bool Function(ResolvedAgentGroupMemberProfile member) matcher,
  ) {
    for (final member in members) {
      if (matcher(member)) {
        return member;
      }
    }
    return null;
  }

  bool _isReviewerLike(ResolvedAgentGroupMemberProfile member) {
    return _containsAnyToken(member, const <String>[
      'reviewer',
      'review',
      '审稿',
      '复核',
      'prose_reviewer',
    ]);
  }

  bool _isCriticOrEditorLike(ResolvedAgentGroupMemberProfile member) {
    return _containsAnyToken(member, const <String>[
      'critic',
      'critique',
      'editor',
      '编辑',
      '主编',
    ]);
  }

  bool _containsAnyToken(
    ResolvedAgentGroupMemberProfile member,
    List<String> tokens,
  ) {
    final haystack = <String>[
      member.profile.id,
      member.profile.name,
      member.profile.role,
      member.profile.description,
    ].join('\n').toLowerCase();
    for (final token in tokens) {
      if (haystack.contains(token.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
