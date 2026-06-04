import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('DomainToolOutcome contracts', () {
    test('request preserves open payload and related tool round evidence', () {
      const codec = DomainToolCodecService();
      final request = codec.requestFromJson(<String, Object?>{
        'call_id': 'tool-call-001',
        'tool_name': 'submit_chapter_delivery',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.writer,
          'source_id': 'writer-main',
        },
        'request_payload': <String, Object?>{
          'chapter_id': 'chapter-010',
          'future_extension': <String, Object?>{'keep_unknown': true},
        },
        'target_refs': <Object?>[
          <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-010',
          },
        ],
        'tool_round_evidence': <String, Object?>{
          'tool_round_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.toolRound,
            'ref_id': 'tool-round-010',
          },
          'tool_call_ids': <Object?>['tool-call-001'],
          'evidence_refs': <Object?>[
            <String, Object?>{
              'evidence_type': NarrativeEvidenceTypes.toolCall,
              'evidence_id': 'tool-result-001',
            },
          ],
        },
      });

      final encoded = codec.requestToJson(request);

      expect(request.validateBasics(), isEmpty);
      expect(request.toolRoundEvidence, isNotNull);
      expect(
        (((encoded['request_payload']
                as Map<String, Object?>)['future_extension']
            as Map<String, Object?>)['keep_unknown']),
        isTrue,
      );
    });

    test('accepted outcome carries permission decision and audit evidence', () {
      const codec = DomainToolCodecService();
      final outcome = codec.outcomeFromJson(<String, Object?>{
        'outcome_id': 'outcome-accepted-001',
        'call_id': 'tool-call-001',
        'tool_name': 'submit_chapter_delivery',
        'outcome_status': DomainToolOutcomeStatuses.accepted,
        'permission_decision': <String, Object?>{
          'disposition': DomainToolPermissionDispositions.accepted,
          'reason': '本章局部提交风险低，可自动接收。',
        },
        'outcome_payload': <String, Object?>{
          'delivery_id': 'delivery-001',
          'accepted_claim_ids': <Object?>['claim-001'],
        },
        'tool_round_evidence': <String, Object?>{
          'tool_round_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.toolRound,
            'ref_id': 'tool-round-010',
          },
          'tool_call_ids': <Object?>['tool-call-001'],
        },
      });

      expect(outcome.validateBasics(), isEmpty);
      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
      expect(
        outcome.permissionDecision?.disposition,
        DomainToolPermissionDispositions.accepted,
      );
      expect(outcome.toolRoundEvidence?.toolRoundRef.refId, 'tool-round-010');
    });

    test('proposed rejected and waiting states remain distinguishable', () {
      final proposed = DomainToolOutcome.fromJson(<String, Object?>{
        'outcome_id': 'outcome-proposed-001',
        'call_id': 'tool-call-002',
        'tool_name': 'propose_constraint_binding',
        'outcome_status': DomainToolOutcomeStatuses.proposed,
        'permission_decision': <String, Object?>{
          'disposition': DomainToolPermissionDispositions.proposed,
          'reason': '转为项目级提案等待后续采纳。',
        },
      });
      final rejected = DomainToolOutcome.fromJson(<String, Object?>{
        'outcome_id': 'outcome-rejected-001',
        'call_id': 'tool-call-003',
        'tool_name': 'submit_semantic_review',
        'outcome_status': DomainToolOutcomeStatuses.rejected,
        'permission_decision': <String, Object?>{
          'disposition': DomainToolPermissionDispositions.rejected,
          'reason': '输入与当前项目阶段不匹配。',
        },
      });
      final waiting = DomainToolOutcome.fromJson(<String, Object?>{
        'outcome_id': 'outcome-waiting-001',
        'call_id': 'tool-call-004',
        'tool_name': 'propose_narrative_profile_update',
        'outcome_status': DomainToolOutcomeStatuses.needsUserConfirmation,
        'permission_decision': <String, Object?>{
          'disposition': DomainToolPermissionDispositions.needsUserConfirmation,
          'reason': '涉及长期项目规则变更。',
          'policy_ref': 'binding-policy-001',
        },
      });

      expect(proposed.validateBasics(), isEmpty);
      expect(rejected.validateBasics(), isEmpty);
      expect(waiting.validateBasics(), isEmpty);
      expect(proposed.outcomeStatus, isNot(rejected.outcomeStatus));
      expect(
        waiting.permissionDecision?.disposition,
        DomainToolPermissionDispositions.needsUserConfirmation,
      );
    });

    test(
      'invalid payload and execution failure remain structurally distinct',
      () {
        final invalidPayload = DomainToolOutcome.fromJson(<String, Object?>{
          'outcome_id': 'outcome-invalid-001',
          'call_id': 'tool-call-005',
          'tool_name': 'submit_chapter_delivery',
          'outcome_status': DomainToolOutcomeStatuses.invalidPayload,
          'error': <String, Object?>{
            'error_code': 'submission_missing_content',
            'message': '正文为空。',
            'error_details': <String, Object?>{'field': 'content'},
          },
        });
        final executionFailed = DomainToolOutcome.fromJson(<String, Object?>{
          'outcome_id': 'outcome-failed-001',
          'call_id': 'tool-call-006',
          'tool_name': 'submit_chapter_delivery',
          'outcome_status': DomainToolOutcomeStatuses.executionFailed,
          'error': <String, Object?>{
            'error_code': 'file_write_failed',
            'message': '底层写入失败。',
            'retryable': true,
          },
        });

        expect(invalidPayload.validateBasics(), isEmpty);
        expect(executionFailed.validateBasics(), isEmpty);
        expect(invalidPayload.error?.retryable, isFalse);
        expect(executionFailed.error?.retryable, isTrue);
        expect(
          invalidPayload.outcomeStatus,
          isNot(executionFailed.outcomeStatus),
        );
      },
    );

    test(
      'validation reports missing ids waiting permission and missing failure error',
      () {
        final request = DomainToolRequest.fromJson(<String, Object?>{
          'call_id': '',
          'tool_name': '',
          'source': <String, Object?>{},
        });
        final waiting = DomainToolOutcome.fromJson(<String, Object?>{
          'outcome_id': '',
          'call_id': '',
          'tool_name': '',
          'outcome_status': DomainToolOutcomeStatuses.needsUserConfirmation,
        });
        final failed = DomainToolOutcome.fromJson(<String, Object?>{
          'outcome_id': 'outcome-failed-002',
          'call_id': 'tool-call-007',
          'tool_name': 'submit_chapter_delivery',
          'outcome_status': DomainToolOutcomeStatuses.executionFailed,
        });

        expect(
          request.validateBasics(),
          containsAll(<String>[
            DomainToolValidationCodes.missingCallId,
            DomainToolValidationCodes.missingToolName,
            DomainToolValidationCodes.missingSourceType,
          ]),
        );
        expect(
          waiting.validateBasics(),
          containsAll(<String>[
            DomainToolValidationCodes.missingOutcomeId,
            DomainToolValidationCodes.missingCallId,
            DomainToolValidationCodes.missingToolName,
            DomainToolValidationCodes.missingPermissionDecisionForWaitingStatus,
          ]),
        );
        expect(
          failed.validateBasics(),
          contains(DomainToolValidationCodes.missingErrorForFailureStatus),
        );
      },
    );
  });
}
