import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintExecutionPolicy', () {
    test('defaults to adaptive policy with stable contract values', () {
      const policy = ExpressionConstraintExecutionPolicy.defaultAdaptive;

      expect(policy.validateBasics(), isEmpty);
      expect(policy.mode, ExpressionConstraintExecutionPolicyModes.adaptive);
      expect(
        policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.sections,
      );
      expect(
        policy.reviewRequirement,
        ExpressionConstraintReviewRequirements.whenApplied,
      );
      expect(
        policy.violationDisposition,
        ExpressionConstraintViolationDispositions.adjustNext,
      );
      expect(policy.allowRuntimeEscalation, isTrue);
      expect(policy.excludeToolProtocols, isTrue);
      expect(policy.excludeResearchExecution, isTrue);
    });

    test('named disabled and force presets stay self-consistent', () {
      const disabled = ExpressionConstraintExecutionPolicy.disabled();
      const force = ExpressionConstraintExecutionPolicy.force();

      expect(disabled.validateBasics(), isEmpty);
      expect(disabled.mode, ExpressionConstraintExecutionPolicyModes.disabled);
      expect(
        disabled.injectionStrength,
        ExpressionConstraintInjectionStrengths.none,
      );
      expect(
        disabled.reviewRequirement,
        ExpressionConstraintReviewRequirements.none,
      );
      expect(disabled.allowRuntimeEscalation, isFalse);

      expect(force.validateBasics(), isEmpty);
      expect(force.mode, ExpressionConstraintExecutionPolicyModes.force);
      expect(
        force.injectionStrength,
        ExpressionConstraintInjectionStrengths.full,
      );
      expect(
        force.reviewRequirement,
        ExpressionConstraintReviewRequirements.alwaysForWriting,
      );
      expect(
        force.violationDisposition,
        ExpressionConstraintViolationDispositions.repair,
      );
    });

    test('codec preserves unknown top-level fields through metadata bag', () {
      final policy = ExpressionConstraintExecutionPolicy.fromJson(
        <String, Object?>{
          'mode': ExpressionConstraintExecutionPolicyModes.force,
          'future_policy_toggle': <String, Object?>{'retain': true},
          'metadata': <String, Object?>{'label': 'kept'},
        },
      );

      final encoded = policy.toJson();

      expect(policy.validateBasics(), isEmpty);
      expect(policy.mode, ExpressionConstraintExecutionPolicyModes.force);
      expect(
        policy.injectionStrength,
        ExpressionConstraintInjectionStrengths.full,
      );
      expect(policy.metadata['label'], 'kept');
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_policy_toggle'])['retain'],
        ),
        isTrue,
      );
    });

    test('fromJson uses mode-specific defaults for omitted fields', () {
      final disabled = ExpressionConstraintExecutionPolicy.fromJson(
        <String, Object?>{
          'mode': ExpressionConstraintExecutionPolicyModes.disabled,
        },
      );
      final force = ExpressionConstraintExecutionPolicy.fromJson(
        <String, Object?>{
          'mode': ExpressionConstraintExecutionPolicyModes.force,
        },
      );

      expect(disabled.validateBasics(), isEmpty);
      expect(
        disabled.injectionStrength,
        ExpressionConstraintInjectionStrengths.none,
      );
      expect(
        disabled.reviewRequirement,
        ExpressionConstraintReviewRequirements.none,
      );
      expect(disabled.allowRuntimeEscalation, isFalse);

      expect(force.validateBasics(), isEmpty);
      expect(
        force.reviewRequirement,
        ExpressionConstraintReviewRequirements.alwaysForWriting,
      );
      expect(
        force.violationDisposition,
        ExpressionConstraintViolationDispositions.repair,
      );
    });

    test('copyWith updates fields without dropping metadata', () {
      const policy = ExpressionConstraintExecutionPolicy(
        metadata: <String, Object?>{'source': 'project'},
      );

      final copied = policy.copyWith(
        mode: ExpressionConstraintExecutionPolicyModes.force,
        injectionStrength: ExpressionConstraintInjectionStrengths.full,
        reviewRequirement:
            ExpressionConstraintReviewRequirements.alwaysForWriting,
        violationDisposition: ExpressionConstraintViolationDispositions.repair,
        allowRuntimeEscalation: false,
      );

      expect(copied.mode, ExpressionConstraintExecutionPolicyModes.force);
      expect(
        copied.reviewRequirement,
        ExpressionConstraintReviewRequirements.alwaysForWriting,
      );
      expect(copied.metadata['source'], 'project');
    });

    test('validation reports invalid enum values and disabled mismatch', () {
      final invalid =
          ExpressionConstraintExecutionPolicy.fromJson(<String, Object?>{
            'mode': 'mystery',
            'injection_strength': 'hyper',
            'review_requirement': 'someday',
            'violation_disposition': 'shrug',
          });
      const disabledMismatch = ExpressionConstraintExecutionPolicy(
        mode: ExpressionConstraintExecutionPolicyModes.disabled,
        injectionStrength: ExpressionConstraintInjectionStrengths.full,
        reviewRequirement:
            ExpressionConstraintReviewRequirements.alwaysForWriting,
      );

      expect(
        invalid.validateBasics(),
        containsAll(<String>[
          ExpressionConstraintExecutionPolicyValidationCodes.invalidMode,
          ExpressionConstraintExecutionPolicyValidationCodes
              .invalidInjectionStrength,
          ExpressionConstraintExecutionPolicyValidationCodes
              .invalidReviewRequirement,
          ExpressionConstraintExecutionPolicyValidationCodes
              .invalidViolationDisposition,
        ]),
      );
      expect(
        disabledMismatch.validateBasics(),
        containsAll(<String>[
          ExpressionConstraintExecutionPolicyValidationCodes
              .invalidDisabledInjectionStrength,
          ExpressionConstraintExecutionPolicyValidationCodes
              .invalidDisabledReviewRequirement,
        ]),
      );
    });
  });
}
