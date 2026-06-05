import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeDomainToolCatalog', () {
    test('builds twelve open tool schemas without genre enums', () {
      final catalog = NarrativeDomainToolCatalog();

      final schemas = catalog.buildOpenAiSchemas();
      final joined = schemas.toString();

      expect(schemas, hasLength(12));
      expect(
        schemas
            .map(
              (schema) =>
                  ((schema['function'] as Map<String, Object?>)['name']
                      as String),
            )
            .toList(growable: false),
        NarrativeDomainToolNames.all,
      );
      expect(joined.contains('快穿'), isFalse);
      expect(joined.contains('死亡回归'), isFalse);
      expect(joined.contains('multi_world_mode'), isFalse);
    });

    test(
      'parses core and information domain tools and preserves open payloads',
      () {
        final catalog = NarrativeDomainToolCatalog();
        const source = NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.writer,
        );

        final chapterDelivery = catalog.parseRequest(
          callId: 'call-001',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: source,
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第01章.md',
            'chapter_content': '# 第01章\n\n正文内容',
            'title': '第01章',
            'submission': <String, Object?>{
              'summary': '章节摘要',
              'future_sidecar_flag': true,
            },
            'future_top_level': <String, Object?>{'keep': true},
          },
        );
        final claims = catalog.parseRequest(
          callId: 'call-002',
          toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
          source: source,
          arguments: <String, Object?>{
            'source': 'writer_generated',
            'claims': <Object?>[
              <String, Object?>{
                'claim_id': 'claim-001',
                'claim_namespace': 'project.state.future',
                'claim_payload': <String, Object?>{
                  'future_unknown_payload': <String, Object?>{'enabled': true},
                },
                'confidence': 0.8,
              },
            ],
            'top_level_extension': 'keep_me',
          },
        );
        final profile = catalog.parseRequest(
          callId: 'call-003',
          toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.deconstruction,
          ),
          arguments: <String, Object?>{
            'proposal_id': 'proposal-001',
            'profile_patch': <String, Object?>{
              'namespace': 'project.custom.profile',
              'display_name': '自定义解释器',
              'future_patch_payload': <String, Object?>{'layers': 3},
            },
            'requires_user_confirmation': true,
          },
        );
        final review = catalog.parseRequest(
          callId: 'call-004',
          toolName: NarrativeDomainToolNames.submitSemanticReview,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.reviewer,
          ),
          arguments: <String, Object?>{
            'review_id': 'review-001',
            'accepted_claims': <Object?>['claim-001'],
            'questioned_claims': <Object?>['claim-002'],
            'findings': <Object?>[
              <String, Object?>{
                'finding_id': 'finding-001',
                'severity': 'medium',
                'summary': '需要补证据。',
                'unable_to_locate_evidence': true,
                'unlocatable_reason': '本轮只有摘要。',
                'confidence': 0.7,
              },
            ],
            'recommended_disposition': 'repair',
          },
        );
        final binding = catalog.parseRequest(
          callId: 'call-005',
          toolName: NarrativeDomainToolNames.proposeConstraintBinding,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.user,
          ),
          arguments: <String, Object?>{
            'binding_id': 'binding-001',
            'constraint_ref': 'expression_constraint.future',
            'applies_to': <Object?>['writing', 'review'],
            'hard_execution_policy': <String, Object?>{
              'ban': <Object?>['x'],
            },
            'soft_review_policy': <String, Object?>{
              'watch': <Object?>['y'],
            },
            'reason': '项目新增限制',
          },
        );
        final clarification = catalog.parseRequest(
          callId: 'call-006',
          toolName: NarrativeDomainToolNames.requestProfileClarification,
          source: source,
          arguments: <String, Object?>{
            'question': '当前规则是只作用于本章，还是后续章节都生效？',
            'options': <Object?>[
              <String, Object?>{'label': '仅本章', 'future': true},
              <String, Object?>{'title': '后续都生效'},
            ],
            'freeform_allowed': true,
            'blocking': true,
          },
        );
        final externalResearch = catalog.parseRequest(
        callId: 'call-007',
        toolName: NarrativeDomainToolNames.requestExternalResearch,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.explainer,
        ),
          arguments: <String, Object?>{
            'query': '镜潮神话中的身份回返',
            'requested_depth': 'deep',
            'reference_relationship': 'inspiration',
            'future_gate_hint': <String, Object?>{'keep': true},
          },
        );
        final researchNote = catalog.parseRequest(
        callId: 'call-008',
        toolName: NarrativeDomainToolNames.submitResearchNote,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.explainer,
        ),
          arguments: <String, Object?>{
            'research_id': 'research-001',
            'query': '镜潮神话中的身份回返',
            'source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/mirror-tide',
            'citation': '《镜潮神话》摘要',
            'summary': '镜与潮在外部资料中常共同承担身份映照作用。',
            'usable_facts': <Object?>['镜与潮经常并置出现。'],
            'creative_suggestions': <Object?>['可作为章节开头和结尾的回扣。'],
            'created_by': 'researcher.agent',
            'usage_policy': <String, Object?>{
              'usage_mode': InformationUsageModes.referenceOnly,
              'citation_risk_level': InformationCitationRiskLevels.normal,
            },
            'future_research_extension': <String, Object?>{'preserve': true},
          },
        );
        final knowledgeCard = catalog.parseRequest(
          callId: 'call-009',
          toolName: NarrativeDomainToolNames.proposeKnowledgeCard,
          source: source,
          arguments: <String, Object?>{
            'card_id': 'knowledge-001',
            'card_namespace': 'writing.main',
            'card_type': 'world_rule',
            'title': '月潮规则',
            'content_payload': <String, Object?>{
              'rule': '月潮夜会放大记忆回声',
              'future_unknown_payload': <String, Object?>{'keep': true},
            },
            'source_refs': <Object?>[
              <String, Object?>{
                'source_ref': <String, Object?>{
                  'source_type': NarrativeSourceTypes.user,
                  'source_id': 'user-knowledge-001',
                },
                'source_authority': InformationSourceAuthorities.userDeclared,
                'role_authority': InformationRoleAuthorities.user,
                'research_depth': InformationResearchDepths.none,
              },
            ],
            'activation_policy': <String, Object?>{
              'activation_priority': InformationActivationPriorities.required,
            },
            'usage_policy': <String, Object?>{
              'usage_mode': InformationUsageModes.normal,
              'citation_risk_level': InformationCitationRiskLevels.low,
            },
            'confidence': 0.9,
            'future_top_level': <String, Object?>{'preserve': 'yes'},
          },
        );
        final designElement = catalog.parseRequest(
          callId: 'call-010',
          toolName: NarrativeDomainToolNames.proposeDesignElement,
          source: source,
          arguments: <String, Object?>{
            'design_id': 'design-001',
            'design_namespace': 'writing.main',
            'design_label': '镜潮回扣',
            'design_payload': <String, Object?>{'motif': '章末的潮声反向解释开头的镜面描写'},
            'source_refs': <Object?>[
              <String, Object?>{
                'source_ref': <String, Object?>{
                  'source_type': NarrativeSourceTypes.writer,
                  'source_id': 'writer-design-001',
                },
                'source_authority': InformationSourceAuthorities.aiInferred,
                'role_authority': InformationRoleAuthorities.writer,
                'research_depth': InformationResearchDepths.quick,
              },
            ],
            'activation_policy': <String, Object?>{
              'activation_priority': InformationActivationPriorities.pinned,
            },
            'usage_policy': <String, Object?>{
              'usage_mode': InformationUsageModes.normal,
              'citation_risk_level': InformationCitationRiskLevels.low,
            },
            'confidence': 0.8,
            'uncertainty': '仍需后续章节验证。',
          },
        );
        final informationLink = catalog.parseRequest(
          callId: 'call-011',
          toolName: NarrativeDomainToolNames.linkInformationEvidence,
          source: source,
          arguments: <String, Object?>{
            'link_id': 'link-001',
            'link_type': 'supports_design',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.researchNote,
              'ref_id': 'research-001',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.designElement,
              'ref_id': 'design-001',
            },
            'future_link_hint': <String, Object?>{'keep': true},
          },
        );
        final referenceWork = catalog.parseRequest(
          callId: 'call-012',
          toolName: NarrativeDomainToolNames.proposeReferenceWork,
          source: source,
          arguments: <String, Object?>{
            'reference_work_id': 'reference-001',
            'title': '雾海镜宫',
            'source_refs': <Object?>[
              <String, Object?>{
                'source_ref': <String, Object?>{
                  'source_type': NarrativeSourceTypes.user,
                  'source_id': 'user-reference-001',
                },
                'source_authority': InformationSourceAuthorities.userDeclared,
                'role_authority': InformationRoleAuthorities.user,
                'research_depth': InformationResearchDepths.none,
              },
            ],
            'relationship_to_project': 'fanfic_reference',
            'declared_usage_intent': '同人续写练习，只借用角色与世界观轮廓。',
            'future_reference_note': <String, Object?>{'keep': true},
          },
        );

        expect(chapterDelivery.isSuccess, isTrue);
        expect(claims.isSuccess, isTrue);
        expect(profile.isSuccess, isTrue);
        expect(review.isSuccess, isTrue);
        expect(binding.isSuccess, isTrue);
        expect(clarification.isSuccess, isTrue);
        expect(externalResearch.isSuccess, isTrue);
        expect(researchNote.isSuccess, isTrue);
        expect(knowledgeCard.isSuccess, isTrue);
        expect(designElement.isSuccess, isTrue);
        expect(informationLink.isSuccess, isTrue);
        expect(referenceWork.isSuccess, isTrue);

        final chapterMetadata =
            chapterDelivery.request!.requestPayload['metadata']
                as Map<String, Object?>;
        final chapterUnknownFields =
            chapterMetadata[OpenJsonContractCodecService
                    .unknownFieldsMetadataKey]
                as Map<String, Object?>;
        final parsedClaim =
            (claims.request!.requestPayload['claims'] as List<Object?>).single
                as Map<String, Object?>;
        final parsedProfilePatch =
            profile.request!.requestPayload['profile_patch']
                as Map<String, Object?>;
        final clarificationOptions =
            clarification.request!.requestPayload['options'] as List<Object?>;
        final externalResearchMetadata =
            externalResearch.request!.requestPayload['metadata']
                as Map<String, Object?>;
        expect(
          (chapterUnknownFields['future_top_level']
              as Map<String, Object?>)['keep'],
          isTrue,
        );
        expect(
          (parsedClaim['source'] as Map<String, Object?>)['source_type'],
          'writer_generated',
        );
        expect(
          ((parsedClaim['claim_payload']
                  as Map<String, Object?>)['future_unknown_payload']
              as Map<String, Object?>)['enabled'],
          isTrue,
        );
        expect(
          (profile.request!.requestPayload['proposal_status'] as String),
          'proposed',
        );
        expect(
          ((parsedProfilePatch['patch_payload']
                  as Map<String, Object?>)['future_patch_payload']
              as Map<String, Object?>)['layers'],
          3,
        );
        expect(review.request!.requestPayload['accepted_claim_ids'], <String>[
          'claim-001',
        ]);
        expect(
          (binding.request!.requestPayload['constraint_type'] as String),
          'expression_constraint.future',
        );
        expect(
          ((clarificationOptions[1] as Map<String, Object?>)['label']
              as String),
          '后续都生效',
        );
        expect(
          (externalResearchMetadata[OpenJsonContractCodecService
                  .unknownFieldsMetadataKey]
              as Map<String, Object?>)['future_gate_hint'],
          isNotNull,
        );
        expect(
          ValueReaders.stringValue(
            researchNote.request!.requestPayload['source_kind'],
          ),
          'web_article',
        );
        expect(
          researchNote.request!.requestPayload['future_research_extension'],
          isNotNull,
        );
        expect(
          ValueReaders.stringValue(
            knowledgeCard.request!.requestPayload['lifecycle_status'],
          ),
          InformationLifecycleStatuses.proposed,
        );
        expect(
          knowledgeCard.request!.requestPayload['future_top_level'],
          isNotNull,
        );
        expect(
          ValueReaders.stringValue(
            designElement.request!.requestPayload['lifecycle_status'],
          ),
          InformationLifecycleStatuses.proposed,
        );
        expect(
          informationLink.request!.requestPayload['future_link_hint'],
          isNotNull,
        );
        expect(
          ValueReaders.stringValue(
            referenceWork.request!.requestPayload['relationship_to_project'],
          ),
          'fanfic_reference',
        );
        expect(
          referenceWork.request!.requestPayload['future_reference_note'],
          isNotNull,
        );
      },
    );

    test(
      'chapter delivery keeps invalid submission for later state machine handling',
      () {
        final catalog = NarrativeDomainToolCatalog();

        final result = catalog.parseRequest(
          callId: 'call-007',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第02章.md',
            'chapter_content': '# 第02章\n\n正文内容',
            'submission': <String, Object?>{
              'submission_id': '',
              'chapter_ref': <String, Object?>{},
            },
          },
        );

        expect(result.isSuccess, isTrue);
        expect(
          ((result.request!.requestPayload['metadata']
                      as Map<String, Object?>)['submission_validation_errors']
                  as List<Object?>)
              .isNotEmpty,
          isTrue,
        );
      },
    );

    test('returns structured issues for malformed payloads', () {
      final catalog = NarrativeDomainToolCatalog();

      final malformedDelivery = catalog.parseRequest(
        callId: 'call-008',
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.writer,
        ),
        arguments: <String, Object?>{
          'chapter_content': '# 第03章',
          'submission': 'not-a-map',
        },
      );
      final malformedClarification = catalog.parseRequest(
        callId: 'call-009',
        toolName: NarrativeDomainToolNames.requestProfileClarification,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.writer,
        ),
        arguments: <String, Object?>{
          'question': '请选择规则',
          'options': <Object?>[
            <String, Object?>{'id': 'opt-1'},
          ],
        },
      );
      final malformedResearchNote = catalog.parseRequest(
        callId: 'call-010',
        toolName: NarrativeDomainToolNames.submitResearchNote,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.explainer,
        ),
        arguments: <String, Object?>{
          'research_id': 'research-invalid',
          'query': '',
          'source_kind': 'web_article',
          'source_url_or_ref': '',
          'citation': '',
          'summary': '',
          'created_by': '',
          'usage_policy': <String, Object?>{},
        },
      );

      expect(malformedDelivery.isSuccess, isFalse);
      expect(
        malformedDelivery.issues.map((issue) => issue.code),
        contains(NarrativeDomainToolValidationCodes.missingRequiredField),
      );
      expect(
        malformedClarification.issues.single.fieldPath,
        'options[0].label',
      );
      expect(malformedResearchNote.isSuccess, isFalse);
      expect(
        malformedResearchNote.issues.single.code,
        NarrativeDomainToolValidationCodes.invalidNestedContract,
      );
    });
  });
}
