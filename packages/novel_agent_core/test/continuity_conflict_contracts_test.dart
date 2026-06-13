import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Continuity conflict contracts', () {
    test(
      'same subject attribute can preserve multiple fact evidences and cluster them without overwriting',
      () {
        final subjectRef = const NarrativeRef(
          refType: NarrativeRefTypes.asset,
          refId: 'character:han-li',
          displayName: '韩立',
        );
        final cautiousClaim = NarrativeStateClaim.fromJson(<String, Object?>{
          'claim_id': 'claim_cautious',
          'claim_namespace': 'character.temperament',
          'claim_label': '韩立平时谨慎',
          'claim_payload': <String, Object?>{
            'trait': 'cautious',
            'context': 'ordinary_risk',
          },
          'affected_refs': <Object?>[subjectRef.toJson()],
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.deconstruction,
            'source_id': 'deconstruction-001',
          },
          'confidence': 0.82,
        });
        final daringClaim = NarrativeStateClaim.fromJson(<String, Object?>{
          'claim_id': 'claim_daring',
          'claim_namespace': 'character.temperament',
          'claim_label': '韩立在极端压力下会冒险',
          'claim_payload': <String, Object?>{
            'trait': 'daring',
            'context': 'extreme_pressure',
          },
          'affected_refs': <Object?>[subjectRef.toJson()],
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.deconstruction,
            'source_id': 'deconstruction-002',
          },
          'confidence': 0.8,
        });
        final cautiousFact = NarrativeFactEvidence.fromJson(<String, Object?>{
          'fact_evidence_id': 'fact_001',
          'subject_ref': subjectRef.toJson(),
          'attribute_key': 'temperament.risk_tolerance',
          'value_payload': <String, Object?>{'value': 'cautious'},
          'value_summary': '在普通风险下保持谨慎。',
          'claim_snapshot': cautiousClaim.toJson(),
          'source': cautiousClaim.source.toJson(),
          'confidence': 0.82,
        });
        final daringFact = NarrativeFactEvidence.fromJson(<String, Object?>{
          'fact_evidence_id': 'fact_002',
          'subject_ref': subjectRef.toJson(),
          'attribute_key': 'temperament.risk_tolerance',
          'value_payload': <String, Object?>{'value': 'daring'},
          'value_summary': '在极端压力下会冒险。',
          'condition_summary': '仅在极端压力与收益足够高时成立。',
          'claim_snapshot': daringClaim.toJson(),
          'source': daringClaim.source.toJson(),
          'confidence': 0.8,
        });

        final cluster = NarrativeConflictCluster.fromJson(<String, Object?>{
          'cluster_id': 'cluster_hanli_risk',
          'subject_ref': subjectRef.toJson(),
          'attribute_key': 'temperament.risk_tolerance',
          'classification': NarrativeConflictClassifications.conditionalChange,
          'cluster_status': NarrativeConflictClusterStatuses.needsDecision,
          'fact_evidences': <Object?>[
            cautiousFact.toJson(),
            daringFact.toJson(),
          ],
          'summary': '同一主体同一属性的两条事实都保留，等待项目决定当前采用口径。',
        });

        expect(cluster.validateBasics(), isEmpty);
        expect(cluster.factEvidences, hasLength(2));
        expect(
          cluster.factEvidences.map((entry) => entry.factEvidenceId),
          containsAll(<String>['fact_001', 'fact_002']),
        );
        expect(
          cluster.classification,
          NarrativeConflictClassifications.conditionalChange,
        );
      },
    );

    test(
      'project canon decision can keep parallel versions or select one interpretation',
      () {
        final decision = ProjectCanonDecision.fromJson(<String, Object?>{
          'decision_id': 'decision_001',
          'cluster_id': 'cluster_hanli_risk',
          'decision_kind':
              ProjectCanonDecisionKinds.adoptConditionalInterpretation,
          'selected_fact_evidence_ids': <Object?>['fact_002'],
          'retained_fact_evidence_ids': <Object?>['fact_001', 'fact_002'],
          'applicable_scope_refs': <Object?>[
            <String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-018',
            },
          ],
          'summary': '保留两条事实，但当前项目按条件性变化解释。',
          'rationale': '常态谨慎与极端压力下冒险并不互斥。',
          'review_required': true,
        });

        expect(decision.validateBasics(), isEmpty);
        expect(
          decision.decisionKind,
          ProjectCanonDecisionKinds.adoptConditionalInterpretation,
        );
        expect(decision.selectedFactEvidenceIds, <String>['fact_002']);
        expect(decision.reviewRequired, isTrue);
      },
    );

    test(
      'review alert can escalate unresolved conflicts and probable author errors without dropping evidence links',
      () {
        final alert = ContinuityReviewAlert.fromJson(<String, Object?>{
          'alert_id': 'alert_001',
          'cluster_id': 'cluster_hanli_risk',
          'alert_kind': ContinuityReviewAlertKinds.unresolvedConflict,
          'severity': ContinuityReviewAlertSeverities.high,
          'related_fact_evidence_ids': <Object?>['fact_001', 'fact_002'],
          'related_decision_id': 'decision_001',
          'summary': '当前冲突仍需人工复核再进入正式 canon。',
          'recommended_action': 'review_before_generation',
          'requires_manual_review': true,
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.reviewer,
            'source_id': 'reviewer-001',
          },
        });

        expect(alert.validateBasics(), isEmpty);
        expect(alert.relatedFactEvidenceIds, hasLength(2));
        expect(alert.requiresManualReview, isTrue);
        expect(alert.severity, ContinuityReviewAlertSeverities.high);
      },
    );

    test(
      'classification catalog covers evolution conditional perspective and error cases',
      () {
        expect(
          NarrativeConflictClassifications.knownValues,
          containsAll(<String>[
            NarrativeConflictClassifications.normalEvolution,
            NarrativeConflictClassifications.conditionalChange,
            NarrativeConflictClassifications.perspectiveDifference,
            NarrativeConflictClassifications.unexplainedConflict,
            NarrativeConflictClassifications.probableAuthorError,
          ]),
        );
      },
    );

    test('validation reports missing ids and invalid conflict metadata', () {
      final fact = NarrativeFactEvidence.fromJson(<String, Object?>{
        'fact_evidence_id': '',
        'subject_ref': <String, Object?>{},
        'attribute_key': '',
        'value_payload': <String, Object?>{},
        'claim_snapshot': <String, Object?>{},
        'source': <String, Object?>{},
        'confidence': 1.2,
      });
      final cluster = NarrativeConflictCluster.fromJson(<String, Object?>{
        'cluster_id': '',
        'subject_ref': <String, Object?>{},
        'attribute_key': '',
        'classification': 'totally_unknown',
        'cluster_status': 'mystery',
        'fact_evidences': <Object?>[fact.toJson()],
      });
      final decision = ProjectCanonDecision.fromJson(<String, Object?>{
        'decision_id': '',
        'cluster_id': '',
        'decision_kind': ProjectCanonDecisionKinds.adoptPrimaryFact,
      });
      final alert = ContinuityReviewAlert.fromJson(<String, Object?>{
        'alert_id': '',
        'cluster_id': '',
        'alert_kind': '',
        'severity': 'urgent',
        'source': <String, Object?>{},
      });

      expect(
        fact.validateBasics(),
        containsAll(<String>[
          ContinuityConflictValidationCodes.missingFactEvidenceId,
          ContinuityConflictValidationCodes.missingSubjectRefType,
          ContinuityConflictValidationCodes.missingSubjectRefId,
          ContinuityConflictValidationCodes.missingAttributeKey,
          ContinuityConflictValidationCodes.missingClaimId,
          ContinuityConflictValidationCodes.missingSourceType,
          ContinuityConflictValidationCodes.invalidConfidence,
        ]),
      );
      expect(
        cluster.validateBasics(),
        containsAll(<String>[
          ContinuityConflictValidationCodes.missingConflictClusterId,
          ContinuityConflictValidationCodes.invalidConflictClassification,
          ContinuityConflictValidationCodes.invalidConflictClusterStatus,
        ]),
      );
      expect(
        decision.validateBasics(),
        containsAll(<String>[
          ContinuityConflictValidationCodes.missingCanonDecisionId,
          ContinuityConflictValidationCodes.missingConflictClusterId,
          ContinuityConflictValidationCodes
              .decisionRequiresSelectedFactEvidence,
        ]),
      );
      expect(
        alert.validateBasics(),
        containsAll(<String>[
          ContinuityConflictValidationCodes.missingReviewAlertId,
          ContinuityConflictValidationCodes.missingConflictClusterId,
          ContinuityConflictValidationCodes.missingAlertKind,
          ContinuityConflictValidationCodes.invalidAlertSeverity,
          ContinuityConflictValidationCodes.missingSourceType,
        ]),
      );
    });
  });
}
