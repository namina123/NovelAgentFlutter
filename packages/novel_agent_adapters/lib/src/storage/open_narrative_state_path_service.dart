import '../tools/project_tool_path_policy.dart';

class OpenNarrativeStatePathService {
  OpenNarrativeStatePathService({ProjectToolPathPolicy? toolPathPolicy})
    : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolPathPolicy _toolPathPolicy;

  String profilesIndexPath() => '.novel_agent/continuity/profiles/index.json';

  String profilePath(String profileId) {
    return '.novel_agent/continuity/profiles/${_safeId(profileId, fallback: 'profile')}.json';
  }

  String claimsLogPath() => '.novel_agent/continuity/claims/claims.jsonl';

  String ledgersIndexPath() => '.novel_agent/continuity/ledgers/index.json';

  String ledgerEntriesPath(String ledgerId) {
    final cleanLedgerId = _safeId(ledgerId, fallback: 'ledger');
    return '.novel_agent/continuity/ledgers/$cleanLedgerId/entries.jsonl';
  }

  String ledgerEventsPath(String ledgerId) {
    final cleanLedgerId = _safeId(ledgerId, fallback: 'ledger');
    return '.novel_agent/continuity/ledgers/$cleanLedgerId/events.jsonl';
  }

  String reviewsIndexPath() => '.novel_agent/continuity/reviews/index.json';

  String reviewPath(String reviewId) {
    return '.novel_agent/continuity/reviews/${_safeId(reviewId, fallback: 'review')}.json';
  }

  String bindingsIndexPath() => '.novel_agent/continuity/bindings/index.json';

  String bindingPath(String bindingId) {
    return '.novel_agent/continuity/bindings/${_safeId(bindingId, fallback: 'binding')}.json';
  }

  String deliveriesIndexPath() =>
      '.novel_agent/continuity/deliveries/index.json';

  String deliveryPath(String deliveryId) {
    return '.novel_agent/continuity/deliveries/${_safeId(deliveryId, fallback: 'delivery')}.json';
  }

  String profileProposalsIndexPath() =>
      '.novel_agent/continuity/profile_proposals/index.json';

  String profileProposalPath(String proposalId) {
    return '.novel_agent/continuity/profile_proposals/${_safeId(proposalId, fallback: 'profile_proposal')}.json';
  }

  String clarificationRequestsIndexPath() =>
      '.novel_agent/continuity/clarifications/index.json';

  String clarificationRequestPath(String requestId) {
    return '.novel_agent/continuity/clarifications/${_safeId(requestId, fallback: 'clarification')}.json';
  }

  String _safeId(String value, {required String fallback}) {
    return _toolPathPolicy.safeFileName(value, fallback: fallback);
  }
}
