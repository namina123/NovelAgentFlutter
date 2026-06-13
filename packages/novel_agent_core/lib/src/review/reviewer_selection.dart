import '../agents/resolved_agent_group_member_profile.dart';

abstract final class ReviewerSelectionModes {
  static const String delegatedReviewer = 'delegated_reviewer';
  static const String delegatedCriticOrEditor =
      'delegated_critic_or_editor';
  static const String primaryWriterSelfReview = 'primary_writer_self_review';
  static const String unavailable = 'unavailable';
}

class ReviewerSelection {
  const ReviewerSelection({
    required this.mode,
    required this.rationale,
    this.member,
  });

  final String mode;
  final String rationale;
  final ResolvedAgentGroupMemberProfile? member;

  bool get isAvailable => member != null;
  bool get isSelfReview =>
      mode == ReviewerSelectionModes.primaryWriterSelfReview;

  String get agentId => member?.profile.id ?? '';
}
