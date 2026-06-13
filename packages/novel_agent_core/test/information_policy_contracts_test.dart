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
        source.sourceIdentity.sourceKind,
        NarrativeSourceTypes.deconstruction,
      );
      expect(source.sourceIdentity.sourceAssetId, 'deconstruction-001');
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
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(encoded['source_ref'])['display_name'],
        ),
        '拆书抽取',
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

    test(
      'collection policy normalizes objective research into rigorous broad collection',
      () {
        const service = InformationCollectionPolicyService();

        final request = service.normalize(
          InformationCollectionRequest(
            query: '唐代天文历法的客观资料',
            requestedDepth: InformationResearchDepths.deep,
            informationDomain: InformationDomains.history,
            sourceRequirements: const InformationSourceRequirements(
              preferredDomains: <String>['gov.cn'],
            ),
            extractionPolicy: const InformationExtractionPolicy(
              maxCandidateCount: 4,
            ),
          ),
        );

        expect(request.collectionMode, InformationCollectionModes.network);
        expect(request.informationDomain, InformationDomains.history);
        expect(request.sourceRequirements.requiresRigorousSources, isTrue);
        expect(request.sourceRequirements.minSourceCount, 2);
        expect(request.extractionPolicy.collectBroadly, isTrue);
        expect(request.extractionPolicy.maxCandidateCount, 4);
        expect(request.extractionPolicy.maxFetchCount, 6);
        expect(
          request.sourceRequirements.networkRegionHint,
          InformationNetworkRegionHints.mainlandChinaPossible,
        );
      },
    );

    test(
      'collection policy routes import mode without import source back to network',
      () {
        const service = InformationCollectionPolicyService();

        final request = service.normalize(
          const InformationCollectionRequest(
            query: '明代江南士绅家庭仆役称谓',
            collectionMode: InformationCollectionModes.import,
            informationDomain: InformationDomains.history,
          ),
        );

        expect(request.collectionMode, InformationCollectionModes.network);
        expect(
          ValueReaders.stringValue(request.metadata['raw_collection_mode']),
          InformationCollectionModes.import,
        );
        expect(
          ValueReaders.stringValue(
            request.metadata['collection_mode_normalization_reason'],
          ),
          'missing_import_source_for_import_collection',
        );
      },
    );

    test(
      'collection policy keeps import mode when an import source is present',
      () {
        const service = InformationCollectionPolicyService();

        final request = service.normalize(
          InformationCollectionRequest.fromJson(<String, Object?>{
            'query': '导入资料中的命名线索',
            'collection_mode': InformationCollectionModes.import,
            'import_relative_path': 'research/source.md',
          }),
        );

        expect(request.collectionMode, InformationCollectionModes.import);
        expect(request.metadata['raw_collection_mode'], isNull);
      },
    );

    test('source quality marks rigorous and reference-only candidates', () {
      const service = InformationSourceQualityService();
      const requirements = InformationSourceRequirements(
        requiresRigorousSources: true,
        minSourceCount: 2,
      );

      final official = service.assessSearchCandidate(
        <String, Object?>{
          'title': '国家统计局数据',
          'url': 'https://www.stats.gov.cn/sj/',
          'snippet': '官方统计资料',
        },
        requirements: requirements,
        informationDomain: InformationDomains.objective,
      );
      final forum = service.assessSearchCandidate(
        <String, Object?>{
          'title': '知乎讨论',
          'url': 'https://www.zhihu.com/question/1',
          'snippet': '网友解释',
        },
        requirements: requirements,
        informationDomain: InformationDomains.objective,
      );

      expect(official.isRigorous, isTrue);
      expect(official.sourceKind, 'government');
      expect(forum.isRigorous, isFalse);
      expect(
        forum.reasons,
        contains('does_not_satisfy_rigorous_source_requirement'),
      );
    });
  });
}
