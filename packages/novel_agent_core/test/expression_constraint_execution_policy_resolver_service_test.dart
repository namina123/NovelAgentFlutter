import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintExecutionPolicyResolverService', () {
    const service = ExpressionConstraintExecutionPolicyResolverService();

    test('skips when override mode disables policy', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.disabled,
          hasBindings: true,
          intent: 'draft',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(
        resolution.policy.mode,
        ExpressionConstraintExecutionPolicyModes.disabled,
      );
      expect(resolution.whySkipped, contains('policy_disabled'));
    });

    test('applies adaptive sections for primary writing turns', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          hasBindings: true,
          appliesTo: ConstraintBindingAppliesTo.writing,
          intent: 'draft',
          taskType: 'chapter',
          stageId: 'draft',
        ),
      );

      expect(resolution.applied, isTrue);
      expect(
        resolution.policy.mode,
        ExpressionConstraintExecutionPolicyModes.adaptive,
      );
      expect(
        resolution.policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.sections,
      );
      expect(
        resolution.policy.reviewRequirement,
        ExpressionConstraintReviewRequirements.whenApplied,
      );
      expect(resolution.whyApplied, contains('primary_writing_turn'));
    });

    test('keeps adaptive review turns lighter than writing turns', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          hasBindings: true,
          appliesTo: ConstraintBindingAppliesTo.review,
          intent: 'review',
          taskType: 'review',
          phase: 'chapter_postprocess',
        ),
      );

      expect(resolution.applied, isTrue);
      expect(
        resolution.policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.brief,
      );
      expect(
        resolution.policy.reviewRequirement,
        ExpressionConstraintReviewRequirements.none,
      );
      expect(resolution.whyApplied, contains('review_turn'));
    });

    test('applies force strongly on user visible text turns', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.force,
          hasBindings: true,
          intent: 'summary',
          taskType: 'summary',
          appliesTo: ConstraintBindingAppliesTo.explanation,
        ),
      );

      expect(resolution.applied, isTrue);
      expect(
        resolution.policy.mode,
        ExpressionConstraintExecutionPolicyModes.force,
      );
      expect(
        resolution.policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.full,
      );
      expect(
        resolution.policy.reviewRequirement,
        ExpressionConstraintReviewRequirements.alwaysForWriting,
      );
      expect(
        resolution.policy.violationDisposition,
        ExpressionConstraintViolationDispositions.repair,
      );
    });

    test('skips workflow orchestration turns even in force mode', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.force,
          hasBindings: true,
          intent: 'workflow_task',
          taskType: 'planning',
          stageId: 'planning',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(resolution.technicalTurnExcluded, isTrue);
      expect(
        resolution.policy.mode,
        ExpressionConstraintExecutionPolicyModes.force,
      );
      expect(resolution.whySkipped, contains('workflow_orchestration_turn'));
    });

    test('keeps force full for workflow chapters without evidence gate', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.force,
          hasBindings: true,
          intent: 'workflow_task',
          taskType: 'chapter',
          stageId: 'draft',
        ),
      );

      expect(resolution.applied, isTrue);
      expect(
        resolution.policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.full,
      );
      expect(
        resolution.policy.reviewRequirement,
        ExpressionConstraintReviewRequirements.none,
      );
      expect(
        resolution.policy.violationDisposition,
        ExpressionConstraintViolationDispositions.repair,
      );
      expect(resolution.whyApplied, contains('primary_writing_turn'));
    });

    test('keeps user visible outline text eligible for force policy', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.force,
          hasBindings: true,
          intent: 'outline',
          taskType: 'planning',
          stageId: 'draft',
        ),
      );

      expect(resolution.applied, isTrue);
      expect(
        resolution.policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.full,
      );
      expect(resolution.whyApplied, contains('planning_turn'));
    });

    test('skips tool protocol turns even in force mode', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          overrideMode: ExpressionConstraintExecutionPolicyModes.force,
          hasBindings: true,
          intent: 'tool',
          taskType: 'tool_only',
          phase: 'tool_protocol',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(resolution.technicalTurnExcluded, isTrue);
      expect(resolution.whySkipped, contains('tool_protocol_turn'));
    });

    test('skips research execution turns by default', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          hasBindings: true,
          intent: 'research',
          taskType: 'research',
          phase: 'research_execution',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(resolution.technicalTurnExcluded, isTrue);
      expect(resolution.whySkipped, contains('research_execution_turn'));
    });

    test('skips path resolution turns by default', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          hasBindings: true,
          taskType: 'path_resolution',
          phase: 'path_resolution',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(resolution.technicalTurnExcluded, isTrue);
      expect(resolution.whySkipped, contains('path_resolution_turn'));
    });

    test('skips when project has no expression constraint bindings', () {
      final resolution = service.resolve(
        const ExpressionConstraintExecutionPolicyResolutionContext(
          hasBindings: false,
          intent: 'draft',
          taskType: 'chapter',
        ),
      );

      expect(resolution.applied, isFalse);
      expect(
        resolution.whySkipped,
        contains('no_expression_constraint_bindings'),
      );
    });

    test(
      'escalates adaptive writing policy after repeated recent violations',
      () {
        final resolution = service.resolve(
          ExpressionConstraintExecutionPolicyResolutionContext(
            hasBindings: true,
            intent: 'draft',
            taskType: 'chapter',
            recentSummaries: <WritingExecutionConstraintSummary>[
              _riskySummary(),
              _riskySummary(),
              const WritingExecutionConstraintSummary(
                present: true,
                expressionConstraintActive: true,
                expressionConstraintBindingCount: 1,
                expressionConstraintReviewRequired: true,
                expressionConstraintReviewProvided: true,
              ),
            ],
          ),
        );

        expect(resolution.applied, isTrue);
        expect(resolution.runtimeEscalated, isTrue);
        expect(
          resolution.policy.injectionStrength,
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          resolution.policy.reviewRequirement,
          ExpressionConstraintReviewRequirements.alwaysForWriting,
        );
        expect(
          resolution.policy.violationDisposition,
          ExpressionConstraintViolationDispositions.repair,
        );
        expect(resolution.whyApplied, contains('recent_violation_escalation'));
      },
    );

    test(
      'escalates adaptive writing policy after repeated surface risk summaries',
      () {
        final resolution = service.resolve(
          ExpressionConstraintExecutionPolicyResolutionContext(
            hasBindings: true,
            intent: 'draft',
            taskType: 'chapter',
            recentSummaries: <WritingExecutionConstraintSummary>[
              _surfaceRiskSummary(),
              _surfaceRiskSummary(),
            ],
          ),
        );

        expect(resolution.applied, isTrue);
        expect(resolution.runtimeEscalated, isTrue);
        expect(
          resolution.policy.injectionStrength,
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          resolution.policy.reviewRequirement,
          ExpressionConstraintReviewRequirements.alwaysForWriting,
        );
        expect(
          resolution.policy.violationDisposition,
          ExpressionConstraintViolationDispositions.repair,
        );
        expect(resolution.whyApplied, contains('recent_violation_escalation'));
      },
    );
  });
}

