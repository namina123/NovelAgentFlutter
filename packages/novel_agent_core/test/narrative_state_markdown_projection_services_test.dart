import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeState markdown projection services', () {
    test(
      'renders stable projection documents with projection-only guidance',
      () {
        final service = NarrativeStateMarkdownProjectionService();
        final source = NarrativeStateProjectionSource(
          profiles: <NarrativeProfile>[
            NarrativeProfile(
              profileId: 'hero',
              profileNamespace: 'character',
              profileLabel: '主角',
              lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
              profilePayload: const <String, Object?>{
                'weapon': 'spear',
                'unknown_trait': <String, Object?>{'rarity': 'mythic'},
              },
              profileExtensions: const <String, Object?>{'mood': 'grim'},
              source: _source(),
              confidence: 0.92,
              reason: 'review accepted',
            ),
          ],
          claims: <NarrativeStateClaim>[
            NarrativeStateClaim.fromJson(<String, Object?>{
              'claim_id': 'claim-1',
              'claim_namespace': 'continuity',
              'claim_label': '武器变更',
              'claim_payload': <String, Object?>{
                'inventory': <Object?>['rope', 'map'],
              },
              'source': _source().toJson(),
              'confidence': 0.87,
              'uncertainty': 'low',
              'metadata': <String, Object?>{'bridge': true},
              'mystery_field': 'kept',
            }),
          ],
          ledgers: <NarrativeStateLedger>[
            NarrativeStateLedger(
              ledgerId: 'main-ledger',
              entries: <NarrativeLedgerEntry>[
                NarrativeLedgerEntry(
                  entryId: 'entry-1',
                  claim: NarrativeStateClaim(
                    claimId: 'claim-1',
                    claimNamespace: 'continuity',
                    claimPayload: const <String, Object?>{
                      'inventory': <Object?>['rope', 'map'],
                    },
                    source: _source(),
                  ),
                  disposition: NarrativeClaimDisposition.accepted,
                  source: _source(),
                ),
              ],
              events: <NarrativeLedgerEvent>[
                NarrativeLedgerEvent(
                  eventId: 'event-1',
                  eventType: 'accepted',
                  disposition: NarrativeClaimDisposition.accepted,
                  source: _source(),
                  entryId: 'entry-1',
                  summary: 'accepted summary',
                ),
              ],
            ),
          ],
          reviews: <NarrativeSemanticReview>[
            NarrativeSemanticReview(
              reviewId: 'review-1',
              source: _source(),
              recommendedDisposition:
                  SemanticReviewRecommendedDisposition.acceptWithNote,
              summary: 'review summary',
            ),
          ],
          bindings: <NarrativeConstraintBindingProposal>[
            NarrativeConstraintBindingProposal(
              bindingId: 'binding-1',
              constraintType: 'style_rule',
              constraintLabel: '禁用全知旁白',
              constraintPayload: const <String, Object?>{
                'unknown_payload': <String, Object?>{'severity': 'high'},
              },
              scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
              policy: const ConstraintBindingPolicy(
                requiresUserConfirmation: true,
              ),
              source: _source(),
            ),
          ],
        );

        final documents = service.buildDocuments(source);
        final repeated = service.buildDocuments(source);

        expect(documents.map((item) => item.relativePath), <String>[
          'continuity/叙事状态规则.md',
          'continuity/最近状态变化.md',
          'constraints/项目约束摘要.md',
          'reviews/语义复核摘要.md',
        ]);
        expect(documents.first.markdown, contains('这份 Markdown 只是结构化事实源的可读投影'));
        expect(
          documents.first.markdown,
          contains(
            NarrativeStateMarkdownProjectionService.profileProposalDraftBlockId,
          ),
        );
        expect(
          documents[1].markdown,
          contains(
            NarrativeStateMarkdownProjectionService.ledgerReferenceBlockId,
          ),
        );
        expect(
          documents[2].markdown,
          contains('`{"unknown_payload":{"severity":"high"}}`'),
        );
        expect(
          repeated.map((item) => item.markdown).toList(growable: false),
          documents.map((item) => item.markdown).toList(growable: false),
        );
      },
    );

    test('bridge parses edited draft blocks into proposal and claim drafts only', () {
      final projectionService = NarrativeStateMarkdownProjectionService();
      final bridgeService = NarrativeStateMarkdownBridgeService();
      final baseDocument = projectionService
          .buildDocuments(const NarrativeStateProjectionSource())
          .firstWhere(
            (item) =>
                item.relativePath ==
                NarrativeStateProjectionDocument.rulesRelativePath,
          );
      final editedRulesMarkdown = baseDocument.markdown.replaceFirst(
        '```json ${NarrativeStateMarkdownProjectionService.profileProposalDraftBlockId}\n[]\n```',
        '''```json ${NarrativeStateMarkdownProjectionService.profileProposalDraftBlockId}
[
  {
    "proposal_id": "proposal-1",
    "proposal_status": "proposed",
    "profile_patch": {
      "patch_id": "patch-1",
      "patch_label": "补充规则",
      "patch_payload": {
        "persona": {
          "temper": "cold"
        }
      },
      "patch_extensions": {
        "unknown_extension": {
          "tone": "clinical"
        }
      },
      "source": {
        "source_type": "markdown_projection",
        "source_id": "rules-md"
      },
      "confidence": 0.74,
      "reason": "edited from md"
    },
    "source": {
      "source_type": "markdown_projection",
      "source_id": "rules-md"
    },
    "target_profile_id": "hero",
    "base_profile_id": "hero",
    "requires_user_confirmation": true,
    "reason": "manual proposal",
    "confidence": 0.74
  }
]
```''',
      );
      final changesDocument = projectionService
          .buildDocuments(const NarrativeStateProjectionSource())
          .firstWhere(
            (item) =>
                item.relativePath ==
                NarrativeStateProjectionDocument.recentChangesRelativePath,
          );
      final editedChangesMarkdown = changesDocument.markdown.replaceFirst(
        '```json ${NarrativeStateMarkdownProjectionService.claimDraftBlockId}\n[]\n```',
        '''```json ${NarrativeStateMarkdownProjectionService.claimDraftBlockId}
[
  {
    "claim_id": "claim-2",
    "claim_namespace": "continuity",
    "claim_label": "新增状态",
    "claim_payload": {
      "inventory": ["map"],
      "unknown_payload": {
        "weather": "ash"
      }
    },
    "source": {
      "source_type": "markdown_projection",
      "source_id": "changes-md"
    },
    "confidence": 0.63,
    "uncertainty": "medium",
    "mystery_field": "kept"
  }
]
```''',
      );

      final profileDrafts = bridgeService.parseDocument(
        editedRulesMarkdown,
        relativePath: NarrativeStateProjectionDocument.rulesRelativePath,
      );
      final claimDrafts = bridgeService.parseDocument(
        editedChangesMarkdown,
        relativePath:
            NarrativeStateProjectionDocument.recentChangesRelativePath,
      );

      expect(profileDrafts.projectionOnly, isTrue);
      expect(profileDrafts.profileProposalDrafts, hasLength(1));
      expect(
        profileDrafts.profileProposalDrafts.single.profilePatch.patchPayload,
        <String, Object?>{
          'persona': <String, Object?>{'temper': 'cold'},
        },
      );
      expect(claimDrafts.claimDrafts.single.toJson()['mystery_field'], 'kept');
      expect(claimDrafts.profileProposalDrafts, isEmpty);
    });

    test(
      'bridge parses binding and semantic review drafts from edited projections',
      () {
        final projectionService = NarrativeStateMarkdownProjectionService();
        final bridgeService = NarrativeStateMarkdownBridgeService();
        final constraintDocument = projectionService
            .buildDocuments(const NarrativeStateProjectionSource())
            .firstWhere(
              (item) =>
                  item.relativePath ==
                  NarrativeStateProjectionDocument
                      .constraintSummaryRelativePath,
            );
        final editedConstraintMarkdown = constraintDocument.markdown.replaceFirst(
          '```json ${NarrativeStateMarkdownProjectionService.bindingDraftBlockId}\n[]\n```',
          '''```json ${NarrativeStateMarkdownProjectionService.bindingDraftBlockId}
[
  {
    "binding_id": "binding-draft-1",
    "constraint_type": "style_rule",
    "constraint_label": "避免全知旁白",
    "constraint_payload": {
      "unknown_payload": {
        "severity": "high"
      }
    },
    "binding_scope": {
      "applies_to": ["draft"]
    },
    "binding_policy": {
      "requires_user_confirmation": true
    },
    "source": {
      "source_type": "markdown_projection",
      "source_id": "constraint-md"
    },
    "confidence": 0.6
  }
]
```''',
        );
        final reviewDocument = projectionService
            .buildDocuments(const NarrativeStateProjectionSource())
            .firstWhere(
              (item) =>
                  item.relativePath ==
                  NarrativeStateProjectionDocument
                      .semanticReviewSummaryRelativePath,
            );
        final editedReviewMarkdown = reviewDocument.markdown.replaceFirst(
          '```json ${NarrativeStateMarkdownProjectionService.semanticReviewDraftBlockId}\n[]\n```',
          '''```json ${NarrativeStateMarkdownProjectionService.semanticReviewDraftBlockId}
[
  {
    "review_id": "review-draft-1",
    "source": {
      "source_type": "markdown_projection",
      "source_id": "review-md"
    },
    "recommended_disposition": "repair",
    "suggested_claims": [
      {
        "claim_id": "claim-from-review",
        "claim_namespace": "continuity",
        "claim_payload": {
          "unknown_payload": {
            "source": "review"
          }
        },
        "source": {
          "source_type": "markdown_projection",
          "source_id": "review-md"
        }
      }
    ],
    "summary": "needs repair",
    "confidence": 0.7
  }
]
```''',
        );

        final bindingDrafts = bridgeService.parseDocument(
          editedConstraintMarkdown,
          relativePath:
              NarrativeStateProjectionDocument.constraintSummaryRelativePath,
        );
        final reviewDrafts = bridgeService.parseDocument(
          editedReviewMarkdown,
          relativePath: NarrativeStateProjectionDocument
              .semanticReviewSummaryRelativePath,
        );

        expect(bindingDrafts.constraintBindingDrafts, hasLength(1));
        expect(
          bindingDrafts.constraintBindingDrafts.single.constraintPayload,
          <String, Object?>{
            'unknown_payload': <String, Object?>{'severity': 'high'},
          },
        );
        expect(reviewDrafts.semanticReviewDrafts, hasLength(1));
        expect(
          reviewDrafts
              .semanticReviewDrafts
              .single
              .suggestedClaims
              .single
              .claimPayload['unknown_payload'],
          <String, Object?>{'source': 'review'},
        );
      },
    );
  });
}

NarrativeSourceRef _source() {
  return const NarrativeSourceRef(
    sourceType: 'tool_call',
    sourceId: 'source-1',
    label: 'tool',
  );
}
