import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativePermissionPolicyService', () {
    test('existing profile update requires user confirmation', () {
      const service = NarrativePermissionPolicyService();
      final request = DomainToolRequest.fromJson(<String, Object?>{
        'call_id': 'tool-call-profile-001',
        'tool_name':
            NarrativePermissionPolicyService.proposeNarrativeProfileUpdate,
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
        },
      });

      final decision = service.decide(request);
      final outcome = service.buildPermissionOutcome(
        outcomeId: 'outcome-profile-001',
        request: request,
      );

      expect(
        decision.disposition,
        DomainToolPermissionDispositions.needsUserConfirmation,
      );
      expect(
        outcome.outcomeStatus,
        DomainToolOutcomeStatuses.needsUserConfirmation,
      );
    });

    test('high-risk constraint binding requires user confirmation', () {
      const service = NarrativePermissionPolicyService();
      final request = DomainToolRequest.fromJson(<String, Object?>{
        'call_id': 'tool-call-constraint-001',
        'tool_name': NarrativePermissionPolicyService.proposeConstraintBinding,
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.system},
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
      });

      final decision = service.decide(request);

      expect(
        decision.disposition,
        DomainToolPermissionDispositions.needsUserConfirmation,
      );
    });

    test('chapter-local low-risk claims can auto accept', () {
      const service = NarrativePermissionPolicyService();
      final request = DomainToolRequest.fromJson(<String, Object?>{
        'call_id': 'tool-call-claim-001',
        'tool_name':
            NarrativePermissionPolicyService.submitNarrativeStateClaims,
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.writer},
        'request_payload': <String, Object?>{
          'claims': <Object?>[
            <String, Object?>{
              'claim_id': 'claim-001',
              'claim_namespace': 'project.state.chapter',
              'claim_payload': <String, Object?>{'state': 'updated'},
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
      });

      final decision = service.decide(request);

      expect(decision.disposition, DomainToolPermissionDispositions.accepted);
    });

    test('semantic review remains proposed rather than directly accepted', () {
      const service = NarrativePermissionPolicyService();
      final request = DomainToolRequest.fromJson(<String, Object?>{
        'call_id': 'tool-call-review-001',
        'tool_name': NarrativePermissionPolicyService.submitSemanticReview,
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
      });

      final decision = service.decide(request);

      expect(decision.disposition, DomainToolPermissionDispositions.proposed);
    });

    test('forbidden script-like payload is rejected', () {
      const service = NarrativePermissionPolicyService();
      final request = DomainToolRequest.fromJson(<String, Object?>{
        'call_id': 'tool-call-forbidden-001',
        'tool_name': NarrativePermissionPolicyService.proposeConstraintBinding,
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.system},
        'request_payload': <String, Object?>{
          'binding_id': 'binding-002',
          'constraint_type': 'chapter_length',
          'binding_scope': <String, Object?>{
            'applies_to': <Object?>[ConstraintBindingAppliesTo.deconstruction],
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
          'script': 'rm -rf /',
        },
      });

      final decision = service.decide(request);

      expect(decision.disposition, DomainToolPermissionDispositions.rejected);
      expect(decision.policyRef, 'policy.forbidden_auto_execute');
    });
  });
}
