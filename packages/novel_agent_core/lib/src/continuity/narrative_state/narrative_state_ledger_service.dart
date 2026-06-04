import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_claim_disposition.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ledger_entry.dart';
import 'narrative_ledger_event.dart';
import 'narrative_ref.dart';
import 'narrative_semantic_review.dart';
import 'narrative_source_ref.dart';
import 'narrative_state_claim.dart';
import 'narrative_state_ledger.dart';
import 'semantic_review_finding.dart';
import 'semantic_review_recommended_disposition.dart';
import 'semantic_review_severity.dart';

class NarrativeStateLedgerMutationResult {
  const NarrativeStateLedgerMutationResult({
    required this.ledger,
    this.primaryEntry,
    this.emittedEvents = const <NarrativeLedgerEvent>[],
    this.relatedEntryIds = const <String>[],
  });

  final NarrativeStateLedger ledger;
  final NarrativeLedgerEntry? primaryEntry;
  final List<NarrativeLedgerEvent> emittedEvents;
  final List<String> relatedEntryIds;
}

class NarrativeStateLedgerReviewRecommendation {
  const NarrativeStateLedgerReviewRecommendation({
    required this.review,
    this.acceptedEntries = const <NarrativeLedgerEntry>[],
    this.questionedEntries = const <NarrativeLedgerEntry>[],
    this.suggestedClaims = const <NarrativeStateClaim>[],
    this.findings = const <SemanticReviewFinding>[],
    this.unresolvedAcceptedClaimIds = const <String>[],
    this.unresolvedQuestionedClaimIds = const <String>[],
    this.requiresManualAttention = false,
    this.relatedRefs = const <NarrativeRef>[],
  });

  final NarrativeSemanticReview review;
  final List<NarrativeLedgerEntry> acceptedEntries;
  final List<NarrativeLedgerEntry> questionedEntries;
  final List<NarrativeStateClaim> suggestedClaims;
  final List<SemanticReviewFinding> findings;
  final List<String> unresolvedAcceptedClaimIds;
  final List<String> unresolvedQuestionedClaimIds;
  final bool requiresManualAttention;
  final List<NarrativeRef> relatedRefs;
}

class NarrativeStateLedgerService {
  const NarrativeStateLedgerService();

