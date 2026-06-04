import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RequestProfileClarificationHandler', () {
    test('returns waiting user outcome for blocking clarification', () async {
      const handler = RequestProfileClarificationHandler();

      final outcome = await handler.handle(
        request: _clarificationRequest(
          callId: 'clarify-call-001',
          blocking: true,
          options: <Object?>[
            <String, Object?>{'label': '仅本章', 'future': true},
            <String, Object?>{'title': '后续都生效'},
          ],
        ),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.proposed,
          reason: '交给 handler 转为等待用户结果。',
        ),
      );

      expect(
        outcome.outcomeStatus,
        DomainToolOutcomeStatuses.needsUserConfirmation,
      );
      expect(
        outcome.permissionDecision?.disposition,
        DomainToolPermissionDispositions.needsUserConfirmation,
      );
      expect(outcome.outcomePayload['blocking'], isTrue);
      expect(outcome.outcomePayload['blocks_progress'], isTrue);
      expect(outcome.outcomePayload['option_count'], 2);
      expect(
        (((outcome.outcomePayload['options'] as List<Object?>)[1]
                as Map<String, Object?>)['label']
            as String),
        '后续都生效',
      );
    });

    test('keeps non-blocking clarification distinguishable', () async {
      const handler = RequestProfileClarificationHandler();

      final outcome = await handler.handle(
        request: _clarificationRequest(
          callId: 'clarify-call-002',
          blocking: false,
          options: <Object?>[
            <String, Object?>{'label': '保持当前默认'},
            <String, Object?>{'label': '我来补充说明'},
          ],
        ),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.proposed,
        ),
      );

      expect(
        outcome.outcomeStatus,
        DomainToolOutcomeStatuses.needsUserConfirmation,
      );
      expect(outcome.outcomePayload['blocking'], isFalse);
      expect(outcome.outcomePayload['blocks_progress'], isFalse);
      expect(outcome.outcomePayload['freeform_allowed'], isTrue);
    });

    test('rejects oversized questionnaire as invalid payload', () async {
      const handler = RequestProfileClarificationHandler();

      final outcome = await handler.handle(
        request: _clarificationRequest(
          callId: 'clarify-call-003',
          blocking: true,
          options: <Object?>[
            <String, Object?>{'label': '选项1'},
            <String, Object?>{'label': '选项2'},
            <String, Object?>{'label': '选项3'},
            <String, Object?>{'label': '选项4'},
            <String, Object?>{'label': '选项5'},
            <String, Object?>{'label': '选项6'},
          ],
        ),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.proposed,
        ),
      );

      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
      expect(
        outcome.error?.errorDetails['validation_errors'],
        contains(ProfileClarificationValidationCodes.tooManyOptions),
      );
    });

    test('dispatcher lets handler produce waiting user outcome', () async {
      final dispatcher = NarrativeDomainToolDispatchService(
        handlers: const <NarrativeDomainToolHandler>[
          RequestProfileClarificationHandler(),
        ],
      );

      final outcome = await dispatcher.dispatch(
        request: _clarificationRequest(
          callId: 'clarify-call-004',
          blocking: true,
          options: <Object?>[
            <String, Object?>{'label': '仅本章'},
            <String, Object?>{'label': '后续都生效'},
          ],
        ),
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
        (outcome.metadata['capability'] as Map<String, Object?>)['tool_name'],
        NarrativeDomainToolNames.requestProfileClarification,
      );
    });
  });
}

DomainToolRequest _clarificationRequest({
  required String callId,
  required bool blocking,
  required List<Object?> options,
}) {
  return DomainToolRequest.fromJson(<String, Object?>{
    'call_id': callId,
    'tool_name': NarrativeDomainToolNames.requestProfileClarification,
    'source': <String, Object?>{'source_type': NarrativeSourceTypes.writer},
    'request_payload': <String, Object?>{
      'question': '当前规则是只作用于本章，还是后续章节都生效？',
      'options': options,
      'freeform_allowed': true,
      'reason': '缺少关键范围信息。',
      'blocking': blocking,
    },
  });
}
