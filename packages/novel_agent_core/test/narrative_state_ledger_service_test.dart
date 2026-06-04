import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeStateLedgerService', () {
    test(
      'submit keeps same claim from different sources as parallel entries',
      () {
        const service = NarrativeStateLedgerService();
        const emptyLedger = NarrativeStateLedger(ledgerId: 'ledger-001');
        final deconstructionClaim = _buildClaim(
          claimId: 'claim-shared',
          sourceType: NarrativeSourceTypes.deconstruction,
        );
        final writerClaim = _buildClaim(
          claimId: 'claim-shared',
          sourceType: NarrativeSourceTypes.writer,
        );

        final observedResult = service.submit(
          ledger: emptyLedger,
          claim: deconstructionClaim,
        );
        final acceptedResult = service.submit(
          ledger: observedResult.ledger,
          claim: writerClaim,
          initialDisposition: NarrativeClaimDisposition.accepted,
        );

        expect(acceptedResult.ledger.entries, hasLength(2));
        expect(
          acceptedResult.ledger.entries
              .map((entry) => entry.source.sourceType)
              .toList(growable: false),
          containsAll(<String>[
            NarrativeSourceTypes.deconstruction,
            NarrativeSourceTypes.writer,
          ]),
        );
        expect(
          acceptedResult.ledger.entries
              .map((entry) => entry.disposition)
              .toList(growable: false),
          containsAll(<NarrativeClaimDisposition>[
            NarrativeClaimDisposition.observed,
            NarrativeClaimDisposition.accepted,
          ]),
        );
      },
    );

    test(
      'accept question and reject update a concrete entry with audit events',
      () {
        const service = NarrativeStateLedgerService();
        final seedEntry = NarrativeLedgerEntry(
          entryId: 'entry-001',
          claim: _buildClaim(
            claimId: 'claim-001',
            sourceType: NarrativeSourceTypes.writer,
          ),
          disposition: NarrativeClaimDisposition.proposed,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
        );
        final seedLedger = NarrativeStateLedger(
          ledgerId: 'ledger-002',
          entries: <NarrativeLedgerEntry>[seedEntry],
        );

        final accepted = service.accept(
          ledger: seedLedger,
          entryId: 'entry-001',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.user,
          ),
          note: '用户确认该 claim。',
        );
        final questioned = service.question(
          ledger: accepted.ledger,
          entryId: 'entry-001',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.reviewer,
          ),
          note: 'reviewer 对证据链仍有疑问。',
        );
        final rejected = service.reject(
          ledger: questioned.ledger,
          entryId: 'entry-001',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.user,
          ),
          note: '用户最终否决该 claim。',
        );

        expect(
          accepted.primaryEntry?.disposition,
          NarrativeClaimDisposition.accepted,
        );
        expect(
          questioned.primaryEntry?.disposition,
          NarrativeClaimDisposition.questioned,
        );
        expect(
          rejected.primaryEntry?.disposition,
          NarrativeClaimDisposition.rejected,
        );
        expect(
          rejected.primaryEntry?.events.map((event) => event.eventType),
          containsAll(<String>[
            'claim_accepted',
            'claim_questioned',
            'claim_rejected',
          ]),
        );
        expect(rejected.ledger.events, hasLength(3));
      },
    );

    test('supersede creates a replacement entry and preserves clear links', () {
      const service = NarrativeStateLedgerService();
      final originalEntry = NarrativeLedgerEntry(
        entryId: 'entry-old',
        claim: _buildClaim(
          claimId: 'claim-old',
          sourceType: NarrativeSourceTypes.writer,
        ),
        disposition: NarrativeClaimDisposition.accepted,
        source: const NarrativeSourceRef(sourceType: NarrativeSourceTypes.user),
      );
      final ledger = NarrativeStateLedger(
        ledgerId: 'ledger-003',
        entries: <NarrativeLedgerEntry>[originalEntry],
      );
      final replacementClaim = _buildClaim(
        claimId: 'claim-new',
        sourceType: NarrativeSourceTypes.recovery,
      );

      final result = service.supersede(
        ledger: ledger,
        entryId: 'entry-old',
        replacementClaim: replacementClaim,
        replacementDisposition: NarrativeClaimDisposition.accepted,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.system,
        ),
        replacementEntryId: 'entry-new',
      );

      final supersededEntry = result.ledger.entries.singleWhere(
        (entry) => entry.entryId == 'entry-old',
      );
      final replacementEntry = result.ledger.entries.singleWhere(
        (entry) => entry.entryId == 'entry-new',
      );

      expect(supersededEntry.disposition, NarrativeClaimDisposition.superseded);
      expect(supersededEntry.replacementEntryIds, contains('entry-new'));
      expect(replacementEntry.supersedesEntryIds, contains('entry-old'));
      expect(result.emittedEvents.map((event) => event.eventType), <String>[
        'claim_superseded',
        'claim_replacement_submitted',
      ]);
    });

    test(
      'review recommendation resolves suggestions without mutating ledger',
      () {
        const service = NarrativeStateLedgerService();
        final acceptedEntry = NarrativeLedgerEntry(
          entryId: 'entry-accepted',
          claim: _buildClaim(
            claimId: 'claim-accepted',
            sourceType: NarrativeSourceTypes.writer,
          ),
          disposition: NarrativeClaimDisposition.proposed,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
        );
        final questionedEntry = NarrativeLedgerEntry(
          entryId: 'entry-questioned',
          claim: _buildClaim(
            claimId: 'claim-questioned',
            sourceType: NarrativeSourceTypes.deconstruction,
          ),
          disposition: NarrativeClaimDisposition.observed,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.deconstruction,
          ),
        );
        final ledger = NarrativeStateLedger(
          ledgerId: 'ledger-004',
          entries: <NarrativeLedgerEntry>[acceptedEntry, questionedEntry],
        );
        final review = NarrativeSemanticReview.fromJson(<String, Object?>{
          'review_id': 'review-001',
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.reviewer,
          },
          'recommended_disposition': 'repair',
          'accepted_claim_ids': <Object?>['claim-accepted'],
          'questioned_claim_ids': <Object?>[
            'claim-questioned',
            'claim-missing',
          ],
          'suggested_claims': <Object?>[
            <String, Object?>{
              'claim_id': 'claim-suggested',
              'claim_namespace': 'analysis.review.patch',
              'claim_payload': <String, Object?>{'need': 'clarify_scope'},
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.reviewer,
              },
            },
          ],
          'findings': <Object?>[
            <String, Object?>{
              'finding_id': 'finding-001',
              'severity': 'blocking',
              'summary': '当前证据链不足以直接推进。',
              'unable_to_locate_evidence': true,
              'unlocatable_reason': 'review 只收到摘要。',
              'confidence': 0.8,
            },
          ],
        });

        final recommendation = service.buildReviewRecommendation(
          ledger: ledger,
          review: review,
        );

        expect(
          recommendation.acceptedEntries.map((entry) => entry.entryId),
          <String>['entry-accepted'],
        );
        expect(
          recommendation.questionedEntries.map((entry) => entry.entryId),
          <String>['entry-questioned'],
        );
        expect(recommendation.unresolvedQuestionedClaimIds, <String>[
          'claim-missing',
        ]);
        expect(
          recommendation.suggestedClaims.single.claimId,
          'claim-suggested',
        );
        expect(recommendation.requiresManualAttention, isTrue);
        expect(
          ledger.entries
              .singleWhere((entry) => entry.entryId == 'entry-accepted')
              .disposition,
          NarrativeClaimDisposition.proposed,
        );
        expect(ledger.events, isEmpty);
      },
    );
  });
}

NarrativeStateClaim _buildClaim({
  required String claimId,
  required String sourceType,
}) {
  return NarrativeStateClaim.fromJson(<String, Object?>{
    'claim_id': claimId,
    'claim_namespace': 'project.state.sample',
    'claim_payload': <String, Object?>{'state': 'updated'},
    'source': <String, Object?>{'source_type': sourceType},
    'confidence': 0.8,
  });
}