  NarrativeStateLedgerMutationResult submit({
    required NarrativeStateLedger ledger,
    required NarrativeStateClaim claim,
    NarrativeClaimDisposition initialDisposition =
        NarrativeClaimDisposition.observed,
    NarrativeSourceRef? source,
    String entryId = '',
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String recordedAt = '',
    String note = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    _ensureClaimIsValid(claim);
    _ensureSubmissionDisposition(initialDisposition);

    final entrySource = source ?? claim.source;
    final resolvedEntryId = _resolveEntryId(
      ledger: ledger,
      claim: claim,
      requestedEntryId: entryId,
    );
    final entryEvidence = _mergeEvidenceRefs(claim.evidenceRefs, evidenceRefs);
    final event = _buildEvent(
      eventType: 'claim_submitted',
      disposition: initialDisposition,
      source: entrySource,
      entryId: resolvedEntryId,
      evidenceRefs: entryEvidence,
      summary: note.isNotEmpty ? note : 'claim 已提交到 narrative state ledger。',
      occurredAt: recordedAt,
      metadata: <String, Object?>{
        'claim_id': claim.claimId,
        'claim_namespace': claim.claimNamespace,
      },
    );
    final entry = NarrativeLedgerEntry(
      entryId: resolvedEntryId,
      claim: claim,
      disposition: initialDisposition,
      source: entrySource,
      evidenceRefs: entryEvidence,
      events: <NarrativeLedgerEvent>[event],
      recordedAt: recordedAt,
      note: note,
      schemaVersion: claim.schemaVersion,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
    final updatedLedger = ledger.copyWith(
      entries: <NarrativeLedgerEntry>[...ledger.entries, entry],
      events: <NarrativeLedgerEvent>[...ledger.events, event],
    );
    return NarrativeStateLedgerMutationResult(
      ledger: updatedLedger,
      primaryEntry: entry,
      emittedEvents: <NarrativeLedgerEvent>[event],
    );
  }

  NarrativeStateLedgerMutationResult accept({
    required NarrativeStateLedger ledger,
    required String entryId,
    required NarrativeSourceRef source,
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String occurredAt = '',
    String note = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transitionEntry(
      ledger: ledger,
      entryId: entryId,
      targetDisposition: NarrativeClaimDisposition.accepted,
      eventType: 'claim_accepted',
      source: source,
      evidenceRefs: evidenceRefs,
      occurredAt: occurredAt,
      note: note,
      metadata: metadata,
    );
  }

  NarrativeStateLedgerMutationResult question({
    required NarrativeStateLedger ledger,
    required String entryId,
    required NarrativeSourceRef source,
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String occurredAt = '',
    String note = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transitionEntry(
      ledger: ledger,
      entryId: entryId,
      targetDisposition: NarrativeClaimDisposition.questioned,
      eventType: 'claim_questioned',
      source: source,
      evidenceRefs: evidenceRefs,
      occurredAt: occurredAt,
      note: note,
      metadata: metadata,
    );
  }

  NarrativeStateLedgerMutationResult reject({
    required NarrativeStateLedger ledger,
    required String entryId,
    required NarrativeSourceRef source,
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String occurredAt = '',
    String note = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return _transitionEntry(
      ledger: ledger,
      entryId: entryId,
      targetDisposition: NarrativeClaimDisposition.rejected,
      eventType: 'claim_rejected',
      source: source,
      evidenceRefs: evidenceRefs,
      occurredAt: occurredAt,
      note: note,
      metadata: metadata,
    );
  }

  NarrativeStateLedgerMutationResult supersede({
    required NarrativeStateLedger ledger,
    required String entryId,
    required NarrativeStateClaim replacementClaim,
    required NarrativeSourceRef source,
    NarrativeClaimDisposition replacementDisposition =
        NarrativeClaimDisposition.proposed,
    String replacementEntryId = '',
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String occurredAt = '',
    String note = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    _ensureClaimIsValid(replacementClaim);
    _ensureSubmissionDisposition(replacementDisposition);

    final currentEntry = _findEntry(ledger, entryId);
    _ensureTransitionAllowed(
      current: currentEntry.disposition,
      target: NarrativeClaimDisposition.superseded,
    );
    final resolvedReplacementEntryId = _resolveEntryId(
      ledger: ledger,
      claim: replacementClaim,
      requestedEntryId: replacementEntryId,
    );
    final mergedEvidence = _mergeEvidenceRefs(
      currentEntry.evidenceRefs,
      evidenceRefs,
    );
    final supersedeEvent = _buildEvent(
      eventType: 'claim_superseded',
      disposition: NarrativeClaimDisposition.superseded,
      source: source,
      entryId: currentEntry.entryId,
      relatedEntryIds: <String>[resolvedReplacementEntryId],
      evidenceRefs: mergedEvidence,
      summary: note.isNotEmpty ? note : 'claim 已被 replacement entry supersede。',
      occurredAt: occurredAt,
      metadata: metadata,
    );
    final replacementEvent = _buildEvent(
      eventType: 'claim_replacement_submitted',
      disposition: replacementDisposition,
      source: source,
      entryId: resolvedReplacementEntryId,
      relatedEntryIds: <String>[currentEntry.entryId],
      evidenceRefs: _mergeEvidenceRefs(
        replacementClaim.evidenceRefs,
        evidenceRefs,
      ),
      summary: note.isNotEmpty ? note : 'replacement claim 已提交到 ledger。',
      occurredAt: occurredAt,
      metadata: <String, Object?>{
        ...metadata,
        'replaces_entry_id': currentEntry.entryId,
      },
    );
    final supersededEntry = currentEntry.copyWith(
      disposition: NarrativeClaimDisposition.superseded,
      source: source,
      evidenceRefs: mergedEvidence,
      replacementEntryIds: _mergeStringLists(
        currentEntry.replacementEntryIds,
        <String>[resolvedReplacementEntryId],
      ),
      events: <NarrativeLedgerEvent>[...currentEntry.events, supersedeEvent],
      recordedAt: occurredAt.isNotEmpty ? occurredAt : currentEntry.recordedAt,
      note: _mergeNote(currentEntry.note, note),
      metadata: _mergeMetadata(metadata, currentEntry.metadata),
    );
    final replacementEntry = NarrativeLedgerEntry(
      entryId: resolvedReplacementEntryId,
      claim: replacementClaim,
      disposition: replacementDisposition,
      source: source,
      evidenceRefs: replacementEvent.evidenceRefs,
      supersedesEntryIds: <String>[currentEntry.entryId],
      events: <NarrativeLedgerEvent>[replacementEvent],
      recordedAt: occurredAt,
      note: note,
      schemaVersion: replacementClaim.schemaVersion,
      metadata: _mergeMetadata(metadata, <String, Object?>{
        'supersedes_entry_id': currentEntry.entryId,
      }),
    );
    final updatedEntries = <NarrativeLedgerEntry>[
      for (final entry in ledger.entries)
        if (entry.entryId == currentEntry.entryId) supersededEntry else entry,
      replacementEntry,
    ];
    final updatedEvents = <NarrativeLedgerEvent>[
      ...ledger.events,
      supersedeEvent,
      replacementEvent,
    ];
    return NarrativeStateLedgerMutationResult(
      ledger: ledger.copyWith(entries: updatedEntries, events: updatedEvents),
      primaryEntry: replacementEntry,
      emittedEvents: <NarrativeLedgerEvent>[supersedeEvent, replacementEvent],
      relatedEntryIds: <String>[
        currentEntry.entryId,
        resolvedReplacementEntryId,
      ],
    );
  }

  NarrativeStateLedgerReviewRecommendation buildReviewRecommendation({
    required NarrativeStateLedger ledger,
    required NarrativeSemanticReview review,
  }) {
    final acceptedEntries = <NarrativeLedgerEntry>[];
    final questionedEntries = <NarrativeLedgerEntry>[];
    final unresolvedAcceptedClaimIds = <String>[];
    final unresolvedQuestionedClaimIds = <String>[];

    for (final claimId in review.acceptedClaimIds) {
      final matches = _findEntriesByClaimId(ledger, claimId);
      if (matches.isEmpty) {
        unresolvedAcceptedClaimIds.add(claimId);
      } else {
        acceptedEntries.addAll(matches);
      }
    }
    for (final claimId in review.questionedClaimIds) {
      final matches = _findEntriesByClaimId(ledger, claimId);
      if (matches.isEmpty) {
        unresolvedQuestionedClaimIds.add(claimId);
      } else {
        questionedEntries.addAll(matches);
      }
    }

    return NarrativeStateLedgerReviewRecommendation(
      review: review,
      acceptedEntries: acceptedEntries,
      questionedEntries: questionedEntries,
      suggestedClaims: review.suggestedClaims,
      findings: review.findings,
      unresolvedAcceptedClaimIds: unresolvedAcceptedClaimIds,
      unresolvedQuestionedClaimIds: unresolvedQuestionedClaimIds,
      requiresManualAttention: _requiresManualAttention(review),
      relatedRefs: review.targetRefs,
    );
  }

  NarrativeStateLedgerMutationResult _transitionEntry({
    required NarrativeStateLedger ledger,
    required String entryId,
    required NarrativeClaimDisposition targetDisposition,
    required String eventType,
    required NarrativeSourceRef source,
    required List<NarrativeEvidenceRef> evidenceRefs,
    required String occurredAt,
    required String note,
    required JsonMap metadata,
  }) {
    final currentEntry = _findEntry(ledger, entryId);
    _ensureTransitionAllowed(
      current: currentEntry.disposition,
      target: targetDisposition,
    );
    final mergedEvidence = _mergeEvidenceRefs(
      currentEntry.evidenceRefs,
      evidenceRefs,
    );
    final event = _buildEvent(
      eventType: eventType,
      disposition: targetDisposition,
      source: source,
      entryId: currentEntry.entryId,
      evidenceRefs: mergedEvidence,
      summary: note.isNotEmpty ? note : _defaultSummaryFor(targetDisposition),
      occurredAt: occurredAt,
      metadata: metadata,
    );
    final updatedEntry = currentEntry.copyWith(
      disposition: targetDisposition,
      source: source,
      evidenceRefs: mergedEvidence,
      events: <NarrativeLedgerEvent>[...currentEntry.events, event],
      recordedAt: occurredAt.isNotEmpty ? occurredAt : currentEntry.recordedAt,
      note: _mergeNote(currentEntry.note, note),
      metadata: _mergeMetadata(metadata, currentEntry.metadata),
    );
    final updatedEntries = <NarrativeLedgerEntry>[
      for (final entry in ledger.entries)
        if (entry.entryId == currentEntry.entryId) updatedEntry else entry,
    ];
    final updatedEvents = <NarrativeLedgerEvent>[...ledger.events, event];
    return NarrativeStateLedgerMutationResult(
      ledger: ledger.copyWith(entries: updatedEntries, events: updatedEvents),
      primaryEntry: updatedEntry,
      emittedEvents: <NarrativeLedgerEvent>[event],
      relatedEntryIds: <String>[updatedEntry.entryId],
    );
  }

  void _ensureClaimIsValid(NarrativeStateClaim claim) {
    final validationErrors = claim.validateBasics();
    if (validationErrors.isNotEmpty) {
      throw ArgumentError.value(
        claim.claimId,
        'claim',
        validationErrors.join(', '),
      );
    }
  }

  void _ensureSubmissionDisposition(NarrativeClaimDisposition disposition) {
    if (disposition == NarrativeClaimDisposition.questioned ||
        disposition == NarrativeClaimDisposition.rejected ||
        disposition == NarrativeClaimDisposition.superseded) {
      throw ArgumentError.value(
        disposition.id,
        'initialDisposition',
        'submit/replacement 只能进入 observed/proposed/accepted。',
      );
    }
  }

  void _ensureTransitionAllowed({
    required NarrativeClaimDisposition current,
    required NarrativeClaimDisposition target,
  }) {
    if (current == NarrativeClaimDisposition.superseded) {
      throw StateError('superseded claim entry 不能再变更。');
    }
    if (current == NarrativeClaimDisposition.rejected &&
        target != NarrativeClaimDisposition.superseded) {
      throw StateError('rejected claim entry 不能直接重新进入其他处置状态。');
    }
  }

  NarrativeLedgerEntry _findEntry(NarrativeStateLedger ledger, String entryId) {
    for (final entry in ledger.entries) {
      if (entry.entryId == entryId.trim()) {
        return entry;
      }
    }
    throw StateError('未找到 ledger entry: $entryId');
  }

  List<NarrativeLedgerEntry> _findEntriesByClaimId(
    NarrativeStateLedger ledger,
    String claimId,
  ) {
    final resolvedClaimId = claimId.trim();
    return ledger.entries
        .where((entry) => entry.claim.claimId == resolvedClaimId)
        .toList(growable: false);
  }

  bool _requiresManualAttention(NarrativeSemanticReview review) {
    if (review.recommendedDisposition ==
            SemanticReviewRecommendedDisposition.repair ||
        review.recommendedDisposition ==
            SemanticReviewRecommendedDisposition.checkpointUser ||
        review.recommendedDisposition ==
            SemanticReviewRecommendedDisposition.manualAttention) {
      return true;
    }
    return review.findings.any(
      (finding) =>
          finding.severity == SemanticReviewSeverity.high ||
          finding.severity == SemanticReviewSeverity.blocking,
    );
  }

  String _resolveEntryId({
    required NarrativeStateLedger ledger,
    required NarrativeStateClaim claim,
    required String requestedEntryId,
  }) {
    final normalizedRequested = requestedEntryId.trim();
    if (normalizedRequested.isNotEmpty) {
      return normalizedRequested;
    }
    final sourceKey = _sourceKey(claim.source);
    final baseId = '${claim.claimId}:$sourceKey';
    final existingIds = ledger.entries.map((entry) => entry.entryId).toSet();
    if (!existingIds.contains(baseId)) {
      return baseId;
    }
    var counter = 2;
    while (existingIds.contains('$baseId:$counter')) {
      counter += 1;
    }
    return '$baseId:$counter';
  }

  String _sourceKey(NarrativeSourceRef source) {
    final sourceType = source.sourceType.trim();
    final sourceId = source.sourceId.trim();
    return sourceId.isEmpty ? sourceType : '$sourceType:$sourceId';
  }

  List<NarrativeEvidenceRef> _mergeEvidenceRefs(
    List<NarrativeEvidenceRef> base,
    List<NarrativeEvidenceRef> extra,
  ) {
    final result = <NarrativeEvidenceRef>[];
    final seen = <String>{};
    for (final entry in <NarrativeEvidenceRef>[...base, ...extra]) {
      final key = '${entry.evidenceType}:${entry.evidenceId}';
      if (seen.add(key)) {
        result.add(entry);
      }
    }
    return List<NarrativeEvidenceRef>.from(result, growable: false);
  }

  List<String> _mergeStringLists(List<String> base, List<String> extra) {
    final result = <String>[];
    for (final entry in <String>[...base, ...extra]) {
      final normalized = entry.trim();
      if (normalized.isNotEmpty && !result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return List<String>.from(result, growable: false);
  }

  String _mergeNote(String base, String extra) {
    final left = base.trim();
    final right = extra.trim();
    if (left.isEmpty) {
      return right;
    }
    if (right.isEmpty || left == right) {
      return left;
    }
    return '$left\n$right';
  }

  JsonMap _mergeMetadata(JsonMap primary, JsonMap secondary) {
    return ValueReaders.deepCopyMap(<String, Object?>{
      ...secondary,
      ...primary,
    });
  }

  NarrativeLedgerEvent _buildEvent({
    required String eventType,
    required NarrativeClaimDisposition disposition,
    required NarrativeSourceRef source,
    required String entryId,
    List<String> relatedEntryIds = const <String>[],
    List<NarrativeEvidenceRef> evidenceRefs = const <NarrativeEvidenceRef>[],
    String summary = '',
    String occurredAt = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    return NarrativeLedgerEvent(
      eventId: '$eventType:$entryId',
      eventType: eventType,
      disposition: disposition,
      source: source,
      entryId: entryId,
      relatedEntryIds: relatedEntryIds,
      evidenceRefs: evidenceRefs,
      summary: summary,
      occurredAt: occurredAt,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }

  String _defaultSummaryFor(NarrativeClaimDisposition disposition) {
    switch (disposition) {
      case NarrativeClaimDisposition.accepted:
        return 'claim 已被接受。';
      case NarrativeClaimDisposition.questioned:
        return 'claim 已进入 questioned 状态。';
      case NarrativeClaimDisposition.rejected:
        return 'claim 已被拒绝。';
      case NarrativeClaimDisposition.superseded:
        return 'claim 已被 supersede。';
      case NarrativeClaimDisposition.observed:
        return 'claim 已被记录。';
      case NarrativeClaimDisposition.proposed:
        return 'claim 已进入 proposed 状态。';
    }
  }
}
