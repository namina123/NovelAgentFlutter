import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative domain tool handlers', () {
    test(
      'claims handler returns accepted outcome for low-risk chapter-local claims',
      () async {
        const handler = SubmitNarrativeStateClaimsHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'claim-call-001',
            'tool_name': NarrativeDomainToolNames.submitNarrativeStateClaims,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
            'request_payload': <String, Object?>{
              'claims': <Object?>[
                <String, Object?>{
                  'claim_id': 'claim-001',
                  'claim_namespace': 'project.state.chapter',
                  'claim_payload': <String, Object?>{
                    'future_unknown_payload': <String, Object?>{
                      'enabled': true,
                    },
                  },
                  'affected_refs': <Object?>[
                    <String, Object?>{
                      'ref_type': NarrativeRefTypes.chapter,
                      'ref_id': 'chapter-001',
                    },
                  ],
                  'context_refs': <Object?>[
                    <String, Object?>{
                      'ref_type': NarrativeRefTypes.segment,
                      'ref_id': 'segment-001',
                    },
                  ],
                  'evidence_refs': <Object?>[
                    <String, Object?>{
                      'evidence_type': NarrativeEvidenceTypes.toolCall,
                      'evidence_id': 'evidence-001',
                    },
                  ],
                  'source': <String, Object?>{
                    'source_type': NarrativeSourceTypes.writer,
                  },
                  'confidence': 0.85,
                },
              ],
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.permissionDecision?.disposition,
          DomainToolPermissionDispositions.accepted,
        );
        expect(outcome.outcomePayload['claim_count'], 1);
        final parsedClaim =
            (outcome.outcomePayload['claims'] as List<Object?>).single
                as Map<String, Object?>;
        expect(
          ((parsedClaim['claim_payload']
                  as Map<String, Object?>)['future_unknown_payload']
              as Map<String, Object?>)['enabled'],
          isTrue,
        );
      },
    );

    test(
      'profile proposal handler can return needs_user_confirmation',
      () async {
        const handler = ProposeNarrativeProfileUpdateHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'profile-call-001',
            'tool_name': NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
            },
            'request_payload': <String, Object?>{
              'proposal_id': 'proposal-001',
              'proposal_status': 'proposed',
              'target_profile_id': 'profile-001',
              'profile_patch': <String, Object?>{
                'patch_id': 'patch-001',
                'patch_payload': <String, Object?>{'scope_rule': 'expanded'},
                'source': <String, Object?>{
                  'source_type': NarrativeSourceTypes.deconstruction,
                },
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
              },
              'evidence_refs': <Object?>[
                <String, Object?>{
                  'evidence_type': NarrativeEvidenceTypes.extractedSnippet,
                  'evidence_id': 'snippet-001',
                },
              ],
              'uncertainty': '需要用户决定是否覆盖原规则。',
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.needsUserConfirmation,
            reason: '涉及长期项目规则。',
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(outcome.outcomePayload['requires_user_confirmation'], isTrue);
        final proposal =
            outcome.outcomePayload['proposal'] as Map<String, Object?>;
        expect(proposal['target_profile_id'] as String, 'profile-001');
      },
    );

    test(
      'semantic review handler remains proposed and does not advance workflow',
      () async {
        const handler = SubmitSemanticReviewHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'review-call-001',
            'tool_name': NarrativeDomainToolNames.submitSemanticReview,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.reviewer,
            },
            'request_payload': <String, Object?>{
              'review_id': 'review-001',
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.reviewer,
              },
              'recommended_disposition': 'repair',
              'findings': <Object?>[
                <String, Object?>{
                  'finding_id': 'finding-001',
                  'severity': 'blocking',
                  'summary': '需要返修。',
                  'unable_to_locate_evidence': true,
                  'unlocatable_reason': '本轮只拿到了摘要。',
                  'confidence': 0.8,
                },
              ],
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.proposed,
            reason: 'review 只进入建议链。',
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        expect(outcome.outcomePayload['review_advances_workflow'], isFalse);
        expect(outcome.outcomePayload['blocking_finding_count'], 1);
      },
    );

    test(
      'constraint binding handler can return needs_user_confirmation for high-risk proposals',
      () async {
        const handler = ProposeConstraintBindingHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'binding-call-001',
            'tool_name': NarrativeDomainToolNames.proposeConstraintBinding,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.system,
            },
            'request_payload': <String, Object?>{
              'binding_id': 'binding-001',
              'constraint_type': 'expression_constraint',
              'constraint_label': '表达限制',
              'binding_scope': <String, Object?>{
                'applies_to': <Object?>[ConstraintBindingAppliesTo.writing],
              },
              'binding_policy': <String, Object?>{'auto_accept': true},
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.system,
              },
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.needsUserConfirmation,
            reason: '高风险约束绑定。',
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(outcome.outcomePayload['requires_user_confirmation'], isTrue);
        final bindingProposal =
            outcome.outcomePayload['binding_proposal'] as Map<String, Object?>;
        expect(
          bindingProposal['constraint_type'] as String,
          'expression_constraint',
        );
      },
    );
  });
}
