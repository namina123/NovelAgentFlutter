import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintInjectionPolicyService', () {
    const service = ExpressionConstraintInjectionPolicyService();

    test('uses brief and sections for draft generation', () {
      final mode = service.resolveMode(intent: 'draft');

      expect(mode, ExpressionConstraintInjectionMode.briefAndSections);
      expect(service.modeId(mode), 'brief_and_sections');
    });

    test('uses brief only for review and postprocess turns', () {
      final reviewMode = service.resolveMode(intent: 'review');
      final postprocessMode = service.resolveMode(
        intent: 'review',
        phase: 'chapter_postprocess',
      );

      expect(reviewMode, ExpressionConstraintInjectionMode.briefOnly);
      expect(postprocessMode, ExpressionConstraintInjectionMode.briefOnly);
    });

    test(
      'disables expression constraints for non-creative turns by default',
      () {
        final mode = service.resolveMode(intent: 'chat');

        expect(mode, ExpressionConstraintInjectionMode.disabled);
      },
    );

    test('uses execution policy disabled ahead of legacy intent fallback', () {
      final mode = service.resolveMode(
        executionPolicy: const ExpressionConstraintExecutionPolicy.disabled(),
        intent: 'draft',
      );

      expect(mode, ExpressionConstraintInjectionMode.disabled);
    });

    test('uses execution policy force as strongest user-visible injection', () {
      final mode = service.resolveMode(
        executionPolicy: const ExpressionConstraintExecutionPolicy.force(),
        intent: 'review',
      );

      expect(mode, ExpressionConstraintInjectionMode.briefAndSections);
    });

    test('maps brief injection strength to brief only mode', () {
      final mode = service.resolveMode(
        policyMode: ExpressionConstraintExecutionPolicyModes.adaptive,
        policyInjectionStrength: ExpressionConstraintInjectionStrengths.brief,
        intent: 'draft',
      );

      expect(mode, ExpressionConstraintInjectionMode.briefOnly);
    });

    test(
      'project stacks still clear constraints when policy disables them',
      () {
        final stack = CreativeRuleStack(
          expressionConstraints: const <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '降低模板化表达。',
            ),
          ],
          expressionConstraintBindings:
              const <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(profileId: 'de_ai'),
              ],
        );

        final brief = service.projectBriefStack(
          stack,
          executionPolicy: const ExpressionConstraintExecutionPolicy.disabled(),
        );
        final section = service.projectSectionStack(
          stack,
          executionPolicy: const ExpressionConstraintExecutionPolicy.disabled(),
        );

        expect(brief.expressionConstraints, isEmpty);
        expect(brief.expressionConstraintBindings, isEmpty);
        expect(section.expressionConstraints, isEmpty);
        expect(section.expressionConstraintBindings, isEmpty);
      },
    );

    test('project section stack keeps constraints for force policy', () {
      final stack = CreativeRuleStack(
        expressionConstraints: const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达。',
          ),
        ],
        expressionConstraintBindings:
            const <ProjectExpressionConstraintBinding>[
              ProjectExpressionConstraintBinding(profileId: 'de_ai'),
            ],
      );

      final brief = service.projectBriefStack(
        stack,
        executionPolicy: const ExpressionConstraintExecutionPolicy.force(),
      );
      final section = service.projectSectionStack(
        stack,
        executionPolicy: const ExpressionConstraintExecutionPolicy.force(),
      );

      expect(brief.expressionConstraints, isNotEmpty);
      expect(brief.expressionConstraintBindings, isNotEmpty);
      expect(section.expressionConstraints, isNotEmpty);
      expect(section.expressionConstraintBindings, isNotEmpty);
    });
  });
}
