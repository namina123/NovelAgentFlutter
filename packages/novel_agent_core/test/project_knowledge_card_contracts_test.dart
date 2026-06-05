import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectKnowledgeCard contracts', () {
    test(
      'round-trips ordinary setting payload without hard-coded genre enums',
      () {
        const codec = ProjectKnowledgeCardCodecService();
        final card = codec.fromJson(<String, Object?>{
          'card_id': 'knowledge-001',
          'card_namespace': 'writing.main',
          'card_type': 'world_rule',
          'title': '世界规则：梦潮期',
          'summary': '梦潮期会使城市边界不稳定。',
          'content_payload': <String, Object?>{
            'rule_family': 'world_rule',
            'named_rule': '梦潮期',
            'effects': <Object?>['街区重叠', '时间错位'],
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
                'source_id': 'user-spec-001',
              },
              'source_authority': InformationSourceAuthorities.userDeclared,
              'role_authority': InformationRoleAuthorities.user,
              'research_depth': InformationResearchDepths.none,
            },
          ],
          'scope_refs': <Object?>[
            <String, Object?>{
              'ref_type': NarrativeRefTypes.asset,
              'ref_id': 'world:main',
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.required,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.95,
          'lifecycle_status': InformationLifecycleStatuses.active,
          'schema_version': 'pis-04',
          'future_extension': <String, Object?>{'preserve': 'yes'},
        });

        final encoded = codec.toJson(card);

        expect(card.validateBasics(), isEmpty);
        expect(card.cardType, 'world_rule');
        expect(
          ValueReaders.stringValue(card.contentPayload['named_rule']),
          '梦潮期',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(encoded['future_extension'])['preserve'],
          ),
          'yes',
        );
        expect(
          (ValueReaders.objectList(card.contentPayload['effects'])).length,
          2,
        );
      },
    );

    test('round-trips external research source with open payload', () {
      const codec = ProjectKnowledgeCardCodecService();
      final card = codec.fromJson(<String, Object?>{
        'card_id': 'knowledge-002',
        'card_namespace': 'analysis.research',
        'card_type': 'cultural_reference',
        'title': '仪式命名资料',
        'content_payload': <String, Object?>{
          'naming_pattern': '以节令和方位组合命名',
          'usable_facts': <Object?>['东序', '暮节', '霜汐'],
        },
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': 'research_note',
              'source_id': 'research-001',
              'label': '外部研究摘记',
            },
            'source_authority': InformationSourceAuthorities.externalResearched,
            'role_authority': InformationRoleAuthorities.researcher,
            'research_depth': InformationResearchDepths.deep,
            'future_source_hint': <String, Object?>{'licensed': true},
          },
        ],
        'activation_policy': <String, Object?>{
          'activation_priority': InformationActivationPriorities.reference,
        },
        'usage_policy': <String, Object?>{
          'usage_mode': InformationUsageModes.referenceOnly,
          'citation_risk_level': InformationCitationRiskLevels.highRisk,
          'requires_confirmation': true,
          'reference_scope': <String, Object?>{
            'source_kind': 'external_research',
          },
        },
        'confidence': 0.72,
        'lifecycle_status': InformationLifecycleStatuses.proposed,
      });

      expect(card.validateBasics(), isEmpty);
      expect(
        card.sourceRefs.first.sourceAuthority,
        InformationSourceAuthorities.externalResearched,
      );
      expect(card.usagePolicy.usageMode, InformationUsageModes.referenceOnly);
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            card.sourceRefs.first.toJson()['future_source_hint'],
          )['licensed'],
        ),
        isTrue,
      );
    });

    test('round-trips deconstruction source and evidence refs', () {
      const codec = ProjectKnowledgeCardCodecService();
      final card = codec.fromJson(<String, Object?>{
        'card_id': 'knowledge-003',
        'card_namespace': 'analysis.deconstruction',
        'card_type': 'naming_rule',
        'title': '原作命名暗线',
        'summary': '核心角色姓氏与旧都方位一一对应。',
        'content_payload': <String, Object?>{
          'pattern': '姓氏映射旧都方位',
          'examples': <Object?>['沈-北门', '陆-西关'],
        },
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
              'source_id': 'deconstruction-bridge-001',
            },
            'source_authority':
                InformationSourceAuthorities.deconstructionExtracted,
            'role_authority': InformationRoleAuthorities.deconstructor,
            'research_depth': InformationResearchDepths.standard,
          },
        ],
        'evidence_refs': <Object?>[
          <String, Object?>{
            'evidence_type': NarrativeEvidenceTypes.extractedSnippet,
            'evidence_id': 'evidence-knowledge-001',
            'target_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.externalImportSnippet,
              'ref_id': 'snippet-001',
              'source_path': 'imports/book/chapter-03.txt',
            },
            'summary': '原文命名出现位置',
          },
        ],
        'scope_refs': <Object?>[
          <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-003',
            'relative_path': 'chapters/第03章.md',
          },
        ],
        'activation_policy': <String, Object?>{
          'activation_priority': InformationActivationPriorities.pinned,
        },
        'usage_policy': <String, Object?>{
          'usage_mode': InformationUsageModes.normal,
          'citation_risk_level': InformationCitationRiskLevels.normal,
        },
        'confidence': 0.83,
        'lifecycle_status': InformationLifecycleStatuses.accepted,
      });

      final copied = card.copyWith(
        summary: '核心角色姓氏与旧都城门方位一一对应。',
        confidence: 0.91,
      );

      expect(card.validateBasics(), isEmpty);
      expect(
        card.sourceRefs.first.sourceRef.sourceType,
        NarrativeSourceTypes.deconstruction,
      );
      expect(
        card.evidenceRefs.first.evidenceType,
        NarrativeEvidenceTypes.extractedSnippet,
      );
      expect(card.scopeRefs.first.refType, NarrativeRefTypes.chapter);
      expect(copied.summary, '核心角色姓氏与旧都城门方位一一对应。');
      expect(copied.confidence, 0.91);
      expect(
        ValueReaders.stringValue(copied.contentPayload['pattern']),
        '姓氏映射旧都方位',
      );
    });

    test('codec service supports empty card lists', () {
      const codec = ProjectKnowledgeCardCodecService();

      expect(codec.fromJsonList(const <Object?>[]), isEmpty);
      expect(codec.toJsonList(const <ProjectKnowledgeCard>[]), isEmpty);
    });

    test('validator reports missing identity and invalid nested refs', () {
      const validator = ProjectKnowledgeCardValidator();
      final card = ProjectKnowledgeCard.fromJson(<String, Object?>{
        'card_id': '',
        'card_namespace': '',
        'card_type': '',
        'title': '',
        'content_payload': <String, Object?>{},
        'source_refs': <Object?>[
          <String, Object?>{'source_ref': <String, Object?>{}},
        ],
        'evidence_refs': <Object?>[
          <String, Object?>{'evidence_type': '', 'evidence_id': ''},
        ],
        'scope_refs': <Object?>[
          <String, Object?>{'ref_type': '', 'ref_id': ''},
        ],
        'activation_policy': <String, Object?>{},
        'usage_policy': <String, Object?>{},
        'confidence': 1.3,
        'lifecycle_status': '',
      });

      expect(
        validator.validate(card),
        containsAll(<String>[
          InformationValidationCodes.missingKnowledgeCardId,
          InformationValidationCodes.missingKnowledgeCardNamespace,
          InformationValidationCodes.missingKnowledgeCardType,
          InformationValidationCodes.missingKnowledgeCardTitle,
          InformationValidationCodes.missingKnowledgeCardLifecycleStatus,
          InformationValidationCodes.invalidKnowledgeCardConfidence,
          InformationValidationCodes.invalidKnowledgeCardSourceRef,
          InformationValidationCodes.invalidKnowledgeCardEvidenceRef,
          InformationValidationCodes.invalidKnowledgeCardScopeRef,
          InformationValidationCodes.missingInformationActivationPriority,
          InformationValidationCodes.missingInformationUsageMode,
          InformationValidationCodes.missingInformationCitationRiskLevel,
        ]),
      );
    });
  });
}
