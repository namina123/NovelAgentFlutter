import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeDomainToolDispatchService', () {
    test(
      'dispatches accepted chapter-local claims through matching handler',
      () async {
        final handler = _FakeNarrativeDomainToolHandler(
          capability: const NarrativeDomainToolCapability(
            toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
            displayName: '提交叙事状态声明',
            supportedSourceTypes: <String>[NarrativeSourceTypes.writer],
          ),
          outcomeBuilder: (request, permissionDecision) => DomainToolOutcome(
            outcomeId: 'outcome-${request.callId}',
            callId: request.callId,
            toolName: request.toolName,
            outcomeStatus: DomainToolOutcomeStatuses.accepted,
            permissionDecision: permissionDecision,
            outcomePayload: const <String, Object?>{'handled': true},
          ),
        );
        final service = NarrativeDomainToolDispatchService(
          handlers: <NarrativeDomainToolHandler>[handler],
        );

        final outcome = await service.dispatch(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'call-claims-001',
            'tool_name': NarrativeDomainToolNames.submitNarrativeStateClaims,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
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
          }),
        );

        expect(
          service.canDispatch(
            NarrativeDomainToolNames.submitNarrativeStateClaims,
          ),
          isTrue,
        );
        expect(
          service
              .capabilityFor(
                NarrativeDomainToolNames.submitNarrativeStateClaims,
              )
              ?.displayName,
          '提交叙事状态声明',
        );
        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.permissionDecision?.disposition,
          DomainToolPermissionDispositions.accepted,
        );
        expect(outcome.outcomePayload['handled'], isTrue);
        expect(handler.callCount, 1);
        expect(
          handler.lastPermissionDecision?.disposition,
          DomainToolPermissionDispositions.accepted,
        );
        expect(outcome.validateBasics(), isEmpty);
      },
    );

    test('returns needs_user_confirmation without invoking handler', () async {
      final handler = _FakeNarrativeDomainToolHandler(
        capability: const NarrativeDomainToolCapability(
          toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
          supportedSourceTypes: <String>[NarrativeSourceTypes.deconstruction],
        ),
        outcomeBuilder: (request, permissionDecision) => DomainToolOutcome(
          outcomeId: 'should-not-run',
          callId: request.callId,
          toolName: request.toolName,
          outcomeStatus: DomainToolOutcomeStatuses.accepted,
          permissionDecision: permissionDecision,
        ),
      );
      final service = NarrativeDomainToolDispatchService(
        handlers: <NarrativeDomainToolHandler>[handler],
      );

      final outcome = await service.dispatch(
        request: DomainToolRequest.fromJson(<String, Object?>{
          'call_id': 'call-profile-001',
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
          },
        }),
      );

      expect(
        outcome.outcomeStatus,
        DomainToolOutcomeStatuses.needsUserConfirmation,
      );
      expect(
        outcome.permissionDecision?.disposition,
        DomainToolPermissionDispositions.needsUserConfirmation,
      );
      expect(
        (outcome.outcomePayload['capability']
            as Map<String, Object?>)['tool_name'],
        NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
      );
      expect(handler.callCount, 0);
      expect(outcome.validateBasics(), isEmpty);
    });

    test(
      'returns invalid_payload for malformed request before handler runs',
      () async {
        final handler = _FakeNarrativeDomainToolHandler(
          capability: const NarrativeDomainToolCapability(
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
          ),
          outcomeBuilder: (request, permissionDecision) => DomainToolOutcome(
            outcomeId: 'should-not-run',
            callId: request.callId,
            toolName: request.toolName,
            outcomeStatus: DomainToolOutcomeStatuses.accepted,
            permissionDecision: permissionDecision,
          ),
        );
        final service = NarrativeDomainToolDispatchService(
          handlers: <NarrativeDomainToolHandler>[handler],
        );

        final outcome = await service.dispatch(
          request: const DomainToolRequest(
            callId: '',
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
            source: NarrativeSourceRef(sourceType: NarrativeSourceTypes.writer),
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        expect(outcome.error?.errorCode, 'invalid_domain_tool_request');
        expect(
          outcome.error?.errorDetails['validation_errors'],
          contains(DomainToolValidationCodes.missingCallId),
        );
        expect(handler.callCount, 0);
        expect(outcome.validateBasics(), isEmpty);
      },
    );
  });
}

class _FakeNarrativeDomainToolHandler implements NarrativeDomainToolHandler {
  _FakeNarrativeDomainToolHandler({
    required this.capability,
    required DomainToolOutcome Function(
      DomainToolRequest request,
      DomainToolPermissionDecision permissionDecision,
    )
    outcomeBuilder,
  }) : _outcomeBuilder = outcomeBuilder;

  final DomainToolOutcome Function(
    DomainToolRequest request,
    DomainToolPermissionDecision permissionDecision,
  )
  _outcomeBuilder;

  @override
  final NarrativeDomainToolCapability capability;

  int callCount = 0;
  DomainToolPermissionDecision? lastPermissionDecision;

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    callCount += 1;
    lastPermissionDecision = permissionDecision;
    return _outcomeBuilder(request, permissionDecision);
  }
}
