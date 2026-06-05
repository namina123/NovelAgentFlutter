import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('DesignElementCard contracts', () {
    test('round-trips naming pattern payload without fixed category table', () {
      const codec = DesignElementCardCodecService();
      final card = codec.fromJson(<String, Object?>{
        'design_id': 'design-001',
        'design_namespace': 'writing.main',
        'design_label': '命名暗线',
        'design_payload': <String, Object?>{
          'pattern_kind': 'naming_line',
          'rule': '角色姓氏首字与派系方位呼应',
          'examples': <Object?>['沈-北门', '陆-西关'],
        },
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': NarrativeSourceTypes.user,
              'source_id': 'user-design-001',
            },
            'source_authority': InformationSourceAuthorities.userDeclared,
            'role_authority': InformationRoleAuthorities.user,
            'research_depth': InformationResearchDepths.none,
          },
        ],
        'linked_refs': <Object?>[
          <String, Object?>{
            'ref_type': InformationLinkedRefTypes.knowledgeCard,
            'ref_id': 'knowledge-001',
          },
          <String, Object?>{
            'ref_type': NarrativeRefTypes.asset,
            'ref_id': 'character:hero',
          },
        ],
        'activation_policy': <String, Object?>{
          'activation_priority': InformationActivationPriorities.pinned,
        },
        'usage_policy': <String, Object?>{
          'usage_mode': InformationUsageModes.normal,
          'citation_risk_level': InformationCitationRiskLevels.low,
        },
        'confidence': 0.88,
        'uncertainty': '后续可能再补充次要角色映射。',
        'lifecycle_status': InformationLifecycleStatuses.active,
        'future_extension': <String, Object?>{'keep': true},
      });

      final encoded = codec.toJson(card);

      expect(card.validateBasics(), isEmpty);
      expect(card.designLabel, '命名暗线');
      expect(
        ValueReaders.stringValue(card.designPayload['rule']),
        '角色姓氏首字与派系方位呼应',
      );
      expect(card.linkedRefs, hasLength(2));
      expect(
        card.linkedRefs.first.refType,
        InformationLinkedRefTypes.knowledgeCard,
      );
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_extension'])['keep'],
        ),
        isTrue,
      );
    });

    test(
      'round-trips symbolic system payload with linked claim and asset refs',
      () {
        const codec = DesignElementCardCodecService();
        final card = codec.fromJson(<String, Object?>{
          'design_id': 'design-002',
          'design_namespace': 'analysis.deconstruction',
          'design_label': '象征系统',
          'design_payload': <String, Object?>{
            'symbol_family': 'mirror-water',
            'interpretation': '镜面与潮水共同指向身份反射与命运回潮',
            'motifs': <Object?>['镜', '水痕', '倒影'],
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
                'source_id': 'deconstruction-002',
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
              'evidence_id': 'design-evidence-001',
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.externalImportSnippet,
                'ref_id': 'snippet-001',
                'source_path': 'imports/source/chapter-08.txt',
              },
            },
          ],
          'scope_refs': <Object?>[
            <String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-008',
              'relative_path': 'chapters/第08章.md',
            },
          ],
          'linked_refs': <Object?>[
            <String, Object?>{
              'ref_type': InformationLinkedRefTypes.narrativeClaim,
              'ref_id': 'claim-002',
            },
            <String, Object?>{
              'ref_type': NarrativeRefTypes.asset,
              'ref_id': 'world:mirror-lake',
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.reference,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.referenceOnly,
            'citation_risk_level': InformationCitationRiskLevels.normal,
          },
          'confidence': 0.79,
          'uncertainty': '部分象征可能是解释性推断。',
          'lifecycle_status': InformationLifecycleStatuses.accepted,
        });

        expect(card.validateBasics(), isEmpty);
        expect(
          card.evidenceRefs.first.evidenceType,
          NarrativeEvidenceTypes.extractedSnippet,
        );
        expect(card.scopeRefs.first.refType, NarrativeRefTypes.chapter);
        expect(
          card.linkedRefs.first.refType,
          InformationLinkedRefTypes.narrativeClaim,
        );
        expect(
          ValueReaders.stringValue(card.designPayload['symbol_family']),
          'mirror-water',
        );
      },
    );

    test(
      'round-trips structural trick payload and copyWith preserves open payload',
      () {
        const codec = DesignElementCardCodecService();
        final card = codec.fromJson(<String, Object?>{
          'design_id': 'design-003',
          'design_namespace': 'writing.main',
          'design_label': '结构巧思',
          'design_payload': <String, Object?>{
            'structure_method': '章节开头的对话会在章末被反向解释',
            'chapter_pattern': <Object?>['伏笔先行', '末尾回扣'],
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-003',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.required,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.67,
          'uncertainty': '仍需后续章节验证是否稳定复现。',
          'lifecycle_status': InformationLifecycleStatuses.proposed,
        });

        final copied = card.copyWith(
          confidence: 0.91,
          uncertainty: '已经在后三章稳定复现。',
        );

        expect(card.validateBasics(), isEmpty);
        expect(copied.confidence, 0.91);
        expect(copied.uncertainty, '已经在后三章稳定复现。');
        expect(
          ValueReaders.stringValue(copied.designPayload['structure_method']),
          '章节开头的对话会在章末被反向解释',
        );
      },
    );

    test('codec service supports empty card lists', () {
      const codec = DesignElementCardCodecService();

      expect(codec.fromJsonList(const <Object?>[]), isEmpty);
      expect(codec.toJsonList(const <DesignElementCard>[]), isEmpty);
    });

    test('validator reports missing identity and invalid nested refs', () {
      const validator = DesignElementCardValidator();
      final card = DesignElementCard.fromJson(<String, Object?>{
        'design_id': '',
        'design_namespace': '',
        'design_label': '',
        'design_payload': <String, Object?>{},
        'source_refs': <Object?>[
          <String, Object?>{'source_ref': <String, Object?>{}},
        ],
        'evidence_refs': <Object?>[
          <String, Object?>{'evidence_type': '', 'evidence_id': ''},
        ],
        'scope_refs': <Object?>[
          <String, Object?>{'ref_type': '', 'ref_id': ''},
        ],
        'linked_refs': <Object?>[
          <String, Object?>{'ref_type': '', 'ref_id': ''},
        ],
        'activation_policy': <String, Object?>{},
        'usage_policy': <String, Object?>{},
        'confidence': 1.5,
        'lifecycle_status': '',
      });

      expect(
        validator.validate(card),
        containsAll(<String>[
          InformationValidationCodes.missingDesignElementId,
          InformationValidationCodes.missingDesignElementNamespace,
          InformationValidationCodes.missingDesignElementLabel,
          InformationValidationCodes.missingDesignElementLifecycleStatus,
          InformationValidationCodes.invalidDesignElementConfidence,
          InformationValidationCodes.invalidDesignElementSourceRef,
          InformationValidationCodes.invalidDesignElementEvidenceRef,
          InformationValidationCodes.invalidDesignElementScopeRef,
          InformationValidationCodes.invalidDesignElementLinkedRef,
          InformationValidationCodes.missingInformationActivationPriority,
          InformationValidationCodes.missingInformationUsageMode,
          InformationValidationCodes.missingInformationCitationRiskLevel,
        ]),
      );
    });
  });
}
