import '../../common/json_types.dart';
import '../../common/value_readers.dart';

class NarrativeProfileAuditEvent {
  const NarrativeProfileAuditEvent({
    required this.eventId,
    required this.eventType,
    this.proposalId = '',
    this.profileId = '',
    this.relatedProposalId = '',
    this.relatedProfileId = '',
    this.summary = '',
    this.metadata = const <String, Object?>{},
  });

  final String eventId;
  final String eventType;
  final String proposalId;
  final String profileId;
  final String relatedProposalId;
  final String relatedProfileId;
  final String summary;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: 审计事件保持开放 metadata，方便后续 repository/投影层附加额外上下文。
    return <String, Object?>{
      'event_id': eventId,
      'event_type': eventType,
      'proposal_id': proposalId,
      'profile_id': profileId,
      'related_proposal_id': relatedProposalId,
      'related_profile_id': relatedProfileId,
      'summary': summary,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
