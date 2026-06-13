import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SubmitChapterDeliveryHandler', () {
    test(
      'keeps delivered body accepted while missing submission becomes sidecar repair',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'delivery-call-001',
            'tool_name': NarrativeDomainToolNames.submitChapterDelivery,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
            'request_payload': <String, Object?>{
              'chapter_path': 'chapters/第01章.md',
              'chapter_content': '# 第01章\n\n正文有效。',
              'title': '第01章',
              'constraint_coverage': <String, Object?>{'length': 'covered'},
            },
            'tool_round_evidence': <String, Object?>{
              'tool_round_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.toolRound,
                'ref_id': 'tool-round-001',
              },
              'tool_call_ids': <Object?>['delivery-call-001'],
              'evidence_refs': <Object?>[
                <String, Object?>{
                  'evidence_type': NarrativeEvidenceTypes.assistantTranscript,
                  'evidence_id': 'assistant-msg-001',
                },
              ],
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        final payload = outcome.outcomePayload;

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          payload['delivery_state'],
          ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        );
        expect(payload['chapter_body_state'], 'delivered');
        expect(payload['sidecar_state'], 'missing');
        expect(
          ((payload['state_result'] as Map<String, Object?>)['reason']
              as String),
          'submission_missing',
        );
        expect(
          ((payload['constraint_coverage'] as Map<String, Object?>)['length']
              as String),
          'covered',
        );
        expect(outcome.toolRoundEvidence?.evidenceRefs, hasLength(2));
      },
    );

    test('distinguishes empty content from title-only output', () async {
      final handler = SubmitChapterDeliveryHandler();

      final missingBody = await handler.handle(
        request: _requestFor(
          callId: 'delivery-call-002',
          chapterContent: '   ',
          submission: _validSubmissionJson(chapterId: 'chapter-002'),
        ),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.accepted,
        ),
      );
      final titleOnly = await handler.handle(
        request: _requestFor(
          callId: 'delivery-call-003',
          title: '第03章',
          chapterContent: '# 第03章',
          submission: _validSubmissionJson(chapterId: 'chapter-003'),
        ),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.accepted,
        ),
      );

      expect(
        missingBody.outcomeStatus,
        DomainToolOutcomeStatuses.invalidPayload,
      );
      expect(
        missingBody.outcomePayload['delivery_state'],
        ChapterDeliveryStateStatuses.missingOutputRecoverable,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            missingBody.outcomePayload['delivery_failure'],
          )['category'],
        ),
        ChapterDeliveryFailureCategories.emptyBody,
      );
      expect(
        missingBody.outcomePayload['chapter_body_state'],
        'missing_or_retryable_failure',
      );
      expect(
        missingBody.outcomePayload['sidecar_state'],
        'blocked_by_chapter_failure',
      );

      expect(titleOnly.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
      expect(
        titleOnly.outcomePayload['delivery_state'],
        ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            titleOnly.outcomePayload['delivery_failure'],
          )['category'],
        ),
        ChapterDeliveryFailureCategories.titleOnlyOutput,
      );
      expect(
        titleOnly.outcomePayload['chapter_body_state'],
        'rewrite_required',
      );
      expect(
        titleOnly.outcomePayload['sidecar_state'],
        'blocked_by_chapter_failure',
      );
    });

    test(
      'invalid submission keeps delivered body and marks sidecar repair required',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: _requestFor(
            callId: 'delivery-call-004',
            chapterContent: '# 第04章\n\n正文有效。',
            submission: const <String, Object?>{
              'submission_id': '',
              'chapter_ref': <String, Object?>{},
            },
          ),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        final stateResult =
            outcome.outcomePayload['state_result'] as Map<String, Object?>;

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.outcomePayload['delivery_state'],
          ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        );
        expect(outcome.outcomePayload['chapter_body_state'], 'delivered');
        expect(outcome.outcomePayload['sidecar_state'], 'repair_required');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              outcome.outcomePayload['delivery_failure'],
            )['category'],
          ),
          ChapterDeliveryFailureCategories.sidecarInvalid,
        );
        expect(stateResult['submission_accepted'], isFalse);
        expect(
          ((stateResult['metadata']
                      as Map<String, Object?>)['submission_validation_errors']
                  as List<Object?>)
              .isNotEmpty,
          isTrue,
        );
      },
    );

    test(
      'dispatcher keeps chapter delivery accepted instead of downgrading to proposed',
      () async {
        final dispatcher = NarrativeDomainToolDispatchService(
          handlers: <NarrativeDomainToolHandler>[
            SubmitChapterDeliveryHandler(),
          ],
        );

        final outcome = await dispatcher.dispatch(
          request: _requestFor(
            callId: 'delivery-call-005',
            chapterContent: '# 第05章\n\n正文有效。',
            submission: _validSubmissionJson(chapterId: 'chapter-005'),
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.permissionDecision?.disposition,
          DomainToolPermissionDispositions.accepted,
        );
        expect(
          outcome.outcomePayload['delivery_state'],
          ChapterDeliveryStateStatuses.delivered,
        );
        expect(outcome.outcomePayload.containsKey('delivery_failure'), isFalse);
      },
    );

    test(
      'promotes missing sidecar into stable delivery failure payload',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: _requestFor(
            callId: 'delivery-call-005A',
            chapterContent: '# 第05A章\n\n正文有效。',
            submission: null,
          ),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              outcome.outcomePayload['delivery_failure'],
            )['category'],
          ),
          ChapterDeliveryFailureCategories.sidecarMissing,
        );
      },
    );

    test(
      'upgrades placeholder chapter path and normalizes submission ref',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: _requestFor(
            callId: 'delivery-call-006',
            title: '第01章',
            chapterContent: '# 第01章 醒在败家子床上\n\n风从窗缝里吹进来。',
            submission: _validSubmissionJson(
              chapterId: 'chapters/第01章.md',
              submissionId: 'submission:chapters/第01章.md',
            ),
          ),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        final payload = outcome.outcomePayload;
        final submission = ValueReaders.mapValue(payload['submission']);
        final chapterRef = ValueReaders.mapValue(submission['chapter_ref']);
        final pathResolution = ValueReaders.mapValue(
          payload['path_resolution'],
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(payload['chapter_path'], 'chapters/第01章_醒在败家子床上.md');
        expect(payload['requested_chapter_path'], 'chapters/第01章.md');
        expect(payload['resolved_chapter_path'], 'chapters/第01章_醒在败家子床上.md');
        expect(payload['title'], '第01章 醒在败家子床上');
        expect(pathResolution['path_changed'], isTrue);
        expect(pathResolution['reason'], 'chapter_placeholder_path_upgraded');
        expect(
          submission['submission_id'],
          'submission:chapters/第01章_醒在败家子床上.md',
        );
        expect(chapterRef['ref_id'], 'chapters/第01章_醒在败家子床上.md');
        expect(chapterRef['relative_path'], 'chapters/第01章_醒在败家子床上.md');
        expect(chapterRef['display_name'], '第01章 醒在败家子床上');
      },
    );

    test(
      'normalizes duplicate placeholder path even when title is missing',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'delivery-call-007',
            'tool_name': NarrativeDomainToolNames.submitChapterDelivery,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
            'request_payload': <String, Object?>{
              'chapter_path': 'chapters\\..\\chapters\\第04章_第04章.md',
              'chapter_content': '正文有效，但当前还没有单独标题。',
              'submission': _validSubmissionJson(
                chapterId: 'chapters/第04章_第04章.md',
              ),
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        final payload = outcome.outcomePayload;
        final submission = ValueReaders.mapValue(payload['submission']);
        final chapterRef = ValueReaders.mapValue(submission['chapter_ref']);
        final pathResolution = ValueReaders.mapValue(
          payload['path_resolution'],
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          payload['requested_chapter_path'],
          'chapters\\..\\chapters\\第04章_第04章.md',
        );
        expect(payload['chapter_path'], 'chapters/第04章.md');
        expect(payload['resolved_chapter_path'], 'chapters/第04章.md');
        expect(payload['title'], '第04章');
        expect(pathResolution['resolved_path'], 'chapters/第04章.md');
        expect(submission['title'], '第04章');
        expect(chapterRef['ref_id'], 'chapters/第04章.md');
        expect(chapterRef['relative_path'], 'chapters/第04章.md');
        expect(chapterRef['display_name'], '第04章');
      },
    );

    test(
      'synthesizes continuity handoff and chapter tail summary for empty submission shell',
      () async {
        final handler = SubmitChapterDeliveryHandler();
        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'delivery-call-008',
            'tool_name': NarrativeDomainToolNames.submitChapterDelivery,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
            'request_payload': <String, Object?>{
              'chapter_path': 'chapters/第08章.md',
              'chapter_content':
                  '# 第08章\n\n陆安谢过陈小满，沿着主街一路走到镇东头，看见大槐树下的青砖门楼。\n\n他抬手敲门，门里的人很快应声，问他找谁。',
              'title': '第08章',
              'submission': <String, Object?>{
                'submission_id': 'submission:chapters/第08章.md',
                'chapter_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapters/第08章.md',
                  'relative_path': 'chapters/第08章.md',
                },
                'title': '第08章',
                'summary': '',
                'final_state_summary': <String, Object?>{},
              },
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        final submission = ValueReaders.mapValue(
          outcome.outcomePayload['submission'],
        );
        final finalState = ValueReaders.mapValue(
          submission['final_state_summary'],
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          ValueReaders.stringValue(submission['summary']),
          contains('章末落点'),
        );
        expect(
          ValueReaders.stringValue(finalState['next_chapter_handoff']),
          contains('不要回退重演'),
        );
        expect(
          ValueReaders.stringValue(finalState['next_chapter_handoff']),
          contains('他抬手敲门'),
        );
        expect(
          ValueReaders.stringValue(finalState['chapter_end_excerpt']),
          contains('门里的人很快应声'),
        );
      },
    );
  });
}

DomainToolRequest _requestFor({
  required String callId,
  String title = '第01章',
  String chapterContent = '# 第01章\n\n正文有效。',
  Map<String, Object?>? submission,
}) {
  return DomainToolRequest.fromJson(<String, Object?>{
    'call_id': callId,
    'tool_name': NarrativeDomainToolNames.submitChapterDelivery,
    'source': <String, Object?>{'source_type': NarrativeSourceTypes.writer},
    'request_payload': <String, Object?>{
      'chapter_path': 'chapters/第01章.md',
      'chapter_content': chapterContent,
      'title': title,
      if (submission != null) 'submission': submission,
    },
  });
}

Map<String, Object?> _validSubmissionJson({
  required String chapterId,
  String submissionId = '',
}) {
  return <String, Object?>{
    'submission_id': submissionId.trim().isEmpty
        ? 'submission-$chapterId'
        : submissionId.trim(),
    'chapter_ref': <String, Object?>{
      'ref_type': NarrativeRefTypes.chapter,
      'ref_id': chapterId,
    },
    'segments': <Object?>[
      <String, Object?>{
        'segment_id': 'segment-$chapterId',
        'order_index': 0,
        'summary': '有效片段。',
      },
    ],
  };
}
