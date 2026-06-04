import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterDeliveryStateMachine', () {
    test('delivers clean chapter with valid submission', () {
      const machine = ChapterDeliveryStateMachine();

      final result = machine.evaluate(
        ChapterDeliveryStateRequest(
          deliveryId: 'delivery-clean',
          chapterPath: 'chapters/第01章.md',
          title: '第01章',
          chapterContent: '# 第01章\n\n这是完整正文。',
          submission: _validSubmission(),
        ),
      );

      expect(result.state, ChapterDeliveryStateStatuses.delivered);
      expect(result.recommendedAction, 'accept');
      expect(result.suggestedOutcomeStatus, DomainToolOutcomeStatuses.accepted);
      expect(result.chapterBodyDelivered, isTrue);
      expect(result.submissionAccepted, isTrue);
    });

    test('distinguishes missing body from title-only output', () {
      const machine = ChapterDeliveryStateMachine();

      final missingBody = machine.evaluate(
        ChapterDeliveryStateRequest(
          deliveryId: 'delivery-missing',
          chapterPath: 'chapters/第02章.md',
          title: '第02章',
          chapterContent: '   ',
          submission: _validSubmission(chapterId: 'chapter-002'),
        ),
      );
      final titleOnly = machine.evaluate(
        ChapterDeliveryStateRequest(
          deliveryId: 'delivery-title-only',
          chapterPath: 'chapters/第03章.md',
          title: '第03章',
          chapterContent: '# 第03章',
          submission: _validSubmission(chapterId: 'chapter-003'),
        ),
      );

      expect(
        missingBody.state,
        ChapterDeliveryStateStatuses.missingOutputRecoverable,
      );
      expect(
        titleOnly.state,
        ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
      );
      expect(missingBody.reason, 'chapter_content_missing');
      expect(titleOnly.reason, 'title_only_output');
    });

    test(
      'distinguishes path mismatch and submission missing without denying body delivery',
      () {
        const machine = ChapterDeliveryStateMachine();

        final pathMismatch = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-path',
            chapterPath: 'chapters/第04章.md',
            resolvedChapterPath: 'drafts/第04章.md',
            title: '第04章',
            chapterContent: '# 第04章\n\n正文有效。',
            submission: _validSubmission(chapterId: 'chapter-004'),
          ),
        );
        final missingSubmission = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-no-submission',
            chapterPath: 'chapters/第05章.md',
            title: '第05章',
            chapterContent: '# 第05章\n\n正文有效。',
          ),
        );

        expect(
          pathMismatch.state,
          ChapterDeliveryStateStatuses.pathMismatchRecoverable,
        );
        expect(pathMismatch.chapterBodyDelivered, isFalse);
        expect(
          missingSubmission.state,
          ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        );
        expect(missingSubmission.chapterBodyDelivered, isTrue);
        expect(missingSubmission.recommendedAction, 'request_sidecar_repair');
      },
    );

    test(
      'invalid submission still keeps delivered_needs_repair rather than failing chapter body',
      () {
        const machine = ChapterDeliveryStateMachine();
        final invalidSubmission = ChapterNarrativeSubmission.fromJson(
          <String, Object?>{
            'submission_id': '',
            'chapter_ref': <String, Object?>{},
          },
        );

        final result = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-invalid-submission',
            chapterPath: 'chapters/第06章.md',
            title: '第06章',
            chapterContent: '# 第06章\n\n正文有效。',
            submission: invalidSubmission,
          ),
        );

        expect(result.state, ChapterDeliveryStateStatuses.deliveredNeedsRepair);
        expect(result.chapterBodyDelivered, isTrue);
        expect(result.submissionAccepted, isFalse);
        expect(result.metadata['submission_validation_errors'], isNotEmpty);
      },
    );

    test(
      'maps waiting and manual gate decisions into unified delivery states',
      () {
        const machine = ChapterDeliveryStateMachine();

        final waiting = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-waiting',
            chapterPath: 'chapters/第07章.md',
            title: '第07章',
            chapterContent: '# 第07章\n\n正文有效。',
            submission: _validSubmission(chapterId: 'chapter-007'),
            gateDecision: const <String, Object?>{
              'disposition': 'blocked_wait_user',
              'reason': 'review_has_suggestions',
            },
          ),
        );
        final manual = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-manual',
            chapterPath: 'chapters/第08章.md',
            title: '第08章',
            chapterContent: '# 第08章\n\n正文有效。',
            submission: _validSubmission(chapterId: 'chapter-008'),
            gateDecision: const <String, Object?>{
              'disposition': 'manual_attention',
              'reason': 'review_has_critical_issues',
            },
          ),
        );

        expect(waiting.state, ChapterDeliveryStateStatuses.waitingUserChoice);
        expect(waiting.recommendedAction, 'checkpoint_user');
        expect(
          manual.state,
          ChapterDeliveryStateStatuses.manualAttentionRequired,
        );
        expect(manual.recommendedAction, 'manual_attention');
      },
    );

    test('distinguishes retryable missing output from hard failure', () {
      const machine = ChapterDeliveryStateMachine();

      final retryableFailure = machine.evaluate(
        const ChapterDeliveryStateRequest(
          deliveryId: 'delivery-retryable',
          chapterPath: 'chapters/第09章.md',
          writeSucceeded: false,
          retryableFailure: true,
          failureReason: '底层写入超时，可重试。',
        ),
      );
      final hardFailure = machine.evaluate(
        const ChapterDeliveryStateRequest(
          deliveryId: 'delivery-hard',
          chapterPath: 'chapters/第10章.md',
          writeSucceeded: false,
          retryableFailure: false,
          failureReason: '底层持久化失败且无法恢复。',
        ),
      );

      expect(
        retryableFailure.state,
        ChapterDeliveryStateStatuses.missingOutputRecoverable,
      );
      expect(retryableFailure.retryable, isTrue);
      expect(hardFailure.state, ChapterDeliveryStateStatuses.hardFailure);
      expect(hardFailure.retryable, isFalse);
    });
  });
}

ChapterNarrativeSubmission _validSubmission({
  String chapterId = 'chapter-001',
}) {
  return ChapterNarrativeSubmission.fromJson(<String, Object?>{
    'submission_id': 'submission-$chapterId',
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
  });
}