WritingExecutionConstraintSummary _riskySummary() {
  // 中文注释: 这个夹具模拟长任务最近章节连续出现表达限制缺证据与硬 gate 的风险信号。
  return const WritingExecutionConstraintSummary(
    present: true,
    expressionConstraintActive: true,
    expressionConstraintBindingCount: 1,
    expressionConstraintReviewRequired: true,
    expressionConstraintReviewProvided: false,
    expressionConstraintEvidenceMissing: true,
    hardConstraintTriggered: true,
    repairRequired: true,
    contentQualityRisk: true,
    reviewSuggested: true,
    hardGateReasons: <String>['expression_constraint_review_missing'],
  );
}

WritingExecutionConstraintSummary _surfaceRiskSummary() {
  // 中文注释: 这个夹具模拟真实长任务里已给出 review 证据，但连续两章都命中强表面表达风险的情况。
  return const WritingExecutionConstraintSummary(
    present: true,
    expressionConstraintActive: true,
    expressionConstraintBindingCount: 1,
    expressionConstraintReviewRequired: true,
    expressionConstraintReviewProvided: true,
    expressionConstraintViolationRecorded: true,
    expressionConstraintRuntimeEscalated: false,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.adjustNext,
    authenticityPassLevel:
        ExpressionConstraintReviewProjection.authenticityAggressive,
    reviewSuggested: true,
    miniRecheckItems: <String>['正文表面风险命中：去 AI 风：—— x6'],
    softGateReasons: <String>['expression_constraint_adjust_next_chapter'],
    expressionConstraintGate: ExpressionConstraintGateSignal(
      present: true,
      severity: ExpressionConstraintGateSeverities.warning,
      recommendedDisposition:
          ExpressionConstraintGateRecommendedDispositions.adjustNext,
      adjustNextChapter: true,
      repeatedPattern: true,
      riskSignals: <String>['正文表面风险命中：去 AI 风：—— x6'],
    ),
  );
}
