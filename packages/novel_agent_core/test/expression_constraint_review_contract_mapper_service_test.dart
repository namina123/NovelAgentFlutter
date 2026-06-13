import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintReviewContractMapperService', () {
    const service = ExpressionConstraintReviewContractMapperService();
    const handoffService = ReviewRepairHandoffService();
    const summaryBuilder = ReviewSummaryBuilderService();

    test('maps adaptive repeated risk into shared adjust-next review contract', () {
      final review = service.buildReview(
        executionId: 'draft_constraint_adjust_next_001',
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
              kind: ExpressionConstraintKind.naturalExpression,
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
                  defaultForProject: true,
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.adaptive,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.alwaysForWriting,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintRuntimeEscalated: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
          expressionConstraintReviewRequired: true,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
          miniRecheckItems: <String>['检查结尾是否又回到概述句', '检查中段是否重复解释'],
        ),
        gateSignal: const ExpressionConstraintGateSignal(
          present: true,
          severity: ExpressionConstraintGateSeverities.warning,
          recommendedDisposition:
              ExpressionConstraintGateRecommendedDispositions.adjustNext,
          reason: 'expression_constraint_adjust_next_repeated_pattern',
          summary: '表达限制风险开始连续出现，建议下一章优先回调。',
          riskSignals: <String>['检查结尾是否又回到概述句', '检查中段是否重复解释'],
          repeatedPattern: true,
          adjustNextChapter: true,
        ),
        targetPaths: const <String>['chapters/ch01.md'],
      )!;

      final handoff = handoffService.handoffFromReview(review);
      final summary = summaryBuilder.buildSummary(review);

      expect(review.validateBasics(), isEmpty);
      expect(review.reviewType, ReviewTypeConstants.style);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.adjustNext,
      );
      expect(review.riskLevel, ReviewRiskLevels.medium);
      expect(review.findings, hasLength(2));
      expect(review.evidencePaths, contains('chapters/ch01.md'));
      expect(handoff.action, RepairHandoffActions.adjustNext);
      expect(summary.validateBasics(), isEmpty);
      expect(
        summary.recommendedDisposition,
        ReviewRecommendedDispositions.adjustNext,
      );
    });

    test('maps missing required review evidence into blocking repair contract', () {
      final review = service.buildReview(
        executionId: 'draft_constraint_missing_review_001',
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'strict_pov_boundary',
              displayName: '严格 POV 边界',
              summary: '限制未知信息越界。',
              kind: ExpressionConstraintKind.narrativeBoundary,
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_strict',
                  profileId: 'strict_pov_boundary',
                  defaultForProject: true,
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.full,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.alwaysForWriting,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.repair,
          expressionConstraintApplied: true,
          expressionConstraintInjectionMode: 'brief_and_sections',
          expressionConstraintReviewRequired: true,
        ),
        review: const ExpressionConstraintReviewProjection(),
        gateSignal: const ExpressionConstraintGateSignal(
          present: true,
          severity: ExpressionConstraintGateSeverities.blocking,
          recommendedDisposition:
              ExpressionConstraintGateRecommendedDispositions.repair,
          reason: 'expression_constraint_review_missing',
          summary: '表达限制要求复核，但当前缺少复核证据。',
          repairRequired: true,
        ),
        targetPaths: const <String>['chapters/ch02.md'],
      )!;

      final handoff = handoffService.handoffFromReview(review);

      expect(review.validateBasics(), isEmpty);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.repair,
      );
      expect(review.riskLevel, ReviewRiskLevels.critical);
      expect(review.repairBrief, contains('补齐表达限制复核证据'));
      expect(review.findings, hasLength(1));
      expect(review.findings.single.severity, ReviewFindingSeverities.blocking);
      expect(handoff.action, RepairHandoffActions.createBlockingRepair);
      expect(handoff.requiresRepairTask, isTrue);
      expect(
        handoff.repairRequest?.targetPaths,
        contains('chapters/ch02.md'),
      );
    });

    test('does not emit shared review contract for disabled policy', () {
      final review = service.buildReview(
        executionId: 'draft_constraint_disabled_001',
        bridgeResult: const WritingExecutionConstraintBridgeResult(
          expressionConstraintProfiles: <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达和解释腔。',
            ),
          ],
          projectExpressionConstraintBindings:
              <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  id: 'binding_1',
                  profileId: 'de_ai',
                ),
              ],
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.disabled,
          expressionConstraintInjectionStrength:
              ExpressionConstraintInjectionStrengths.none,
          expressionConstraintReviewRequirement:
              ExpressionConstraintReviewRequirements.none,
          expressionConstraintViolationDisposition:
              ExpressionConstraintViolationDispositions.remind,
          expressionConstraintApplied: false,
          expressionConstraintInjectionMode: 'disabled',
          expressionConstraintReviewRequired: false,
        ),
        review: const ExpressionConstraintReviewProjection(
          authenticityPassLevel:
              ExpressionConstraintReviewProjection.authenticityAggressive,
        ),
        gateSignal: const ExpressionConstraintGateSignal(),
        targetPaths: const <String>['chapters/ch03.md'],
      );

      expect(review, isNull);
    });
  });
}
