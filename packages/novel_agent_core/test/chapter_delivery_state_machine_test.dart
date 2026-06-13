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
      expect(
        missingBody.deliveryFailure?.category,
        ChapterDeliveryFailureCategories.emptyBody,
      );
      expect(
        titleOnly.deliveryFailure?.category,
        ChapterDeliveryFailureCategories.titleOnlyOutput,
      );
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
          pathMismatch.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.pathMismatch,
        );
        expect(
          missingSubmission.state,
          ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        );
        expect(missingSubmission.chapterBodyDelivered, isTrue);
        expect(missingSubmission.recommendedAction, 'request_sidecar_repair');
        expect(
          missingSubmission.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.sidecarMissing,
        );
      },
    );

    test(
      'treats too-short body as rewrite-required content quality failure',
      () {
        const machine = ChapterDeliveryStateMachine();

        final result = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-too-short',
            chapterPath: 'chapters/第05A章.md',
            title: '第05A章',
            chapterContent: '# 第05A章\n\n太短了。',
            minimumBodyLength: 80,
            submission: _validSubmission(chapterId: 'chapter-005A'),
          ),
        );

        expect(
          result.state,
          ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
        );
        expect(result.reason, 'chapter_body_too_short');
        expect(result.chapterBodyDelivered, isFalse);
        expect(result.metadata['minimum_body_length'], 80);
        expect(
          result.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.bodyTooShort,
        );
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
        expect(
          result.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.sidecarInvalid,
        );
      },
    );

    test(
      'missing evidence keeps delivered body but marks sidecar repair required',
      () {
        const machine = ChapterDeliveryStateMachine();

        final result = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-missing-evidence',
            chapterPath: 'chapters/第06A章.md',
            title: '第06A章',
            chapterContent: '# 第06A章\n\n正文有效且有完整段落。',
            submission: _validSubmission(chapterId: 'chapter-006A'),
            requireEvidence: true,
          ),
        );

        expect(result.state, ChapterDeliveryStateStatuses.deliveredNeedsRepair);
        expect(result.reason, 'submission_evidence_missing');
        expect(result.chapterBodyDelivered, isTrue);
        expect(result.submissionAccepted, isFalse);
        expect(
          result.deliveryFailure?.category,
          ChapterDeliveryFailureCategories.deliveryEvidenceMissing,
        );
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
      expect(
        retryableFailure.deliveryFailure?.category,
        ChapterDeliveryFailureCategories.writeFailed,
      );
      expect(hardFailure.state, ChapterDeliveryStateStatuses.hardFailure);
      expect(hardFailure.retryable, isFalse);
      expect(
        hardFailure.deliveryFailure?.category,
        ChapterDeliveryFailureCategories.writeFailed,
      );
    });

    test(
      'treats severe chapter-length drift as content-quality rewrite requirement for ordinary and long-task shaped requests',
      () {
        const machine = ChapterDeliveryStateMachine();
        final evaluation = ChapterLengthEvaluation(
          profile: const ChapterLengthProfile(
            enabled: true,
            targetLength: 2200,
            preferredMin: 1800,
            preferredMax: 2600,
            stage: 'draft',
          ),
          policy: const ChapterLengthDistributionPolicy(),
          currentRecord: const ChapterLengthRecord(
            length: 700,
            sortOrder: 1,
            relativePath: 'chapters/第11章.md',
          ),
          level: 'severely_off',
          recommendedAction: 'review_or_repair',
          notes: const <String>['偏离已经明显。'],
          targetDeviation: 1500,
          targetDeviationRatio: 0.68,
        );

        final ordinary = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-ordinary-length',
            chapterPath: 'chapters/第11章.md',
            title: '第11章',
            chapterContent: '# 第11章\n\n正文有效但字数严重不足。',
            submission: _validSubmission(chapterId: 'chapter-011'),
            chapterLengthEvaluation: evaluation,
            metadata: const <String, Object?>{
              'runtime_source': 'ordinary_conversation_runtime',
            },
          ),
        );
        final longTask = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-longtask-length',
            chapterPath: 'chapters/第12章.md',
            title: '第12章',
            chapterContent: '# 第12章\n\n正文有效但字数严重不足。',
            submission: _validSubmission(chapterId: 'chapter-012'),
            chapterLengthEvaluation: evaluation,
            metadata: const <String, Object?>{
              'runtime_source': 'long_task_runtime',
            },
          ),
        );

        expect(
          ordinary.state,
          ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
        );
        expect(
          longTask.state,
          ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
        );
        expect(ordinary.reason, 'chapter_length_severely_off');
        expect(longTask.reason, 'chapter_length_severely_off');
      },
    );

    test(
      'marks missing expression-constraint review as delivered_needs_repair',
      () {
        const machine = ChapterDeliveryStateMachine();

        final missingReview = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-missing-review',
            chapterPath: 'chapters/第13章.md',
            title: '第13章',
            chapterContent: '# 第13章\n\n正文有效且结构完整。',
            submission: _validSubmission(
              chapterId: 'chapter-013',
              withEvidence: true,
            ),
            requireExpressionConstraintReview: true,
          ),
        );
        final reviewed = machine.evaluate(
          ChapterDeliveryStateRequest(
            deliveryId: 'delivery-reviewed',
            chapterPath: 'chapters/第14章.md',
            title: '第14章',
            chapterContent: '# 第14章\n\n正文有效且结构完整。',
            submission: _validSubmission(
              chapterId: 'chapter-014',
              withEvidence: true,
            ),
            requireExpressionConstraintReview: true,
            expressionConstraintReview:
                const ExpressionConstraintReviewProjection(
                  authenticityPassLevel:
                      ExpressionConstraintReviewProjection.authenticityLight,
                  reviewFocuses: <String>['控制解释腔'],
                ),
          ),
        );

        expect(
          missingReview.state,
          ChapterDeliveryStateStatuses.deliveredNeedsRepair,
        );
        expect(missingReview.reason, 'expression_constraint_review_missing');
        expect(reviewed.state, ChapterDeliveryStateStatuses.delivered);
      },
    );
  });
}

ChapterNarrativeSubmission _validSubmission({
  String chapterId = 'chapter-001',
  bool withEvidence = false,
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
    if (withEvidence)
      'evidence_refs': <Object?>[
        <String, Object?>{
          'evidence_type': NarrativeEvidenceTypes.assistantTranscript,
          'evidence_id': 'evidence-$chapterId',
        },
      ],
  });
}
