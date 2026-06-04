import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeSemanticReview contracts', () {
    test('supports accepted questioned and suggested claims with recommendation only', () {
      const codec = NarrativeSemanticReviewCodecService();
      final review = codec.fromJson(<String, Object?>{
        'review_id': 'review-001',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.reviewer,
          'source_id': 'reviewer-001',
        },
        'recommended_disposition': 'repair',
        'target_refs': <Object?>[
          <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-001',
          },
        ],
        'accepted_claim_ids': <Object?>['claim-accepted-001'],
        'questioned_claim_ids': <Object?>['claim-questioned-001'],
        'suggested_claims': <Object?>[
          <String, Object?>{
            'claim_id': 'claim-suggested-001',
            'claim_namespace': 'analysis.review.suggested',
            'claim_payload': <String, Object?>{
              'suggested_fix': 'tighten_scope_boundary',
            },
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.reviewer,
            },
          },
        ],
        'findings': <Object?>[
          <String, Object?>{
            'finding_id': 'finding-001',
            'severity': 'high',
            'summary': '本章中段 scope 切换提示不足。',
            'evidence_refs': <Object?>[
              <String, Object?>{
                'evidence_type': NarrativeEvidenceTypes.reviewNote,
                'evidence_id': 'evidence-001',
              },
            ],
            'related_claim_ids': <Object?>['claim-questioned-001'],
            'suggested_action': 'repair_scope_boundary',
            'confidence': 0.8,
          },
        ],
        'summary': '建议先返工再继续。',
        'confidence': 0.85,
      });

      final encoded = codec.toJson(review);

      expect(
        review.recommendedDisposition,
        SemanticReviewRecommendedDisposition.repair,
      );
      expect(review.acceptedClaimIds, contains('claim-accepted-001'));
      expect(review.questionedClaimIds, contains('claim-questioned-001'));
      expect(review.suggestedClaims.single.claimId, 'claim-suggested-001');
      expect(
        review.findings.single.severity,
        SemanticReviewSeverity.high,
      );
      expect(review.validateBasics(), isEmpty);
      expect(encoded.containsKey('ledger_disposition'), isFalse);
    });

    test('finding may explain inability to locate evidence', () {
      final finding = SemanticReviewFinding.fromJson(<String, Object?>{
        'finding_id': 'finding-unlocatable',
        'severity': 'medium',
        'summary': '推断本章有潜在视角问题，但当前无法精确定位。',
        'unable_to_locate_evidence': true,
        'unlocatable_reason': '上游只提供了摘要，没有精确片段。',
        'confidence': 0.55,
      });

      expect(finding.validateBasics(), isEmpty);
      expect(finding.unableToLocateEvidence, isTrue);
    });

    test('blocking finding with missing evidence must explain why', () {
      final finding = SemanticReviewFinding.fromJson(<String, Object?>{
        'finding_id': 'finding-blocking',
        'severity': 'blocking',
        'summary': '结尾状态与前文冲突。',
        'confidence': 0.9,
      });

      expect(
        finding.validateBasics(),
        contains(
          SemanticReviewValidationCodes.findingNeedsEvidenceOrUnlocatableReason,
        ),
      );
    });

    test('validation basics report missing review identity and source', () {
      final review = NarrativeSemanticReview.fromJson(<String, Object?>{
        'review_id': '',
        'source': <String, Object?>{},
        'recommended_disposition': 'accept_with_note',
        'findings': <Object?>[
          <String, Object?>{
            'finding_id': '',
            'severity': 'low',
            'summary': '',
            'confidence': 1.2,
          },
        ],
        'confidence': 1.1,
      });

      expect(
        review.validateBasics(),
        containsAll(<String>[
          SemanticReviewValidationCodes.missingReviewId,
          SemanticReviewValidationCodes.missingSourceType,
          SemanticReviewValidationCodes.invalidConfidence,
          SemanticReviewValidationCodes.missingFindingId,
          SemanticReviewValidationCodes.missingFindingSummary,
          SemanticReviewValidationCodes.findingNeedsEvidenceOrUnlocatableReason,
        ]),
      );
    });
  });
}
