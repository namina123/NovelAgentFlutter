import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WritingExecutionConstraintBridgeService', () {
    const service = WritingExecutionConstraintBridgeService();

    test(
      'binding chapter length overrides legacy metadata and reports source',
      () {
        final result = service.bridge(
          appliesTo: ConstraintBindingAppliesTo.writing,
          projectTypeId: 'long_novel',
          stageId: 'draft',
          intent: 'workflow_task',
          taskType: 'chapter',
          legacyChapterLengthOptions: const <String, Object?>{
            'enable_chapter_word_constraints': true,
            'chapter_word_target': 1800,
            'chapter_word_min': 1500,
          },
          narrativeBindings: <NarrativeConstraintBindingProposal>[
            NarrativeConstraintBindingProposal(
              bindingId: 'binding_length_main',
              constraintType: 'chapter_length',
              scope: const ConstraintBindingScope(
                appliesTo: <String>[ConstraintBindingAppliesTo.writing],
                stageIds: <String>['draft'],
              ),
              policy: const ConstraintBindingPolicy(
                hardExecutionPolicy: <String, Object?>{
                  'target_word_count': 2600,
                },
              ),
              source: const NarrativeSourceRef(sourceType: 'user'),
              constraintPayload: const <String, Object?>{
                'target_word_count': 2600,
                'preferred_min': 2300,
                'preferred_max': 2900,
              },
            ),
          ],
        );

        final profile = ValueReaders.mapValue(
          result.chapterLengthMetadata['chapter_length_profile'],
        );
        expect(ValueReaders.intValue(profile['target_length']), 2600);
        expect(ValueReaders.intValue(profile['preferred_min']), 2300);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result.runtimeReport['chapter_length'],
            )['source'],
          ),
          'binding',
        );
        expect(
          result.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.adaptive,
        );
        expect(
          result.expressionConstraintInjectionStrength,
          ExpressionConstraintInjectionStrengths.sections,
        );
        expect(
          result.expressionConstraintReviewRequirement,
          ExpressionConstraintReviewRequirements.whenApplied,
        );
        expect(result.expressionConstraintApplied, isFalse);
        expect(
          result.expressionConstraintSkippedReasons,
          contains('no_expression_constraint_bindings'),
        );
        expect(result.expressionConstraintInjectionMode, 'disabled');
        expect(result.expressionConstraintReviewRequired, isFalse);
      },
    );

    test(
      'expression bindings preserve legacy profiles and synthesize project level rules',
      () {
        final result = service.bridge(
          appliesTo: ConstraintBindingAppliesTo.writing,
          projectTypeId: 'long_novel',
          agentId: 'writer',
          stageId: 'draft',
          intent: 'draft',
          legacyExpressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少模板化收束句。'],
            },
          ],
          legacyProjectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'id': 'legacy_default',
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
          narrativeBindings: <NarrativeConstraintBindingProposal>[
            NarrativeConstraintBindingProposal(
              bindingId: 'binding_expression_1',
              constraintType: 'expression_constraint',
              constraintLabel: '表达限制',
              scope: const ConstraintBindingScope(
                appliesTo: <String>[ConstraintBindingAppliesTo.writing],
                agentIds: <String>['writer'],
              ),
              policy: const ConstraintBindingPolicy(autoAccept: true),
              source: const NarrativeSourceRef(sourceType: 'user'),
              constraintPayload: const <String, Object?>{
                'profile_id': 'de_ai',
                'project_level_rules': <Object?>['避免模板化总结句。', '收束段保持角色体感。'],
                'risk_signals': <Object?>['总而言之'],
              },
            ),
          ],
        );

        expect(
          result.expressionConstraintProfiles.map((profile) => profile.id),
          contains('de_ai'),
        );
        expect(result.expressionConstraintProfiles.length, 2);
        expect(
          result.projectExpressionConstraintBindings
              .map((binding) => binding.profileId)
              .where((profileId) => profileId == 'de_ai')
              .length,
          greaterThanOrEqualTo(1),
        );
        final synthetic = result.expressionConstraintProfiles.firstWhere(
          (profile) => profile.id != 'de_ai',
        );
        expect(synthetic.rules, contains('避免模板化总结句。'));
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              result.runtimeReport['expression_constraints'],
            )['binding_profile_count'],
          ),
          1,
        );
        expect(
          result.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.adaptive,
        );
        expect(
          result.expressionConstraintInjectionStrength,
          ExpressionConstraintInjectionStrengths.sections,
        );
        expect(
          result.expressionConstraintReviewRequirement,
          ExpressionConstraintReviewRequirements.whenApplied,
        );
        expect(result.expressionConstraintApplied, isTrue);
        expect(
          result.expressionConstraintAppliedReasons,
          contains('primary_writing_turn'),
        );
        expect(result.expressionConstraintInjectionMode, 'brief_and_sections');
        expect(result.expressionConstraintReviewRequired, isTrue);
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                result.runtimeReport['execution_gate'],
              )['expression_constraints'],
            )['review_required'],
          ),
          isTrue,
        );
      },
    );

    test(
      'policy override disabled keeps bindings explainable without requiring review',
      () {
        final result = service.bridge(
          appliesTo: ConstraintBindingAppliesTo.writing,
          projectTypeId: 'long_novel',
          stageId: 'draft',
          intent: 'draft',
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.disabled,
          legacyExpressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少模板化收束句。'],
            },
          ],
          legacyProjectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'id': 'legacy_default',
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
        );

        expect(
          result.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.disabled,
        );
        expect(result.expressionConstraintApplied, isFalse);
        expect(result.expressionConstraintInjectionMode, 'disabled');
        expect(result.expressionConstraintReviewRequired, isFalse);
        expect(
          result.expressionConstraintSkippedReasons,
          contains('policy_disabled'),
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                result.runtimeReport['execution_gate'],
              )['expression_constraints'],
            )['disabled'],
          ),
          isTrue,
        );
      },
    );

    test(
      'force policy skips workflow planning orchestration without review gate',
      () {
        final result = service.bridge(
          appliesTo: ConstraintBindingAppliesTo.writing,
          projectTypeId: 'long_novel',
          stageId: 'planning',
          intent: 'workflow_task',
          taskType: 'planning',
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          legacyExpressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少模板化收束句。'],
            },
          ],
          legacyProjectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'id': 'legacy_default',
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
        );

        expect(
          result.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.force,
        );
        expect(result.expressionConstraintApplied, isFalse);
        expect(result.expressionConstraintTechnicalTurnExcluded, isTrue);
        expect(
          result.expressionConstraintSkippedReasons,
          contains('workflow_orchestration_turn'),
        );
        expect(result.expressionConstraintInjectionMode, 'disabled');
        expect(result.expressionConstraintReviewRequired, isFalse);
        final gate = ValueReaders.mapValue(
          ValueReaders.mapValue(
            result.runtimeReport['execution_gate'],
          )['expression_constraints'],
        );
        expect(ValueReaders.boolValue(gate['applied']), isFalse);
        expect(ValueReaders.boolValue(gate['review_required']), isFalse);
      },
    );

    test(
      'force policy keeps chapter injection full without missing review gate',
      () {
        final result = service.bridge(
          appliesTo: ConstraintBindingAppliesTo.writing,
          projectTypeId: 'long_novel',
          stageId: 'draft',
          intent: 'workflow_task',
          taskType: 'chapter',
          expressionConstraintPolicyMode:
              ExpressionConstraintExecutionPolicyModes.force,
          legacyExpressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少模板化收束句。'],
            },
          ],
          legacyProjectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'id': 'legacy_default',
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
        );

        expect(result.expressionConstraintApplied, isTrue);
        expect(
          result.expressionConstraintInjectionStrength,
          ExpressionConstraintInjectionStrengths.full,
        );
        expect(
          result.expressionConstraintViolationDisposition,
          ExpressionConstraintViolationDispositions.repair,
        );
        expect(
          result.expressionConstraintReviewRequirement,
          ExpressionConstraintReviewRequirements.none,
        );
        expect(result.expressionConstraintInjectionMode, 'brief_and_sections');
        expect(result.expressionConstraintReviewRequired, isFalse);
        expect(
          result.expressionConstraintAppliedReasons,
          contains('primary_writing_turn'),
        );
      },
    );
  });
}
