import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Review contract models', () {
    test('shared review contract round-trips with reviewer basis findings and unknown fields', () {
      final review = ReviewContract.fromJson(<String, Object?>{
        'review_id': 'review-001',
        'review_type': 'general',
        'reviewer': <String, Object?>{
          'reviewer_id': 'reviewer-agent',
          'reviewer_role': 'reviewer',
          'label': '主审',
        },
        'basis': <String, Object?>{
          'basis_type': 'chapter_delivery',
          'summary': '基于第一章正文与约束摘要进行审查。',
          'source_paths': <Object?>['chapters/ch01.md'],
          'target_paths': <Object?>['chapters/ch01.md'],
          'policy_refs': <Object?>['policy.review.light'],
        },
        'findings': <Object?>[
          <String, Object?>{
            'finding_id': 'finding-001',
            'severity': 'blocking',
            'summary': '章节结尾状态与前文冲突。',
            'suggested_action': 'repair_character_state',
            'evidence_paths': <Object?>['chapters/ch01.md'],
          },
          <String, Object?>{
            'finding_id': 'finding-002',
            'severity': 'medium',
            'summary': '中段节奏略有重复。',
            'suggested_action': 'adjust_scene_rhythm',
            'evidence_paths': <Object?>['analysis/rhythm-note.md'],
          },
        ],
        'risk_level': 'high',
        'recommended_disposition': 'repair',
        'repair_brief': '先修正角色状态，再继续下一章。',
        'summary': '建议先插入修复任务。',
        'evidence_paths': <Object?>[
          'chapters/ch01.md',
          'reviews/general/review-001.md',
        ],
        'created_at': '2026-06-06T11:00:00Z',
        'future_field': <String, Object?>{'kept': true},
        'metadata': <String, Object?>{'source': 'test'},
      });

      final encoded = review.toJson();

      expect(review.validateBasics(), isEmpty);
      expect(review.reviewer.reviewerId, 'reviewer-agent');
      expect(review.basis.basisType, 'chapter_delivery');
      expect(review.findings.length, 2);
      expect(review.riskLevel, ReviewRiskLevels.high);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.repair,
      );
      expect(review.repairBrief, contains('修正角色状态'));
      expect(review.metadata['source'], 'test');
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_field'])['kept'],
        ),
        isTrue,
      );
    });

    test('repair disposition requires repair brief and evidence paths', () {
      const review = ReviewContract(
        reviewId: 'review-002',
        reviewType: 'general',
        reviewer: ReviewReviewerRef(
          reviewerId: 'writer',
          reviewerRole: 'writer_self_review',
        ),
        basis: ReviewBasis(
          basisType: 'chapter_delivery',
          summary: '已读取章节正文。',
        ),
        findings: <ReviewFindingContract>[
          ReviewFindingContract(
            findingId: 'finding-001',
            severity: ReviewFindingSeverities.blocking,
            summary: '发现阻塞问题。',
          ),
        ],
        riskLevel: ReviewRiskLevels.critical,
        recommendedDisposition: ReviewRecommendedDispositions.repair,
      );

      expect(
        review.validateBasics(),
        containsAll(<String>[
          ReviewContractValidationCodes.missingEvidencePaths,
          ReviewContractValidationCodes.repairDispositionNeedsBrief,
        ]),
      );
    });

    test('summary builder deduplicates evidence and counts blocking findings', () {
      const builder = ReviewSummaryBuilderService();
      const review = ReviewContract(
        reviewId: 'review-003',
        reviewType: 'style',
        reviewer: ReviewReviewerRef(
          reviewerId: 'prose_reviewer',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'checkpoint_review',
          sourcePaths: <String>['chapters/ch02.md'],
        ),
        findings: <ReviewFindingContract>[
          ReviewFindingContract(
            findingId: 'finding-a',
            severity: ReviewFindingSeverities.blocking,
            summary: '对话语气与角色设定冲突。',
            evidencePaths: <String>['chapters/ch02.md'],
          ),
          ReviewFindingContract(
            findingId: 'finding-b',
            severity: ReviewFindingSeverities.medium,
            summary: '说明句略多。',
            evidencePaths: <String>['analysis/style-note.md'],
          ),
        ],
        riskLevel: ReviewRiskLevels.high,
        recommendedDisposition: ReviewRecommendedDispositions.adjustNext,
        summary: '本章可继续，但下章前需收紧文风。',
        repairBrief: '若继续漂移则插入文风修订。',
        evidencePaths: <String>[
          'chapters/ch02.md',
          'analysis/style-note.md',
        ],
      );

      final summary = builder.buildSummary(review);

      expect(summary.validateBasics(), isEmpty);
      expect(summary.reviewId, 'review-003');
      expect(summary.findingCount, 2);
      expect(summary.blockingFindingCount, 1);
      expect(
        summary.recommendedDisposition,
        ReviewRecommendedDispositions.adjustNext,
      );
      expect(
        summary.evidencePaths,
        <String>['chapters/ch02.md', 'analysis/style-note.md'],
      );
    });

    test('artifact keeps summary and requires at least one persisted path', () {
      const artifact = ReviewArtifact(
        artifactId: 'artifact-001',
        reviewId: 'review-004',
        summary: ReviewSummary(
          reviewId: 'review-004',
          reviewType: 'continuity',
          reviewerId: 'continuity_keeper',
          reviewerRole: 'reviewer',
          riskLevel: ReviewRiskLevels.medium,
          recommendedDisposition: ReviewRecommendedDispositions.remind,
          findingCount: 1,
          blockingFindingCount: 0,
          summary: '有轻微连续性提醒。',
          evidencePaths: <String>['chapters/ch03.md'],
        ),
        jsonPath: 'reviews/continuity/review-004.json',
      );

      expect(artifact.validateBasics(), isEmpty);
      expect(artifact.summary.reviewType, 'continuity');
      expect(artifact.jsonPath, contains('review-004.json'));
    });
  });
}
