import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeSupervisorRiskPolicyService', () {
    const service = NarrativeSupervisorRiskPolicyService();

    test('flags recoverable chapter delivery as repair instead of waiting user', () {
      final risk = service.assess(
        result: const <String, Object?>{
          'ok': true,
          'executed_tools': <Object?>[],
          'response': <String, Object?>{},
        },
        execution: const <String, Object?>{
          'chapter_delivery_state': 'missing_output_recoverable',
          'chapter_delivery': <String, Object?>{
            'delivery_state': 'missing_output_recoverable',
            'chapter_path': 'chapters/ch01.md',
            'state_result': <String, Object?>{
              'reason': 'chapter_body_missing',
            },
          },
        },
      );

      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(risk['delivery'])['category'],
        ),
        'repair',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(risk['overall'])['category'],
        ),
        'repair',
      );
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(risk['overall'])['waiting_user'],
        ),
        isFalse,
      );
    });

    test('treats blocking semantic review findings as repair and tracks claim disposition counts', () {
      final review = NarrativeSemanticReview(
        reviewId: 'semantic-review-1',
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.reviewer,
          sourceId: 'reviewer-1',
        ),
        recommendedDisposition: SemanticReviewRecommendedDisposition.repair,
        questionedClaimIds: const <String>['claim-questioned-1'],
        findings: const <SemanticReviewFinding>[
          SemanticReviewFinding(
            findingId: 'finding-1',
            severity: SemanticReviewSeverity.blocking,
            summary: '结尾和前文设定冲突。',
            unableToLocateEvidence: true,
            unlocatableReason: 'focused test',
          ),
        ],
      );

      final risk = service.assess(
        result: <String, Object?>{
          'ok': true,
          'executed_tools': <Object?>[
            <String, Object?>{
              'name': 'submit_semantic_review',
              'result': <String, Object?>{
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'review': review.toJson(),
                  },
                },
              },
            },
          ],
          'response': const <String, Object?>{},
        },
      );

      final reviewRisk = ValueReaders.mapValue(risk['review']);
      expect(ValueReaders.stringValue(reviewRisk['category']), 'repair');
      expect(ValueReaders.intValue(reviewRisk['blocking_finding_count']), 1);
      expect(ValueReaders.intValue(reviewRisk['questioned_claim_count']), 1);
      expect(
        ValueReaders.stringValue(ValueReaders.mapValue(risk['overall'])['category']),
        'repair',
      );
    });

    test('keeps waiting_user for true permission confirmation only', () {
      final risk = service.assess(
        result: const <String, Object?>{
          'ok': true,
          'executed_tools': <Object?>[
            <String, Object?>{
              'name': 'request_profile_clarification',
              'result': <String, Object?>{
                'waiting_for_user_choice': true,
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'needs_user_confirmation',
                  'permission_decision': <String, Object?>{
                    'disposition': 'needs_user_confirmation',
                  },
                },
              },
            },
          ],
          'response': <String, Object?>{},
        },
      );

      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(risk['permission'])['waiting_for_user'],
        ),
        isTrue,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(risk['overall'])['category'],
        ),
        'checkpoint_user',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(risk['overall'])['reason'],
        ),
        'permission_waiting_user',
      );
    });
  });
}
