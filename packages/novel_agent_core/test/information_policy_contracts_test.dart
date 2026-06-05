import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information policy contracts', () {
    test('source ref wraps narrative source and preserves unknown fields', () {
      final source = InformationSourceRef.fromJson(<String, Object?>{
        'source_ref': <String, Object?>{
          'source_type': NarrativeSourceTypes.deconstruction,
          'source_id': 'deconstruction-001',
          'label': '拆书抽取',
        },
        'source_authority':
            InformationSourceAuthorities.deconstructionExtracted,
        'role_authority': InformationRoleAuthorities.deconstructor,
        'research_depth': InformationResearchDepths.standard,
        'future_extension': <String, Object?>{'retain': true},
      });

      final encoded = source.toJson();

      expect(source.validateBasics(), isEmpty);
      expect(source.sourceRef.sourceType, NarrativeSourceTypes.deconstruction);
      expect(
        source.sourceAuthority,
        InformationSourceAuthorities.deconstructionExtracted,
      );
      expect(source.roleAuthority, InformationRoleAuthorities.deconstructor);
      expect(source.researchDepth, InformationResearchDepths.standard);
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_extension'])['retain'],
        ),
        isTrue,
      );
    });

    test(
      'usage policy expresses external work and read only research usage',
      () {
        final policy = InformationUsagePolicy.fromJson(<String, Object?>{
          'usage_mode': InformationUsageModes.readOnly,
          'citation_risk_level': InformationCitationRiskLevels.highRisk,
          'requires_confirmation': true,
          'allows_derivative_use': false,
          'allows_direct_quote': false,
          'reference_scope': <String, Object?>{
            'relation': 'fanfic_reference',
            'work_title': '现实作品甲',
            'license_note': '只允许研究摘记，不允许直接改写原文',
          },
          'future_policy_flag': 'keep_me',
        });

        final encoded = policy.toJson();

        expect(policy.validateBasics(), isEmpty);
        expect(policy.usageMode, InformationUsageModes.readOnly);
        expect(
          policy.citationRiskLevel,
          InformationCitationRiskLevels.highRisk,
        );
        expect(policy.requiresConfirmation, isTrue);
        expect(policy.allowsDerivativeUse, isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(policy.referenceScope)['relation'],
          ),
          'fanfic_reference',
        );
        expect(encoded['future_policy_flag'], 'keep_me');
      },
    );

    test('activation policy preserves known priorities and unknown fields', () {
      final requiredPolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': InformationActivationPriorities.required,
        },
      );
      final pinnedPolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': InformationActivationPriorities.pinned,
        },
      );
      final normalPolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': InformationActivationPriorities.normal,
        },
      );
      final referencePolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': InformationActivationPriorities.reference,
        },
      );
      final backgroundPolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': InformationActivationPriorities.background,
          'requires_explicit_selection': true,
          'preferred_budget_chars': 480,
          'future_activation_hint': <String, Object?>{'cut_last': true},
        },
      );

      final encoded = backgroundPolicy.toJson();

      expect(requiredPolicy.validateBasics(), isEmpty);
      expect(pinnedPolicy.validateBasics(), isEmpty);
      expect(normalPolicy.validateBasics(), isEmpty);
      expect(referencePolicy.validateBasics(), isEmpty);
      expect(backgroundPolicy.validateBasics(), isEmpty);
      expect(
        backgroundPolicy.activationPriority,
        InformationActivationPriorities.background,
      );
      expect(backgroundPolicy.requiresExplicitSelection, isTrue);
      expect(backgroundPolicy.preferredBudgetChars, 480);
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_activation_hint'])['cut_last'],
        ),
        isTrue,
      );
    });

    test('validation reports missing policy fields and conflicting usage', () {
      final source = InformationSourceRef.fromJson(<String, Object?>{
        'source_ref': <String, Object?>{},
      });
      final usagePolicy = InformationUsagePolicy.fromJson(<String, Object?>{
        'usage_mode': '',
        'citation_risk_level': '',
        'allows_derivative_use': false,
        'allows_direct_quote': true,
      });
      final activationPolicy = InformationActivationPolicy.fromJson(
        <String, Object?>{
          'activation_priority': '',
          'preferred_budget_chars': -1,
        },
      );

      expect(
        source.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationSourceType,
          InformationValidationCodes.missingInformationSourceAuthority,
          InformationValidationCodes.missingInformationRoleAuthority,
          InformationValidationCodes.missingInformationResearchDepth,
        ]),
      );
      expect(
        usagePolicy.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationUsageMode,
          InformationValidationCodes.missingInformationCitationRiskLevel,
          InformationValidationCodes.conflictingInformationUsageDisposition,
        ]),
      );
      expect(
        activationPolicy.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationActivationPriority,
          InformationValidationCodes.invalidInformationPreferredBudgetChars,
        ]),
      );
    });
  });
}
