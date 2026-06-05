import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information domain tool handlers', () {
    test(
      'request external research returns accepted controlled request without network execution',
      () async {
        const handler = RequestExternalResearchHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'research-request-call-001',
            'tool_name': NarrativeDomainToolNames.requestExternalResearch,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
            'request_payload': <String, Object?>{
              'query': '北欧神话中的世界树象征',
              'purpose': '补充设定考据',
              'requested_depth': InformationResearchDepths.quick,
              'reference_relationship': 'inspiration',
              'user_granted_network_access': true,
              'target_refs': <Object?>[
                <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapter-001',
                },
              ],
              'metadata': <String, Object?>{'session_id': 'session-001'},
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(
          outcome.permissionDecision?.disposition,
          DomainToolPermissionDispositions.accepted,
        );
        expect(outcome.outcomePayload['network_execution_performed'], isFalse);
        final researchRequest =
            outcome.outcomePayload['research_request'] as Map<String, Object?>;
        expect(researchRequest['query'], '北欧神话中的世界树象征');
        expect(researchRequest['requested_by'], NarrativeSourceTypes.writer);
      },
    );

    test(
      'submit research note returns accepted note with promotion disposition',
      () async {
        const handler = SubmitResearchNoteHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'research-note-call-001',
            'tool_name': NarrativeDomainToolNames.submitResearchNote,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.system,
            },
            'request_payload': <String, Object?>{
              'research_id': 'research-001',
              'query': '星象隐喻在古典叙事中的常见用法',
              'source_kind': 'web_article',
              'source_url_or_ref': 'https://example.com/research-note',
              'citation': 'Example Research Article',
              'summary': '整理出可借鉴的象征层次。',
              'usable_facts': <Object?>['星象常用于命运预示'],
              'creative_suggestions': <Object?>['可映射为章节标题暗线'],
              'created_by': 'researcher-agent',
              'usage_policy': <String, Object?>{
                'usage_mode': InformationUsageModes.referenceOnly,
                'citation_risk_level': InformationCitationRiskLevels.normal,
                'allows_derivative_use': true,
              },
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(outcome.outcomePayload['stored_as_research_note'], isTrue);
        expect(
          outcome.outcomePayload['promotion_disposition'],
          InformationPermissionDispositions.proposed,
        );
        expect(outcome.outcomePayload['usable_fact_count'], 1);
      },
    );

    test('knowledge card from external research remains proposed', () async {
      const handler = ProposeKnowledgeCardHandler();

      final outcome = await handler.handle(
        request: DomainToolRequest.fromJson(<String, Object?>{
          'call_id': 'knowledge-card-call-001',
          'tool_name': NarrativeDomainToolNames.proposeKnowledgeCard,
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.writer,
          },
          'request_payload': <String, Object?>{
            'card_id': 'knowledge-001',
            'card_namespace': 'project.world',
            'card_type': 'cultural_mapping',
            'title': '世界树意象映射',
            'summary': '将世界树意象映射为阵营结构。',
            'content_payload': <String, Object?>{
              'motif': 'world_tree',
              'future_unknown_payload': <String, Object?>{'enabled': true},
            },
            'source_refs': <Object?>[
              <String, Object?>{
                'source_ref': <String, Object?>{
                  'source_type': NarrativeSourceTypes.system,
                },
                'source_authority':
                    InformationSourceAuthorities.externalResearched,
                'role_authority': InformationRoleAuthorities.researcher,
                'research_depth': InformationResearchDepths.standard,
              },
            ],
            'activation_policy': <String, Object?>{
              'activation_priority': InformationActivationPriorities.normal,
              'preferred_budget_chars': 320,
            },
            'usage_policy': <String, Object?>{
              'usage_mode': InformationUsageModes.referenceOnly,
              'citation_risk_level': InformationCitationRiskLevels.normal,
              'allows_derivative_use': true,
            },
            'confidence': 0.74,
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          },
        }),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.accepted,
        ),
      );

      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
      final knowledgeCard =
          outcome.outcomePayload['knowledge_card'] as Map<String, Object?>;
      expect(knowledgeCard['card_type'], 'cultural_mapping');
      expect(
        ((knowledgeCard['content_payload']
                as Map<String, Object?>)['future_unknown_payload']
            as Map<String, Object?>)['enabled'],
        isTrue,
      );
    });

    test(
      'design element proposal can require user confirmation as first-class outcome',
      () async {
        const handler = ProposeDesignElementHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'design-element-call-001',
            'tool_name': NarrativeDomainToolNames.proposeDesignElement,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
            },
            'request_payload': <String, Object?>{
              'design_id': 'design-001',
              'design_namespace': 'analysis.symbolism',
              'design_label': '命名暗线',
              'design_payload': <String, Object?>{'pattern': '章节标题都对应星宿'},
              'source_refs': <Object?>[
                <String, Object?>{
                  'source_ref': <String, Object?>{
                    'source_type': NarrativeSourceTypes.deconstruction,
                  },
                  'source_authority':
                      InformationSourceAuthorities.deconstructionExtracted,
                  'role_authority': InformationRoleAuthorities.deconstructor,
                  'research_depth': InformationResearchDepths.none,
                },
              ],
              'linked_refs': <Object?>[
                <String, Object?>{
                  'ref_type': NarrativeRefTypes.asset,
                  'ref_id': 'knowledge-001',
                },
              ],
              'activation_policy': <String, Object?>{
                'activation_priority': InformationActivationPriorities.pinned,
                'preferred_budget_chars': 180,
              },
              'usage_policy': <String, Object?>{
                'usage_mode': InformationUsageModes.restricted,
                'citation_risk_level': InformationCitationRiskLevels.highRisk,
                'requires_confirmation': true,
                'allows_derivative_use': false,
              },
              'confidence': 0.66,
              'lifecycle_status': InformationLifecycleStatuses.proposed,
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(outcome.outcomePayload.containsKey('design_element'), isTrue);
        expect(outcome.outcomePayload.containsKey('proposal'), isFalse);
        expect(outcome.outcomePayload['requires_user_confirmation'], isTrue);
      },
    );

    test('link information evidence auto-accepts structured links', () async {
      const handler = LinkInformationEvidenceHandler();

      final outcome = await handler.handle(
        request: DomainToolRequest.fromJson(<String, Object?>{
          'call_id': 'information-link-call-001',
          'tool_name': NarrativeDomainToolNames.linkInformationEvidence,
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.recovery,
          },
          'request_payload': <String, Object?>{
            'link_id': 'link-001',
            'link_type': 'supports',
            'source_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.asset,
              'ref_id': 'research-001',
            },
            'target_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.asset,
              'ref_id': 'knowledge-001',
            },
            'summary': '研究笔记支撑知识卡设定',
            'created_by': 'recovery-pipeline',
          },
        }),
        permissionDecision: const DomainToolPermissionDecision(
          disposition: DomainToolPermissionDispositions.accepted,
        ),
      );

      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
      expect(outcome.outcomePayload['link_registered'], isTrue);
      final informationLink =
          outcome.outcomePayload['information_link'] as Map<String, Object?>;
      expect(informationLink['link_type'], 'supports');
    });

    test(
      'reference work proposal can require user confirmation for high-risk relationship',
      () async {
        const handler = ProposeReferenceWorkHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'reference-work-call-001',
            'tool_name': NarrativeDomainToolNames.proposeReferenceWork,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.user,
            },
            'request_payload': <String, Object?>{
              'reference_work_id': 'reference-001',
              'title': '某原作',
              'source_refs': <Object?>[
                <String, Object?>{
                  'source_ref': <String, Object?>{
                    'source_type': NarrativeSourceTypes.user,
                  },
                  'source_authority': InformationSourceAuthorities.userDeclared,
                  'role_authority': InformationRoleAuthorities.user,
                  'research_depth': InformationResearchDepths.none,
                },
              ],
              'relationship_to_project': 'fanfic_reference',
              'declared_usage_intent': '续写练习',
              'risk_notes': <Object?>['涉及同人边界'],
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(outcome.outcomePayload['requires_user_confirmation'], isTrue);
        expect(
          outcome.outcomePayload['relationship_to_project'],
          'fanfic_reference',
        );
      },
    );

    test(
      'invalid information link payload returns invalid_payload outcome',
      () async {
        const handler = LinkInformationEvidenceHandler();

        final outcome = await handler.handle(
          request: DomainToolRequest.fromJson(<String, Object?>{
            'call_id': 'information-link-call-002',
            'tool_name': NarrativeDomainToolNames.linkInformationEvidence,
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.system,
            },
            'request_payload': <String, Object?>{
              'link_id': '',
              'link_type': 'supports',
              'source_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'research-001',
              },
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'knowledge-001',
              },
            },
          }),
          permissionDecision: const DomainToolPermissionDecision(
            disposition: DomainToolPermissionDispositions.accepted,
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        expect(
          outcome.error?.errorCode,
          'invalid_link_information_evidence_payload',
        );
      },
    );
  });
}
